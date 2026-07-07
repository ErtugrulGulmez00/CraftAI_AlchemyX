import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/haptics.dart';
import '../core/localization/app_strings.dart';
import '../core/theme/app_theme.dart';
import '../models/element_model.dart';
import '../providers/game_provider.dart';
import '../providers/settings_provider.dart';
import 'element_card.dart';
import 'globe_background.dart';
import 'merge_particles.dart';

/// Virtual canvas size — elements can be placed anywhere in this space.
const double _kVirtualSize = 4000;

/// Below this zoom level the table starts blending into the "planet in
/// space" globe visualization; at/above it, it's the normal flat table.
/// Purely a rendering threshold derived from the existing [_scale] — it
/// does not add any new gesture/state logic.
const double _kGlobeThreshold = 0.6;

/// The pinch-zoom lower bound (see the `.clamp(_kMinScale, 2.5)` call in
/// `_onPointerMove`). The globe transition is calibrated against this so it
/// actually reaches full effect at maximum zoom-out, instead of an
/// arbitrary fraction of it.
const double _kMinScale = 0.35;

/// Deep-space gradient for the crafting table itself, independent of the
/// app's light/dark theme — the table is meant to read as space at any
/// zoom, consistent with the globe view it blends into.
const Color _kSpaceTop = Color(0xFF14102A);
const Color _kSpaceBottom = Color(0xFF05040A);

/// The top "alchemy table": a pannable, zoomable infinite canvas where
/// elements can be dragged around and dropped onto each other to combine.
class CraftCanvas extends StatefulWidget {
  const CraftCanvas({super.key});

  @override
  State<CraftCanvas> createState() => _CraftCanvasState();
}

class _CraftCanvasState extends State<CraftCanvas>
    with SingleTickerProviderStateMixin {
  static const double itemSize = kCraftItemSize;
  final GlobalKey _canvasKey = GlobalKey();

  // Slow, purely decorative rotation for the globe starfield — independent
  // of and never interacts with the pan/zoom pointer logic below.
  late final AnimationController _globeRotation;

  @override
  void initState() {
    super.initState();
    _globeRotation = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 50),
    )..repeat();
  }

  @override
  void dispose() {
    _globeRotation.dispose();
    super.dispose();
  }

  // ── Pan / zoom state ─────────────────────────────────────────────────────
  // Implemented with a raw Listener (not GestureDetector) so panning never
  // competes in the gesture arena with a child element's Draggable — a
  // GestureDetector's ScaleGestureRecognizer can win that arena and starve
  // the item's own drag recognizer, making items undraggable after a
  // pinch/pan. Listener always receives every pointer event regardless of
  // arena outcome, so it can never block descendants.
  Offset _panOffset = Offset.zero;
  double _scale = 1.0;
  int? _draggingItemId; // set by a child element to suppress pan while dragging

  final Map<int, Offset> _activePointers = {};
  double? _pinchStartDistance;
  double? _pinchStartScale;
  Offset? _pinchStartFocal;
  Offset? _pinchStartPan;

  // ── Merge burst effects ──────────────────────────────────────────────────
  final List<_MergeBurst> _bursts = [];
  int _burstSeq = 0;

  /// Id of the canvas item currently under a grid element being dragged in.
  int? _hoverMergeTargetId;

  // ── Coordinate helpers ───────────────────────────────────────────────────

  RenderBox get _canvasBox =>
      _canvasKey.currentContext!.findRenderObject() as RenderBox;

  /// Screen-local → virtual canvas coordinates.
  Offset _toVirtual(Offset local) => (local - _panOffset) / _scale;

  /// Converts a drop's global feedback top-left to the virtual center position.
  Offset _dropCenter(Offset globalFeedbackTopLeft) {
    final local = _canvasBox.globalToLocal(globalFeedbackTopLeft);
    final screenCenter = local + const Offset(itemSize / 2, itemSize / 2);
    return _toVirtual(screenCenter);
  }

  void _addBurst(Offset virtualPosition) {
    final id = _burstSeq++;
    setState(() => _bursts.add(_MergeBurst(id: id, position: virtualPosition)));
  }

  void _removeBurst(int id) {
    setState(() => _bursts.removeWhere((b) => b.id == id));
  }

  /// Returns the topmost canvas item whose card bounds contain [virtual],
  /// or `null` if it's over empty table space. [excludeId] skips the item
  /// currently being dragged, so it can't be detected as its own target.
  CanvasItem? _itemAt(
    Offset virtual,
    List<CanvasItem> items, {
    int? excludeId,
  }) {
    for (final item in items.reversed) {
      if (item.id == excludeId) continue;
      final rect = Rect.fromCenter(
        center: item.position,
        width: itemSize,
        height: itemSize,
      );
      if (rect.contains(virtual)) return item;
    }
    return null;
  }

  // ── Per-item drag callbacks (manual pan, not Draggable — see the note on
  // _CanvasElement's GestureDetector for why) ─────────────────────────────

  void _onItemDragUpdate(int id, Offset virtualPos) {
    final items = context.read<GameProvider>().canvasItems;
    final target = _itemAt(virtualPos, items, excludeId: id);
    if (target?.id != _hoverMergeTargetId) {
      setState(() => _hoverMergeTargetId = target?.id);
    }
  }

  void _onItemDragFinished(int id, Offset virtualPos) {
    final game = context.read<GameProvider>();
    final target = _itemAt(virtualPos, game.canvasItems, excludeId: id);
    if (target != null) {
      _addBurst(target.position);
      game.combineItems(id, target.id);
    } else {
      game.moveItem(id, virtualPos);
    }
    if (mounted) setState(() => _hoverMergeTargetId = null);
  }

  // ── Gesture handlers ─────────────────────────────────────────────────────

  void _onPointerDown(PointerDownEvent event) {
    _activePointers[event.pointer] = event.position;
    if (_activePointers.length == 2) {
      final pts = _activePointers.values.toList();
      _pinchStartDistance = (pts[0] - pts[1]).distance;
      _pinchStartScale = _scale;
      _pinchStartFocal = (pts[0] + pts[1]) / 2;
      _pinchStartPan = _panOffset;
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!_activePointers.containsKey(event.pointer)) return;
    _activePointers[event.pointer] = event.position;
    if (_draggingItemId != null) return; // item's own drag owns this gesture

    // Canvas pan/zoom is two-finger only — a single finger is reserved
    // entirely for picking up and moving elements, so there's no ambiguity
    // between "I'm dragging an element" and "I'm panning the table".
    if (_activePointers.length >= 2 && _pinchStartDistance != null) {
      final pts = _activePointers.values.toList();
      final dist = (pts[0] - pts[1]).distance;
      if (_pinchStartDistance! > 0) {
        final newScale = (_pinchStartScale! * (dist / _pinchStartDistance!))
            .clamp(_kMinScale, 2.5);
        final focalLocalStart = _canvasBox.globalToLocal(_pinchStartFocal!);
        final focalVirtual =
            (focalLocalStart - _pinchStartPan!) / _pinchStartScale!;
        final focal = (pts[0] + pts[1]) / 2;
        final focalLocalNow = _canvasBox.globalToLocal(focal);
        setState(() {
          _scale = newScale;
          _panOffset = focalLocalNow - focalVirtual * newScale;
        });
      }
    }
  }

  void _onPointerUp(PointerEvent event) {
    _activePointers.remove(event.pointer);
    if (_activePointers.length < 2) {
      _pinchStartDistance = null;
    }
    // Safety net: a drag can only be in progress while a finger is down, so
    // once every pointer is lifted, pan/zoom must be re-enabled no matter
    // what — this guards against a dragged element's widget being disposed
    // mid-drag (e.g. it flips to the pending/combining card) before its own
    // onDragEnd fires, which would otherwise leave _draggingItemId stuck
    // set and permanently freeze the canvas.
    if (_activePointers.isEmpty && _draggingItemId != null) {
      setState(() => _draggingItemId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final colors = AppColors.of(context);
    final t = AppStrings.of(context.watch<SettingsProvider>().language);

    // Pure render-time value derived from the existing zoom scale — no new
    // gesture/state logic. 0 = flat table, 1 = fully the "planet" view.
    // Calibrated against the real pinch-zoom range (_kMinScale.._kGlobeThreshold)
    // so it actually reaches 1.0 at maximum zoom-out instead of an arbitrary
    // fraction of it.
    final globeFactor =
        ((_kGlobeThreshold - _scale) / (_kGlobeThreshold - _kMinScale)).clamp(
          0.0,
          1.0,
        );

    // Solid space-colored backdrop behind everything: the rounded/circular
    // clip below isn't a perfect circle on a non-square viewport, so its
    // corners reveal whatever sits directly behind this widget. Without
    // this, that gap showed the Scaffold's own background color instead of
    // matching space — a visible mismatched "layer" behind the table.
    return ColoredBox(
      color: _kSpaceBottom,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: _onPointerDown,
        onPointerMove: _onPointerMove,
        onPointerUp: _onPointerUp,
        onPointerCancel: _onPointerUp,
        child: DragTarget<GameElement>(
          onMove: (details) {
            final virtual = _dropCenter(details.offset);
            final target = _itemAt(virtual, game.canvasItems);
            if (target?.id != _hoverMergeTargetId) {
              setState(() => _hoverMergeTargetId = target?.id);
            }
          },
          onLeave: (_) => setState(() => _hoverMergeTargetId = null),
          onAcceptWithDetails: (details) {
            final virtual = _dropCenter(details.offset);
            final target = _itemAt(virtual, game.canvasItems);
            if (target != null) {
              _addBurst(target.position);
              game.combineWithNew(details.data, target.id);
            } else {
              game.addToCanvas(details.data, virtual);
            }
            setState(() => _hoverMergeTargetId = null);
          },
          builder: (context, candidateData, rejectedData) {
            return LayoutBuilder(
              builder: (context, constraints) {
                // The sphere's radius grows with globeFactor (see below);
                // the OUTER container's own corner radius stays a small,
                // constant value — BorderRadius on a non-square rect turns
                // into a stretched "stadium" shape at large radii, never a
                // true circle, which looked like a lopsided blob mid-
                // transition. The globe painter already self-clips to a
                // true circle internally, so the outer clip doesn't need to
                // (and shouldn't) grow into one too.
                final viewSize = constraints.biggest;
                final maxRadius = viewSize.shortestSide / 2;
                const cornerRadius = 24.0;

                return Container(
                  key: _canvasKey,
                  clipBehavior: Clip.antiAlias,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(
                      Radius.circular(cornerRadius),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      // Deep-space colors regardless of light/dark app theme —
                      // the crafting table is meant to read as space at any
                      // zoom level, consistent with the globe view it blends
                      // into.
                      colors: [_kSpaceTop, _kSpaceBottom],
                    ),
                  ),
                  child: Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      // "Planet in space" view — grows and fades in together
                      // as the canvas zooms out past _kGlobeThreshold, using
                      // the same cornerRadius as the clip above so the
                      // sphere's edge always exactly matches the visible
                      // silhouette. Rotation is driven by its own
                      // independent, slow-looping AnimationController.
                      if (globeFactor > 0)
                        Positioned.fill(
                          child: RepaintBoundary(
                            child: AnimatedBuilder(
                              animation: _globeRotation,
                              builder: (context, _) => CustomPaint(
                                painter: GlobeBackgroundPainter(
                                  opacity: globeFactor,
                                  sphereRadius: maxRadius * globeFactor,
                                  rotation: _globeRotation.value,
                                  primary: colors.primary,
                                  primaryDark: colors.primaryDark,
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Empty-state hint.
                      if (game.canvasItems.isEmpty)
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '✨',
                                style: TextStyle(
                                  fontSize: 36,
                                  color: colors.textMuted.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                t.dragElementsHere,
                                style: TextStyle(
                                  color: colors.textMuted.withValues(
                                    alpha: 0.7,
                                  ),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Transformed layer: elements + merge bursts.
                      Positioned.fill(
                        child: Transform(
                          transform: Matrix4.identity()
                            ..translateByDouble(
                              _panOffset.dx,
                              _panOffset.dy,
                              0,
                              1,
                            )
                            ..scaleByDouble(_scale, _scale, 1, 1),
                          child: SizedBox(
                            width: _kVirtualSize,
                            height: _kVirtualSize,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                // Table starfield — anchored to virtual canvas
                                // coordinates (unlike the old dot-grid) so stars
                                // stay put and never swim/reshuffle while
                                // panning/zooming. Static (no per-frame
                                // twinkle animation): this paints unconditionally
                                // during ordinary gameplay, and repainting ~260
                                // circles every frame just for a barely-visible
                                // pulse was wasted raster work that could jank
                                // out and delay touch/drag recognition — not
                                // worth it for a decorative flourish.
                                const Positioned.fill(
                                  child: RepaintBoundary(
                                    child: CustomPaint(
                                      painter: _StarFieldPainter(),
                                    ),
                                  ),
                                ),

                                // The item currently being dragged (if any) is
                                // rendered last so it paints on top of the rest
                                // while the user moves it around.
                                for (final item in [
                                  ...game.canvasItems.where(
                                    (i) => i.id != _draggingItemId,
                                  ),
                                  ...game.canvasItems.where(
                                    (i) => i.id == _draggingItemId,
                                  ),
                                ])
                                  Positioned(
                                    // The Stack's own reordering trick (moving
                                    // the dragged item to the end of this list
                                    // so it paints on top) only preserves each
                                    // item's widget State correctly if the
                                    // outer Positioned itself carries a stable
                                    // key — Stack's list-reconciliation matches
                                    // by the DIRECT child widget's key, not a
                                    // key nested further inside. Without this,
                                    // reordering during a drag could scramble
                                    // which item's State/Element got reused
                                    // where, making unrelated elements replay
                                    // their entrance bounce animation.
                                    key: ValueKey('pos-${item.id}'),
                                    left: item.position.dx - itemSize / 2,
                                    top: item.position.dy - itemSize / 2,
                                    child: game.pendingItemIds.contains(item.id)
                                        ? _PendingCard(
                                            key: ValueKey('pending-${item.id}'),
                                            size: itemSize,
                                          )
                                        : _CanvasElement(
                                            key: ValueKey(
                                              '${item.id}-${item.element.key}',
                                            ),
                                            item: item,
                                            size: itemSize,
                                            scale: _scale,
                                            globeFactor: globeFactor,
                                            isMergeTarget:
                                                item.id == _hoverMergeTargetId,
                                            onDragStarted: () {
                                              if (mounted) {
                                                setState(
                                                  () =>
                                                      _draggingItemId = item.id,
                                                );
                                              }
                                            },
                                            onDragEnded: () {
                                              if (mounted) {
                                                setState(
                                                  () => _draggingItemId = null,
                                                );
                                              }
                                            },
                                            onDragUpdate: (virtualPos) =>
                                                _onItemDragUpdate(
                                                  item.id,
                                                  virtualPos,
                                                ),
                                            onDragFinished: (virtualPos) =>
                                                _onItemDragFinished(
                                                  item.id,
                                                  virtualPos,
                                                ),
                                          ),
                                  ),
                                for (final burst in _bursts)
                                  Positioned(
                                    left:
                                        burst.position.dx -
                                        MergeParticles.size / 2,
                                    top:
                                        burst.position.dy -
                                        MergeParticles.size / 2,
                                    child: IgnorePointer(
                                      child: MergeParticles(
                                        key: ValueKey(burst.id),
                                        colors: colors,
                                        onCompleted: () =>
                                            _removeBurst(burst.id),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Canvas element widget
// ─────────────────────────────────────────────────────────────────────────────

class _CanvasElement extends StatefulWidget {
  const _CanvasElement({
    super.key,
    required this.item,
    required this.size,
    required this.scale,
    required this.globeFactor,
    required this.isMergeTarget,
    required this.onDragStarted,
    required this.onDragEnded,
    required this.onDragUpdate,
    required this.onDragFinished,
  });

  final CanvasItem item;
  final double size;
  final double scale;
  final double globeFactor;
  final bool isMergeTarget;
  final VoidCallback onDragStarted;
  final VoidCallback onDragEnded;
  final void Function(Offset virtualPosition) onDragUpdate;
  final void Function(Offset virtualPosition) onDragFinished;

  @override
  State<_CanvasElement> createState() => _CanvasElementState();
}

class _CanvasElementState extends State<_CanvasElement>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _dragging = false;
  Offset _dragDelta = Offset.zero; // screen-space offset while dragging

  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 0.0,
        end: 1.15,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 65,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.15,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 35,
    ),
  ]).animate(_controller);

  late final Animation<double> _rotation = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: -0.12,
        end: 0.05,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 65,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 0.05,
        end: 0.0,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 35,
    ),
  ]).animate(_controller);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..forward();
  }

  @override
  void dispose() {
    // If this element gets disposed (e.g. it flips to the pending/combining
    // card) while a drag on it is still in flight, its own onDragEnd never
    // fires. Tell the parent canvas the drag is over anyway so pan/zoom
    // never gets stuck disabled.
    if (_dragging) widget.onDragEnded();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _deleteWithFeedback() async {
    final game = context.read<GameProvider>();
    await _controller.reverse();
    if (!mounted) return;
    game.removeFromCanvas(widget.item.id);
  }

  void _onPanStart(DragStartDetails details) {
    _dragging = true;
    setState(() => _dragDelta = Offset.zero);
    widget.onDragStarted();
    Haptics.grab();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() => _dragDelta += details.delta);
    widget.onDragUpdate(widget.item.position + _dragDelta / widget.scale);
  }

  void _onPanEnd(DragEndDetails details) {
    final finalVirtualPos = widget.item.position + _dragDelta / widget.scale;
    _dragging = false;
    setState(() => _dragDelta = Offset.zero);
    widget.onDragEnded();
    Haptics.drop();
    widget.onDragFinished(finalVirtualPos);
  }

  @override
  Widget build(BuildContext context) {
    final game = context.read<GameProvider>();
    final colors = AppColors.of(context);
    final item = widget.item;
    final size = widget.size;
    // Elements coalesce into small glowing star-dots as the canvas zooms
    // out into the globe view — purely visual, the same GestureDetector
    // below keeps handling drag/delete/duplicate no matter which
    // representation is showing.
    final dotFactor = ((widget.globeFactor - 0.3) / 0.5).clamp(0.0, 1.0);

    // A single GestureDetector owns onDoubleTap, onLongPress AND the manual
    // pan handlers together — Flutter's gesture arena resolves sibling
    // recognizers on the SAME GestureDetector fairly, based on actual
    // movement (pan needs to exceed kTouchSlop, long-press needs to stay
    // under it for ~500ms). A separate `Draggable`/`LongPressDraggable`
    // widget instead uses its own recognizer with a hard time/threshold
    // race against the sibling recognizers, which — no matter how the
    // numbers are tuned — either steals long-press/double-tap before they
    // can fire, or makes reposition-dragging feel delayed. Doing the drag
    // manually here avoids that race entirely, and dropping `Draggable`'s
    // Overlay-based feedback also means the card can simply translate
    // itself in place while dragging, and merge-target detection is
    // reported live to the parent canvas via onDragUpdate/onDragFinished
    // (reusing the same _itemAt hit-testing the tray-drop path already uses).
    return Transform.translate(
      offset: _dragDelta,
      child: ScaleTransition(
        scale: _scale,
        child: RotationTransition(
          turns: _rotation,
          child: GestureDetector(
            onDoubleTap: () => game.duplicateItem(item.id),
            onLongPress: _deleteWithFeedback,
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            child: SizedBox(
              width: size,
              height: size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (dotFactor < 1)
                    Opacity(
                      opacity: 1 - dotFactor,
                      child: ElementCard(
                        element: item.element,
                        highlighted: widget.isMergeTarget,
                      ),
                    ),
                  if (dotFactor > 0)
                    Opacity(
                      opacity: dotFactor,
                      child: _ElementStarDot(color: colors.accent),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// What an element looks like from "orbit" — a small glowing star instead
/// of the full card, crossfaded in as the canvas zooms into the globe view.
class _ElementStarDot extends StatelessWidget {
  const _ElementStarDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    // Colored core (not plain white) so real elements read as distinctly
    // different from the dim white decorative stars around them — you can
    // still pick your own elements out even fully zoomed out.
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.9),
            blurRadius: 14,
            spreadRadius: 3,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pending card (shown while waiting for combination result)
// ─────────────────────────────────────────────────────────────────────────────

class _PendingCard extends StatefulWidget {
  const _PendingCard({super.key, required this.size});
  final double size;

  @override
  State<_PendingCard> createState() => _PendingCardState();
}

class _PendingCardState extends State<_PendingCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _sparkleScale;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _sparkleScale = Tween<double>(
      begin: 0.8,
      end: 1.25,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _glow = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: colors.primary.withValues(
                    alpha: 0.2 + _glow.value * 0.3,
                  ),
                  width: 1.0 + _glow.value * 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: _glow.value * 0.15),
                    blurRadius: 12 + _glow.value * 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(
                        alpha: 0.08 + _glow.value * 0.08,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Transform.scale(
                      scale: _sparkleScale.value,
                      child: const Text('✨', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _BouncingDots(
                    progress: _controller.value,
                    color: colors.textMuted,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BouncingDots extends StatelessWidget {
  const _BouncingDots({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: List.generate(3, (i) {
        final phase = ((progress + i / 3) % 1.0);
        final dy = phase < 0.5
            ? -4.0 * (phase / 0.5)
            : -4.0 * (1 - (phase - 0.5) / 0.5);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Transform.translate(
            offset: Offset(0, dy),
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dot-grid background painter (adapts to pan/zoom)
// ─────────────────────────────────────────────────────────────────────────────

/// A single star in the table's background starfield, fixed at a virtual
/// canvas coordinate (not screen space) so stars never swim/reshuffle while
/// panning or zooming — they're painted inside the same transformed layer
/// as the elements themselves.
class _TableStar {
  const _TableStar({
    required this.position,
    required this.radius,
    required this.opacity,
  });

  final Offset position;
  final double radius;
  final double opacity;
}

class _StarFieldPainter extends CustomPainter {
  const _StarFieldPainter();

  static final List<_TableStar> _stars = _generateStars();

  static List<_TableStar> _generateStars() {
    final rand = math.Random(99);
    return List.generate(260, (_) {
      return _TableStar(
        position: Offset(
          rand.nextDouble() * _kVirtualSize,
          rand.nextDouble() * _kVirtualSize,
        ),
        radius: 0.8 + rand.nextDouble() * 1.6,
        opacity: 0.15 + rand.nextDouble() * 0.5,
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final star in _stars) {
      canvas.drawCircle(
        star.position,
        star.radius,
        Paint()..color = Colors.white.withValues(alpha: star.opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StarFieldPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Merge burst
// ─────────────────────────────────────────────────────────────────────────────

class _MergeBurst {
  _MergeBurst({required this.id, required this.position});
  final int id;
  final Offset position;
}

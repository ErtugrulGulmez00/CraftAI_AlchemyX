import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/haptics.dart';
import '../core/localization/app_strings.dart';
import '../core/theme/app_theme.dart';
import '../models/element_model.dart';
import '../providers/game_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/craft_canvas.dart';
import '../widgets/element_card.dart';

/// The "Craft" tab: canvas on top, horizontal element tray at the bottom.
/// A fixed ⭐ drop-zone lives in the bottom-left corner of the canvas —
/// dragging any element onto it toggles that element's favourite state.
class CraftView extends StatelessWidget {
  const CraftView({super.key});

  // Tray size constants — duplicated here so the drop-zone overlay can
  // position itself flush above the tray without importing private state.
  static const _trayRows = 3;
  static const _trayChipHeight = 76.0;
  static const _traySpacing = 8.0;
  static const _trayHeight =
      _trayRows * _trayChipHeight + (_trayRows + 1) * _traySpacing; // 260 px

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── Main layout: canvas + element tray ───────────────────────────
        const Column(
          children: [
            Expanded(child: CraftCanvas()),
            _HorizontalElementBar(),
          ],
        ),

        // ── Fixed ⭐ drop-zone — bottom-left of the canvas ────────────────
        // It sits just above the element tray and never scrolls away.
        // Drag any element chip here to toggle its favourite state.
        const Positioned(
          left: 12,
          bottom: _trayHeight + 12,
          child: _FavoriteDropZone(),
        ),
      ],
    );
  }
}

// ── Favourite drop-zone ───────────────────────────────────────────────────────

class _FavoriteDropZone extends StatelessWidget {
  const _FavoriteDropZone();

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();

    return DragTarget<GameElement>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) {
        HapticFeedback.mediumImpact();
        game.toggleFavorite(details.data);
      },
      builder: (context, candidateData, _) {
        final isHovering = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: isHovering ? 64 : 48,
          height: isHovering ? 64 : 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isHovering
                ? const Color(0xFFFFC94A).withValues(alpha: 0.22)
                : Colors.black.withValues(alpha: 0.38),
            border: Border.all(
              color: isHovering
                  ? const Color(0xFFFFC94A)
                  : Colors.white.withValues(alpha: 0.22),
              width: isHovering ? 2.2 : 1.5,
            ),
            boxShadow: isHovering
                ? [
                    BoxShadow(
                      color: const Color(0xFFFFC94A).withValues(alpha: 0.50),
                      blurRadius: 22,
                      spreadRadius: 5,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.28),
                      blurRadius: 8,
                    ),
                  ],
          ),
          alignment: Alignment.center,
          child: Text(
            '⭐',
            style: TextStyle(fontSize: isHovering ? 30 : 22),
          ),
        );
      },
    );
  }
}

// ── Element tray ─────────────────────────────────────────────────────────────

class _HorizontalElementBar extends StatefulWidget {
  const _HorizontalElementBar();

  @override
  State<_HorizontalElementBar> createState() => _HorizontalElementBarState();
}

class _HorizontalElementBarState extends State<_HorizontalElementBar> {
  bool _showFavoritesOnly = false;

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final allElements = game.discoveredElements;
    final elements = _showFavoritesOnly
        ? allElements.where((e) => game.isFavorite(e)).toList()
        : allElements;
    final colors = AppColors.of(context);
    final t = AppStrings.of(context.watch<SettingsProvider>().language);

    const rows = 3;
    const chipHeight = 76.0;
    const spacing = 8.0;
    final barHeight = rows * chipHeight + (rows + 1) * spacing;

    return Stack(
      children: [
        Container(
          height: barHeight,
          decoration: BoxDecoration(
            color: colors.surface,
            boxShadow: const [
              BoxShadow(
                color: Color(0x18000000),
                blurRadius: 16,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: elements.isEmpty
              ? Center(
                  child: Text(
                    _showFavoritesOnly
                        ? t.noFavoritesYet
                        : t.dragElementsHere,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                )
              : GridView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: spacing,
                    vertical: spacing,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: rows,
                    mainAxisSpacing: spacing,
                    crossAxisSpacing: spacing,
                    childAspectRatio: 80 / chipHeight,
                  ),
                  itemCount: elements.length,
                  itemBuilder: (context, index) {
                    final element = elements[index];
                    final isFav = game.isFavorite(element);
                    return LongPressDraggable<GameElement>(
                      data: element,
                      delay: const Duration(milliseconds: 25),
                      hapticFeedbackOnStart: false,
                      onDragStarted: Haptics.grab,
                      onDragEnd: (_) => Haptics.drop(),
                      dragAnchorStrategy: (draggable, context, position) =>
                          const Offset(kCraftItemSize / 2, kCraftItemSize / 2),
                      feedback: Material(
                        type: MaterialType.transparency,
                        child: SizedBox(
                          width: kCraftItemSize,
                          height: kCraftItemSize,
                          child: Center(child: ElementCard(element: element)),
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.35,
                        child: _ElementChip(
                          element: element,
                          colors: colors,
                          isFavorite: isFav,
                        ),
                      ),
                      child: _ElementChip(
                        element: element,
                        colors: colors,
                        isFavorite: isFav,
                      ),
                    );
                  },
                ),
        ),

        // ── Favourites-only filter toggle ─────────────────────────────────
        Positioned(
          right: 6,
          top: 6,
          child: GestureDetector(
            onTap: () =>
                setState(() => _showFavoritesOnly = !_showFavoritesOnly),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _showFavoritesOnly
                    ? const Color(0xFFFFC94A).withValues(alpha: 0.20)
                    : colors.surface,
                border: Border.all(
                  color: _showFavoritesOnly
                      ? const Color(0xFFFFC94A)
                      : colors.primary.withValues(alpha: 0.28),
                  width: 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 6,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                _showFavoritesOnly ? '⭐' : '☆',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Element chip ──────────────────────────────────────────────────────────────

class _ElementChip extends StatelessWidget {
  const _ElementChip({
    required this.element,
    required this.colors,
    required this.isFavorite,
  });

  final GameElement element;
  final AppPalette colors;
  final bool isFavorite;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: colors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isFavorite
                  ? const Color(0xFFFFC94A).withValues(alpha: 0.65)
                  : colors.primary.withValues(alpha: 0.12),
              width: isFavorite ? 1.4 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                element.emoji,
                style: const TextStyle(fontSize: 22),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                element.name,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        if (isFavorite)
          const Positioned(
            top: -4,
            left: -4,
            child: Text('⭐', style: TextStyle(fontSize: 11)),
          ),
      ],
    );
  }
}

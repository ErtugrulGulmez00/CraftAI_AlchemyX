import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/haptics.dart';
import '../core/localization/app_strings.dart';
import '../core/services/share_service.dart';
import '../core/theme/app_theme.dart';
import '../models/element_model.dart';
import '../providers/game_provider.dart';
import '../providers/settings_provider.dart';
import 'confetti_overlay.dart';
import 'element_card.dart';
import 'merge_particles.dart';

/// The reusable tap-based "tube + mortar" combine scene from Alchemy Table
/// mode. Renders the animated table/tubes/mortar, the tappable element tray,
/// first-discovery/error toasts and the confetti overlay — everything except
/// a Scaffold/AppBar shell, so it can be embedded by any mode (Alchemy
/// Table, Target Mode, Challenge Mode) that wants this mechanic.
class AlchemyTableBody extends StatefulWidget {
  const AlchemyTableBody({super.key});

  @override
  State<AlchemyTableBody> createState() => _AlchemyTableBodyState();
}

class _AlchemyTableBodyState extends State<AlchemyTableBody>
    with TickerProviderStateMixin {
  GameElement? _tubeA;
  GameElement? _tubeB;
  bool _combining = false;
  bool _showBurst = false;
  GameElement? _lastResult;
  int _burstSeq = 0;

  GameElement? _discoveryBanner;
  late final AnimationController _discoveryBannerController;

  bool _showFavoritesOnly = false;

  final List<_SteamParticle> _steamParticles = [];
  int _steamSeq = 0;

  late final AnimationController _mortarController;
  late final AnimationController _idleController;
  late final AnimationController _tubeShakeController;
  late final AnimationController _resultController;
  // Candle flicker during combine
  late final AnimationController _candleController;
  // Smooth BG color tint transition
  late final AnimationController _bgTintController;
  // Slow ambient dust drift — purely decorative, loops forever
  late final AnimationController _ambientController;
  // Tiny spider dangling from the ceiling, bobbing up and down forever
  late final AnimationController _spiderController;

  late final Animation<double> _mortarScale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: 1.28,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 30,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.28,
        end: 0.85,
      ).chain(CurveTween(curve: Curves.easeIn)),
      weight: 35,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 0.85,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 35,
    ),
  ]).animate(_mortarController);

  late final Animation<double> _idleScale = Tween(
    begin: 1.0,
    end: 1.04,
  ).animate(CurvedAnimation(parent: _idleController, curve: Curves.easeInOut));

  late final Animation<double> _tubeShake =
      TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0.0, end: -6.0), weight: 25),
        TweenSequenceItem(tween: Tween(begin: -6.0, end: 6.0), weight: 25),
        TweenSequenceItem(tween: Tween(begin: 6.0, end: -4.0), weight: 25),
        TweenSequenceItem(tween: Tween(begin: -4.0, end: 0.0), weight: 25),
      ]).animate(
        CurvedAnimation(parent: _tubeShakeController, curve: Curves.linear),
      );

  // Result: scale + slide-up from mortar
  late final Animation<double> _resultScale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 0.0,
        end: 1.15,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 55,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.15,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeInOut)),
      weight: 45,
    ),
  ]).animate(_resultController);

  late final Animation<double> _resultSlide = Tween(
    begin: 40.0,
    end: 0.0,
  ).animate(CurvedAnimation(parent: _resultController, curve: Curves.easeOut));

  // Candle flame intensity (0=normal, 1=blazing)
  late final Animation<double> _candleFlame = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 0.0,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 40,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: 0.0,
      ).chain(CurveTween(curve: Curves.easeIn)),
      weight: 60,
    ),
  ]).animate(_candleController);

  late final Animation<double> _bgTint = Tween(
    begin: 0.0,
    end: 1.0,
  ).animate(CurvedAnimation(parent: _bgTintController, curve: Curves.easeOut));

  @override
  void initState() {
    super.initState();
    _mortarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _tubeShakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _resultController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _candleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _bgTintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _discoveryBannerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 9000),
    )..repeat();
    _spiderController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _mortarController.dispose();
    _idleController.dispose();
    _tubeShakeController.dispose();
    _resultController.dispose();
    _candleController.dispose();
    _bgTintController.dispose();
    _discoveryBannerController.dispose();
    _ambientController.dispose();
    _spiderController.dispose();
    super.dispose();
  }

  void _showDiscoveryBanner(GameElement discovery) {
    setState(() => _discoveryBanner = discovery);
    _discoveryBannerController.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 2600), () {
      if (!mounted) return;
      _discoveryBannerController.reverse().whenComplete(() {
        if (mounted) setState(() => _discoveryBanner = null);
      });
    });
  }

  void _handleTap(GameElement element) {
    if (_combining) return;
    if (_tubeA == null) {
      HapticFeedback.selectionClick();
      setState(() => _tubeA = element);
      _bgTintController.forward();
      return;
    }
    if (_tubeB == null) {
      HapticFeedback.selectionClick();
      setState(() => _tubeB = element);
      _combine();
    }
  }

  Future<void> _combine() async {
    final a = _tubeA;
    final b = _tubeB;
    if (a == null || b == null) return;

    setState(() {
      _combining = true;
      _lastResult = null;
      final rnd = math.Random();
      for (var i = 0; i < 6; i++) {
        _steamParticles.add(
          _SteamParticle(
            id: _steamSeq++,
            dx: (rnd.nextDouble() - 0.5) * 44,
            delay: Duration(milliseconds: (rnd.nextDouble() * 250).toInt()),
            size: 9 + rnd.nextDouble() * 16,
          ),
        );
      }
    });

    _mortarController.forward(from: 0);
    _tubeShakeController.forward(from: 0);
    _candleController.forward(from: 0);
    Haptics.grab();

    final game = context.read<GameProvider>();
    // Already-known combinations resolve instantly from the local cache —
    // without a floor here, the mortar/tube-shake animation would barely
    // start before the result appears. Force at least one full brewing
    // cycle so every combine feels consistent, cached or not.
    final results = await Future.wait([
      game.combineElements(a, b),
      Future.delayed(const Duration(milliseconds: 650)),
    ]);
    final result = results[0] as GameElement?;

    if (!mounted) return;

    setState(() {
      _tubeA = null;
      _tubeB = null;
      _combining = false;
      _steamParticles.clear();
      _lastResult = result;
      if (result != null) {
        _burstSeq++;
        _showBurst = true;
      }
    });

    _bgTintController.reverse();

    if (result != null) {
      _resultController.forward(from: 0);
      Future.delayed(const Duration(milliseconds: 2400), () {
        if (mounted) setState(() => _lastResult = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final colors = AppColors.of(context);
    final t = AppStrings.of(context.watch<SettingsProvider>().language);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Dynamic BG tint colors from selected elements
    final tintA = _tubeA != null
        ? elementAccentColor(_tubeA!.name)
        : const Color(0xFF6C5CE7);
    final tintB = _tubeB != null
        ? elementAccentColor(_tubeB!.name)
        : const Color(0xFF4834D4);

    if (game.lastError != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(game.lastError!)));
        game.clearError();
      });
    }
    if (game.lastFirstDiscovery != null) {
      final discovery = game.lastFirstDiscovery!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showDiscoveryBanner(discovery);
        game.clearFirstDiscoveryFlag();
      });
    }

    return Stack(
      children: [
        // ── Dynamic background ──────────────────────────────────────────
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _bgTint,
            builder: (context, _) {
              final t = _bgTint.value;
              return DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(
                        isDark
                            ? const Color(0xFF1A1528)
                            : const Color(0xFF2C1F5E),
                        tintA.withValues(alpha: 0.35),
                        t,
                      )!,
                      Color.lerp(
                        isDark
                            ? const Color(0xFF0E0C18)
                            : const Color(0xFF1A1235),
                        tintB.withValues(alpha: 0.35),
                        t,
                      )!,
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // ── Stars ────────────────────────────────────────────────────────
        Positioned.fill(
          child: IgnorePointer(child: CustomPaint(painter: _StarsPainter())),
        ),

        // ── Ambient dust motes ───────────────────────────────────────────
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _ambientController,
              builder: (context, _) => CustomPaint(
                painter: _AmbientDustPainter(_ambientController.value),
              ),
            ),
          ),
        ),

        // ── Dangling spider ──────────────────────────────────────────────
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Center(
              child: AnimatedBuilder(
                animation: _spiderController,
                builder: (context, _) {
                  final drop =
                      Curves.easeInOut.transform(_spiderController.value) * 60;
                  return CustomPaint(
                    size: const Size(20, 84),
                    painter: _DanglingSpiderPainter(drop),
                  );
                },
              ),
            ),
          ),
        ),

        // ── Main content ─────────────────────────────────────────────────
        Column(
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Alchemy table background
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: _candleController,
                        builder: (context, _) => CustomPaint(
                          painter: _AlchemyTablePainter(
                            isDark: isDark,
                            candleFlame: _candleFlame.value,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Table scene: tubes, mortar, runes, result
                  Positioned.fill(
                    child: _TableScene(
                      tubeA: _tubeA,
                      tubeB: _tubeB,
                      combining: _combining,
                      showBurst: _showBurst,
                      burstSeq: _burstSeq,
                      lastResult: _lastResult,
                      steamParticles: _steamParticles,
                      mortarScale: _mortarScale,
                      idleScale: _idleScale,
                      tubeShake: _tubeShake,
                      resultScale: _resultScale,
                      resultSlide: _resultSlide,
                      mortarController: _mortarController,
                      idleController: _idleController,
                      tubeShakeController: _tubeShakeController,
                      resultController: _resultController,
                      hint: t.alchemyTableHint,
                      brewingLabel: t.alchemyBrewing,
                      colors: colors,
                      onBurstCompleted: () {
                        if (mounted) setState(() => _showBurst = false);
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Element tray
            _TappableTray(
              elements: _showFavoritesOnly
                  ? game.discoveredElements
                        .where((e) => game.isFavorite(e))
                        .toList()
                  : game.discoveredElements,
              disabled: _combining,
              colors: colors,
              onTap: _handleTap,
              onToggleFavorite: (element) {
                HapticFeedback.selectionClick();
                game.toggleFavorite(element);
              },
              isFavorite: game.isFavorite,
              selectedA: _tubeA,
              selectedB: _tubeB,
              showFavoritesOnly: _showFavoritesOnly,
              noFavoritesLabel: t.noFavoritesYet,
            ),
          ],
        ),

        // Favorites-only filter toggle — anchored to the tray's top-right
        // corner so it doesn't take any extra space of its own.
        Positioned(
          right: 10,
          bottom: _TappableTray.height + 8,
          child: GestureDetector(
            onTap: () =>
                setState(() => _showFavoritesOnly = !_showFavoritesOnly),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF13101E).withValues(alpha: 0.85),
                border: Border.all(
                  color: _showFavoritesOnly
                      ? const Color(0xFFFFC94A)
                      : Colors.white.withValues(alpha: 0.25),
                  width: 1.4,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                _showFavoritesOnly ? '⭐' : '☆',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ),

        // Confetti
        Positioned.fill(
          child: IgnorePointer(
            child: ConfettiOverlay(trigger: game.lastFirstDiscovery),
          ),
        ),

        // First-discovery banner — anchored just above the element tray so
        // it lands right where the player is already looking.
        if (_discoveryBanner != null)
          Positioned(
            left: 20,
            right: 20,
            bottom: _TappableTray.height + 12,
            child: AnimatedBuilder(
              animation: _discoveryBannerController,
              builder: (context, child) {
                final curved = Curves.easeOutBack.transform(
                  _discoveryBannerController.value,
                );
                return Opacity(
                  opacity: _discoveryBannerController.value.clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(0, (1 - curved) * 18),
                    child: child,
                  ),
                );
              },
              child: _FirstDiscoveryBanner(
                text: t.firstDiscoveryToast(
                  _discoveryBanner!.emoji,
                  _discoveryBanner!.name,
                ),
                onShare: () => ShareService.shareDiscovery(
                  emoji: _discoveryBanner!.emoji,
                  name: _discoveryBanner!.name,
                  cardTitle: t.shareCardTitle,
                  shareText: t.shareDiscoveryText(_discoveryBanner!.name),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _FirstDiscoveryBanner extends StatelessWidget {
  const _FirstDiscoveryBanner({required this.text, required this.onShare});

  final String text;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFC94A), Color(0xFFFF8A3D)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFA726).withValues(alpha: 0.45),
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🌟', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onShare,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.25),
              ),
              child: const Icon(Icons.share, size: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Table Scene ────────────────────────────────────────────────────────────

class _TableScene extends StatelessWidget {
  const _TableScene({
    required this.tubeA,
    required this.tubeB,
    required this.combining,
    required this.showBurst,
    required this.burstSeq,
    required this.lastResult,
    required this.steamParticles,
    required this.mortarScale,
    required this.idleScale,
    required this.tubeShake,
    required this.resultScale,
    required this.resultSlide,
    required this.mortarController,
    required this.idleController,
    required this.tubeShakeController,
    required this.resultController,
    required this.hint,
    required this.brewingLabel,
    required this.colors,
    required this.onBurstCompleted,
  });

  final GameElement? tubeA;
  final GameElement? tubeB;
  final bool combining;
  final bool showBurst;
  final int burstSeq;
  final GameElement? lastResult;
  final List<_SteamParticle> steamParticles;
  final Animation<double> mortarScale;
  final Animation<double> idleScale;
  final Animation<double> tubeShake;
  final Animation<double> resultScale;
  final Animation<double> resultSlide;
  final AnimationController mortarController;
  final AnimationController idleController;
  final AnimationController tubeShakeController;
  final AnimationController resultController;
  final String hint;
  final String brewingLabel;
  final AppPalette colors;
  final VoidCallback onBurstCompleted;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        final w = constraints.maxWidth;
        final tableTopY = h * 0.50;

        return Stack(
          children: [
            // ── Left tube ───────────────────────────────────────────────────
            Positioned(
              left: w * 0.14,
              top: tableTopY - 125,
              child: AnimatedBuilder(
                animation: tubeShakeController,
                builder: (context, child) => Transform.translate(
                  offset: Offset(tubeShake.value, 0),
                  child: child,
                ),
                child: _AlchemyTube(element: tubeA, colors: colors, label: 'A'),
              ),
            ),

            // ── Left burner ──────────────────────────────────────────────────
            // Sits right under the tube's base so the flames visibly lick
            // it, like a lab stove heating the tube.
            Positioned(
              left: w * 0.14,
              top: tableTopY + 14,
              child: const SizedBox(
                width: 74,
                child: Center(child: _BurnerFlame()),
              ),
            ),

            // ── Right tube ──────────────────────────────────────────────────
            Positioned(
              right: w * 0.14,
              top: tableTopY - 125,
              child: AnimatedBuilder(
                animation: tubeShakeController,
                builder: (context, child) => Transform.translate(
                  offset: Offset(-tubeShake.value, 0),
                  child: child,
                ),
                child: _AlchemyTube(element: tubeB, colors: colors, label: 'B'),
              ),
            ),

            // ── Right burner ─────────────────────────────────────────────────
            Positioned(
              right: w * 0.14,
              top: tableTopY + 14,
              child: const SizedBox(
                width: 74,
                child: Center(child: _BurnerFlame()),
              ),
            ),

            // ── Mortar ──────────────────────────────────────────────────────
            Positioned(
              left: 0,
              right: 0,
              top: tableTopY - 80,
              child: Center(
                child: SizedBox(
                  width: 130,
                  height: 130,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Glow when both filled
                      if (tubeA != null && tubeB != null)
                        AnimatedBuilder(
                          animation: idleController,
                          builder: (context, _) => Container(
                            width: 110 + idleScale.value * 22,
                            height: 110 + idleScale.value * 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  colors.secondary.withValues(alpha: 0.38),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),

                      // Orbiting runes during combine
                      if (combining) _RuneOrbit(controller: mortarController),

                      // Mortar body
                      AnimatedBuilder(
                        animation: Listenable.merge([
                          mortarController,
                          idleController,
                        ]),
                        builder: (context, child) {
                          final scale = combining
                              ? mortarScale.value
                              : idleScale.value;
                          return Transform.scale(scale: scale, child: child);
                        },
                        child: CustomPaint(
                          size: const Size(100, 88),
                          painter: _MortarPainter(
                            filled: tubeA != null && tubeB != null,
                            colorA: tubeA != null
                                ? elementAccentColor(tubeA!.name)
                                : Colors.transparent,
                            colorB: tubeB != null
                                ? elementAccentColor(tubeB!.name)
                                : Colors.transparent,
                          ),
                        ),
                      ),

                      // Steam wisps
                      ...steamParticles.map((p) => _SteamWisp(particle: p)),

                      // Spark burst
                      if (showBurst)
                        IgnorePointer(
                          child: MergeParticles(
                            key: ValueKey(burstSeq),
                            colors: colors,
                            onCompleted: onBurstCompleted,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Result card: slides up from mortar ──────────────────────────
            Positioned(
              left: 0,
              right: 0,
              // Pushed below the burners' row so the hint text doesn't sit
              // on the same horizontal line as the stove flames.
              top: tableTopY + 68,
              child: Center(
                child: lastResult != null
                    ? AnimatedBuilder(
                        animation: resultController,
                        builder: (context, child) => Transform.translate(
                          offset: Offset(0, resultSlide.value),
                          child: Transform.scale(
                            scale: resultScale.value,
                            child: child,
                          ),
                        ),
                        child: _ResultCard(
                          element: lastResult!,
                          colors: colors,
                        ),
                      )
                    : combining
                    ? _CombiningIndicator(colors: colors, label: brewingLabel)
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 48),
                        child: Text(
                          hint,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.50),
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                      ),
              ),
            ),

            // ── Familiar (a little black cat on the floor) ───────────────────
            Positioned(
              left: w * 0.03,
              bottom: 2,
              child: AnimatedBuilder(
                animation: idleController,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, (1 - idleScale.value) * -18),
                  child: child,
                ),
                child: const Text('🐈‍⬛', style: TextStyle(fontSize: 26)),
              ),
            ),

            // ── Flow arrows ─────────────────────────────────────────────────
            if (tubeA != null && !combining)
              Positioned(
                left: w * 0.22,
                top: tableTopY - 68,
                child: _ArrowIndicator(
                  pointing: ArrowDirection.right,
                  color: elementAccentColor(tubeA!.name),
                ),
              ),
            if (tubeB != null && !combining)
              Positioned(
                right: w * 0.22,
                top: tableTopY - 68,
                child: _ArrowIndicator(
                  pointing: ArrowDirection.left,
                  color: elementAccentColor(tubeB!.name),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ── Burner Flame (ambient, always lit under each tube) ─────────────────────

class _BurnerFlame extends StatefulWidget {
  const _BurnerFlame();

  @override
  State<_BurnerFlame> createState() => _BurnerFlameState();
}

class _BurnerFlameState extends State<_BurnerFlame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) => CustomPaint(
          size: const Size(54, 22),
          painter: _BurnerFlamePainter(_ctrl.value),
        ),
      ),
    );
  }
}

class _BurnerFlamePainter extends CustomPainter {
  _BurnerFlamePainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final baseY = size.height - 3;

    // Wide burner ring the flames sit on — reads as a lab stove under the
    // tube rather than a single candle.
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, baseY + 1), width: 46, height: 6),
      Paint()..color = const Color(0xFF2B2B2B).withValues(alpha: 0.75),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, baseY + 1), width: 34, height: 3.5),
      Paint()..color = const Color(0xFF4A4A4A).withValues(alpha: 0.8),
    );

    // Shared warm glow across the whole burner row.
    final glow = Paint()
      ..color = const Color(0xFFFF8A3D).withValues(alpha: 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, baseY - 6), width: 44, height: 18),
      glow,
    );

    Path flamePath(double fx, double h, double w) => Path()
      ..moveTo(fx, baseY)
      ..cubicTo(fx - w, baseY - h * 0.4, fx - w * 0.6, baseY - h, fx, baseY - h)
      ..cubicTo(fx + w * 0.6, baseY - h, fx + w, baseY - h * 0.4, fx, baseY);

    // A row of small jets across the ring, like a gas stove burner. Each
    // jet flickers on its own phase so the row ripples instead of pulsing.
    const jetOffsets = [-16.0, -8.0, 0.0, 8.0, 16.0];
    for (var i = 0; i < jetOffsets.length; i++) {
      final fx = cx + jetOffsets[i];
      final flicker =
          0.8 +
          0.2 * math.sin(t * 2 * math.pi + i * 1.7) +
          0.08 * math.sin(t * 2 * math.pi * 2.7 + i * 0.9);
      // Center jets slightly taller for a natural dome shape.
      final heightScale = i == 2 ? 1.0 : (i == 1 || i == 3 ? 0.85 : 0.68);
      final flameH = 14 * heightScale * flicker;

      canvas.drawPath(
        flamePath(fx, flameH, 4.4),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              const Color(0xFFFF9800).withValues(alpha: 0.9),
              const Color(0xFFFFEB3B).withValues(alpha: 0.6),
            ],
          ).createShader(Rect.fromLTWH(fx - 5, baseY - flameH, 10, flameH)),
      );

      // Inner (blue) core, like a real gas burner.
      canvas.drawPath(
        flamePath(fx, flameH * 0.55, 2.4),
        Paint()
          ..color = const Color(0xFF64B5F6).withValues(alpha: 0.85 * flicker),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BurnerFlamePainter oldDelegate) =>
      oldDelegate.t != t;
}

// ── Orbiting Rune Symbols ─────────────────────────────────────────────────

class _RuneOrbit extends StatefulWidget {
  const _RuneOrbit({required this.controller});
  final AnimationController controller;

  @override
  State<_RuneOrbit> createState() => _RuneOrbitState();
}

class _RuneOrbitState extends State<_RuneOrbit>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;
  static const _runes = ['⊕', '⊗', '⋈', '∞', '⟐', '◈'];

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _spin,
      builder: (context, _) {
        return SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: List.generate(_runes.length, (i) {
              final angle =
                  _spin.value * 2 * math.pi + (i * 2 * math.pi / _runes.length);
              final radius = 52.0;
              final dx = math.cos(angle) * radius;
              final dy = math.sin(angle) * radius;
              final opacity =
                  (0.5 + 0.5 * math.sin(_spin.value * 2 * math.pi + i)).clamp(
                    0.2,
                    0.85,
                  );
              return Transform.translate(
                offset: Offset(dx, dy),
                child: Opacity(
                  opacity: opacity,
                  child: Text(
                    _runes[i],
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

// ── Stars Painter ─────────────────────────────────────────────────────────

class _StarsPainter extends CustomPainter {
  static final List<Offset> _positions = List.generate(60, (i) {
    final rnd = math.Random(i * 31337);
    return Offset(rnd.nextDouble(), rnd.nextDouble());
  });
  static final List<double> _sizes = List.generate(60, (i) {
    final rnd = math.Random(i * 99991);
    return 0.5 + rnd.nextDouble() * 1.5;
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.55);
    for (var i = 0; i < _positions.length; i++) {
      canvas.drawCircle(
        Offset(
          _positions[i].dx * size.width,
          _positions[i].dy * size.height * 0.55,
        ),
        _sizes[i],
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StarsPainter oldDelegate) => false;
}

// ── Ambient Dust Motes ────────────────────────────────────────────────────

/// Slow-drifting glowing specks across the whole scene — pure atmosphere,
/// never collides with anything since it only ever paints in the
/// background, well behind the table/tubes/tray.
class _AmbientDustPainter extends CustomPainter {
  _AmbientDustPainter(this.progress);

  final double progress;

  static const _count = 22;
  static final List<double> _x = List.generate(
    _count,
    (i) => math.Random(i * 13).nextDouble(),
  );
  static final List<double> _speed = List.generate(
    _count,
    (i) => 0.4 + math.Random(i * 271).nextDouble() * 0.8,
  );
  static final List<double> _phase = List.generate(
    _count,
    (i) => math.Random(i * 911).nextDouble(),
  );
  static final List<double> _size = List.generate(
    _count,
    (i) => 1.2 + math.Random(i * 4177).nextDouble() * 1.8,
  );
  static final List<double> _sway = List.generate(
    _count,
    (i) => 8 + math.Random(i * 733).nextDouble() * 14,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < _count; i++) {
      final t = (progress * _speed[i] + _phase[i]) % 1.0;
      // Drift slowly upward, wrapping from bottom to top.
      final y = size.height * (1 - t);
      final x = _x[i] * size.width + math.sin(t * 2 * math.pi) * _sway[i];
      final fade = math.sin(t * math.pi); // fades in, peaks, fades out
      paint.color = Colors.white.withValues(alpha: 0.18 * fade);
      canvas.drawCircle(Offset(x, y), _size[i], paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AmbientDustPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ── Dangling Spider ───────────────────────────────────────────────────────

/// A tiny spider on a single thread, dead-center at the very top of the
/// scene, endlessly bobbing down and back up — well above where the tubes
/// start, so it never competes with anything interactive.
class _DanglingSpiderPainter extends CustomPainter {
  _DanglingSpiderPainter(this.drop);

  /// How far down the thread the spider currently hangs, in pixels.
  final double drop;

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width / 2;
    final spiderY = 6 + drop;

    final threadPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.30)
      ..strokeWidth = 0.8;
    canvas.drawLine(Offset(x, 0), Offset(x, spiderY), threadPaint);

    final bodyPaint = Paint()..color = Colors.black.withValues(alpha: 0.55);
    final legPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.45)
      ..strokeWidth = 0.8;

    // Legs — two short strokes on each side.
    for (final side in [-1.0, 1.0]) {
      canvas.drawLine(
        Offset(x, spiderY - 1),
        Offset(x + side * 4, spiderY - 3),
        legPaint,
      );
      canvas.drawLine(
        Offset(x, spiderY + 1),
        Offset(x + side * 4, spiderY + 3),
        legPaint,
      );
    }

    canvas.drawCircle(Offset(x, spiderY), 2.6, bodyPaint);
  }

  @override
  bool shouldRepaint(covariant _DanglingSpiderPainter oldDelegate) =>
      oldDelegate.drop != drop;
}

// ── Alchemy Table Painter ─────────────────────────────────────────────────

class _AlchemyTablePainter extends CustomPainter {
  const _AlchemyTablePainter({required this.isDark, this.candleFlame = 0.0});

  final bool isDark;

  /// 0.0 = normal candle, 1.0 = blazing during combine
  final double candleFlame;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final tableTopY = h * 0.50;
    final tableThickness = h * 0.048;
    // Wide enough to leave clear corner space for the decorative props
    // beside the tubes (which sit at ~14% inset from each edge).
    final tableWidthTop = w * 0.94;
    final tableWidthBottom = w * 1.0;
    final tableLeft = (w - tableWidthTop) / 2;
    final tableRight = tableLeft + tableWidthTop;
    final tableLeftB = (w - tableWidthBottom) / 2;
    final tableRightB = tableLeftB + tableWidthBottom;

    final woodLight = isDark
        ? const Color(0xFF4A3520)
        : const Color(0xFF7A4820);
    final woodDark = isDark ? const Color(0xFF2E1E0E) : const Color(0xFF4A2910);
    final woodEdge = isDark ? const Color(0xFF1C1008) : const Color(0xFF2E1508);

    // ── Table surface ────────────────────────────────────────────────────
    final tableSurface = Path()
      ..moveTo(tableLeft, tableTopY)
      ..lineTo(tableRight, tableTopY)
      ..lineTo(tableRightB, tableTopY + tableThickness)
      ..lineTo(tableLeftB, tableTopY + tableThickness)
      ..close();

    canvas.drawPath(
      tableSurface,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [woodLight, woodDark],
        ).createShader(Rect.fromLTWH(0, tableTopY, w, tableThickness)),
    );

    // ── Front edge ───────────────────────────────────────────────────────
    final frontEdge = Path()
      ..moveTo(tableLeftB, tableTopY + tableThickness)
      ..lineTo(tableRightB, tableTopY + tableThickness)
      ..lineTo(tableRightB, tableTopY + tableThickness + h * 0.030)
      ..lineTo(tableLeftB, tableTopY + tableThickness + h * 0.030)
      ..close();
    canvas.drawPath(frontEdge, Paint()..color = woodEdge);

    // ── Wood grain ───────────────────────────────────────────────────────
    final grainPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.07)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    for (var i = 1; i <= 8; i++) {
      final frac = i / 9.0;
      canvas.drawLine(
        Offset(tableLeft + tableWidthTop * frac, tableTopY),
        Offset(
          tableLeftB + tableWidthBottom * frac,
          tableTopY + tableThickness,
        ),
        grainPaint,
      );
    }

    // ── Table legs ───────────────────────────────────────────────────────
    final legPaint = Paint()..color = woodEdge;
    final legW = w * 0.022;
    final legTop = tableTopY + tableThickness + h * 0.030;
    final legH = h * 0.28;
    canvas.drawRect(
      Rect.fromLTWH(tableLeftB + w * 0.035, legTop, legW, legH),
      legPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(tableRightB - w * 0.035 - legW, legTop, legW, legH),
      legPaint,
    );

    // ── Decorative props ─────────────────────────────────────────────────
    // Scaled down and tucked into the far corners so they stay clear of the
    // tubes' footprint (the tubes sit at ~14%-32% inset from each edge).

    // Open book (far left corner).
    canvas.save();
    canvas.translate(tableLeft + w * 0.008, tableTopY - 14);
    canvas.scale(0.55);
    _drawBook(canvas, Offset.zero, isDark);
    canvas.restore();

    // Two potion bottles, stacked toward the far right corner.
    canvas.save();
    canvas.translate(tableRight - w * 0.075, tableTopY - 22);
    canvas.scale(0.6);
    _drawPotionBottle(canvas, Offset.zero, const Color(0xFF4ECDC4), isDark);
    canvas.restore();

    canvas.save();
    canvas.translate(tableRight - w * 0.045, tableTopY - 18);
    canvas.scale(0.6);
    _drawPotionBottle(canvas, Offset.zero, const Color(0xFFE040FB), isDark);
    canvas.restore();

    // Candle, far right corner (reacts to combine).
    canvas.save();
    canvas.translate(tableRight - w * 0.018, tableTopY - 26);
    canvas.scale(0.65);
    _drawCandle(canvas, Offset.zero, isDark, candleFlame);
    canvas.restore();

    // ── Ambient glow under table shadow ─────────────────────────────────
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w / 2, tableTopY + tableThickness + h * 0.04),
        width: w * 0.75,
        height: h * 0.14,
      ),
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                const Color(0xFF6C5CE7).withValues(alpha: 0.18),
                Colors.transparent,
              ],
            ).createShader(
              Rect.fromCenter(
                center: Offset(w / 2, tableTopY + tableThickness + h * 0.04),
                width: w * 0.75,
                height: h * 0.14,
              ),
            ),
    );

    // ── Ceiling cobwebs ──────────────────────────────────────────────────
    // Tucked right into the top corners, well above where the tubes start
    // (tableTopY - 155), so they never compete with anything interactive.
    _drawCobweb(canvas, Offset.zero, w * 0.16, flip: false);
    _drawCobweb(canvas, Offset(w, 0), w * 0.16, flip: true);
  }

  void _drawCobweb(
    Canvas canvas,
    Offset corner,
    double radius, {
    required bool flip,
  }) {
    final dir = flip ? -1.0 : 1.0;
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Radial threads.
    for (var i = 0; i <= 4; i++) {
      final angle = (i / 4) * (math.pi / 2);
      canvas.drawLine(
        corner,
        Offset(
          corner.dx + dir * math.cos(angle) * radius,
          corner.dy + math.sin(angle) * radius,
        ),
        paint,
      );
    }

    // Concentric arcs connecting the threads.
    for (var ring = 1; ring <= 3; ring++) {
      final r = radius * (ring / 3.5);
      final path = Path();
      for (var i = 0; i <= 4; i++) {
        final angle = (i / 4) * (math.pi / 2);
        final point = Offset(
          corner.dx + dir * math.cos(angle) * r,
          corner.dy + math.sin(angle) * r,
        );
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  void _drawBook(Canvas canvas, Offset origin, bool isDark) {
    final cover = isDark ? const Color(0xFF5A3E2B) : const Color(0xFF8B5E3C);
    final page = isDark ? const Color(0xFFDDD5C0) : const Color(0xFFF5EDD5);
    // Left page
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(origin.dx, origin.dy, 30, 20),
        topLeft: const Radius.circular(2),
        bottomLeft: const Radius.circular(2),
      ),
      Paint()..color = page,
    );
    // Right page
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(origin.dx + 30, origin.dy, 30, 20),
        topRight: const Radius.circular(2),
        bottomRight: const Radius.circular(2),
      ),
      Paint()..color = page.withValues(alpha: 0.85),
    );
    // Spine
    canvas.drawRect(
      Rect.fromLTWH(origin.dx + 27, origin.dy, 6, 20),
      Paint()..color = cover,
    );
    // Lines
    final linePaint = Paint()
      ..color = Colors.brown.withValues(alpha: 0.22)
      ..strokeWidth = 1;
    for (var i = 1; i <= 4; i++) {
      final y = origin.dy + i * 4.0;
      canvas.drawLine(
        Offset(origin.dx + 4, y),
        Offset(origin.dx + 26, y),
        linePaint,
      );
      canvas.drawLine(
        Offset(origin.dx + 33, y),
        Offset(origin.dx + 56, y),
        linePaint,
      );
    }
    // Small rune on right page
    final runePaint = Paint()
      ..color = Colors.brown.withValues(alpha: 0.30)
      ..strokeWidth = 0.8;
    canvas.drawCircle(
      Offset(origin.dx + 44, origin.dy + 14),
      4,
      runePaint..style = PaintingStyle.stroke,
    );
    canvas.drawLine(
      Offset(origin.dx + 44, origin.dy + 10),
      Offset(origin.dx + 44, origin.dy + 18),
      runePaint,
    );
    canvas.drawLine(
      Offset(origin.dx + 40, origin.dy + 14),
      Offset(origin.dx + 48, origin.dy + 14),
      runePaint,
    );
  }

  void _drawPotionBottle(
    Canvas canvas,
    Offset origin,
    Color liquid,
    bool isDark,
  ) {
    final glass = Colors.white.withValues(alpha: isDark ? 0.10 : 0.16);
    final outline = Paint()
      ..color = Colors.white.withValues(alpha: 0.30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Body oval
    final body = Path()
      ..addOval(
        Rect.fromCenter(
          center: Offset(origin.dx + 10, origin.dy + 22),
          width: 22,
          height: 28,
        ),
      );
    canvas.drawPath(body, Paint()..color = glass);
    canvas.drawPath(body, outline);
    // Liquid
    canvas.drawPath(
      Path()..addOval(
        Rect.fromCenter(
          center: Offset(origin.dx + 10, origin.dy + 24),
          width: 15,
          height: 17,
        ),
      ),
      Paint()..color = liquid.withValues(alpha: 0.65),
    );
    // Neck
    canvas.drawRect(
      Rect.fromLTWH(origin.dx + 7, origin.dy + 7, 6, 9),
      Paint()..color = glass,
    );
    canvas.drawRect(Rect.fromLTWH(origin.dx + 7, origin.dy + 7, 6, 9), outline);
    // Cork
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(origin.dx + 5.5, origin.dy + 3, 9, 5),
        const Radius.circular(2),
      ),
      Paint()
        ..color = isDark ? const Color(0xFF8B6B3A) : const Color(0xFFB8874A),
    );
    // Shimmer
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(origin.dx + 7, origin.dy + 19),
        width: 9,
        height: 12,
      ),
      -math.pi * 0.7,
      math.pi * 0.5,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.28)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
    // Glow dot at top of liquid
    canvas.drawCircle(
      Offset(origin.dx + 10, origin.dy + 14),
      3,
      Paint()
        ..color = liquid.withValues(alpha: 0.30)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  void _drawCandle(Canvas canvas, Offset origin, bool isDark, double flame) {
    final flameExtra = flame * 16; // blazing offset

    // Candle body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(origin.dx, origin.dy + 12, 14, 32),
        const Radius.circular(3),
      ),
      Paint()
        ..color = isDark ? const Color(0xFFDDCCA0) : const Color(0xFFF5E8C0),
    );
    // Wax drip
    canvas.drawCircle(
      Offset(origin.dx + 5, origin.dy + 22),
      3.5,
      Paint()
        ..color = (isDark ? const Color(0xFFCCBB90) : const Color(0xFFE8D5A0)),
    );
    // Wick
    canvas.drawLine(
      Offset(origin.dx + 7, origin.dy + 12),
      Offset(origin.dx + 7, origin.dy + 7),
      Paint()
        ..color = Colors.black54
        ..strokeWidth = 1.5,
    );

    // Flame — grows with candleFlame
    final flameH = 14 + flameExtra;
    final flamePaint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              Color.lerp(
                const Color(0xFFFFF176),
                const Color(0xFFFFFFFF),
                flame * 0.5,
              )!,
              Color.lerp(
                const Color(0xFFFF9800),
                const Color(0xFFFF5500),
                flame * 0.7,
              )!,
            ],
          ).createShader(
            Rect.fromLTWH(
              origin.dx + 1,
              origin.dy - flameH - 2,
              12,
              flameH + 8,
            ),
          );

    final flamePath = Path()
      ..moveTo(origin.dx + 7, origin.dy + 6)
      ..cubicTo(
        origin.dx + 1,
        origin.dy - 2,
        origin.dx + 0,
        origin.dy - flameH + 2,
        origin.dx + 7,
        origin.dy - flameH + 4,
      )
      ..cubicTo(
        origin.dx + 14,
        origin.dy - flameH + 2,
        origin.dx + 13,
        origin.dy - 2,
        origin.dx + 7,
        origin.dy + 6,
      );
    canvas.drawPath(flamePath, flamePaint);

    // Glow — stronger when blazing
    final glowRadius = 12.0 + flameExtra * 0.8;
    canvas.drawCircle(
      Offset(origin.dx + 7, origin.dy - flameH / 2),
      glowRadius,
      Paint()
        ..color = Color.lerp(
          const Color(0xFFFF9800).withValues(alpha: 0.18),
          const Color(0xFFFF5500).withValues(alpha: 0.50),
          flame,
        )!
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 + flameExtra * 0.5),
    );
  }

  @override
  bool shouldRepaint(covariant _AlchemyTablePainter old) =>
      old.isDark != isDark || old.candleFlame != candleFlame;
}

// ── Mortar Painter ────────────────────────────────────────────────────────

class _MortarPainter extends CustomPainter {
  const _MortarPainter({
    required this.filled,
    required this.colorA,
    required this.colorB,
  });

  final bool filled;
  final Color colorA;
  final Color colorB;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 + 4;

    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [const Color(0xFF6A5848), const Color(0xFF2E2018)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Bowl
    final bowlPath = Path()
      ..moveTo(cx - 42, cy - 13)
      ..quadraticBezierTo(cx - 46, cy + 22, cx - 26, cy + 32)
      ..lineTo(cx + 26, cy + 32)
      ..quadraticBezierTo(cx + 46, cy + 22, cx + 42, cy - 13)
      ..close();
    canvas.drawPath(bowlPath, bodyPaint);

    // Rim ellipse
    final rimRect = Rect.fromCenter(
      center: Offset(cx, cy - 13),
      width: 90,
      height: 22,
    );
    canvas.drawOval(rimRect, bodyPaint);
    canvas.drawOval(
      rimRect,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Liquid when filled
    if (filled &&
        colorA != Colors.transparent &&
        colorB != Colors.transparent) {
      final lp = Path()
        ..moveTo(cx - 34, cy - 8)
        ..quadraticBezierTo(cx - 36, cy + 20, cx - 18, cy + 27)
        ..lineTo(cx + 18, cy + 27)
        ..quadraticBezierTo(cx + 36, cy + 20, cx + 34, cy - 8)
        ..close();
      canvas.drawPath(
        lp,
        Paint()
          ..shader = LinearGradient(
            colors: [
              colorA.withValues(alpha: 0.80),
              colorB.withValues(alpha: 0.80),
            ],
          ).createShader(Rect.fromLTWH(cx - 36, cy - 8, 72, 35)),
      );
      // Shimmer surface
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy - 7), width: 58, height: 14),
        Paint()..color = Colors.white.withValues(alpha: 0.12),
      );
    }

    // Highlight
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx - 16, cy + 2), width: 30, height: 40),
      -math.pi * 0.75,
      math.pi * 0.45,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    // Pestle
    final pestlePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [const Color(0xFF7A6050), const Color(0xFF3E2A18)],
      ).createShader(Rect.fromLTWH(cx + 12, cy - 36, 14, 48));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx + 16, cy - 36, 8, 44),
        const Radius.circular(4),
      ),
      pestlePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + 20, cy + 10), width: 16, height: 11),
      pestlePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _MortarPainter old) =>
      old.filled != filled || old.colorA != colorA || old.colorB != colorB;
}

// ── Alchemy Tube (StatefulWidget with bubble animation) ───────────────────

class _AlchemyTube extends StatefulWidget {
  const _AlchemyTube({
    required this.element,
    required this.colors,
    required this.label,
  });

  final GameElement? element;
  final AppPalette colors;
  final String label;

  @override
  State<_AlchemyTube> createState() => _AlchemyTubeState();
}

class _AlchemyTubeState extends State<_AlchemyTube>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bubbleCtrl;
  final List<_Bubble> _bubbles = [];
  final _rnd = math.Random();

  @override
  void initState() {
    super.initState();
    _bubbleCtrl =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 1200),
          )
          ..addListener(_spawnBubbles)
          ..repeat();
    _initBubbles();
  }

  void _initBubbles() {
    for (var i = 0; i < 4; i++) {
      _bubbles.add(
        _Bubble(
          x: 0.2 + _rnd.nextDouble() * 0.6,
          startY: _rnd.nextDouble(),
          speed: 0.4 + _rnd.nextDouble() * 0.6,
          size: 2.0 + _rnd.nextDouble() * 3.0,
          phase: _rnd.nextDouble(),
        ),
      );
    }
  }

  void _spawnBubbles() {
    // Stagger bubbles by phase so they don't all move in lockstep
    setState(() {});
  }

  @override
  void dispose() {
    _bubbleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final element = widget.element;
    final liquidColor = element != null
        ? elementAccentColor(element.name)
        : Colors.transparent;

    return SizedBox(
      width: 74,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tube body
          Container(
            width: 66,
            height: 148,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
                bottomLeft: Radius.circular(38),
                bottomRight: Radius.circular(38),
              ),
              border: Border.all(
                color: element != null
                    ? liquidColor.withValues(alpha: 0.65)
                    : Colors.white.withValues(alpha: 0.22),
                width: element != null ? 1.8 : 1.2,
              ),
              boxShadow: element != null
                  ? [
                      BoxShadow(
                        color: liquidColor.withValues(alpha: 0.45),
                        blurRadius: 22,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // Liquid fill
                AnimatedContainer(
                  duration: const Duration(milliseconds: 380),
                  curve: Curves.easeOut,
                  width: double.infinity,
                  height: element != null ? 92 : 0,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        liquidColor.withValues(alpha: 0.42),
                        liquidColor.withValues(alpha: 0.92),
                      ],
                    ),
                  ),
                ),

                // ── Bubbles (only when element present) ──────────────────
                if (element != null)
                  AnimatedBuilder(
                    animation: _bubbleCtrl,
                    builder: (context, _) {
                      return CustomPaint(
                        size: const Size(66, 92),
                        painter: _BubblePainter(
                          bubbles: _bubbles,
                          progress: _bubbleCtrl.value,
                          color: liquidColor,
                        ),
                      );
                    },
                  ),

                // Glass highlight stripe
                Positioned(
                  left: 8,
                  top: 8,
                  bottom: 8,
                  child: Container(
                    width: 5,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: Colors.white.withValues(alpha: 0.14),
                    ),
                  ),
                ),

                // Element info
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: element == null
                      ? Text(
                          widget.label,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.25),
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              element.emoji,
                              style: const TextStyle(fontSize: 24),
                            ),
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: Text(
                                element.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 9,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // Stand
          Container(
            height: 11,
            width: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: const Color(0xFF5A3E1E).withValues(alpha: 0.72),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.30),
                  blurRadius: 4,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bubble Model & Painter ────────────────────────────────────────────────

class _Bubble {
  _Bubble({
    required this.x,
    required this.startY,
    required this.speed,
    required this.size,
    required this.phase,
  });
  final double x;
  final double startY;
  final double speed;
  final double size;
  final double phase;
}

class _BubblePainter extends CustomPainter {
  const _BubblePainter({
    required this.bubbles,
    required this.progress,
    required this.color,
  });

  final List<_Bubble> bubbles;
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    for (final b in bubbles) {
      final t = ((progress * b.speed + b.phase) % 1.0);
      // Bubbles rise from bottom to top within the liquid area
      final y = size.height - (t * size.height);
      if (y < 0 || y > size.height) continue;
      final x = b.x * size.width + math.sin(t * math.pi * 3) * 4;
      final opacity = (1 - (t * t)).clamp(0.0, 1.0) * 0.5;
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawCircle(Offset(x, y), b.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BubblePainter old) => old.progress != progress;
}

// ── Result Card ───────────────────────────────────────────────────────────

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.element, required this.colors});

  final GameElement element;
  final AppPalette colors;

  @override
  Widget build(BuildContext context) {
    final accent = elementAccentColor(element.name);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.28),
            colors.surface.withValues(alpha: 0.92),
          ],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.60), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.40),
            blurRadius: 28,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(element.emoji, style: const TextStyle(fontSize: 38)),
          const SizedBox(height: 6),
          Text(
            element.name,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 17,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Combining Indicator ───────────────────────────────────────────────────

class _CombiningIndicator extends StatelessWidget {
  const _CombiningIndicator({required this.colors, required this.label});
  final AppPalette colors;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: colors.secondary,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            color: colors.secondary,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

// ── Arrow Indicator ───────────────────────────────────────────────────────

enum ArrowDirection { left, right }

class _ArrowIndicator extends StatelessWidget {
  const _ArrowIndicator({required this.pointing, required this.color});
  final ArrowDirection pointing;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Icon(
      pointing == ArrowDirection.right
          ? Icons.arrow_forward_rounded
          : Icons.arrow_back_rounded,
      color: color.withValues(alpha: 0.75),
      size: 20,
    );
  }
}

// ── Steam Particles ───────────────────────────────────────────────────────

class _SteamParticle {
  const _SteamParticle({
    required this.id,
    required this.dx,
    required this.delay,
    required this.size,
  });
  final int id;
  final double dx;
  final Duration delay;
  final double size;
}

class _SteamWisp extends StatefulWidget {
  const _SteamWisp({required this.particle});
  final _SteamParticle particle;

  @override
  State<_SteamWisp> createState() => _SteamWispState();
}

class _SteamWispState extends State<_SteamWisp>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );
    Future.delayed(widget.particle.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = _ctrl.value;
        final eased = Curves.easeOut.transform(t);
        return Transform.translate(
          offset: Offset(widget.particle.dx * t, -65 * eased),
          child: Opacity(
            opacity: (1 - t).clamp(0.0, 1.0) * 0.7,
            child: Container(
              width: widget.particle.size,
              height: widget.particle.size,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Tappable Element Tray ─────────────────────────────────────────────────

class _TappableTray extends StatelessWidget {
  const _TappableTray({
    required this.elements,
    required this.disabled,
    required this.colors,
    required this.onTap,
    required this.onToggleFavorite,
    required this.isFavorite,
    required this.selectedA,
    required this.selectedB,
    required this.showFavoritesOnly,
    required this.noFavoritesLabel,
  });

  final List<GameElement> elements;
  final bool disabled;
  final AppPalette colors;
  final void Function(GameElement) onTap;
  final void Function(GameElement) onToggleFavorite;
  final bool Function(GameElement) isFavorite;
  final GameElement? selectedA;
  final GameElement? selectedB;
  final bool showFavoritesOnly;
  final String noFavoritesLabel;

  static const _rows = 3;
  static const _tileSize = 72.0;
  static const _spacing = 8.0;

  /// Total rendered height of the tray — exposed so overlays (e.g. the
  /// first-discovery banner) can anchor themselves flush above it.
  static const double height = _rows * _tileSize + (_rows - 1) * _spacing + 20;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF13101E).withValues(alpha: 0.92),
        border: const Border(
          top: BorderSide(color: Color(0xFF6C5CE7), width: 0.5),
        ),
      ),
      child: elements.isEmpty && showFavoritesOnly
          ? Center(
              child: Text(
                noFavoritesLabel,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : GridView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _rows,
                mainAxisSpacing: _spacing,
                crossAxisSpacing: _spacing,
                childAspectRatio: 1.0,
              ),
              itemCount: elements.length,
              itemBuilder: (context, index) {
                final element = elements[index];
                final isSelectedA = selectedA?.key == element.key;
                final isSelectedB = selectedB?.key == element.key;
                final isSelected = isSelectedA || isSelectedB;
                return Opacity(
                  opacity: disabled ? 0.45 : 1,
                  child: GestureDetector(
                    onTap: disabled ? null : () => onTap(element),
                    onLongPress: disabled
                        ? null
                        : () => onToggleFavorite(element),
                    child: _AlchemyTile(
                      element: element,
                      colors: colors,
                      isSelected: isSelected,
                      isFavorite: isFavorite(element),
                      slotLabel: isSelectedA ? 'A' : (isSelectedB ? 'B' : null),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _AlchemyTile extends StatelessWidget {
  const _AlchemyTile({
    required this.element,
    required this.colors,
    required this.isSelected,
    required this.isFavorite,
    this.slotLabel,
  });

  final GameElement element;
  final AppPalette colors;
  final bool isSelected;
  final bool isFavorite;
  final String? slotLabel;

  @override
  Widget build(BuildContext context) {
    final accent = elementAccentColor(element.name);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: isSelected
            ? accent.withValues(alpha: 0.22)
            : const Color(0xFF1E1A2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected
              ? accent.withValues(alpha: 0.80)
              : accent.withValues(alpha: 0.20),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: 0.40),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      element.emoji,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Text(
                  element.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 9,
                    color: Colors.white70,
                  ),
                ),
              ),
            ],
          ),
          if (slotLabel != null)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                width: 15,
                height: 15,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF13101E),
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  slotLabel!,
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          if (isFavorite)
            const Positioned(
              top: -4,
              left: -4,
              child: Text('⭐', style: TextStyle(fontSize: 13)),
            ),
        ],
      ),
    );
  }
}

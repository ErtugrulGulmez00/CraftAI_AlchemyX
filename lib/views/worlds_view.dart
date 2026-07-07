import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../core/localization/app_strings.dart';
import '../core/services/supabase_service.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/animated_section_widgets.dart';
import 'free_mode_view.dart';
import 'alchemy_table_mode_view.dart';
import 'mode_family_hub_view.dart';

/// "Play" tab: choose how you want to play. Always a dark, starlit "cosmic
/// lab" scene regardless of the app's light/dark theme setting — this is a
/// deliberate brand moment, same idea as Alchemy Table's own hardcoded-dark
/// lobby screen.
class WorldsView extends StatefulWidget {
  const WorldsView({super.key, required this.remote});

  final SupabaseService remote;

  @override
  State<WorldsView> createState() => _WorldsViewState();
}

class _WorldsViewState extends State<WorldsView> with TickerProviderStateMixin {
  late final AnimationController _entrance;
  late final AnimationController _driftController;

  // Alchemy Table's deep amber/gold accent — a warm, mystical feel
  // distinct from the other modes.
  static const _alchemyAccent = Color(0xFFFFA53D);

  // Space Mode's cyan accent — matches the globe/starfield visualization
  // used on its infinite canvas.
  static const _spaceAccent = Color(0xFF4FD1E8);

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _driftController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 26),
    )..repeat();
  }

  @override
  void dispose() {
    _entrance.dispose();
    _driftController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context.watch<SettingsProvider>().language);
    final auth = context.watch<AuthProvider>();

    var stagger = 0;
    Widget stag(Widget child) =>
        Stagger(animation: _entrance, index: stagger++, child: child);

    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0xFF0B0916)),
      child: Stack(
        children: [
          // ── Nebula glow ──────────────────────────────────────────────────
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.55),
                    radius: 1.1,
                    colors: [
                      const Color(0xFF6C3FE0).withValues(alpha: 0.35),
                      const Color(0xFF2A1A5E).withValues(alpha: 0.18),
                      const Color(0xFF0B0916),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // ── Stars ────────────────────────────────────────────────────────
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _PlayStarsPainter()),
            ),
          ),

          // ── Drifting elements ────────────────────────────────────────────
          // Confined to a thin band at the very top and very bottom of the
          // screen, well clear of the centered logo/cards block, so they
          // never drift over anything tappable.
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _driftController,
                builder: (context, _) => CustomPaint(
                  painter: _DriftingElementsPainter(_driftController.value),
                ),
              ),
            ),
          ),

          // ── Everything (logo + both cards + sign-in) centered as one
          // group on the *full* screen, so the whole composition balances
          // instead of leaving a big empty gap under the cards. ────────────
          Positioned.fill(
            child: Align(
              alignment: const Alignment(0, 0.22),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 26),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    stag(
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: ShaderMask(
                                  shaderCallback: (bounds) =>
                                      const LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.white,
                                          Color(0xFFB9C0CE),
                                          Colors.white,
                                        ],
                                        stops: [0.0, 0.55, 1.0],
                                      ).createShader(bounds),
                                  child: Text(
                                    'CraftAI',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 84,
                                      letterSpacing: 0.5,
                                      height: 1.0,
                                      shadows: [
                                        Shadow(
                                          color: const Color(
                                            0xFF9C7FF5,
                                          ).withValues(alpha: 0.6),
                                          blurRadius: 18,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              // The mascot perches right over the "AI" of
                              // the wordmark, same as the reference design.
                              Positioned(
                                top: -72,
                                right: -6,
                                child: IgnorePointer(
                                  child: SizedBox(
                                    width: 96,
                                    height: 96,
                                    child: Lottie.asset(
                                      'assets/robot.json',
                                      repeat: true,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            t.chooseHowToPlay,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 36),
                    stag(
                      _NeonModeCard(
                        emoji: '⚗️',
                        title: t.alchemyTableModeTitle,
                        badge: t.mainGameBadge,
                        subtitle: t.alchemyTableModeSubtitle,
                        accent: _alchemyAccent,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ModeFamilyHubView(
                              remote: widget.remote,
                              useTubeMechanic: true,
                              title: t.alchemyTableModeTitle,
                              subtitle: t.alchemyTableModeSubtitle,
                              emoji: '⚗️',
                              accent: _alchemyAccent,
                              mainGameTitle: t.alchemyTableModeTitle,
                              mainGameBuilder: (_) =>
                                  AlchemyTableModeView(remote: widget.remote),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    stag(
                      _NeonModeCard(
                        emoji: '🪐',
                        title: t.freeModeTitle,
                        badge: null,
                        subtitle: t.freeModeSubtitle,
                        accent: _spaceAccent,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ModeFamilyHubView(
                              remote: widget.remote,
                              useTubeMechanic: false,
                              title: t.freeModeTitle,
                              subtitle: t.freeModeSubtitle,
                              emoji: '🪐',
                              accent: _spaceAccent,
                              mainGameTitle: t.freeModeTitle,
                              mainGameBuilder: (_) =>
                                  FreeModeView(remote: widget.remote),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (!auth.isSignedIn) ...[
                      const SizedBox(height: 64),
                      stag(
                        Center(
                          child: _GoogleSignInButton(
                            tooltip: t.signInWithGoogle,
                            onTap: auth.signInWithGoogle,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fixed-seed starfield, twinkling very slowly — a static decorative layer,
/// same idea as the one used on the splash screen.
class _PlayStarsPainter extends CustomPainter {
  static final List<Offset> _positions = List.generate(90, (i) {
    final rnd = math.Random(i * 7919);
    return Offset(rnd.nextDouble(), rnd.nextDouble());
  });
  static final List<double> _sizes = List.generate(90, (i) {
    final rnd = math.Random(i * 104729);
    return 0.6 + rnd.nextDouble() * 1.6;
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.55);
    for (var i = 0; i < _positions.length; i++) {
      canvas.drawCircle(
        Offset(_positions[i].dx * size.width, _positions[i].dy * size.height),
        _sizes[i],
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PlayStarsPainter oldDelegate) => false;
}

/// Element emoji slowly drifting left-to-right (or the reverse), each
/// confined to either the top or bottom sliver of the screen — never the
/// vertical middle, where the logo/cards block always lives.
class _DriftingElementsPainter extends CustomPainter {
  _DriftingElementsPainter(this.progress);

  final double progress;

  static const _elements = [
    (emoji: '🔥', yFraction: 0.04, speed: 1.0, phase: 0.02, size: 20.0),
    (emoji: '💧', yFraction: 0.08, speed: 0.75, phase: 0.35, size: 20.0),
    (emoji: '🌍', yFraction: 0.03, speed: 1.2, phase: 0.65, size: 18.0),
    (emoji: '🌬️', yFraction: 0.10, speed: 0.9, phase: 0.85, size: 18.0),
    (emoji: '🏢', yFraction: 0.93, speed: 0.85, phase: 0.10, size: 20.0),
    (emoji: '🧱', yFraction: 0.97, speed: 1.05, phase: 0.45, size: 18.0),
    (emoji: '🪨', yFraction: 0.95, speed: 0.7, phase: 0.60, size: 18.0),
    (emoji: '🌋', yFraction: 0.91, speed: 1.15, phase: 0.90, size: 22.0),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final e in _elements) {
      final t = (progress * e.speed + e.phase) % 1.0;
      final x = t * (size.width + 60) - 30;
      final y = e.yFraction * size.height;
      final fade = (math.sin(t * math.pi)).clamp(0.0, 1.0);

      final painter = TextPainter(
        text: TextSpan(
          text: e.emoji,
          style: TextStyle(fontSize: e.size),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      canvas.save();
      canvas.translate(x, y);
      canvas.saveLayer(
        Rect.fromLTWH(0, 0, painter.width, painter.height),
        Paint()..color = Colors.white.withValues(alpha: 0.4 * fade),
      );
      painter.paint(canvas, Offset.zero);
      canvas.restore();
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _DriftingElementsPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _GoogleSignInButton extends StatelessWidget {
  const _GoogleSignInButton({required this.tooltip, required this.onTap});

  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Container(
            width: 52,
            height: 52,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: SvgPicture.asset(
              'assets/google_logo.svg',
              width: 24,
              height: 24,
            ),
          ),
        ),
      ),
    );
  }
}

/// A full-width mode card with a glowing neon border, matching the app's
/// hand-off design reference: icon chip on the left, title + optional
/// "flagship" badge + description in the middle, a circular chevron button
/// on the right.
class _NeonModeCard extends StatelessWidget {
  const _NeonModeCard({
    required this.emoji,
    required this.title,
    required this.badge,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final String? badge;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFF15111F),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: accent.withValues(alpha: 0.85),
              width: 1.6,
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.35),
                blurRadius: 28,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  color: const Color(0xFF0E0C18),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.55),
                      blurRadius: 20,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(emoji, style: const TextStyle(fontSize: 34)),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        badge!,
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 13.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: accent, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.chevron_right, color: accent, size: 24),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/localization/app_strings.dart';
import '../core/services/supabase_service.dart';
import '../providers/settings_provider.dart';
import 'main_shell.dart';
import 'onboarding_view.dart';

/// A short, fully Flutter-drawn intro shown on cold start: a starfield
/// backdrop with a glowing emblem that morphs from the Alchemy Table's amber
/// glow into Space Mode's indigo glow, echoing the app's two mode families.
/// Auto-advances to onboarding (first run) or the main shell.
class SplashView extends StatefulWidget {
  const SplashView({super.key, required this.remote});

  final SupabaseService remote;

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  static const _alchemyAccent = Color(0xFFD97706);
  static const _spaceAccent = Color(0xFF4C3FBF);

  late final AnimationController _ctrl;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _textFade;
  late final Animation<double> _morph;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..forward();

    _logoFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.30, curve: Curves.easeOut),
    );
    _logoScale = Tween(begin: 0.72, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOutBack),
      ),
    );
    _textFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.30, 0.55, curve: Curves.easeOut),
    );
    _morph = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.35, 1.0, curve: Curves.easeInOut),
    );

    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) _advance();
    });
  }

  void _advance() {
    Future.delayed(const Duration(milliseconds: 260), () {
      if (!mounted) return;
      final settings = context.read<SettingsProvider>();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => settings.hasSeenWelcome
              ? MainShell(remote: widget.remote)
              : const OnboardingView(),
        ),
      );
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context.watch<SettingsProvider>().language);

    return Scaffold(
      backgroundColor: const Color(0xFF0E0C18),
      body: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final morph = _morph.value;
          final glow = Color.lerp(_alchemyAccent, _spaceAccent, morph)!;

          return Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.1),
                      radius: 1.1,
                      colors: [
                        glow.withValues(alpha: 0.28),
                        const Color(0xFF0E0C18),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(painter: _SplashStarsPainter()),
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Opacity(
                      opacity: _logoFade.value,
                      child: Transform.scale(
                        scale: _logoScale.value,
                        // The real launcher icon artwork, so the native
                        // splash → Flutter splash handoff is seamless.
                        child: Image.asset(
                          'assets/icon/app_icon_foreground.png',
                          width: 220,
                          height: 220,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Opacity(
                      opacity: _textFade.value,
                      child: Column(
                        children: [
                          Text(
                            'CraftAI',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            t.tagline,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SplashEmblem extends StatelessWidget {
  const _SplashEmblem({required this.glow, required this.morph});

  final Color glow;

  /// 0.0 = fully Alchemy Table (⚗️), 1.0 = fully Space Mode (🪐).
  final double morph;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [glow.withValues(alpha: 0.35), Colors.transparent],
              ),
            ),
          ),
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [glow, glow.withValues(alpha: 0.7)],
              ),
              boxShadow: [
                BoxShadow(
                  color: glow.withValues(alpha: 0.45),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: (1 - morph).clamp(0.0, 1.0),
                  child: const Text('⚗️', style: TextStyle(fontSize: 40)),
                ),
                Opacity(
                  opacity: morph.clamp(0.0, 1.0),
                  child: const Text('🪐', style: TextStyle(fontSize: 40)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashStarsPainter extends CustomPainter {
  static final List<Offset> _positions = List.generate(70, (i) {
    final rnd = math.Random(i * 7919);
    return Offset(rnd.nextDouble(), rnd.nextDouble());
  });
  static final List<double> _sizes = List.generate(70, (i) {
    final rnd = math.Random(i * 104729);
    return 0.6 + rnd.nextDouble() * 1.6;
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.5);
    for (var i = 0; i < _positions.length; i++) {
      canvas.drawCircle(
        Offset(_positions[i].dx * size.width, _positions[i].dy * size.height),
        _sizes[i],
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SplashStarsPainter oldDelegate) => false;
}

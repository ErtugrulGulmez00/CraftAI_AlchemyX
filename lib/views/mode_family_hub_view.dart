import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/localization/app_strings.dart';
import '../core/services/supabase_service.dart';
import '../providers/settings_provider.dart';
import '../widgets/animated_section_widgets.dart';
import 'challenge_mode_view.dart';
import 'target_mode_view.dart';

/// Sub-menu shown after tapping "Alchemy Table" or "Space Mode" on the Play
/// tab: pick between the mode family's flagship experience (Ana Oyun) and
/// its Target/Challenge variants, both of which reuse the same mechanic as
/// the family they were opened from (tube+mortar for Alchemy Table, free
/// canvas for Space Mode). Same dark cosmic/neon visual language as the
/// Play tab itself.
class ModeFamilyHubView extends StatefulWidget {
  const ModeFamilyHubView({
    super.key,
    required this.remote,
    required this.useTubeMechanic,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.accent,
    required this.mainGameTitle,
    required this.mainGameBuilder,
  });

  final SupabaseService remote;
  final bool useTubeMechanic;
  final String title;
  final String subtitle;
  final String emoji;
  final Color accent;
  final String mainGameTitle;
  final WidgetBuilder mainGameBuilder;

  @override
  State<ModeFamilyHubView> createState() => _ModeFamilyHubViewState();
}

class _ModeFamilyHubViewState extends State<ModeFamilyHubView>
    with SingleTickerProviderStateMixin {
  static const _targetAccent = Color(0xFFFF6B4A);
  static const _challengeAccent = Color(0xFFFFD54F);

  late final AnimationController _entrance;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context.watch<SettingsProvider>().language);

    var stagger = 0;
    Widget stag(Widget child) =>
        Stagger(animation: _entrance, index: stagger++, child: child);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text(widget.title),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(color: Color(0xFF0B0916)),
        child: Stack(
          children: [
            // ── Nebula glow, tinted with this family's own accent ──────────
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.6),
                      radius: 1.1,
                      colors: [
                        widget.accent.withValues(alpha: 0.30),
                        widget.accent.withValues(alpha: 0.12),
                        const Color(0xFF0B0916),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // ── Stars ───────────────────────────────────────────────────────
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _HubStarsPainter()),
              ),
            ),

            SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                children: [
                  stag(
                    Column(
                      children: [
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                widget.accent,
                                widget.accent.withValues(alpha: 0.7),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: widget.accent.withValues(alpha: 0.55),
                                blurRadius: 26,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            widget.emoji,
                            style: const TextStyle(fontSize: 40),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          t.chooseHowToPlay,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.subtitle,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  stag(
                    _HubNeonCard(
                      emoji: widget.emoji,
                      title: widget.mainGameTitle,
                      subtitle: widget.subtitle,
                      accent: widget.accent,
                      badge: t.mainGameBadge,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: widget.mainGameBuilder),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  stag(
                    _HubNeonCard(
                      emoji: '🎯',
                      title: t.targetModeTitle,
                      subtitle: t.targetModeSubtitle,
                      accent: _targetAccent,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TargetModeView(
                            remote: widget.remote,
                            useTubeMechanic: widget.useTubeMechanic,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  stag(
                    _HubNeonCard(
                      emoji: '🏆',
                      title: t.challengeModeTitle,
                      subtitle: t.challengeModeSubtitle,
                      accent: _challengeAccent,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChallengeModeView(
                            remote: widget.remote,
                            useTubeMechanic: widget.useTubeMechanic,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fixed-seed starfield, same idea as the Play tab's own background layer.
class _HubStarsPainter extends CustomPainter {
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
  bool shouldRepaint(covariant _HubStarsPainter oldDelegate) => false;
}

/// A full-width neon-bordered mode card, matching the Play tab's own
/// `_NeonModeCard` styling: icon chip on the left, title + optional
/// "flagship" badge + description in the middle, a circular chevron on the
/// right.
class _HubNeonCard extends StatelessWidget {
  const _HubNeonCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
    this.badge,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF15111F),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: accent.withValues(alpha: 0.85),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.32),
                blurRadius: 24,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  color: const Color(0xFF0E0C18),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.5),
                      blurRadius: 18,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(emoji, style: const TextStyle(fontSize: 30)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        badge!,
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.62),
                        fontSize: 12.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: accent, width: 1.4),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.chevron_right, color: accent, size: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

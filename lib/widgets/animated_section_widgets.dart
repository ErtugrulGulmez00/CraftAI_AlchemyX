import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// A proper, centered section title — bigger and bolder than a plain body
/// label so it actually reads as a heading rather than another line of text.
/// Shared by any page that groups content into labeled sections (Stats,
/// Play, ...).
class SectionHeading extends StatelessWidget {
  const SectionHeading(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.titleLarge,
    );
  }
}

/// Fades + slides its child up on entrance, staggered by [index] so a
/// page's blocks appear one after another instead of all at once.
class Stagger extends StatelessWidget {
  const Stagger({
    super.key,
    required this.animation,
    required this.index,
    required this.child,
  });

  final Animation<double> animation;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final start = (index * 0.12).clamp(0.0, 0.6);
    final curved = CurvedAnimation(
      parent: animation,
      curve: Interval(
        start,
        (start + 0.4).clamp(0.0, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );
    return AnimatedBuilder(
      animation: curved,
      child: child,
      builder: (context, child) => Opacity(
        opacity: curved.value,
        child: Transform.translate(
          offset: Offset(0, (1 - curved.value) * 16),
          child: child,
        ),
      ),
    );
  }
}

/// Gradient banner with a few faint floating emoji for texture — the shared
/// "hero" chrome used at the top of a page (Stats' animated total, Play's
/// welcome header, ...). Callers supply whatever center content they need.
class HeroCard extends StatelessWidget {
  const HeroCard({
    super.key,
    required this.colors,
    required this.child,
    this.particles = const ['🧪', '✨', '🔮', '⚗️'],
    this.height = 140,
  });

  final AppPalette colors;
  final Widget child;
  final List<String> particles;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primary, colors.primaryDark],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (var i = 0; i < particles.length; i++)
            Positioned(
              left: (i * 90.0) % 320 - 20,
              top: (i.isEven ? 12.0 : 78.0),
              child: Opacity(
                opacity: 0.16,
                child: Text(particles[i], style: const TextStyle(fontSize: 34)),
              ),
            ),
          child,
        ],
      ),
    );
  }
}

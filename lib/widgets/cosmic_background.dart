import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The shared dark "starlit lab" backdrop used across the Play tab and its
/// mode-family sub-pages: a solid near-black base, a nebula glow tinted with
/// the caller's own accent color, and a fixed-seed twinkling starfield.
/// Purely decorative — always painted behind [child].
class CosmicBackground extends StatelessWidget {
  const CosmicBackground({
    super.key,
    required this.accent,
    required this.child,
    this.nebulaAlignment = const Alignment(0, -0.55),
  });

  final Color accent;
  final Widget child;
  final Alignment nebulaAlignment;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0xFF0B0916)),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: nebulaAlignment,
                    radius: 1.1,
                    colors: [
                      accent.withValues(alpha: 0.30),
                      accent.withValues(alpha: 0.13),
                      const Color(0xFF0B0916),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _CosmicStarsPainter()),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _CosmicStarsPainter extends CustomPainter {
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
  bool shouldRepaint(covariant _CosmicStarsPainter oldDelegate) => false;
}

import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A single fixed star in the decorative starfield — position is normalized
/// to a unit disk (distance from center in [0,1]) so it scales with whatever
/// sphere radius is painted.
class _Star {
  const _Star({
    required this.unitOffset,
    required this.radius,
    required this.opacity,
  });

  final Offset unitOffset;
  final double radius;
  final double opacity;
}

/// A soft, blurred "continent" patch on the planet's surface — purely
/// decorative texture so the sphere reads as a world, not a plain gradient
/// ball.
class _ContinentBlob {
  const _ContinentBlob({
    required this.unitOffset,
    required this.unitRadius,
    required this.opacity,
  });

  final Offset unitOffset;
  final double unitRadius;
  final double opacity;
}

/// Paints a 2D "planet in space" illusion: a shaded radial-gradient sphere
/// with a fixed starfield that slowly rotates. This is a pure visual
/// illusion (no real 3D/depth) — cheap enough to redraw every frame and
/// crossfaded in by the caller based on how zoomed-out the canvas is.
class GlobeBackgroundPainter extends CustomPainter {
  GlobeBackgroundPainter({
    required this.opacity,
    required this.sphereRadius,
    required this.rotation,
    required this.primary,
    required this.primaryDark,
  });

  /// Overall fade-in amount, 0 (invisible) .. 1 (fully opaque).
  final double opacity;

  /// Pixel radius to paint the sphere at — passed in by the caller (rather
  /// than derived from the canvas size here) so it always exactly matches
  /// the outer clip shape's radius instead of two independently-computed
  /// circles drifting apart mid-transition.
  final double sphereRadius;

  /// Looping 0..1 value driving the slow "spin" of the starfield.
  final double rotation;

  final Color primary;
  final Color primaryDark;

  static final List<_Star> _stars = _generateStars();
  static final List<_ContinentBlob> _continents = _generateContinents();

  static List<_Star> _generateStars() {
    final rand = math.Random(42); // fixed seed: stars never regenerate/jump
    return List.generate(90, (_) {
      final angle = rand.nextDouble() * 2 * math.pi;
      final dist = math.sqrt(rand.nextDouble()); // uniform disk distribution
      return _Star(
        unitOffset: Offset(math.cos(angle), math.sin(angle)) * dist,
        radius: 0.6 + rand.nextDouble() * 1.6,
        opacity: 0.25 + rand.nextDouble() * 0.65,
      );
    });
  }

  static List<_ContinentBlob> _generateContinents() {
    final rand = math.Random(7); // different fixed seed than the starfield
    return List.generate(6, (_) {
      final angle = rand.nextDouble() * 2 * math.pi;
      final dist = rand.nextDouble() * 0.7; // keep clear of the sphere's rim
      return _ContinentBlob(
        unitOffset: Offset(math.cos(angle), math.sin(angle)) * dist,
        unitRadius: 0.18 + rand.nextDouble() * 0.22,
        opacity: 0.12 + rand.nextDouble() * 0.14,
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;

    final center = size.center(Offset.zero);
    final rect = Rect.fromCircle(center: center, radius: sphereRadius);

    // Everything below is painted at full strength onto an offscreen layer,
    // then the whole layer is faded by [opacity] in one go on restore —
    // simpler than threading alpha through every individual paint.
    canvas.saveLayer(
      rect.inflate(8),
      Paint()..color = Colors.white.withValues(alpha: opacity),
    );

    final gradient = RadialGradient(
      center: const Alignment(-0.3, -0.35),
      radius: 1.15,
      colors: [
        Color.lerp(primary, Colors.white, 0.2)!,
        primaryDark,
        const Color(0xFF05040A),
      ],
      stops: const [0.0, 0.55, 1.0],
    );
    canvas.drawCircle(
      center,
      sphereRadius,
      Paint()..shader = gradient.createShader(rect),
    );

    // Continents + starfield share the same slow rotation and are clipped
    // to the sphere's disk so they read as "on the planet", not floating
    // outside it.
    canvas.save();
    canvas.clipPath(Path()..addOval(rect));
    final angle = rotation * 2 * math.pi;
    final cosA = math.cos(angle);
    final sinA = math.sin(angle);

    // Soft, blurred "continent" patches — pure texture, no hard edges.
    for (final blob in _continents) {
      final rotated = Offset(
        blob.unitOffset.dx * cosA - blob.unitOffset.dy * sinA,
        blob.unitOffset.dx * sinA + blob.unitOffset.dy * cosA,
      );
      final pos = center + rotated * sphereRadius;
      final blobRadius = blob.unitRadius * sphereRadius;
      canvas.drawCircle(
        pos,
        blobRadius,
        Paint()
          ..color = Colors.white.withValues(alpha: blob.opacity)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, blobRadius * 0.6),
      );
    }

    for (final star in _stars) {
      final rotated = Offset(
        star.unitOffset.dx * cosA - star.unitOffset.dy * sinA,
        star.unitOffset.dx * sinA + star.unitOffset.dy * cosA,
      );
      final pos = center + rotated * sphereRadius;
      canvas.drawCircle(
        pos,
        star.radius,
        Paint()..color = Colors.white.withValues(alpha: star.opacity),
      );
    }
    canvas.restore();

    // Thin rim-light so the disk reads as a lit sphere, not a flat circle.
    canvas.drawCircle(
      center,
      sphereRadius - 1,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: 0.18),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant GlobeBackgroundPainter oldDelegate) =>
      oldDelegate.opacity != opacity ||
      oldDelegate.sphereRadius != sphereRadius ||
      oldDelegate.rotation != rotation ||
      oldDelegate.primary != primary ||
      oldDelegate.primaryDark != primaryDark;
}

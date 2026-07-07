import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// A brief spark burst played when two elements combine — extracted so
/// both [CraftCanvas] and Quick Combine mode can reuse the exact same
/// celebratory effect instead of duplicating it.
class MergeParticles extends StatefulWidget {
  const MergeParticles({
    super.key,
    required this.colors,
    required this.onCompleted,
  });

  static const double size = 160;

  final AppPalette colors;
  final VoidCallback onCompleted;

  @override
  State<MergeParticles> createState() => _MergeParticlesState();
}

class _MergeParticlesState extends State<MergeParticles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Spark> _sparks;

  @override
  void initState() {
    super.initState();
    final rand = math.Random();
    final palette = [
      widget.colors.primary,
      widget.colors.secondary,
      widget.colors.accent,
    ];
    _sparks = List.generate(14, (_) {
      return _Spark(
        angle: rand.nextDouble() * 2 * math.pi,
        distance: 28 + rand.nextDouble() * 42,
        size: 3 + rand.nextDouble() * 4,
        color: palette[rand.nextInt(palette.length)],
      );
    });
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward().whenComplete(widget.onCompleted);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          size: const Size.square(MergeParticles.size),
          painter: _SparkPainter(_sparks, _controller.value),
        );
      },
    );
  }
}

class _Spark {
  _Spark({
    required this.angle,
    required this.distance,
    required this.size,
    required this.color,
  });

  final double angle;
  final double distance;
  final double size;
  final Color color;
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.sparks, this.progress);

  final List<_Spark> sparks;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final eased = Curves.easeOut.transform(progress);
    final opacity = (1 - progress).clamp(0.0, 1.0);

    for (final spark in sparks) {
      final offset =
          center +
          Offset(math.cos(spark.angle), math.sin(spark.angle)) *
              spark.distance *
              eased;
      final paint = Paint()..color = spark.color.withValues(alpha: opacity);
      canvas.drawCircle(offset, spark.size * (1 - progress * 0.4), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparkPainter oldDelegate) => true;
}

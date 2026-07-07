import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A celebratory confetti burst that falls from the top of the screen.
///
/// Stays mounted with no visible output until [trigger] changes from `null`
/// to a non-null value (e.g. `game.lastFirstDiscovery`), at which point it
/// plays a ~1.4s burst. Place it as the last child of a [Stack], wrapped in
/// `Positioned.fill` + `IgnorePointer` so it doesn't block touches.
class ConfettiOverlay extends StatefulWidget {
  const ConfettiOverlay({super.key, this.trigger});

  final Object? trigger;

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  static const _colors = [
    Color(0xFFFFC107),
    Color(0xFFFF6B6B),
    Color(0xFF54A0FF),
    Color(0xFF1DD1A1),
    Color(0xFFC56CF0),
    Color(0xFFFFD93D),
  ];

  late final AnimationController _controller;
  List<_ConfettiPiece> _pieces = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
  }

  @override
  void didUpdateWidget(covariant ConfettiOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != null && widget.trigger != oldWidget.trigger) {
      _play();
    }
  }

  void _play() {
    final size = MediaQuery.sizeOf(context);
    final rand = math.Random();
    _pieces = List.generate(40, (_) {
      return _ConfettiPiece(
        x: rand.nextDouble() * size.width,
        delay: rand.nextDouble() * 0.3,
        fallSpeed: 0.7 + rand.nextDouble() * 0.5,
        drift: (rand.nextDouble() - 0.5) * 100,
        spin: (rand.nextDouble() - 0.5) * 10,
        size: 6 + rand.nextDouble() * 6,
        color: _colors[rand.nextInt(_colors.length)],
      );
    });
    _controller.forward(from: 0);
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
        if (_controller.isDismissed) return const SizedBox.shrink();
        return CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(_pieces, _controller.value),
        );
      },
    );
  }
}

class _ConfettiPiece {
  _ConfettiPiece({
    required this.x,
    required this.delay,
    required this.fallSpeed,
    required this.drift,
    required this.spin,
    required this.size,
    required this.color,
  });

  final double x;
  final double delay;
  final double fallSpeed;
  final double drift;
  final double spin;
  final double size;
  final Color color;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.progress);

  final List<_ConfettiPiece> pieces;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    for (final piece in pieces) {
      final t = ((progress - piece.delay) / (1 - piece.delay)).clamp(0.0, 1.0);
      if (t <= 0) continue;
      final y = -20 + t * (size.height + 40) * piece.fallSpeed;
      if (y > size.height + 20) continue;
      final x = piece.x + piece.drift * t;
      final fadeIn = (t / 0.1).clamp(0.0, 1.0);
      final fadeOut = t > 0.85 ? ((1 - t) / 0.15).clamp(0.0, 1.0) : 1.0;
      final paint = Paint()
        ..color = piece.color.withValues(alpha: math.min(fadeIn, fadeOut));
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(piece.spin * t * math.pi);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: piece.size,
          height: piece.size * 0.6,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}

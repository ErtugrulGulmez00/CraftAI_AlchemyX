import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Renders a square "I discovered X!" card in the app's cosmic style and
/// hands it to the system share sheet. Pure Canvas drawing (no offscreen
/// widgets), so it works from any context — snackbar actions included.
class ShareService {
  ShareService._();

  static const _size = 1080.0;

  /// Draws the card, writes it to a temp PNG and opens the share sheet.
  /// Best-effort: sharing is never worth crashing gameplay over.
  static Future<void> shareDiscovery({
    required String emoji,
    required String name,
    required String cardTitle,
    required String shareText,
  }) async {
    try {
      final bytes = await _renderCard(
        emoji: emoji,
        name: name,
        title: cardTitle,
      );
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/craftai_discovery.png');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: shareText);
    } catch (_) {}
  }

  static Future<List<int>> _renderCard({
    required String emoji,
    required String name,
    required String title,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const rect = Rect.fromLTWH(0, 0, _size, _size);

    // Base + nebula, matching CosmicBackground's palette.
    canvas.drawRect(rect, Paint()..color = const Color(0xFF0B0916));
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.4),
          radius: 1.1,
          colors: [
            const Color(0xFF6C3FE0).withValues(alpha: 0.35),
            const Color(0xFF6C3FE0).withValues(alpha: 0.12),
            const Color(0xFF0B0916),
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(rect),
    );

    // Fixed-seed starfield.
    final starPaint = Paint()..color = Colors.white;
    for (var i = 0; i < 90; i++) {
      final rx = Random(i * 7919).nextDouble();
      final ry = Random(i * 104729).nextDouble();
      final r = 1.0 + Random(i * 31).nextDouble() * 2.4;
      starPaint.color = Colors.white.withValues(
        alpha: 0.25 + Random(i * 13).nextDouble() * 0.55,
      );
      canvas.drawCircle(Offset(rx * _size, ry * _size), r, starPaint);
    }

    void drawText(
      String text,
      double y,
      TextStyle style, {
      double maxWidth = _size - 120,
    }) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        maxLines: 2,
        ellipsis: '…',
      )..layout(maxWidth: maxWidth);
      painter.paint(canvas, Offset((_size - painter.width) / 2, y));
    }

    // Glow disc behind the emoji.
    canvas.drawCircle(
      const Offset(_size / 2, 430),
      190,
      Paint()
        ..color = const Color(0xFF6C3FE0).withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60),
    );

    drawText(
      '✨ $title ✨',
      140,
      const TextStyle(
        color: Color(0xFFFFD54F),
        fontSize: 54,
        fontWeight: FontWeight.w800,
      ),
    );
    drawText(emoji, 290, const TextStyle(fontSize: 260));
    drawText(
      name,
      640,
      const TextStyle(
        color: Colors.white,
        fontSize: 88,
        fontWeight: FontWeight.w800,
      ),
    );
    drawText(
      'CraftAI',
      930,
      TextStyle(
        color: Colors.white.withValues(alpha: 0.85),
        fontSize: 44,
        fontWeight: FontWeight.w800,
        letterSpacing: 2,
      ),
    );

    final image = await recorder.endRecording().toImage(
      _size.toInt(),
      _size.toInt(),
    );
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }
}

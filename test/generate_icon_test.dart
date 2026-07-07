// One-off generator (not a real test): draws the CraftAI launcher icon
// with dart:ui and writes the PNGs flutter_launcher_icons consumes.
// Run with:  flutter test test/generate_icon_test.dart
// then:      dart run flutter_launcher_icons
//
// Design (vector interpretation of the approved mockup): dark space bg,
// silver-rimmed rounded plate, neon-orange ring connecting four element
// medallions (fire / tornado / wind / rocks), and a golden "AI" alchemy
// retort with a falling drop in the middle.
//
// Outputs:
//   assets/icon/app_icon.png             — full icon
//   assets/icon/app_icon_foreground.png  — transparent, safe-zone scaled,
//                                          for the Android adaptive icon

import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _size = 1024.0;
const _cx = _size / 2;
const _neon = Color(0xFFFF9F2E);

// ── Background ─────────────────────────────────────────────────────────────

void _drawBackground(Canvas canvas) {
  const rect = Rect.fromLTWH(0, 0, _size, _size);
  canvas.drawRect(rect, Paint()..color = const Color(0xFF0A0D18));
  // Faint teal + purple nebula hints, like the mockup's corners.
  canvas.drawRect(
    rect,
    Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.8, -0.7),
        radius: 0.9,
        colors: [
          const Color(0xFF1B4A44).withValues(alpha: 0.35),
          Colors.transparent,
        ],
      ).createShader(rect),
  );
  canvas.drawRect(
    rect,
    Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.85, 0.6),
        radius: 0.9,
        colors: [
          const Color(0xFF3A2450).withValues(alpha: 0.35),
          Colors.transparent,
        ],
      ).createShader(rect),
  );

  // Starfield: mostly white pinpricks, a few warm orange motes.
  for (var i = 0; i < 60; i++) {
    final rx = Random(i * 7919).nextDouble();
    final ry = Random(i * 104729).nextDouble();
    final warm = Random(i * 53).nextDouble() < 0.2;
    final r = 1.5 + Random(i * 31).nextDouble() * 3.5;
    canvas.drawCircle(
      Offset(rx * _size, ry * _size),
      r,
      Paint()
        ..color = (warm ? const Color(0xFFFFB86B) : Colors.white).withValues(
          alpha: 0.2 + Random(i * 13).nextDouble() * 0.5,
        ),
    );
  }
}

/// Silver-rimmed rounded-square plate the whole composition sits on.
void _drawPlate(Canvas canvas) {
  // Nearly full-bleed: launchers mask the icon into their own shape, so
  // any margin we leave just makes the icon look small on the home screen.
  final plate = RRect.fromRectAndRadius(
    Rect.fromCenter(center: const Offset(_cx, _cx), width: 1014, height: 1014),
    const Radius.circular(220),
  );
  canvas.drawRRect(
    plate,
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF141A29), Color(0xFF0C101C)],
      ).createShader(plate.outerRect),
  );
  canvas.drawRRect(
    plate,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFB8BEC9), Color(0xFF5A6070), Color(0xFF9AA0AC)],
      ).createShader(plate.outerRect),
  );
}

// ── Neon ring + medallions ─────────────────────────────────────────────────

void _neonStroke(Canvas canvas, Path path, double width) {
  canvas.drawPath(
    path,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width + 14
      ..color = _neon.withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
  );
  canvas.drawPath(
    path,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFC46B), Color(0xFFFF8A1E)],
      ).createShader(Rect.fromCircle(center: const Offset(_cx, _cx), radius: 340)),
  );
}

// Big ring so the corner medallions land in the plate's actual corners —
// the ring's cardinal points nearly touch the plate's edge midpoints.
const _ringR = 440.0;

void _drawRing(Canvas canvas) {
  _neonStroke(
    canvas,
    Path()
      ..addOval(Rect.fromCircle(center: const Offset(_cx, _cx), radius: _ringR)),
    12,
  );
}

void _drawMedallionShell(Canvas canvas, Offset c, double r) {
  canvas.drawCircle(c, r, Paint()..color = const Color(0xFF0B0F1B));
  _neonStroke(canvas, Path()..addOval(Rect.fromCircle(center: c, radius: r)), 10);
}

// Corner art — all vector (the headless test renderer has no emoji font).

void _drawFire(Canvas canvas, Offset c) {
  Path flame(double s) => Path()
    ..moveTo(c.dx, c.dy + 52 * s)
    ..cubicTo(c.dx - 46 * s, c.dy + 30 * s, c.dx - 34 * s, c.dy - 10 * s,
        c.dx - 12 * s, c.dy - 28 * s)
    ..cubicTo(c.dx - 18 * s, c.dy - 6 * s, c.dx - 2 * s, c.dy - 2 * s,
        c.dx + 4 * s, c.dy - 52 * s)
    ..cubicTo(c.dx + 22 * s, c.dy - 26 * s, c.dx + 40 * s, c.dy - 8 * s,
        c.dx + 40 * s, c.dy + 16 * s)
    ..cubicTo(c.dx + 40 * s, c.dy + 42 * s, c.dx + 22 * s, c.dy + 52 * s,
        c.dx, c.dy + 52 * s)
    ..close();

  canvas.drawPath(
    flame(1.0),
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: const [Color(0xFFE0451F), Color(0xFFFF9800)],
      ).createShader(Rect.fromCircle(center: c, radius: 60)),
  );
  canvas.drawPath(
    flame(0.55)..shift(const Offset(0, 10)),
    Paint()..color = const Color(0xFFFFD54F),
  );
}

void _drawTornado(Canvas canvas, Offset c) {
  final widths = [92.0, 68.0, 46.0, 28.0, 14.0];
  for (var i = 0; i < widths.length; i++) {
    final y = c.dy - 38 + i * 19.0;
    final xOff = (i.isEven ? -1 : 1) * i * 3.0;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(c.dx + xOff, y),
        width: widths[i],
        height: 22,
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round
        ..shader = const LinearGradient(
          colors: [Color(0xFF9BE7FF), Color(0xFF3FA9E0)],
        ).createShader(Rect.fromCircle(center: c, radius: 60)),
    );
  }
}

void _drawWind(Canvas canvas, Offset c) {
  final paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 11
    ..strokeCap = StrokeCap.round
    ..shader = const LinearGradient(
      colors: [Colors.white, Color(0xFF9BD4F5)],
    ).createShader(Rect.fromCircle(center: c, radius: 60));

  // Two spiral curls, like the mockup's gust swirl.
  canvas.drawPath(
    Path()
      ..moveTo(c.dx - 48, c.dy - 8)
      ..cubicTo(c.dx - 10, c.dy - 52, c.dx + 44, c.dy - 40, c.dx + 40, c.dy - 8)
      ..cubicTo(c.dx + 37, c.dy + 14, c.dx + 12, c.dy + 16, c.dx + 10, c.dy - 2),
    paint,
  );
  canvas.drawPath(
    Path()
      ..moveTo(c.dx - 44, c.dy + 26)
      ..cubicTo(c.dx - 6, c.dy + 4, c.dx + 30, c.dy + 18, c.dx + 22, c.dy + 40)
      ..cubicTo(c.dx + 16, c.dy + 54, c.dx - 2, c.dy + 50, c.dx - 2, c.dy + 38),
    paint,
  );
}

void _drawRocks(Canvas canvas, Offset c) {
  void nugget(Offset o, double s, Color base) {
    final path = Path()
      ..moveTo(o.dx - 30 * s, o.dy + 22 * s)
      ..lineTo(o.dx - 34 * s, o.dy - 6 * s)
      ..lineTo(o.dx - 10 * s, o.dy - 26 * s)
      ..lineTo(o.dx + 22 * s, o.dy - 18 * s)
      ..lineTo(o.dx + 32 * s, o.dy + 10 * s)
      ..lineTo(o.dx + 14 * s, o.dy + 24 * s)
      ..close();
    canvas.drawPath(path, Paint()..color = base);
    // Top facet highlight.
    canvas.drawPath(
      Path()
        ..moveTo(o.dx - 34 * s, o.dy - 6 * s)
        ..lineTo(o.dx - 10 * s, o.dy - 26 * s)
        ..lineTo(o.dx + 22 * s, o.dy - 18 * s)
        ..lineTo(o.dx - 4 * s, o.dy - 2 * s)
        ..close(),
      Paint()..color = Colors.white.withValues(alpha: 0.22),
    );
  }

  nugget(c + const Offset(-22, 16), 0.9, const Color(0xFF8A6A45));
  nugget(c + const Offset(26, 20), 0.7, const Color(0xFF6E5236));
  nugget(c + const Offset(4, -18), 1.0, const Color(0xFFA5825A));
}

// ── Center: golden AI retort ───────────────────────────────────────────────

void _drawRetort(Canvas canvas) {
  const bodyC = Offset(_cx, 560);
  const bodyR = 150.0;

  // Warm glow behind everything.
  canvas.drawCircle(
    bodyC,
    215,
    Paint()
      ..color = _neon.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80),
  );

  final gold = Paint()
    ..shader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFE3A0), Color(0xFFE0952B), Color(0xFFB06A14)],
    ).createShader(Rect.fromCircle(center: bodyC, radius: bodyR + 60));

  // Tripod legs + stand band.
  for (final dx in [-92.0, 0.0, 92.0]) {
    final foot = Offset(bodyC.dx + dx * 1.25, bodyC.dy + 218);
    canvas.drawPath(
      Path()
        ..moveTo(bodyC.dx + dx - 16, bodyC.dy + 118)
        ..lineTo(bodyC.dx + dx + 16, bodyC.dy + 118)
        ..lineTo(foot.dx + 12, foot.dy)
        ..lineTo(foot.dx - 12, foot.dy)
        ..close(),
      gold,
    );
  }
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(bodyC.dx, bodyC.dy + 118),
      width: 260,
      height: 64,
    ),
    gold,
  );

  // Neck: a tapered tube rising from the sphere's top, arching right and
  // turning down into an open spout mouth (the drop hangs just below it).
  final neck = Path()
    ..moveTo(bodyC.dx - 46, bodyC.dy - 116)
    ..cubicTo(bodyC.dx - 46, bodyC.dy - 236, bodyC.dx + 48, bodyC.dy - 266,
        bodyC.dx + 130, bodyC.dy - 230)
    ..cubicTo(bodyC.dx + 172, bodyC.dy - 212, bodyC.dx + 198, bodyC.dy - 186,
        bodyC.dx + 206, bodyC.dy - 152)
    ..lineTo(bodyC.dx + 154, bodyC.dy - 144)
    ..cubicTo(bodyC.dx + 148, bodyC.dy - 168, bodyC.dx + 116, bodyC.dy - 186,
        bodyC.dx + 76, bodyC.dy - 196)
    ..cubicTo(bodyC.dx + 28, bodyC.dy - 206, bodyC.dx + 10, bodyC.dy - 178,
        bodyC.dx + 10, bodyC.dy - 108)
    ..close();
  canvas.drawPath(neck, gold);
  // Open mouth of the spout (dark ellipse suggesting the tube opening).
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(bodyC.dx + 180, bodyC.dy - 148),
      width: 52,
      height: 18,
    ),
    Paint()..color = const Color(0xFF7A4A0E),
  );
  // Collar where neck meets body.
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(bodyC.dx - 18, bodyC.dy - 118),
      width: 96,
      height: 30,
    ),
    gold,
  );

  // Falling drop under the spout.
  final drop = Offset(bodyC.dx + 186, bodyC.dy - 92);
  canvas.drawPath(
    Path()
      ..moveTo(drop.dx, drop.dy - 34)
      ..quadraticBezierTo(drop.dx + 26, drop.dy + 4, drop.dx, drop.dy + 22)
      ..quadraticBezierTo(drop.dx - 26, drop.dy + 4, drop.dx, drop.dy - 34),
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFE9B0), Color(0xFFFF9F2E)],
      ).createShader(Rect.fromCircle(center: drop, radius: 34)),
  );

  // Glass sphere body.
  canvas.drawCircle(
    bodyC,
    bodyR,
    Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.4),
        colors: const [Color(0xFFFFF3CE), Color(0xFFF3B24A), Color(0xFFC97D18)],
      ).createShader(Rect.fromCircle(center: bodyC, radius: bodyR)),
  );
  // Glowing liquid in the lower half.
  canvas.save();
  canvas.clipPath(Path()..addOval(Rect.fromCircle(center: bodyC, radius: bodyR - 14)));
  canvas.drawRect(
    Rect.fromLTWH(bodyC.dx - bodyR, bodyC.dy - 4, bodyR * 2, bodyR),
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFB23E), Color(0xFFE06A10)],
      ).createShader(Rect.fromCircle(center: bodyC, radius: bodyR)),
  );
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(bodyC.dx, bodyC.dy - 4),
      width: (bodyR - 14) * 2,
      height: 44,
    ),
    Paint()..color = const Color(0xFFFFE08A),
  );
  canvas.restore();

  // Glass highlight glint.
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(bodyC.dx - 72, bodyC.dy - 74),
      width: 56,
      height: 96,
    ),
    Paint()..color = Colors.white.withValues(alpha: 0.35),
  );

  // "AI" medallion on the stand band.
  final medC = Offset(bodyC.dx, bodyC.dy + 118);
  canvas.drawCircle(medC, 56, gold);
  canvas.drawCircle(medC, 56,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = const Color(0xFF8A5510));
  canvas.drawCircle(medC, 44,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xFF8A5510).withValues(alpha: 0.7));
  final ai = TextPainter(
    text: const TextSpan(
      text: 'AI',
      style: TextStyle(
        fontFamily: 'Nunito',
        fontSize: 52,
        fontWeight: FontWeight.w800,
        color: Color(0xFF6E4208),
        letterSpacing: 2,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  ai.paint(canvas, Offset(medC.dx - ai.width / 2, medC.dy - ai.height / 2));
}

/// Ring, medallions and retort — everything except bg/plate, reused at a
/// smaller scale for the adaptive foreground.
void _drawComposition(Canvas canvas) {
  _drawRing(canvas);

  const d = _ringR / 1.4142; // medallion centers sit on the ring's diagonals
  const tl = Offset(_cx - d, _cx - d);
  const tr = Offset(_cx + d, _cx - d);
  const bl = Offset(_cx - d, _cx + d);
  const br = Offset(_cx + d, _cx + d);

  for (final c in [tl, tr, bl, br]) {
    _drawMedallionShell(canvas, c, 100);
  }
  _drawFire(canvas, tl);
  _drawTornado(canvas, tr);
  _drawWind(canvas, bl);
  _drawRocks(canvas, br);

  // The wider ring leaves more room in the middle — grow the retort with
  // it so it stays the visual anchor of the icon.
  canvas.save();
  canvas.translate(_cx, 560);
  canvas.scale(1.22);
  canvas.translate(-_cx, -560);
  _drawRetort(canvas);
  canvas.restore();
}

Future<void> _savePng(
  String path, {
  required bool withBackground,
  required double contentScale,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  if (withBackground) {
    _drawBackground(canvas);
    _drawPlate(canvas);
  }

  canvas.save();
  canvas.translate(_cx, _cx);
  canvas.scale(contentScale);
  canvas.translate(-_cx, -_cx);
  _drawComposition(canvas);
  canvas.restore();

  // (No corner sparkle anymore — the medallions own the corners now.)

  final image = await recorder.endRecording().toImage(
    _size.toInt(),
    _size.toInt(),
  );
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File(path);
  await file.parent.create(recursive: true);
  await file.writeAsBytes(bytes!.buffer.asUint8List());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generate launcher icon PNGs', () async {
    // The headless test renderer has no fonts — load Nunito from the app's
    // own assets so the "AI" medallion renders as real glyphs.
    final fontData = File(
      'assets/fonts/Nunito-ExtraBold.ttf',
    ).readAsBytesSync();
    final loader = FontLoader('Nunito')
      ..addFont(Future.value(ByteData.view(fontData.buffer)));
    await loader.load();

    await _savePng(
      'assets/icon/app_icon.png',
      withBackground: true,
      contentScale: 1.10,
    );
    // Adaptive foreground: the composition's diagonal extent is ~±555px
    // and the launcher shows roughly the center ±341px (72/108dp) — 0.62
    // puts the corner medallions right at that visible edge.
    await _savePng(
      'assets/icon/app_icon_foreground.png',
      withBackground: false,
      contentScale: 0.62,
    );
    expect(File('assets/icon/app_icon.png').existsSync(), isTrue);
  });
}

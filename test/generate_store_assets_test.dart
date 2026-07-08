// One-off generator (not a real test): composes Play Store promo images
// from raw device screenshots — cosmic background, Turkish headline, and
// the screenshot in a glowing rounded device frame. Also renders the
// 1024x500 feature graphic.
//
// Usage:
//   1. Put raw 1080x2400 screenshots where [_shotsDir] points.
//   2. flutter test test/generate_store_assets_test.dart
//   3. Outputs land in store_assets/ (1080x1920 each + feature graphic).

import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _shotsDir =
    r'C:\Users\HP\AppData\Local\Temp\claude\c--Users-HP-Desktop-WordCraftInf\76356260-3c04-42e0-b041-22ddbb459997\scratchpad';
const _outDir = 'store_assets';

const _w = 1080.0;
const _h = 1920.0;

class _Promo {
  const _Promo(this.file, this.title, this.subtitle, this.accent);
  final String file;
  final String title;
  final String subtitle;
  final Color accent;
}

const _promos = [
  _Promo(
    'shot1_oyna.png',
    'Sonsuz Keşif Evreni',
    'Yapay zekâ destekli birleştirme oyunu',
    Color(0xFF8B5CF6),
  ),
  _Promo(
    'shot3_simya.png',
    'Simya Masasında Demle',
    'İki elementi seç, havanda karıştır',
    Color(0xFFFFA53D),
  ),
  _Promo(
    'shot5_canvas.png',
    'Sonsuz Uzay Tuvali',
    'Sürükle, bırak, yeni elementler keşfet',
    Color(0xFF4FD1E8),
  ),
  _Promo(
    'shot4_yarisma.png',
    'Günlük Yarışma',
    'Günün kelimesini en hızlı sen bul',
    Color(0xFFFFD54F),
  ),
  _Promo(
    'shot6_tarif.png',
    'Element Ansiklopedisi',
    'Her keşfin tarifi cebinde',
    Color(0xFF22C55E),
  ),
  _Promo(
    'shot7_istatistik.png',
    'Günlük Görevler',
    'Rozetler kazan, ilerlemeni takip et',
    Color(0xFF8B5CF6),
  ),
  _Promo(
    'shot2_hub.png',
    'Üç Mod Bir Arada',
    'Ana Oyun · Hedef Modu · Yarışma',
    Color(0xFFFF6B4A),
  ),
  _Promo(
    'shot8_ayarlar.png',
    '5 Dilde Oyna',
    'Türkçe, İngilizce, Almanca, İspanyolca, Portekizce',
    Color(0xFF14B8A6),
  ),
];

Future<ui.Image> _loadImage(String path) async {
  final bytes = await File(path).readAsBytes();
  final codec = await ui.instantiateImageCodec(bytes);
  return (await codec.getNextFrame()).image;
}

void _drawCosmicBg(Canvas canvas, Size size, Color accent) {
  final rect = Offset.zero & size;
  canvas.drawRect(rect, Paint()..color = const Color(0xFF0B0916));
  canvas.drawRect(
    rect,
    Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.75),
        radius: 1.3,
        colors: [
          accent.withValues(alpha: 0.38),
          accent.withValues(alpha: 0.10),
          const Color(0xFF0B0916),
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(rect),
  );
  for (var i = 0; i < 70; i++) {
    final rx = Random(i * 7919).nextDouble();
    final ry = Random(i * 104729).nextDouble();
    final r = 1.2 + Random(i * 31).nextDouble() * 2.6;
    canvas.drawCircle(
      Offset(rx * size.width, ry * size.height),
      r,
      Paint()
        ..color = Colors.white.withValues(
          alpha: 0.18 + Random(i * 13).nextDouble() * 0.45,
        ),
    );
  }
}

void _drawText(
  Canvas canvas,
  String text,
  double y,
  double fontSize,
  Color color, {
  FontWeight weight = FontWeight.w800,
  double maxWidth = _w - 120,
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: 'Nunito',
        fontSize: fontSize,
        fontWeight: weight,
        color: color,
        height: 1.15,
      ),
    ),
    textAlign: TextAlign.center,
    textDirection: TextDirection.ltr,
    maxLines: 2,
  )..layout(minWidth: maxWidth, maxWidth: maxWidth);
  painter.paint(canvas, Offset((_w - maxWidth) / 2, y));
}

Future<void> _composePromo(_Promo promo, String outPath) async {
  final shot = await _loadImage('$_shotsDir\\${promo.file}');

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  _drawCosmicBg(canvas, const Size(_w, _h), promo.accent);

  _drawText(canvas, promo.title, 96, 72, Colors.white);
  _drawText(
    canvas,
    promo.subtitle,
    200,
    32,
    Colors.white.withValues(alpha: 0.65),
    weight: FontWeight.w600,
  );

  // Screenshot in a rounded, glowing frame. Crop the OS status bar and
  // gesture bar off the raw capture.
  const srcCropTop = 110.0;
  const srcCropBottom = 58.0; // just the gesture pill — keep the nav labels
  final src = Rect.fromLTWH(
    0,
    srcCropTop,
    shot.width.toDouble(),
    shot.height.toDouble() - srcCropTop - srcCropBottom,
  );
  const dstW = 800.0;
  final dstH = dstW * src.height / src.width;
  final dst = Rect.fromLTWH((_w - dstW) / 2, 300, dstW, dstH);
  final rrect = RRect.fromRectAndRadius(dst, const Radius.circular(44));

  canvas.drawRRect(
    rrect.inflate(6),
    Paint()
      ..color = promo.accent.withValues(alpha: 0.55)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40),
  );
  canvas.save();
  canvas.clipRRect(rrect);
  canvas.drawImageRect(shot, src, dst, Paint());
  canvas.restore();
  canvas.drawRRect(
    rrect,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..color = promo.accent,
  );

  final image = await recorder.endRecording().toImage(_w.toInt(), _h.toInt());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  await File(outPath).writeAsBytes(bytes!.buffer.asUint8List());
}

Future<void> _composeFeatureGraphic(String outPath) async {
  const w = 1024.0, h = 500.0;
  final icon = await _loadImage('assets/icon/app_icon_foreground.png');

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  _drawCosmicBg(canvas, const Size(w, h), const Color(0xFF8B5CF6));

  // Icon art on the left.
  const iconSize = 460.0;
  canvas.drawImageRect(
    icon,
    Rect.fromLTWH(0, 0, icon.width.toDouble(), icon.height.toDouble()),
    const Rect.fromLTWH(10, (h - iconSize) / 2, iconSize, iconSize),
    Paint(),
  );

  // Wordmark + tagline on the right.
  final title = TextPainter(
    text: const TextSpan(
      text: 'CraftAI',
      style: TextStyle(
        fontFamily: 'Nunito',
        fontSize: 110,
        fontWeight: FontWeight.w800,
        color: Colors.white,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  title.paint(canvas, const Offset(470, 140));

  final tagline = TextPainter(
    text: TextSpan(
      text: 'Yapay zekâ ile sonsuz\nkeşif oyunu',
      style: TextStyle(
        fontFamily: 'Nunito',
        fontSize: 40,
        fontWeight: FontWeight.w600,
        color: Colors.white.withValues(alpha: 0.75),
        height: 1.25,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  tagline.paint(canvas, const Offset(474, 272));

  final image = await recorder.endRecording().toImage(w.toInt(), h.toInt());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  await File(outPath).writeAsBytes(bytes!.buffer.asUint8List());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generate store assets', () async {
    final fontData = File(
      'assets/fonts/Nunito-ExtraBold.ttf',
    ).readAsBytesSync();
    final semi = File('assets/fonts/Nunito-SemiBold.ttf').readAsBytesSync();
    final loader = FontLoader('Nunito')
      ..addFont(Future.value(ByteData.view(fontData.buffer)))
      ..addFont(Future.value(ByteData.view(semi.buffer)));
    await loader.load();

    await Directory(_outDir).create(recursive: true);

    for (var i = 0; i < _promos.length; i++) {
      await _composePromo(_promos[i], '$_outDir/screenshot_${i + 1}.png');
    }
    await _composeFeatureGraphic('$_outDir/feature_graphic.png');

    expect(File('$_outDir/screenshot_1.png').existsSync(), isTrue);
  });
}

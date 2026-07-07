// One-off generator for the game's $0-cost sound effects.
//
// Synthesizes a handful of short sine-wave based WAV files (no external
// assets / licensing needed) into assets/sounds/. Run with:
//   dart run tool/generate_sounds.dart
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

const int sampleRate = 44100;

void main() {
  final dir = Directory('assets/sounds');
  if (!dir.existsSync()) dir.createSync(recursive: true);

  // Short, snappy "pop" for placing/combining elements.
  _write('${dir.path}/pop.wav', _tone(frequency: 700, durationMs: 90, decay: 14));

  // Cheerful ascending arpeggio for a first-ever discovery.
  _write(
    '${dir.path}/discovery.wav',
    _concat([
      _tone(frequency: 523.25, durationMs: 110, decay: 8), // C5
      _tone(frequency: 659.25, durationMs: 110, decay: 8), // E5
      _tone(frequency: 783.99, durationMs: 180, decay: 6), // G5
    ]),
  );

  // Low, gentle "no combination" buzz.
  _write('${dir.path}/error.wav', _tone(frequency: 180, durationMs: 220, decay: 5));

  stdout.writeln('Wrote pop.wav, discovery.wav, error.wav to ${dir.path}');
}

/// Generates a single sine tone with an exponential decay envelope so it
/// doesn't click at the start/end.
Float64List _tone({required double frequency, required int durationMs, required double decay}) {
  final sampleCount = (sampleRate * durationMs / 1000).round();
  final samples = Float64List(sampleCount);
  for (var i = 0; i < sampleCount; i++) {
    final t = i / sampleRate;
    final envelope = exp(-decay * t);
    samples[i] = sin(2 * pi * frequency * t) * envelope;
  }
  return samples;
}

Float64List _concat(List<Float64List> parts) {
  final total = parts.fold<int>(0, (sum, p) => sum + p.length);
  final result = Float64List(total);
  var offset = 0;
  for (final part in parts) {
    result.setRange(offset, offset + part.length, part);
    offset += part.length;
  }
  return result;
}

void _write(String path, Float64List samples) {
  final pcm = Int16List(samples.length);
  for (var i = 0; i < samples.length; i++) {
    pcm[i] = (samples[i].clamp(-1.0, 1.0) * 32767).round();
  }

  final dataBytes = pcm.buffer.asUint8List();
  final byteRate = sampleRate * 2; // mono, 16-bit
  final header = BytesBuilder();

  void writeString(String s) => header.add(s.codeUnits);
  void writeUint32(int v) => header.add([v & 0xFF, (v >> 8) & 0xFF, (v >> 16) & 0xFF, (v >> 24) & 0xFF]);
  void writeUint16(int v) => header.add([v & 0xFF, (v >> 8) & 0xFF]);

  writeString('RIFF');
  writeUint32(36 + dataBytes.length);
  writeString('WAVE');
  writeString('fmt ');
  writeUint32(16); // fmt chunk size
  writeUint16(1); // PCM
  writeUint16(1); // mono
  writeUint32(sampleRate);
  writeUint32(byteRate);
  writeUint16(2); // block align
  writeUint16(16); // bits per sample
  writeString('data');
  writeUint32(dataBytes.length);

  final file = File(path);
  final out = BytesBuilder();
  out.add(header.toBytes());
  out.add(dataBytes);
  file.writeAsBytesSync(out.toBytes());
}

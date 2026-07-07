import 'package:audioplayers/audioplayers.dart';

import '../game_settings.dart';

/// Tiny, $0-cost sound effects for game feedback. All clips live in
/// assets/sounds/ and were synthesized locally (no licensing concerns).
class SoundService {
  final AudioPlayer _player = AudioPlayer();

  Future<void> _play(String asset) async {
    if (!GameSettings.soundEnabled) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/$asset'));
    } catch (_) {
      // Sound is purely cosmetic - never let it crash the game.
    }
  }

  /// Played when two elements are combined successfully.
  Future<void> playPop() => _play('pop.wav');

  /// Played when a brand-new element is discovered for the first time.
  Future<void> playDiscovery() => _play('discovery.wav');

  /// Played when a combination has no result.
  Future<void> playError() => _play('error.wav');

  void dispose() => _player.dispose();
}

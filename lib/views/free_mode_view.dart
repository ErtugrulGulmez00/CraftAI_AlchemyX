import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_constants.dart';
import '../core/services/combination_service.dart';
import '../core/services/local_storage_service.dart';
import '../core/services/sound_service.dart';
import '../core/services/supabase_service.dart';
import '../providers/game_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/cosmic_background.dart';
import 'game_screen.dart';

/// Space Mode's "Ana Oyun": a single always-on save slot, so tapping into
/// it goes straight to gameplay — no world-picker screen in between. Briefly
/// shows a loading spinner while the local save is opened (near-instant,
/// since it's just a Hive box read).
class FreeModeView extends StatefulWidget {
  const FreeModeView({super.key, required this.remote});

  final SupabaseService remote;

  @override
  State<FreeModeView> createState() => _FreeModeViewState();
}

class _FreeModeViewState extends State<FreeModeView> {
  static const _accent = Color(0xFF4FD1E8);

  GameProvider? _game;
  late final String _fullSessionId;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final language = context.read<SettingsProvider>().language;
    final sessionId = AppConstants.sessionIds.first;
    _fullSessionId = AppConstants.sessionKey(sessionId, language);

    final localStorage = LocalStorageService();
    await localStorage.init(
      _fullSessionId,
      startingElements: AppConstants.startingElementsFor(language),
    );
    if (!mounted) return;

    setState(() {
      _game = GameProvider(
        localStorage,
        CombinationService(localStorage, widget.remote, _fullSessionId),
        SoundService(),
        sessionId,
        language: language,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = _game;
    if (game == null) {
      return const Scaffold(
        body: CosmicBackground(
          accent: _accent,
          child: Center(child: CircularProgressIndicator(color: _accent)),
        ),
      );
    }
    return ChangeNotifierProvider.value(
      value: game,
      child: GameScreen(fullSessionId: _fullSessionId),
    );
  }
}

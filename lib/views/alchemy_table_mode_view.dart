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
import 'alchemy_table_game_screen.dart';

/// Alchemy Table's "Ana Oyun": single dedicated save slot, so tapping into
/// it goes straight to gameplay — no info/lobby screen in between. Briefly
/// shows a loading spinner while the local save is opened (near-instant,
/// since it's just a Hive box read).
class AlchemyTableModeView extends StatefulWidget {
  const AlchemyTableModeView({super.key, required this.remote});

  final SupabaseService remote;

  @override
  State<AlchemyTableModeView> createState() => _AlchemyTableModeViewState();
}

class _AlchemyTableModeViewState extends State<AlchemyTableModeView> {
  static const _accent = Color(0xFFFFA53D);

  GameProvider? _game;
  late final String _sessionId;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final language = context.read<SettingsProvider>().language;
    _sessionId = AppConstants.sessionKey('alchemytable', language);

    final localStorage = LocalStorageService();
    await localStorage.init(
      _sessionId,
      startingElements: AppConstants.startingElementsFor(language),
    );
    if (!mounted) return;

    setState(() {
      _game = GameProvider(
        localStorage,
        CombinationService(localStorage, widget.remote, _sessionId),
        SoundService(),
        _sessionId,
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
      child: AlchemyTableGameScreen(fullSessionId: _sessionId),
    );
  }
}

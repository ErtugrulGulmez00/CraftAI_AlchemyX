import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_constants.dart';
import '../core/localization/app_strings.dart';
import '../core/services/combination_service.dart';
import '../core/services/local_storage_service.dart';
import '../core/services/sound_service.dart';
import '../core/services/supabase_service.dart';
import '../providers/game_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/cosmic_background.dart';
import 'target_mode_game_screen.dart';

/// Target Mode: the player picks a word at the start and plays until they
/// discover an element with that exact name. Tinted amber when reached from
/// Alchemy Table, cyan when reached from Space Mode, matching whichever
/// mechanic it will use.
class TargetModeView extends StatefulWidget {
  const TargetModeView({
    super.key,
    required this.remote,
    required this.useTubeMechanic,
  });

  final SupabaseService remote;
  final bool useTubeMechanic;

  @override
  State<TargetModeView> createState() => _TargetModeViewState();
}

class _TargetModeViewState extends State<TargetModeView> {
  final _controller = TextEditingController();

  static const _alchemyAccent = Color(0xFFFFA53D);
  static const _spaceAccent = Color(0xFF4FD1E8);

  Color get _accent => widget.useTubeMechanic ? _alchemyAccent : _spaceAccent;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final word = _controller.text.trim().toLowerCase();
    if (word.isEmpty) return;

    final language = context.read<SettingsProvider>().language;
    final sessionId = AppConstants.sessionKey('target', language);

    final localStorage = LocalStorageService();
    await localStorage.init(
      sessionId,
      startingElements: AppConstants.startingElementsFor(language),
    );
    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => GameProvider(
            localStorage,
            CombinationService(localStorage, widget.remote, sessionId),
            SoundService(),
            sessionId,
            language: language,
            targetWord: word,
          ),
          child: TargetModeGameScreen(useTubeMechanic: widget.useTubeMechanic),
        ),
      ),
    );

    if (!mounted) return;
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context.watch<SettingsProvider>().language);
    final accent = _accent;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text(t.targetModeTitle),
      ),
      body: CosmicBackground(
        accent: accent,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [accent, accent.withValues(alpha: 0.7)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.5),
                        blurRadius: 22,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Text('🎯', style: TextStyle(fontSize: 34)),
                ),
                const SizedBox(height: 20),
                Text(
                  t.targetModeQuestion,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  t.targetModeDescription,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _controller,
                  textCapitalization: TextCapitalization.words,
                  onSubmitted: (_) => _start(),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: t.targetModeHint,
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                    filled: true,
                    fillColor: const Color(0xFF15111F),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: accent, width: 1.6),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _start,
                    child: Text(
                      t.start,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

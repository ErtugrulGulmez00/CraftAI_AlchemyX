import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_constants.dart';
import '../core/constants/game_language.dart';
import '../core/constants/word_bank.dart';
import '../core/localization/app_strings.dart';
import '../core/services/combination_service.dart';
import '../core/services/local_storage_service.dart';
import '../core/services/sound_service.dart';
import '../core/services/supabase_service.dart';
import '../providers/auth_provider.dart';
import '../providers/game_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/cosmic_background.dart';
import '../widgets/leaderboard_list.dart';
import 'challenge_game_screen.dart';

/// Global Hive box recording each day's completion time.
const String challengeStateBox = 'challenge_state';

/// Key inside [challengeStateBox]: date + language + account, so switching
/// Google accounts (or languages) doesn't inherit another run's completion.
/// Guests share a single 'guest' namespace.
String challengeCompletionKey(
  String todayKey,
  GameLanguage language,
  String? userId,
) => '${todayKey}_${language.code}_${userId ?? 'guest'}';

/// Challenge Mode: everyone gets the same word on the same UTC day, races
/// against the clock to discover it, and (if signed in) appears on that
/// day's leaderboard. Tinted amber when reached from Alchemy Table, cyan
/// when reached from Space Mode, matching whichever mechanic it will use.
class ChallengeModeView extends StatefulWidget {
  const ChallengeModeView({
    super.key,
    required this.remote,
    required this.useTubeMechanic,
  });

  final SupabaseService remote;
  final bool useTubeMechanic;

  @override
  State<ChallengeModeView> createState() => _ChallengeModeViewState();
}

class _ChallengeModeViewState extends State<ChallengeModeView> {
  static const _alchemyAccent = Color(0xFFFFA53D);
  static const _spaceAccent = Color(0xFF4FD1E8);

  late final String _todayKey = todayDateKey();
  late final GameLanguage _language;
  late final String _word;
  int? _completedSeconds;

  Color get _accent => widget.useTubeMechanic ? _alchemyAccent : _spaceAccent;

  @override
  void initState() {
    super.initState();
    _language = context.read<SettingsProvider>().language;
    _word = todaysChallengeWord(_language);
    _loadCompletion();
  }

  String? _lastCompletionKey;

  /// Completion is namespaced per account (and language), so switching
  /// Google accounts on the same device gives each account its own fresh
  /// daily run instead of inheriting the previous account's "completed".
  String _completionKey(AuthProvider auth) =>
      challengeCompletionKey(_todayKey, _language, auth.userId);

  Future<void> _loadCompletion() async {
    final auth = context.read<AuthProvider>();
    final key = _completionKey(auth);
    _lastCompletionKey = key;
    final box = await Hive.openBox(challengeStateBox);
    if (!mounted) return;
    setState(() => _completedSeconds = box.get(key) as int?);
  }

  Future<void> _start() async {
    final localStorage = LocalStorageService();
    final sessionId = AppConstants.sessionKey(
      'challenge_$_todayKey',
      _language,
    );
    // Always start from a clean slate so a previous (unfinished) attempt's
    // discoveries can't be reused to fake a faster time.
    await LocalStorageService.resetSession(sessionId);
    await localStorage.init(
      sessionId,
      startingElements: AppConstants.startingElementsFor(_language),
    );

    // Register the official (server-clock) start of today's run — the
    // leaderboard time is computed from this on the server, and only the
    // first start of the day counts.
    await widget.remote.startChallengeRun(date: _todayKey, language: _language);
    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => GameProvider(
            localStorage,
            CombinationService(localStorage, widget.remote, sessionId),
            SoundService(),
            sessionId,
            language: _language,
            targetWord: _word.toLowerCase(),
          ),
          child: ChallengeGameScreen(
            startTime: DateTime.now(),
            todayKey: _todayKey,
            word: _word,
            remote: widget.remote,
            useTubeMechanic: widget.useTubeMechanic,
          ),
        ),
      ),
    );

    _loadCompletion();
  }

  String _formatSeconds(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final t = AppStrings.of(_language);
    final completed = _completedSeconds;
    final accent = _accent;

    // Account switched while this screen is alive (sign-in/out happens via
    // the banner below) → re-read the new account's own completion state.
    if (_lastCompletionKey != null &&
        _lastCompletionKey != _completionKey(auth)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadCompletion();
      });
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text(t.challengeModeTitle),
      ),
      body: CosmicBackground(
        accent: accent,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
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
                child: const Text('🏆', style: TextStyle(fontSize: 34)),
              ),
              const SizedBox(height: 20),
              if (!auth.isSignedIn)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF15111F),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: accent.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    children: [
                      const Text('🏆', style: TextStyle(fontSize: 22)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          t.signInForLeaderboard,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: auth.signInWithGoogle,
                        child: Text(t.signIn, style: TextStyle(color: accent)),
                      ),
                    ],
                  ),
                ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF15111F),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: accent.withValues(alpha: 0.75)),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.28),
                      blurRadius: 22,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.todaysChallenge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _todayKey,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '🎯 $_word',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: accent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (completed == null)
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
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          t.completedIn(_formatSeconds(completed)),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Colors.greenAccent,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Leaderboard is always visible — seeing today's times (or an
              // empty board begging to be claimed) is the motivation to play.
              const SizedBox(height: 24),
              Text(
                t.leaderboard,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              LeaderboardList(
                date: _todayKey,
                language: _language,
                remote: widget.remote,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

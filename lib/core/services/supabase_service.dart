import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/element_model.dart';
import '../constants/app_constants.dart';
import '../constants/game_language.dart';
import '../utils/combination_key.dart';

/// Thrown when two elements have no sensible combination - the LLM (or a
/// cached prior LLM answer) explicitly said "these don't combine".
class NoCombinationException implements Exception {
  const NoCombinationException();

  @override
  String toString() => 'These elements do not combine';
}

/// Stage 2 & 3 of the craft pipeline: the global Supabase database and,
/// when nothing is found, the LLM-backed Edge Function that invents a
/// brand new element.
class SupabaseService {
  SupabaseClient get _client => Supabase.instance.client;

  /// True only for a real Google account, not the anonymous session every
  /// player gets on first launch — mirrors [AuthProvider.isSignedIn].
  bool get _isRealUser => _client.auth.currentUser?.isAnonymous == false;

  static Future<void> init() async {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      // ignore: deprecated_member_use
      anonKey: AppConstants.supabaseAnonKey,
    );

    // Every player gets an anonymous account so combinations can be
    // attributed via `discovered_by` without requiring sign-up.
    // Silently skip if offline — the app still works with local cache.
    final client = Supabase.instance.client;
    if (client.auth.currentSession == null) {
      try {
        await client.auth.signInAnonymously();
      } catch (_) {}
    }

    // Pre-warm the PostgREST HTTP connection so the first combination
    // lookup doesn't pay the TCP + TLS handshake cost mid-game.
    try {
      await client
          .from(AppConstants.combinationsTable)
          .select('pair_key')
          .limit(1);
    } catch (_) {}
  }

  /// Returns the Supabase table name for [language].
  String _tableFor(GameLanguage language) => switch (language) {
    GameLanguage.turkishV2 => AppConstants.combinationsTableTr2,
    GameLanguage.german => AppConstants.combinationsTableDe,
    GameLanguage.spanish => AppConstants.combinationsTableEs,
    GameLanguage.portuguese => AppConstants.combinationsTablePt,
    _ => AppConstants.combinationsTable,
  };

  /// Stage 2: looks up a combination that some player in the world has
  /// already discovered.
  ///
  /// Throws [NoCombinationException] if this pair was previously checked
  /// and found to have no sensible combination. Returns `null` if the
  /// pair has never been looked up before (caller should try stage 3).
  Future<GameElement?> findCombination(
    String a,
    String b,
    GameLanguage language,
  ) async {
    final row = await _client
        .from(_tableFor(language))
        .select()
        .eq('pair_key', combinationKey(a, b, language))
        .maybeSingle();

    if (row == null) return null;

    if (row['no_combination'] == true) {
      throw const NoCombinationException();
    }

    return GameElement(
      name: row['result_name'] as String,
      emoji: _sanitizeEmoji(row['result_emoji'] as String),
      isFirstDiscovery: false,
    );
  }

  /// The LLM occasionally returns a plain word (in any script) instead of
  /// an emoji for the `emoji` field. Such strings blow up the fixed-size
  /// emoji badges in the UI, so require at least one actual pictographic
  /// character and a sane length, falling back to a placeholder otherwise.
  String _sanitizeEmoji(String value) {
    final trimmed = value.trim();
    // Emoji live in the misc-symbols (U+2600–U+2BFF) and supplementary
    // pictograph (U+1F000+) blocks; plain words in any script don't.
    final hasPictograph = trimmed.runes.any(
      (r) => r >= 0x1F000 || (r >= 0x2600 && r <= 0x2BFF),
    );
    if (trimmed.isEmpty || !hasPictograph || trimmed.length > 16) {
      return '❔';
    }
    return trimmed;
  }

  /// Stage 3: asks the Edge Function for a brand new combination. Since
  /// the v2 hardening, the function does ALL the writing itself (with the
  /// service role) — the client just receives the canonical stored result,
  /// so a tampered client can no longer poison the shared tables.
  ///
  /// Throws [NoCombinationException] if the LLM decides these two elements
  /// have no sensible combination (the server records that verdict too).
  Future<GameElement> craftNewCombination(
    String a,
    String b,
    GameLanguage language,
  ) async {
    final response = await _client.functions.invoke(
      AppConstants.craftEdgeFunction,
      body: {'elementA': a, 'elementB': b, 'language': language.code},
    );

    final data = response.data as Map<String, dynamic>;

    if (data['name'] == null) {
      throw const NoCombinationException();
    }

    return GameElement(
      name: data['name'] as String,
      emoji: _sanitizeEmoji(data['emoji'] as String),
      isFirstDiscovery: data['isFirstDiscovery'] == true,
    );
  }

  /// Registers the start of today's challenge run on the server. The
  /// server's clock is what the leaderboard time is computed from (see
  /// challenge_server_timing.sql) — the first start of the day wins, so
  /// re-entering the screen doesn't reset the clock. Best-effort/no-op for
  /// guests and repeat calls.
  Future<void> startChallengeRun({
    required String date,
    required GameLanguage language,
  }) async {
    if (!_isRealUser) return;
    try {
      await _client.from('challenge_runs').insert({
        'user_id': _client.auth.currentUser!.id,
        'challenge_date': date,
        'language': language.code,
      });
    } catch (_) {
      // Already started today (PK conflict) or offline — nothing to do.
    }
  }

  /// Tells the server the challenge is complete; it computes the elapsed
  /// seconds from its own clocks and writes the leaderboard row itself
  /// (clients can no longer submit arbitrary times/names). Returns the
  /// recorded seconds, or null if it couldn't be recorded.
  Future<int?> finishChallenge({
    required String date,
    required GameLanguage language,
  }) async {
    if (!_isRealUser) return null;
    try {
      final result = await _client.rpc(
        'finish_challenge',
        params: {'p_date': date, 'p_language': language.code},
      );
      return result as int?;
    } catch (_) {
      return null;
    }
  }

  /// Returns the Challenge Mode leaderboard for [date] and [language],
  /// fastest first.
  Future<List<Map<String, dynamic>>> fetchLeaderboard(
    String date,
    GameLanguage language,
  ) async {
    final rows = await _client
        .from(AppConstants.challengeResultsTable)
        .select()
        .eq('challenge_date', date)
        .eq('language', language.code)
        .order('seconds');

    return List<Map<String, dynamic>>.from(rows);
  }

  /// Submits an "A + B = C" community suggestion (English or Turkish) for
  /// the current (real, signed-in) user.
  Future<void> submitCombinationSuggestion({
    required String elementA,
    required String elementB,
    required String suggestedName,
    required String suggestedEmoji,
    required String suggestedByName,
    required GameLanguage language,
  }) async {
    await _client.from(AppConstants.combinationSuggestionsTable).insert({
      'element_a': elementA.trim(),
      'element_b': elementB.trim(),
      'suggested_name': suggestedName.trim(),
      'suggested_emoji': suggestedEmoji.trim(),
      'suggested_by': _client.auth.currentUser!.id,
      'suggested_by_name': suggestedByName,
      'language': language.code,
    });
  }

  /// Returns the current user's own suggestions, newest first.
  Future<List<Map<String, dynamic>>> fetchOwnSuggestions() async {
    final rows = await _client
        .from(AppConstants.combinationSuggestionsTable)
        .select()
        .eq('suggested_by', _client.auth.currentUser!.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(rows);
  }

  /// Admin-only: returns all pending suggestions, oldest first.
  Future<List<Map<String, dynamic>>> fetchPendingSuggestions() async {
    final rows = await _client
        .from(AppConstants.combinationSuggestionsTable)
        .select()
        .eq('status', 'pending')
        .order('created_at');

    return List<Map<String, dynamic>>.from(rows);
  }

  /// Admin-only: approves [suggestion], overriding the result for that pair
  /// in the combinations table for the suggestion's own language (English
  /// or Turkish/`v2_combinations`) and marking the suggestion as approved.
  Future<void> approveSuggestion(Map<String, dynamic> suggestion) async {
    final elementA = suggestion['element_a'] as String;
    final elementB = suggestion['element_b'] as String;
    final language = GameLanguage.fromCode(suggestion['language'] as String);
    final pairKey = combinationKey(elementA, elementB, language);

    await _client.from(_tableFor(language)).upsert({
      'pair_key': pairKey,
      'element_a': elementA.toLowerCase().trim(),
      'element_b': elementB.toLowerCase().trim(),
      'result_name': suggestion['suggested_name'],
      'result_emoji': suggestion['suggested_emoji'],
      'is_first_discovery': false,
      'no_combination': false,
      'discovered_by': _client.auth.currentUser!.id,
    }, onConflict: 'pair_key');

    await _client
        .from(AppConstants.combinationSuggestionsTable)
        .update({'status': 'approved'})
        .eq('id', suggestion['id']);
  }

  /// Admin-only: marks suggestion [id] as rejected.
  Future<void> rejectSuggestion(String id) async {
    await _client
        .from(AppConstants.combinationSuggestionsTable)
        .update({'status': 'rejected'})
        .eq('id', id);
  }

  /// Best-effort cloud backup of a newly-discovered element, so a real
  /// (signed-in) player's progress survives a reinstall / new device.
  /// No-ops for guests/anonymous sessions, and silently swallows failures —
  /// this must never interrupt the combine flow.
  Future<void> upsertProgress({
    required String sessionId,
    required GameElement element,
  }) async {
    if (!_isRealUser) return;
    try {
      await _client.from(AppConstants.userProgressTable).upsert({
        'user_id': _client.auth.currentUser!.id,
        'session_id': sessionId,
        'element_key': element.key,
        'element_name': element.name,
        'element_emoji': element.emoji,
      }, onConflict: 'user_id,session_id,element_key');
    } catch (_) {}
  }

  /// Deletes the cloud backup rows for [sessionId] (or every session when
  /// null) so a locally-reset world doesn't resurrect on the next sign-in.
  /// Best-effort, guests no-op.
  Future<void> deleteProgress({String? sessionId}) async {
    if (!_isRealUser) return;
    try {
      var query = _client
          .from(AppConstants.userProgressTable)
          .delete()
          .eq('user_id', _client.auth.currentUser!.id);
      if (sessionId != null) {
        query = query.eq('session_id', sessionId);
      }
      await query;
    } catch (_) {}
  }

  /// Permanently deletes the signed-in user's account and every personal
  /// row (progress backup, challenge times, suggestions) via the
  /// `delete-account` edge function. Throws on failure so the UI can tell
  /// the user it didn't happen.
  Future<void> deleteAccount() async {
    final response = await _client.functions.invoke('delete-account');
    final data = response.data;
    if (data is! Map || data['ok'] != true) {
      throw Exception('Account deletion failed: $data');
    }
  }

  /// Every element the current (real, signed-in) user has backed up,
  /// grouped by the local session id it belongs to — used to restore
  /// progress on a new device/reinstall. Returns an empty map for
  /// guests/anonymous sessions or on failure.
  Future<Map<String, List<GameElement>>> fetchAllProgressGrouped() async {
    if (!_isRealUser) return {};
    try {
      final rows = await _client
          .from(AppConstants.userProgressTable)
          .select()
          .eq('user_id', _client.auth.currentUser!.id);

      final grouped = <String, List<GameElement>>{};
      for (final row in rows) {
        grouped
            .putIfAbsent(row['session_id'] as String, () => [])
            .add(
              GameElement(
                name: row['element_name'] as String,
                emoji: row['element_emoji'] as String,
              ),
            );
      }
      return grouped;
    } catch (_) {
      return {};
    }
  }
}

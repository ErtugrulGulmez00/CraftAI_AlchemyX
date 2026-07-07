import 'dart:async';

import '../../models/element_model.dart';
import '../constants/game_language.dart';
import 'daily_quest_service.dart';
import 'local_storage_service.dart';
import 'supabase_service.dart';

/// Orchestrates the 3-stage, $0-cost lookup chain described in the
/// project brief:
///   1. Local Hive cache (instant, offline)
///   2. Supabase `combinations` table (shared, world-discovered)
///   3. LLM via Supabase Edge Function (first-ever discovery)
class CombinationService {
  CombinationService(this._local, this._remote, this.sessionId);

  final LocalStorageService _local;
  final SupabaseService _remote;

  /// The local save-slot this service is bound to — used to attribute any
  /// newly-discovered element to the right cloud backup row (see
  /// [SupabaseService.upsertProgress]).
  final String sessionId;

  Future<GameElement> combine(
    GameElement a,
    GameElement b,
    GameLanguage language,
  ) async {
    unawaited(DailyQuestService.recordCombine());

    // Stage 1: local cache.
    final cachedKey = _local.getCachedCombination(a.name, b.name, language);
    if (cachedKey != null) {
      final cached = _local.getElementByKey(cachedKey);
      if (cached != null) return cached;
    }

    // Stage 2: global Supabase database.
    final globalResult = await _withRetry(
      () => _remote.findCombination(a.name, b.name, language),
    );
    if (globalResult != null) {
      await _persistResult(a, b, globalResult, language);
      return globalResult;
    }

    // Stage 3: first-ever discovery via LLM.
    final newResult = await _withRetry(
      () => _remote.craftNewCombination(a.name, b.name, language),
    );
    await _persistResult(a, b, newResult, language);
    return newResult;
  }

  /// Retries transient network/server failures (the Edge Function's LLM
  /// upstreams occasionally 500/502, and mobile connections drop) before
  /// surfacing an error. A definitive "these don't combine" answer is a
  /// real result, never a failure — it passes straight through.
  Future<T> _withRetry<T>(Future<T> Function() action) async {
    const maxAttempts = 3;
    for (var attempt = 1; ; attempt++) {
      try {
        return await action();
      } on NoCombinationException {
        rethrow;
      } catch (_) {
        if (attempt >= maxAttempts) rethrow;
        await Future.delayed(Duration(milliseconds: 400 * attempt));
      }
    }
  }

  Future<void> _persistResult(
    GameElement a,
    GameElement b,
    GameElement result,
    GameLanguage language,
  ) async {
    // A "new discovery" for daily quests means new to this device, not
    // just new to this pair — stage 2 often returns elements the player
    // already owns via a different recipe.
    if (!_local.hasElement(result.name)) {
      unawaited(DailyQuestService.recordDiscovery());
    }

    // Persist a normalized (non-"first discovery") copy: the
    // isFirstDiscovery flag is a one-time celebration for the call that
    // just discovered it, not a permanent property of the element. This
    // ensures replaying the same combination later doesn't re-trigger the
    // "first discovery in the world" celebration.
    final saved = GameElement(name: result.name, emoji: result.emoji);
    await _local.saveElement(saved);
    await _local.cacheCombination(a.name, b.name, result.key, language);
    // Fire-and-forget: never let a cloud backup failure block gameplay.
    unawaited(_remote.upsertProgress(sessionId: sessionId, element: saved));
  }
}

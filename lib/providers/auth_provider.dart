import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants/app_constants.dart';
import '../core/services/local_storage_service.dart';
import '../core/services/supabase_service.dart';

/// Tracks whether the current Supabase session belongs to a real
/// (Google-signed-in) user or just the automatic anonymous session that
/// every player gets on first launch.
class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    Supabase.instance.client.auth.onAuthStateChange.listen((state) {
      notifyListeners();

      // Once per real sign-in, pull the player's cloud-backed progress
      // (see SupabaseService.upsertProgress) into any local sessions —
      // additive only, never overwrites/removes anything, so this is
      // always safe to run silently in the background.
      final user = state.session?.user;
      if (state.event == AuthChangeEvent.signedIn &&
          user != null &&
          user.isAnonymous == false &&
          _restoredForUserId != user.id) {
        _restoredForUserId = user.id;
        _restoreCloudProgress();
      }
    });
  }

  String? _restoredForUserId;

  Future<void> _restoreCloudProgress() async {
    try {
      final grouped = await SupabaseService().fetchAllProgressGrouped();
      for (final entry in grouped.entries) {
        await LocalStorageService.mergeElementsIntoSession(
          entry.key,
          entry.value,
        );
      }
    } catch (_) {}
  }

  SupabaseClient get _client => Supabase.instance.client;

  User? get _user => _client.auth.currentUser;

  /// True only for a real Google account, not the anonymous session.
  bool get isSignedIn => _user != null && _user!.isAnonymous == false;

  /// The real (non-anonymous) account's id, or null for guests — used to
  /// namespace per-account local state like daily-challenge completion.
  String? get userId => isSignedIn ? _user!.id : null;

  /// True only for the app's admin account (see [AppConstants.adminUserId]).
  bool get isAdmin => _user?.id == AppConstants.adminUserId;

  /// Best-effort display name for the leaderboard.
  String get displayName {
    final meta = _user?.userMetadata;
    final name = meta?['full_name'] ?? meta?['name'] ?? _user?.email;
    return (name as String?) ?? 'Player';
  }

  Future<void> signInWithGoogle() {
    return _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: AppConstants.oauthRedirectUrl,
    );
  }

  Future<void> signOut() async {
    // Tolerate a failed sign-out: after account deletion the server has
    // already invalidated this session, and rejecting that call must not
    // prevent falling back to a fresh anonymous session below.
    try {
      await _client.auth.signOut();
    } catch (_) {}
    // Restore an anonymous session so gameplay (combination lookups,
    // rate-limit identity) keeps working.
    try {
      await _client.auth.signInAnonymously();
    } catch (_) {}
  }
}

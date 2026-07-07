import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/localization/app_strings.dart';
import '../core/services/local_storage_service.dart';
import '../core/services/supabase_service.dart';
import '../core/theme/app_theme.dart';
import '../providers/game_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/alchemy_table_body.dart';
import 'discoveries_view.dart';

/// Alchemy Table mode — a mystical 2.5D perspective lab scene.
class AlchemyTableGameScreen extends StatelessWidget {
  const AlchemyTableGameScreen({super.key, required this.fullSessionId});

  /// The exact (language-suffixed) local save key — needed only to support
  /// resetting this world from within the game itself.
  final String fullSessionId;

  Future<void> _confirmAndReset(BuildContext context, AppStringsData t) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(t.startNewWorldTitle),
        content: Text(t.eraseWorldConfirm(fullSessionId)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(t.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(t.reset),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await LocalStorageService.resetSession(fullSessionId);
    // Also drop this world's cloud backup rows, otherwise the next
    // sign-in would silently restore everything just erased.
    await SupabaseService().deleteProgress(sessionId: fullSessionId);
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final colors = AppColors.of(context);
    final t = AppStrings.of(context.watch<SettingsProvider>().language);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.alchemyTableModeTitle),
        actions: [
          _CounterPill(count: game.discoveredElements.length, colors: colors),
          IconButton(
            icon: const Icon(Icons.travel_explore),
            tooltip: t.discoveries,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChangeNotifierProvider.value(
                  value: game,
                  child: const DiscoveriesView(canAddToCanvas: false),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.restart_alt),
            tooltip: t.resetWorldTooltip,
            onPressed: () => _confirmAndReset(context, t),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: const AlchemyTableBody(),
    );
  }
}

// ── Counter Pill ──────────────────────────────────────────────────────────

class _CounterPill extends StatelessWidget {
  const _CounterPill({required this.count, required this.colors});
  final int count;
  final AppPalette colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          const Text('⚗️', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: colors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/localization/app_strings.dart';
import '../core/services/local_storage_service.dart';
import '../core/services/share_service.dart';
import '../core/services/supabase_service.dart';
import '../core/theme/app_theme.dart';
import '../providers/game_provider.dart' show GameProvider, ElementSortMode;
import '../providers/settings_provider.dart';
import '../widgets/confetti_overlay.dart';
import 'craft_view.dart';
import 'discoveries_view.dart';

/// Full-screen crafting experience for one world. Pushed on top of the
/// global [MainShell] (so the global bottom nav is intentionally hidden
/// while playing — like opening a detail screen).
class GameScreen extends StatelessWidget {
  const GameScreen({super.key, required this.fullSessionId});

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

    if (game.lastFirstDiscovery != null) {
      final discovery = game.lastFirstDiscovery!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              t.firstDiscoveryToast(discovery.emoji, discovery.name),
            ),
            backgroundColor: colors.primaryDark,
            action: SnackBarAction(
              label: t.share,
              textColor: Colors.amber,
              onPressed: () => ShareService.shareDiscovery(
                emoji: discovery.emoji,
                name: discovery.name,
                cardTitle: t.shareCardTitle,
                shareText: t.shareDiscoveryText(discovery.name),
              ),
            ),
          ),
        );
        game.clearFirstDiscoveryFlag();
      });
    }

    if (game.lastError != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(game.lastError!)));
        game.clearError();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(t.worldTitle(game.sessionId)),
        actions: [
          _CounterPill(count: game.discoveredElements.length, colors: colors),
          PopupMenuButton<ElementSortMode>(
            icon: const Icon(Icons.sort),
            tooltip: t.sortTooltip,
            initialValue: game.sortMode,
            onSelected: game.setSortMode,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: ElementSortMode.time,
                child: Text(t.sortByTime),
              ),
              PopupMenuItem(
                value: ElementSortMode.name,
                child: Text(t.sortByName),
              ),
              PopupMenuItem(
                value: ElementSortMode.emoji,
                child: Text(t.sortByEmoji),
              ),
              PopupMenuItem(
                value: ElementSortMode.random,
                child: Text(t.sortByRandom),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.travel_explore),
            tooltip: t.discoveries,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider.value(
                    value: game,
                    child: const DiscoveriesView(canAddToCanvas: true),
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: t.clearTable,
            onPressed: game.clearCanvas,
          ),
          IconButton(
            icon: const Icon(Icons.restart_alt),
            tooltip: t.resetWorldTooltip,
            onPressed: () => _confirmAndReset(context, t),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        children: [
          const CraftView(),
          Positioned.fill(
            child: IgnorePointer(
              child: ConfettiOverlay(trigger: game.lastFirstDiscovery),
            ),
          ),
        ],
      ),
    );
  }
}

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
        color: colors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          const Text('🧪', style: TextStyle(fontSize: 16)),
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

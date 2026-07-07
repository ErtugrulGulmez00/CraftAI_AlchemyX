import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/localization/app_strings.dart';
import '../core/services/share_service.dart';
import '../core/theme/app_theme.dart';
import '../providers/game_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/alchemy_table_body.dart';
import '../widgets/confetti_overlay.dart';
import 'craft_view.dart';
import 'discoveries_view.dart';

/// Full-screen Target Mode session: either the Alchemy Table tube+mortar
/// mechanic or the free-drag canvas (depending on which mode family it was
/// entered from), with a goal banner and a celebration when the target word
/// is found.
class TargetModeGameScreen extends StatelessWidget {
  const TargetModeGameScreen({super.key, required this.useTubeMechanic});

  final bool useTubeMechanic;

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final colors = AppColors.of(context);
    final t = AppStrings.of(context.watch<SettingsProvider>().language);
    final target = game.targetWord ?? '';
    final targetLabel = target.isEmpty
        ? target
        : target[0].toUpperCase() + target.substring(1);

    if (!useTubeMechanic) {
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
    }

    if (game.targetReached) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(t.congratulations),
            content: Text(t.youDiscovered(targetLabel)),
            actions: [
              TextButton(
                onPressed: () {
                  game.clearTargetReached();
                  Navigator.of(context).pop();
                },
                child: Text(t.keepPlaying),
              ),
              FilledButton(
                onPressed: () {
                  game.clearTargetReached();
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: Text(t.newTarget),
              ),
            ],
          ),
        );
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('🎯 $targetLabel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flag_outlined),
            tooltip: t.changeTarget,
            onPressed: () => Navigator.of(context).pop(),
          ),
          IconButton(
            icon: const Icon(Icons.travel_explore),
            tooltip: t.discoveries,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider.value(
                    value: game,
                    child: DiscoveriesView(canAddToCanvas: !useTubeMechanic),
                  ),
                ),
              );
            },
          ),
          if (!useTubeMechanic)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: t.clearTable,
              onPressed: game.clearCanvas,
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: useTubeMechanic
          ? const AlchemyTableBody()
          : Stack(
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

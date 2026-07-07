import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import '../core/localization/app_strings.dart';
import '../core/services/share_service.dart';
import '../core/services/supabase_service.dart';
import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/game_provider.dart';
import '../widgets/alchemy_table_body.dart';
import '../widgets/confetti_overlay.dart';
import 'challenge_mode_view.dart';
import 'craft_view.dart';
import 'discoveries_view.dart';

/// The Challenge Mode game screen: either the Alchemy Table tube+mortar
/// mechanic or the free-drag canvas (depending on which mode family it was
/// entered from). Shows a running timer and, once the daily target word is
/// discovered, records the elapsed time locally and (for real signed-in
/// users) submits it to the leaderboard.
class ChallengeGameScreen extends StatefulWidget {
  const ChallengeGameScreen({
    super.key,
    required this.startTime,
    required this.todayKey,
    required this.word,
    required this.remote,
    required this.useTubeMechanic,
  });

  final DateTime startTime;
  final String todayKey;
  final String word;
  final SupabaseService remote;
  final bool useTubeMechanic;

  @override
  State<ChallengeGameScreen> createState() => _ChallengeGameScreenState();
}

class _ChallengeGameScreenState extends State<ChallengeGameScreen> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsed = DateTime.now().difference(widget.startTime));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _onTargetReached(GameProvider game) async {
    _finished = true;
    _timer?.cancel();
    final elapsed = DateTime.now().difference(widget.startTime);
    setState(() => _elapsed = elapsed);

    final t = AppStrings.of(game.language);
    final auth = context.read<AuthProvider>();

    final box = await Hive.openBox(challengeStateBox);
    await box.put(
      challengeCompletionKey(widget.todayKey, game.language, auth.userId),
      elapsed.inSeconds,
    );

    if (auth.isSignedIn) {
      // The server computes the official time from its own start/finish
      // clocks (see challenge_server_timing.sql) — the local stopwatch is
      // for display only and can't influence the leaderboard.
      await widget.remote.finishChallenge(
        date: widget.todayKey,
        language: game.language,
      );
    }

    if (!mounted) return;
    final wordLabel = widget.word[0].toUpperCase() + widget.word.substring(1);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.congratulations),
        content: Text(t.foundWordIn(wordLabel, _formatDuration(elapsed))),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop();
            },
            child: Text(t.viewLeaderboard),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final colors = AppColors.of(context);
    final t = AppStrings.of(game.language);

    if (!_finished && game.targetReached) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _onTargetReached(game),
      );
    }

    if (!widget.useTubeMechanic) {
      if (game.lastFirstDiscovery != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final element = game.lastFirstDiscovery;
          if (element == null) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(t.firstDiscoverySnack(element.emoji, element.name)),
              action: SnackBarAction(
                label: t.share,
                textColor: Colors.amber,
                onPressed: () => ShareService.shareDiscovery(
                  emoji: element.emoji,
                  name: element.name,
                  cardTitle: t.shareCardTitle,
                  shareText: t.shareDiscoveryText(element.name),
                ),
              ),
            ),
          );
          game.clearFirstDiscoveryFlag();
        });
      }

      if (game.lastError != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final error = game.lastError;
          if (error == null) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error)));
          game.clearError();
        });
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(t.challengeAppBarTitle),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: Text(
              _formatDuration(_elapsed),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: colors.primaryDark,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.travel_explore),
            tooltip: t.discoveries,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider.value(
                    value: game,
                    child: DiscoveriesView(
                      canAddToCanvas: !widget.useTubeMechanic,
                    ),
                  ),
                ),
              );
            },
          ),
          if (!widget.useTubeMechanic)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: t.clearTable,
              onPressed: game.clearCanvas,
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: widget.useTubeMechanic
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

import 'package:flutter/material.dart';

import '../core/constants/game_language.dart';
import '../core/localization/app_strings.dart';
import '../core/services/supabase_service.dart';
import '../core/theme/app_theme.dart';

/// Shows the Challenge Mode leaderboard for a given date and language,
/// fastest time first. Medals for the top 3, plain rank numbers after that.
class LeaderboardList extends StatelessWidget {
  const LeaderboardList({
    super.key,
    required this.date,
    required this.language,
    required this.remote,
  });

  final String date;
  final GameLanguage language;
  final SupabaseService remote;

  String _formatSeconds(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String _medal(int rank) {
    switch (rank) {
      case 0:
        return '🥇';
      case 1:
        return '🥈';
      case 2:
        return '🥉';
      default:
        return '${rank + 1}.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final t = AppStrings.of(language);

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: remote.fetchLeaderboard(date, language),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final rows = snapshot.data ?? const [];

        if (rows.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              t.noLeaderboardYet,
              style: TextStyle(
                color: colors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }

        return Column(
          children: [
            for (var i = 0; i < rows.length; i++)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 36,
                      child: Text(
                        _medal(i),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        rows[i]['display_name'] as String? ?? t.player,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      _formatSeconds(rows[i]['seconds'] as int),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: colors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

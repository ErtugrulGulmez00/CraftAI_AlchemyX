import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_constants.dart';
import '../core/constants/game_language.dart';
import '../core/localization/app_strings.dart';
import '../core/services/daily_quest_service.dart';
import '../core/services/local_storage_service.dart';
import '../core/theme/app_theme.dart';
import '../providers/settings_provider.dart';
import '../widgets/animated_section_widgets.dart';
import '../widgets/cosmic_background.dart';

/// "Stats" tab: a quick at-a-glance dashboard aggregating progress across
/// every world *and every language* on this device (each language is its
/// own parallel save, so a Turkish-only player previously saw nothing here).
class StatsView extends StatefulWidget {
  const StatsView({super.key});

  @override
  State<StatsView> createState() => _StatsViewState();
}

class _StatsViewState extends State<StatsView>
    with SingleTickerProviderStateMixin {
  /// language -> sessionId -> discovered count.
  Map<GameLanguage, Map<String, int>>? _counts;

  /// language -> total world-first discoveries across its worlds.
  Map<GameLanguage, int>? _firstDiscoveries;

  /// Today's (combine attempts, new discoveries) for the daily quests.
  (int, int) _questCounts = (0, 0);

  late final AnimationController _entrance;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _load();
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final counts = <GameLanguage, Map<String, int>>{};
    final firsts = <GameLanguage, int>{};

    for (final lang in GameLanguage.active) {
      final perWorld = <String, int>{};
      var firstTotal = 0;
      for (final id in [
        ...AppConstants.sessionIds,
        ...AppConstants.extraStatSessionIds,
      ]) {
        final sessionId = AppConstants.sessionKey(id, lang);
        perWorld[id] = await LocalStorageService.getElementCount(sessionId);
        firstTotal += await LocalStorageService.getFirstDiscoveryCount(
          sessionId,
        );
      }
      counts[lang] = perWorld;
      firsts[lang] = firstTotal;
    }

    final quests = await DailyQuestService.today();

    if (!mounted) return;
    setState(() {
      _counts = counts;
      _firstDiscoveries = firsts;
      _questCounts = quests;
    });
    _entrance.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final t = AppStrings.of(context.watch<SettingsProvider>().language);
    final counts = _counts;
    final firsts = _firstDiscoveries;

    if (counts == null || firsts == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final total = counts.values
        .expand((perWorld) => perWorld.values)
        .fold<int>(0, (a, b) => a + b);
    final totalFirsts = firsts.values.fold<int>(0, (a, b) => a + b);
    final best = counts.values
        .expand((perWorld) => perWorld.values)
        .fold<int>(0, (a, b) => a > b ? a : b);
    final languagesPlayed = counts.entries
        .where((e) => e.value.values.any((c) => c > 0))
        .length;

    var stagger = 0;
    Widget stag(Widget child) =>
        Stagger(animation: _entrance, index: stagger++, child: child);

    return CosmicBackground(
      accent: const Color(0xFF8B5CF6),
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          children: [
            stag(
              _HeroTotal(
                total: total,
                label: t.totalDiscovered,
                colors: colors,
              ),
            ),
            const SizedBox(height: 20),
            SectionHeading(t.overview),
            const SizedBox(height: 12),
            stag(
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: '🌟',
                      value: '$totalFirsts',
                      label: t.firstDiscoveries,
                      colors: colors,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: '🏆',
                      value: '$best',
                      label: t.bestWorld,
                      colors: colors,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: '🌐',
                      value: '$languagesPlayed/${GameLanguage.active.length}',
                      label: t.languagesPlayed,
                      colors: colors,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            SectionHeading(t.dailyQuestsTitle),
            const SizedBox(height: 12),
            stag(
              Column(
                children: [
                  _QuestTile(
                    emoji: '⚗️',
                    label: t.questCombine(10),
                    progress: _questCounts.$1,
                    goal: 10,
                    colors: colors,
                  ),
                  const SizedBox(height: 10),
                  _QuestTile(
                    emoji: '✨',
                    label: t.questDiscover(5),
                    progress: _questCounts.$2,
                    goal: 5,
                    colors: colors,
                  ),
                  const SizedBox(height: 10),
                  _QuestTile(
                    emoji: '🚀',
                    label: t.questDiscover(15),
                    progress: _questCounts.$2,
                    goal: 15,
                    colors: colors,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            SectionHeading(t.badgesTitle),
            const SizedBox(height: 12),
            stag(_BadgeStrip(totalFirsts: totalFirsts, colors: colors)),
            const SizedBox(height: 28),
            SectionHeading(t.perLanguage),
            const SizedBox(height: 12),
            for (final lang in GameLanguage.active)
              stag(
                _LanguageSection(
                  language: lang,
                  perWorld: counts[lang]!,
                  firstDiscoveries: firsts[lang]!,
                  max: best == 0 ? 1 : best,
                  colors: colors,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// One daily-quest row: emoji, label, progress bar and an x/y counter that
/// flips to a checkmark once the goal is reached. Counters reset naturally
/// each day (see [DailyQuestService]).
class _QuestTile extends StatelessWidget {
  const _QuestTile({
    required this.emoji,
    required this.label,
    required this.progress,
    required this.goal,
    required this.colors,
  });

  final String emoji;
  final String label;
  final int progress;
  final int goal;
  final AppPalette colors;

  @override
  Widget build(BuildContext context) {
    final done = progress >= goal;
    final clamped = progress.clamp(0, goal);
    final accent = done ? const Color(0xFF22C55E) : colors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: done ? 0.45 : 0.12)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: clamped / goal,
                    minHeight: 6,
                    backgroundColor: colors.textMuted.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation(accent),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          done
              ? const Icon(Icons.check_circle, color: Color(0xFF22C55E))
              : Text(
                  '$clamped/$goal',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: colors.textMuted,
                  ),
                ),
        ],
      ),
    );
  }
}

/// Horizontally scrollable row of milestone badges, keyed off total
/// world-first discoveries — unlocked ones are vivid, locked ones muted.
class _BadgeStrip extends StatelessWidget {
  const _BadgeStrip({required this.totalFirsts, required this.colors});

  final int totalFirsts;
  final AppPalette colors;

  static const _tiers = [
    (threshold: 1, emoji: '🥉'),
    (threshold: 10, emoji: '🥈'),
    (threshold: 25, emoji: '🥇'),
    (threshold: 50, emoji: '🏅'),
    (threshold: 100, emoji: '🎖️'),
    (threshold: 250, emoji: '👑'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 86,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _tiers.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final tier = _tiers[index];
          final unlocked = totalFirsts >= tier.threshold;
          return Opacity(
            opacity: unlocked ? 1.0 : 0.35,
            child: Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: unlocked
                        ? colors.primary.withValues(alpha: 0.12)
                        : colors.textMuted.withValues(alpha: 0.08),
                    border: Border.all(
                      color: unlocked
                          ? colors.primary.withValues(alpha: 0.3)
                          : colors.textMuted.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Text(tier.emoji, style: const TextStyle(fontSize: 24)),
                ),
                const SizedBox(height: 4),
                Text(
                  '${tier.threshold}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: colors.textMuted,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Big animated headline number at the top of the Stats tab — counts up
/// from 0 on every load/refresh. Thin wrapper around the shared [HeroCard]
/// chrome (gradient + floating particles).
class _HeroTotal extends StatelessWidget {
  const _HeroTotal({
    required this.total,
    required this.label,
    required this.colors,
  });

  final int total;
  final String label;
  final AppPalette colors;

  @override
  Widget build(BuildContext context) {
    return HeroCard(
      colors: colors,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: total),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) => Text(
              '$value',
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.colors,
  });

  final String icon;
  final String value;
  final String label;
  final AppPalette colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.primary.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: colors.textMuted,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageSection extends StatelessWidget {
  const _LanguageSection({
    required this.language,
    required this.perWorld,
    required this.firstDiscoveries,
    required this.max,
    required this.colors,
  });

  final GameLanguage language;
  final Map<String, int> perWorld;
  final int firstDiscoveries;
  final int max;
  final AppPalette colors;

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(language);
    final total = perWorld.values.fold<int>(0, (a, b) => a + b);
    final played = total > 0;
    final accent = language.accentColor;

    return Opacity(
      opacity: played ? 1.0 : 0.5,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(14, 16, 16, 16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: played
                ? accent.withValues(alpha: 0.25)
                : colors.primary.withValues(alpha: 0.08),
          ),
          boxShadow: played
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: played
                      ? accent
                      : colors.textMuted.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              language.flag,
                              style: const TextStyle(fontSize: 18),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              language.nativeName,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: colors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        if (played)
                          Text(
                            '🧪 $total   🌟 $firstDiscoveries',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: colors.textMuted,
                              fontSize: 12,
                            ),
                          )
                        else
                          Text(
                            '—',
                            style: TextStyle(
                              color: colors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                    if (played) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final id in [
                            ...AppConstants.sessionIds,
                            ...AppConstants.extraStatSessionIds,
                          ])
                            _WorldRing(
                              label: switch (id) {
                                'alchemytable' => '⚗️',
                                'target' => '🎯',
                                _ => t.worldTitle(id),
                              },
                              value: perWorld[id] ?? 0,
                              max: max,
                              accent: accent,
                              colors: colors,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small radial progress ring for one world's discovered count, relative
/// to [max] (the highest count across all worlds/languages) — replaces the
/// old flat linear bar with something a bit more game-like.
class _WorldRing extends StatelessWidget {
  const _WorldRing({
    required this.label,
    required this.value,
    required this.max,
    required this.accent,
    required this.colors,
  });

  final String label;
  final int value;
  final int max;
  final Color accent;
  final AppPalette colors;

  @override
  Widget build(BuildContext context) {
    final fraction = (value / max).clamp(0.0, 1.0);
    return Column(
      children: [
        SizedBox(
          width: 56,
          height: 56,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: CircularProgressIndicator(
                  value: 1,
                  strokeWidth: 5,
                  color: colors.primary.withValues(alpha: 0.1),
                ),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: fraction),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (context, animated, child) => SizedBox(
                  width: 56,
                  height: 56,
                  child: CircularProgressIndicator(
                    value: animated,
                    strokeWidth: 5,
                    strokeCap: StrokeCap.round,
                    color: accent,
                    backgroundColor: Colors.transparent,
                  ),
                ),
              ),
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, color: colors.textMuted)),
      ],
    );
  }
}

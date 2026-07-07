import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/game_language.dart';
import '../core/localization/app_strings.dart';
import '../core/services/supabase_service.dart';
import '../core/theme/app_theme.dart';
import '../providers/settings_provider.dart';
import '../widgets/animated_section_widgets.dart';

/// Admin-only screen listing pending "A + B = C" community suggestions
/// (English and Turkish, mixed), with approve/reject actions. Approving
/// overrides the result for that pair in the suggestion's own language
/// table going forward.
class CombinationReviewView extends StatefulWidget {
  const CombinationReviewView({super.key});

  @override
  State<CombinationReviewView> createState() => _CombinationReviewViewState();
}

class _CombinationReviewViewState extends State<CombinationReviewView> {
  final _remote = SupabaseService();
  late Future<List<Map<String, dynamic>>> _pending;
  final Set<String> _processing = {};

  @override
  void initState() {
    super.initState();
    _pending = _remote.fetchPendingSuggestions();
  }

  Future<void> _refresh() async {
    final future = _remote.fetchPendingSuggestions();
    setState(() => _pending = future);
    await future;
  }

  Future<void> _approve(Map<String, dynamic> suggestion) async {
    final id = suggestion['id'] as String;
    setState(() => _processing.add(id));
    await _remote.approveSuggestion(suggestion);
    if (!mounted) return;
    setState(() {
      _processing.remove(id);
      _pending = _remote.fetchPendingSuggestions();
    });
  }

  Future<void> _reject(String id) async {
    setState(() => _processing.add(id));
    await _remote.rejectSuggestion(id);
    if (!mounted) return;
    setState(() {
      _processing.remove(id);
      _pending = _remote.fetchPendingSuggestions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context.watch<SettingsProvider>().language);
    final colors = AppColors.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(t.reviewSuggestionsTitle)),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _pending,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            final rows = snapshot.data ?? const [];

            if (rows.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  _ReviewHeader(colors: colors, t: t),
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        t.noPendingSuggestions,
                        style: TextStyle(
                          color: colors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                _ReviewHeader(colors: colors, t: t),
                const SizedBox(height: 20),
                for (final row in rows)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              GameLanguage.fromCode(
                                row['language'] as String? ?? 'en',
                              ).flag,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${row['element_a']} + ${row['element_b']} '
                                '→ ${row['suggested_emoji']} '
                                '${row['suggested_name']}',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          t.suggestedBy(
                            row['suggested_by_name'] as String? ?? '',
                          ),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _processing.contains(row['id'])
                                    ? null
                                    : () => _reject(row['id'] as String),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.redAccent,
                                ),
                                child: Text(t.reject),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton(
                                onPressed: _processing.contains(row['id'])
                                    ? null
                                    : () => _approve(row),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                child: Text(t.approve),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ReviewHeader extends StatelessWidget {
  const _ReviewHeader({required this.colors, required this.t});

  final AppPalette colors;
  final AppStringsData t;

  @override
  Widget build(BuildContext context) {
    return HeroCard(
      colors: colors,
      height: 100,
      particles: const ['🧑‍⚖️', '✨', '🧪'],
      child: Text(
        t.reviewSuggestionsTitle,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
      ),
    );
  }
}

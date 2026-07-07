import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/game_language.dart';
import '../core/localization/app_strings.dart';
import '../core/services/supabase_service.dart';
import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/animated_section_widgets.dart';

/// Screen (English or Turkish) where signed-in users can suggest "Element A
/// + Element B = suggested result" and see the status of their own
/// suggestions.
class CombinationSuggestionsView extends StatefulWidget {
  const CombinationSuggestionsView({super.key});

  @override
  State<CombinationSuggestionsView> createState() =>
      _CombinationSuggestionsViewState();
}

class _CombinationSuggestionsViewState
    extends State<CombinationSuggestionsView> {
  final _remote = SupabaseService();
  final _elementAController = TextEditingController();
  final _elementBController = TextEditingController();
  final _resultNameController = TextEditingController();
  final _resultEmojiController = TextEditingController();
  late Future<List<Map<String, dynamic>>> _ownSuggestions;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _ownSuggestions = _remote.fetchOwnSuggestions();
  }

  @override
  void dispose() {
    _elementAController.dispose();
    _elementBController.dispose();
    _resultNameController.dispose();
    _resultEmojiController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final elementA = _elementAController.text.trim();
    final elementB = _elementBController.text.trim();
    final resultName = _resultNameController.text.trim();
    final resultEmoji = _resultEmojiController.text.trim();
    if (elementA.isEmpty ||
        elementB.isEmpty ||
        resultName.isEmpty ||
        resultEmoji.isEmpty) {
      return;
    }

    setState(() => _submitting = true);
    final auth = context.read<AuthProvider>();
    final language = context.read<SettingsProvider>().language;
    await _remote.submitCombinationSuggestion(
      elementA: elementA,
      elementB: elementB,
      suggestedName: resultName,
      suggestedEmoji: resultEmoji,
      suggestedByName: auth.displayName,
      language: language,
    );

    if (!mounted) return;
    final t = AppStrings.of(language);
    _elementAController.clear();
    _elementBController.clear();
    _resultNameController.clear();
    _resultEmojiController.clear();
    setState(() {
      _submitting = false;
      _ownSuggestions = _remote.fetchOwnSuggestions();
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(t.suggestionSubmitted)));
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.redAccent;
      default:
        return Colors.orange;
    }
  }

  String _statusLabel(AppStringsData t, String status) {
    switch (status) {
      case 'approved':
        return t.suggestionStatusApproved;
      case 'rejected':
        return t.suggestionStatusRejected;
      default:
        return t.suggestionStatusPending;
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = context.watch<SettingsProvider>().language;
    final t = AppStrings.of(language);
    final colors = AppColors.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(t.suggestCombinationTitle)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          HeroCard(
            colors: colors,
            height: 100,
            particles: const ['💡', '✨', '🧪'],
            child: Text(
              t.suggestCombinationIntro,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _elementAController,
            decoration: InputDecoration(
              labelText: t.elementALabel,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _elementBController,
            decoration: InputDecoration(
              labelText: t.elementBLabel,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _resultNameController,
            decoration: InputDecoration(
              labelText: t.suggestedResultNameLabel,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _resultEmojiController,
            decoration: InputDecoration(
              labelText: t.suggestedResultEmojiLabel,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submitting ? null : _submit,
              child: Text(t.submitSuggestion),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            t.yourSuggestions,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _ownSuggestions,
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
                    t.noSuggestionsYet,
                    style: TextStyle(
                      color: colors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }

              return Column(
                children: [
                  for (final row in rows)
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
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _statusColor(
                                row['status'] as String,
                              ).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _statusLabel(t, row['status'] as String),
                              style: TextStyle(
                                color: _statusColor(row['status'] as String),
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

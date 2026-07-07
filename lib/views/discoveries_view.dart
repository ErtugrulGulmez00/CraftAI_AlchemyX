import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/localization/app_strings.dart';
import '../core/theme/app_theme.dart';
import '../models/element_model.dart';
import '../providers/game_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/element_card.dart';

/// The "Discoveries" tab: a searchable list of every element the player
/// has found so far in this world.
class DiscoveriesView extends StatefulWidget {
  const DiscoveriesView({super.key, required this.canAddToCanvas});

  /// Whether tapping an element should add it to a free-drag canvas and
  /// close this screen — only meaningful for canvas-based modes (Space
  /// Mode). Tube-mechanic modes (Alchemy Table, and Target/Challenge when
  /// opened from that family) have no canvas, so tapping does nothing.
  final bool canAddToCanvas;

  @override
  State<DiscoveriesView> createState() => _DiscoveriesViewState();
}

class _DiscoveriesViewState extends State<DiscoveriesView> {
  String _query = '';

  /// Bottom sheet listing every locally-known recipe for [element].
  void _showRecipes(
    BuildContext context,
    GameProvider game,
    GameElement element,
    AppStringsData t,
  ) {
    final recipes = game.recipesFor(element);
    final colors = AppColors.of(context);

    String labelFor(String key) {
      final known = game.elementByKey(key);
      if (known == null) {
        // Recipe ingredient not in this world's box (e.g. after a restore) —
        // show the raw key, capitalized, without an emoji.
        return key.isEmpty ? key : key[0].toUpperCase() + key.substring(1);
      }
      return '${known.emoji} ${known.name}';
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.textMuted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: Text(
                  element.emoji,
                  style: const TextStyle(fontSize: 44),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  element.name,
                  style: Theme.of(
                    sheetContext,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                t.recipesTitle,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: colors.textMuted,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              if (recipes.isEmpty)
                Text(
                  t.noRecipesKnown,
                  style: TextStyle(color: colors.textMuted, height: 1.4),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: recipes.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 12,
                      color: colors.primary.withValues(alpha: 0.06),
                    ),
                    itemBuilder: (_, index) {
                      final (a, b) = recipes[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${labelFor(a)}  +  ${labelFor(b)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward,
                              size: 16,
                              color: colors.textMuted,
                            ),
                            const SizedBox(width: 8),
                            Text(element.emoji),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final game = context.watch<GameProvider>();
    final t = AppStrings.of(context.watch<SettingsProvider>().language);
    final elements = game.discoveredElements;

    final filtered = _query.isEmpty
        ? elements
        : elements
              .where((e) => e.name.toLowerCase().contains(_query.toLowerCase()))
              .toList();

    return Scaffold(
      appBar: AppBar(title: Text(t.discoveriesTitle(game.sessionId))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: t.searchHint(elements.length),
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: colors.surface,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      t.noMatches(_query),
                      style: TextStyle(
                        color: colors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 2.0,
                        ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final element = filtered[index];
                      // Canvas modes keep tap = "add to canvas", so the
                      // encyclopedia lives on long-press there; tube modes
                      // have no canvas, so tap opens it directly.
                      return InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: widget.canAddToCanvas
                            ? () {
                                final random = Random();
                                final position = Offset(
                                  80 + random.nextDouble() * 160,
                                  80 + random.nextDouble() * 160,
                                );
                                game.addToCanvas(element, position);
                                Navigator.of(context).pop();
                              }
                            : () => _showRecipes(context, game, element, t),
                        onLongPress: () =>
                            _showRecipes(context, game, element, t),
                        child: Center(child: ElementCard(element: element)),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

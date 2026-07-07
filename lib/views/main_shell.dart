import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/localization/app_strings.dart';
import '../core/services/supabase_service.dart';
import '../providers/settings_provider.dart';
import 'settings_view.dart';
import 'stats_view.dart';
import 'worlds_view.dart';

/// The app's global root shell. The bottom navigation lives here (not
/// inside a single world) so Worlds, Stats and Settings are always one
/// tap apart. Entering a world pushes a full-screen game on top.
class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.remote});

  final SupabaseService remote;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  // Play sits in the middle tab slot (index 1) — Stats on the left, Settings
  // on the right — and is the tab shown on cold start.
  int _index = 1;

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context.watch<SettingsProvider>().language);
    final titles = [t.navStats, 'CraftAI', t.navSettings];
    final tabs = [
      const StatsView(),
      WorldsView(remote: widget.remote),
      const SettingsView(),
    ];

    return Scaffold(
      // Every tab paints its own cosmic background edge-to-edge, so the
      // AppBar (where shown) floats transparently on top of it.
      appBar: _index == 1
          ? null
          : AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              foregroundColor: Colors.white,
              title: Text(titles[_index]),
            ),
      extendBodyBehindAppBar: true,
      body: SafeArea(
        top: _index != 1,
        bottom: false,
        child: IndexedStack(index: _index, children: tabs),
      ),
      bottomNavigationBar: _CosmicNavBar(
        index: _index,
        onChanged: (value) => setState(() => _index = value),
        items: [('📊', t.navStats), ('🌍', t.navPlay), ('⚙️', t.navSettings)],
      ),
    );
  }
}

/// A dark, glowing-chip bottom nav — each tab is its own rounded-square
/// icon button, with the active one picking up a cyan neon border, matching
/// the Play tab's own cosmic/neon visual language.
class _CosmicNavBar extends StatelessWidget {
  const _CosmicNavBar({
    required this.index,
    required this.onChanged,
    required this.items,
  });

  final int index;
  final ValueChanged<int> onChanged;
  final List<(String emoji, String label)> items;

  static const _activeAccent = Color(0xFF4FD1E8);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0xFF0B0916)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var i = 0; i < items.length; i++)
                _CosmicNavItem(
                  emoji: items[i].$1,
                  label: items[i].$2,
                  selected: i == index,
                  accent: _activeAccent,
                  onTap: () => onChanged(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CosmicNavItem extends StatelessWidget {
  const _CosmicNavItem({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1730),
              borderRadius: BorderRadius.circular(18),
              border: selected
                  ? Border.all(color: accent, width: 1.8)
                  : Border.all(color: Colors.transparent, width: 1.8),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.55),
                        blurRadius: 18,
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 30)),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: selected ? accent : Colors.white54,
            ),
          ),
        ],
      ),
    );
  }
}

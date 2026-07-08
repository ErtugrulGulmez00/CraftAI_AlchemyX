import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants/app_constants.dart';
import '../core/constants/game_language.dart';
import '../core/localization/app_strings.dart';
import '../core/services/local_storage_service.dart';
import '../core/services/notification_service.dart';
import '../core/services/supabase_service.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/animated_section_widgets.dart';
import '../widgets/cosmic_background.dart';
import 'combination_review_view.dart';
import 'combination_suggestions_view.dart';

// The settings page always sits on the dark CosmicBackground, so it uses a
// fixed dark palette instead of the theme's (which would paint bright cards
// onto the starfield in light mode).
const _kCard = Color(0xFF16121F);
const _kCardBorder = Color(0x14FFFFFF);
const _kTitle = Colors.white;
final _kSubtle = Colors.white.withValues(alpha: 0.45);
final _kMuted = Colors.white.withValues(alpha: 0.30);

/// "Settings" tab: app-wide preferences plus the usual housekeeping every
/// mobile app is expected to have (how-to, about, data reset).
class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  /// Turning the reminder on schedules the daily notification (asking for
  /// permission first); the preference is only persisted if the permission
  /// was granted, so a denied prompt leaves the switch off.
  Future<void> _toggleDailyReminder(bool value, AppStringsData t) async {
    final settings = context.read<SettingsProvider>();
    if (value) {
      final granted = await NotificationService.enableDailyReminder(
        title: t.dailyReminderNotifTitle,
        body: t.dailyReminderNotifBody,
      );
      if (granted) await settings.setDailyReminder(true);
    } else {
      await NotificationService.disableDailyReminder();
      await settings.setDailyReminder(false);
    }
  }

  Future<void> _launchURL(String urlString) async {
    final uri = Uri.parse(urlString);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not launch: $urlString')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Error launching link')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final auth = context.watch<AuthProvider>();
    final t = AppStrings.of(settings.language);

    var stagger = 0;
    Widget stag(Widget child) =>
        Stagger(animation: _entrance, index: stagger++, child: child);

    final showCommunity =
        settings.language == GameLanguage.turkishV2 ||
        settings.language == GameLanguage.english;

    return CosmicBackground(
      accent: const Color(0xFF8B5CF6),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          // ── Account ────────────────────────────────────────────────────
          stag(
            auth.isSignedIn
                ? _ProfileCard(name: auth.displayName, onSignOut: auth.signOut)
                : _SignInCard(
                    title: t.signInWithGoogle,
                    subtitle: t.challengeTimesSaved,
                    onTap: auth.signInWithGoogle,
                  ),
          ),

          // ── Preferences ────────────────────────────────────────────────
          _SectionLabel(t.appearance),
          stag(
            _SettingsCard(
              rows: [
                _SwitchRow(
                  icon: Icons.volume_up_outlined,
                  title: t.soundEffects,
                  subtitle: t.soundEffectsSubtitle,
                  accent: const Color(0xFFF97316),
                  value: settings.soundEnabled,
                  onChanged: settings.setSound,
                ),
                _SwitchRow(
                  icon: Icons.vibration,
                  title: t.haptics,
                  subtitle: t.hapticsSubtitle,
                  accent: const Color(0xFFE84393),
                  value: settings.hapticsEnabled,
                  onChanged: settings.setHaptics,
                ),
                _SwitchRow(
                  icon: Icons.notifications_active_outlined,
                  title: t.dailyReminder,
                  subtitle: t.dailyReminderSubtitle,
                  accent: const Color(0xFFFFD54F),
                  value: settings.dailyReminderEnabled,
                  onChanged: (value) => _toggleDailyReminder(value, t),
                ),
              ],
            ),
          ),

          // ── Language ───────────────────────────────────────────────────
          _SectionLabel(t.languageSectionLabel),
          stag(
            _SettingsCard(
              rows: [
                _NavRow(
                  icon: Icons.translate,
                  title: t.languageSectionLabel,
                  accent: const Color(0xFF14B8A6),
                  trailing: Text(
                    '${settings.language.flag}  ${settings.language.nativeName}',
                    style: const TextStyle(
                      color: Color(0xFF14B8A6),
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
                  ),
                  onTap: () => _openLanguagePicker(context, settings, t),
                ),
              ],
              footnote: t.languageSubtitle,
            ),
          ),

          // ── Community ──────────────────────────────────────────────────
          if (showCommunity && auth.isSignedIn) ...[
            _SectionLabel(t.communitySuggestionsLabel),
            stag(
              _SettingsCard(
                rows: [
                  _NavRow(
                    icon: Icons.lightbulb_outline,
                    title: t.suggestCombinationTile,
                    accent: const Color(0xFF4FD1E8),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CombinationSuggestionsView(),
                      ),
                    ),
                  ),
                  if (auth.isAdmin)
                    _NavRow(
                      icon: Icons.fact_check_outlined,
                      title: t.reviewSuggestionsTile,
                      accent: const Color(0xFF4FD1E8),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const CombinationReviewView(),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],

          // ── About ──────────────────────────────────────────────────────
          _SectionLabel(t.about),
          stag(
            _SettingsCard(
              rows: [
                _NavRow(
                  icon: Icons.help_outline,
                  title: t.howToPlay,
                  accent: const Color(0xFF22C55E),
                  onTap: () => _showHowToPlay(context, t),
                ),
                _NavRow(
                  icon: Icons.auto_awesome,
                  title: t.aboutCraftAI,
                  accent: const Color(0xFF8B5CF6),
                  onTap: () => _showAbout(context, t),
                ),
                _NavRow(
                  icon: Icons.privacy_tip_outlined,
                  title: t.privacyPolicy,
                  accent: const Color(0xFF3B82F6),
                  onTap: () => _launchURL(
                    'https://ertugrulgulmez00.github.io/-craftai-legal/',
                  ),
                ),
                _NavRow(
                  icon: Icons.apps,
                  title: t.otherApps,
                  accent: const Color(0xFFEC4899),
                  onTap: () => _launchURL(
                    'https://play.google.com/store/apps/details?id=com.kitapayraciadana.ritim5',
                  ),
                ),
              ],
            ),
          ),

          // ── Danger zone ────────────────────────────────────────────────
          _SectionLabel(t.dangerZone),
          stag(
            _SettingsCard(
              danger: true,
              rows: [
                _NavRow(
                  icon: Icons.delete_forever_outlined,
                  title: t.resetAllWorlds,
                  accent: Colors.redAccent,
                  danger: true,
                  onTap: () => _confirmResetAll(context, t),
                ),
                if (auth.isSignedIn)
                  _NavRow(
                    icon: Icons.person_off_outlined,
                    title: t.deleteAccount,
                    accent: Colors.redAccent,
                    danger: true,
                    onTap: () => _confirmDeleteAccount(context, t),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 28),
          Center(
            child: Text(
              'CraftAI  ·  v${AppConstants.appVersion}',
              style: TextStyle(
                color: _kMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openLanguagePicker(
    BuildContext context,
    SettingsProvider settings,
    AppStringsData t,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _LanguagePickerSheet(settings: settings),
    );
  }

  void _showHowToPlay(BuildContext context, AppStringsData t) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(t.howToPlay),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.howToPlayStep1),
            const SizedBox(height: 8),
            Text(t.howToPlayStep2),
            const SizedBox(height: 8),
            Text(t.howToPlayStep3),
            const SizedBox(height: 8),
            Text(t.howToPlayStep4),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(t.gotIt),
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context, AppStringsData t) {
    showAboutDialog(
      context: context,
      applicationName: 'CraftAI',
      applicationVersion: 'v${AppConstants.appVersion}',
      applicationIcon: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.asset(
          'assets/icon/app_icon.png',
          width: 52,
          height: 52,
          fit: BoxFit.cover,
        ),
      ),
      children: [SizedBox(height: 8), Text(t.aboutDescription)],
    );
  }

  Future<void> _confirmResetAll(BuildContext context, AppStringsData t) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(t.resetAllWorldsTitle),
        content: Text(t.resetAllWorldsBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(t.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(t.resetAll),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    for (final lang in GameLanguage.active) {
      for (final id in [
        ...AppConstants.sessionIds,
        ...AppConstants.extraStatSessionIds,
      ]) {
        await LocalStorageService.resetSession(
          AppConstants.sessionKey(id, lang),
        );
      }
    }
    // Also wipe the cloud backup, so signing in again doesn't resurrect
    // the worlds the player just chose to erase.
    await SupabaseService().deleteProgress();
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(t.allWorldsReset)));
  }

  /// Google Play (and KVKK/GDPR) mandated in-app account deletion: wipes
  /// every personal row server-side via the `delete-account` edge function,
  /// then drops back to a fresh anonymous session locally.
  Future<void> _confirmDeleteAccount(
    BuildContext context,
    AppStringsData t,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(t.deleteAccountConfirmTitle),
        content: Text(t.deleteAccountConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(t.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(t.deleteConfirmAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final auth = context.read<AuthProvider>();
    try {
      await SupabaseService().deleteAccount();
      await auth.signOut();
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.accountDeleted)));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.accountDeleteFailed)));
    }
  }
}

// ── Account cards ───────────────────────────────────────────────────────────

/// Signed-in identity: gradient initial avatar, name, Google badge and a
/// quiet sign-out button — one card instead of a header + separate row.
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.name, required this.onSignOut});

  final String name;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kCardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF8B5CF6), Color(0xFF4FD1E8)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                  blurRadius: 14,
                ),
              ],
            ),
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: _kTitle,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      padding: const EdgeInsets.all(1.5),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: SvgPicture.asset('assets/google_logo.svg'),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Google',
                      style: TextStyle(fontSize: 12, color: _kSubtle),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onSignOut,
            icon: Icon(Icons.logout, size: 20, color: _kSubtle),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Signed-out call-to-action: the whole card is the sign-in button, with
/// the real Google logo and the "your times get saved" benefit line.
class _SignInCard extends StatelessWidget {
  const _SignInCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kCard,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.45),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.18),
                blurRadius: 18,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: SvgPicture.asset('assets/google_logo.svg'),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: _kTitle,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 11.5, color: _kSubtle),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: _kMuted),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section building blocks ────────────────────────────────────────────────

/// Minimal uppercase micro-label — the AppBar already titles the page, so
/// sections only need quiet wayfinding, not decorated headers.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 26, bottom: 10, left: 6),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.4,
          color: _kSubtle,
        ),
      ),
    );
  }
}

/// Groups a section's rows into one rounded card with hairline dividers.
/// The optional [footnote] renders inside the card bottom in small muted
/// text (used for the language-switching explanation).
class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.rows, this.footnote, this.danger = false});

  final List<Widget> rows;
  final String? footnote;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: danger ? const Color(0xFF221118) : _kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: danger
              ? Colors.redAccent.withValues(alpha: 0.25)
              : _kCardBorder,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                indent: 64,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            rows[i],
          ],
          if (footnote != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  footnote!,
                  style: TextStyle(fontSize: 11, height: 1.4, color: _kMuted),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Rounded-square tinted icon shared by every row — the single element
/// that gives the page its color rhythm.
class _RowIcon extends StatelessWidget {
  const _RowIcon({required this.icon, required this.accent});

  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 18, color: accent),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      child: Row(
        children: [
          _RowIcon(icon: icon, accent: accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                    color: _kTitle,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11.5, color: _kSubtle),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: accent,
            inactiveThumbColor: Colors.white38,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.08),
            trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
          ),
        ],
      ),
    );
  }
}

/// Tappable row that navigates or opens a dialog/sheet — icon, title, an
/// optional trailing value (e.g. the current language) and a chevron.
class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.icon,
    required this.title,
    required this.accent,
    required this.onTap,
    this.trailing,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final Color accent;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              _RowIcon(icon: icon, accent: accent),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                    color: danger ? Colors.redAccent : _kTitle,
                  ),
                ),
              ),
              if (trailing != null) ...[trailing!, const SizedBox(width: 4)],
              Icon(Icons.chevron_right, size: 20, color: _kMuted),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Language picker ────────────────────────────────────────────────────────

const _kLanguageOptions = [
  (GameLanguage.english, false),
  (GameLanguage.turkishV2, false),
  (GameLanguage.german, true),
  (GameLanguage.spanish, true),
  (GameLanguage.portuguese, true),
];

/// Bottom-sheet list of every language, flag + name + BETA badge, with a
/// checkmark on the currently selected one. Dark-styled to match the page.
class _LanguagePickerSheet extends StatelessWidget {
  const _LanguagePickerSheet({required this.settings});

  final SettingsProvider settings;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1626),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _kCardBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < _kLanguageOptions.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 1,
                  indent: 54,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              _LanguageOptionRow(
                language: _kLanguageOptions[i].$1,
                isBeta: _kLanguageOptions[i].$2,
                selected: settings.language == _kLanguageOptions[i].$1,
                onTap: () {
                  settings.setLanguage(_kLanguageOptions[i].$1);
                  Navigator.of(context).pop();
                },
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _LanguageOptionRow extends StatelessWidget {
  const _LanguageOptionRow({
    required this.language,
    required this.isBeta,
    required this.selected,
    required this.onTap,
  });

  final GameLanguage language;
  final bool isBeta;
  final bool selected;
  final VoidCallback onTap;

  static const _accent = Color(0xFF14B8A6);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Text(language.flag, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 14),
            Text(
              language.nativeName,
              style: TextStyle(
                fontSize: 15,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? _accent : _kTitle,
              ),
            ),
            if (isBeta) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'BETA',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Colors.orange,
                  ),
                ),
              ),
            ],
            const Spacer(),
            if (selected) const Icon(Icons.check_circle, color: _accent),
          ],
        ),
      ),
    );
  }
}

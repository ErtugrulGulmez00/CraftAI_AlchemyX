import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../core/constants/game_language.dart';
import '../core/localization/app_strings.dart';
import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';

// Simple onboarding-only strings that don't need to go into AppStringsData.
const _obLang = {
  GameLanguage.english: (
    'Choose your language',
    'Tap a language to continue in it.',
  ),
  GameLanguage.turkishV2: ('Dilini seç', 'Devam etmek için bir dile dokun.'),
  GameLanguage.german: (
    'Wähle deine Sprache',
    'Tippe auf eine Sprache, um fortzufahren.',
  ),
  GameLanguage.spanish: ('Elige tu idioma', 'Toca un idioma para continuar.'),
  GameLanguage.portuguese: (
    'Escolha seu idioma',
    'Toque em um idioma para continuar.',
  ),
};

const _obNext = {
  GameLanguage.english: 'Next',
  GameLanguage.turkishV2: 'İleri',
  GameLanguage.german: 'Weiter',
  GameLanguage.spanish: 'Siguiente',
  GameLanguage.portuguese: 'Próximo',
};

const _obGetStarted = {
  GameLanguage.english: 'Get Started',
  GameLanguage.turkishV2: 'Başlayalım',
  GameLanguage.german: 'Loslegen',
  GameLanguage.spanish: 'Empezar',
  GameLanguage.portuguese: 'Começar',
};

const _obWelcomeTitle = {
  GameLanguage.english: 'Welcome to CraftAI',
  GameLanguage.turkishV2: 'CraftAI\'ya Hoş Geldin',
  GameLanguage.german: 'Willkommen bei CraftAI',
  GameLanguage.spanish: 'Bienvenido a CraftAI',
  GameLanguage.portuguese: 'Bem-vindo ao CraftAI',
};

const _obHowTitle = {
  GameLanguage.english: 'How it works',
  GameLanguage.turkishV2: 'Nasıl oynanır',
  GameLanguage.german: 'So funktioniert\'s',
  GameLanguage.spanish: 'Cómo funciona',
  GameLanguage.portuguese: 'Como funciona',
};

const _obModesTitle = {
  GameLanguage.english: 'Two worlds to explore',
  GameLanguage.turkishV2: 'İki farklı dünya',
  GameLanguage.german: 'Zwei Welten zum Entdecken',
  GameLanguage.spanish: 'Dos mundos por explorar',
  GameLanguage.portuguese: 'Dois mundos para explorar',
};

const _obModesHint = {
  GameLanguage.english: 'Each one also has Target and Challenge modes inside',
  GameLanguage.turkishV2:
      'Her ikisinin içinde Hedef Mod ve Yarışma Modu da var',
  GameLanguage.german:
      'Beide enthalten auch den Ziel- und Herausforderungsmodus',
  GameLanguage.spanish:
      'Ambos incluyen también el Modo Objetivo y el Modo Desafío',
  GameLanguage.portuguese: 'Ambos também incluem o Modo Alvo e o Modo Desafio',
};

/// Full-screen onboarding flow shown to first-time users.
/// Page 0 lets the user pick a language; all subsequent pages
/// immediately render in that language.
class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView>
    with TickerProviderStateMixin {
  final _controller = PageController();
  int _page = 0;
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  )..repeat();

  static const _totalPages = 5;

  void _next() {
    _controller.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final lang = settings.language;
    final colors = AppColors.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colors.primary.withValues(alpha: 0.12),
                  colors.background,
                  colors.secondary.withValues(alpha: 0.08),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _float,
                builder: (context, _) {
                  return Stack(
                    children: [
                      _FloatingEmoji(
                        emoji: '💧',
                        left: 0.08,
                        top: 0.10,
                        t: _float.value,
                        speed: 1.0,
                        size: 34,
                      ),
                      _FloatingEmoji(
                        emoji: '🔥',
                        left: 0.78,
                        top: 0.16,
                        t: _float.value,
                        speed: 0.7,
                        size: 30,
                      ),
                      _FloatingEmoji(
                        emoji: '✨',
                        left: 0.85,
                        top: 0.55,
                        t: _float.value,
                        speed: 1.3,
                        size: 26,
                      ),
                      _FloatingEmoji(
                        emoji: '🌊',
                        left: 0.05,
                        top: 0.62,
                        t: _float.value,
                        speed: 0.85,
                        size: 28,
                      ),
                      _FloatingEmoji(
                        emoji: '🌪️',
                        left: 0.50,
                        top: 0.06,
                        t: _float.value,
                        speed: 1.15,
                        size: 24,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Page indicator dots
                Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_totalPages, (i) {
                      final active = i == _page;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active
                              ? colors.primary
                              : colors.primary.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                ),
                // Pages
                Expanded(
                  child: PageView(
                    controller: _controller,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (p) => setState(() => _page = p),
                    children: [
                      _LanguagePage(onNext: _next),
                      _WelcomePage(lang: lang, onNext: _next),
                      _HowToPlayPage(lang: lang, onNext: _next),
                      _ModesPage(lang: lang, onNext: _next),
                      _LoginPage(lang: lang),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Page 0 — Language selection
// ────────────────────────────────────────────────────────────
class _LanguagePage extends StatelessWidget {
  const _LanguagePage({required this.onNext});
  final VoidCallback onNext;

  static const _languages = [
    (GameLanguage.english, 'English', '🇬🇧', false),
    (GameLanguage.turkishV2, 'Türkçe', '🇹🇷', false),
    (GameLanguage.german, 'Deutsch', '🇩🇪', true),
    (GameLanguage.spanish, 'Español', '🇪🇸', true),
    (GameLanguage.portuguese, 'Português', '🇧🇷', true),
  ];

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final colors = AppColors.of(context);
    final (title, subtitle) = _obLang[settings.language]!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const Spacer(flex: 2),
          Text('🌍', style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.textMuted),
          ),
          const SizedBox(height: 32),
          // Language chips
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              for (final (lang, label, flag, isBeta) in _languages)
                _LangChip(
                  flag: flag,
                  label: label,
                  selected: settings.language == lang,
                  isBeta: isBeta,
                  onTap: () => settings.setLanguage(lang),
                ),
            ],
          ),
          const Spacer(flex: 3),
          _NextButton(label: _obNext[settings.language]!, onTap: onNext),
          const SizedBox(height: 28),
        ],
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  const _LangChip({
    required this.flag,
    required this.label,
    required this.selected,
    required this.isBeta,
    required this.onTap,
  });
  final String flag;
  final String label;
  final bool selected;
  final bool isBeta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? colors.primary : colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? colors.primary : colors.surface,
            width: 2,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(flag, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : null,
              ),
            ),
            if (isBeta) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.25)
                      : colors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'BETA',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.white : colors.accent,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Page 1 — Welcome
// ────────────────────────────────────────────────────────────
class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.lang, required this.onNext});
  final GameLanguage lang;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(lang);
    final colors = AppColors.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const Spacer(flex: 2),
          // Logo
          _OnboardingLogo(colors: colors),
          const SizedBox(height: 32),
          Text(
            _obWelcomeTitle[lang]!,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Text(
            t.tagline,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colors.textMuted,
              height: 1.5,
            ),
          ),
          const Spacer(flex: 3),
          _NextButton(label: _obNext[lang]!, onTap: onNext),
          const SizedBox(height: 28),
        ],
      ),
    );
  }
}

class _OnboardingLogo extends StatelessWidget {
  const _OnboardingLogo({required this.colors});
  final AppPalette colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.40),
            blurRadius: 36,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Image.asset(
          'assets/icon/app_icon.png',
          width: 120,
          height: 120,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Page 2 — How to play
// ────────────────────────────────────────────────────────────
class _HowToPlayPage extends StatelessWidget {
  const _HowToPlayPage({required this.lang, required this.onNext});
  final GameLanguage lang;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(lang);
    final colors = AppColors.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const Spacer(flex: 2),
          Text('🎮', style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 24),
          Text(
            _obHowTitle[lang]!,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 32),
          _StepTile(text: t.howToPlayStep1, color: colors.primary),
          const SizedBox(height: 12),
          _StepTile(text: t.howToPlayStep2, color: colors.secondary),
          const SizedBox(height: 12),
          _StepTile(text: t.howToPlayStep3, color: colors.accent),
          const SizedBox(height: 12),
          _StepTile(text: t.howToPlayStep4, color: colors.textMuted),
          const Spacer(flex: 3),
          _NextButton(label: _obNext[lang]!, onTap: onNext),
          const SizedBox(height: 28),
        ],
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Page 3 — Game modes
// ────────────────────────────────────────────────────────────
class _ModesPage extends StatelessWidget {
  const _ModesPage({required this.lang, required this.onNext});
  final GameLanguage lang;
  final VoidCallback onNext;

  // Same identity colors used for the two mode-family cards on the Play tab.
  static const _alchemyAccent = Color(0xFFD97706);
  static const _spaceAccent = Color(0xFF4C3FBF);

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(lang);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const Spacer(flex: 2),
          Text('🏆', style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 24),
          Text(
            _obModesTitle[lang]!,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 32),
          _ModeCard(
            emoji: '⚗️',
            title: t.alchemyTableModeTitle,
            subtitle: t.alchemyTableModeSubtitle,
            color: _alchemyAccent,
          ),
          const SizedBox(height: 12),
          _ModeCard(
            emoji: '🪐',
            title: t.freeModeTitle,
            subtitle: t.freeModeSubtitle,
            color: _spaceAccent,
          ),
          const SizedBox(height: 14),
          Text(
            _obModesHint[lang]!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.of(context).textMuted,
            ),
          ),
          const Spacer(flex: 3),
          _NextButton(label: _obGetStarted[lang]!, onTap: onNext),
          const SizedBox(height: 28),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
  });
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: colors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Page 4 — Login (Google / Guest)
// ────────────────────────────────────────────────────────────
class _LoginPage extends StatelessWidget {
  const _LoginPage({required this.lang});
  final GameLanguage lang;

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(lang);
    final settings = context.watch<SettingsProvider>();
    final auth = context.watch<AuthProvider>();
    final colors = AppColors.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const Spacer(flex: 3),
          _OnboardingLogo(colors: colors),
          const SizedBox(height: 32),
          Text(
            'CraftAI',
            style: Theme.of(
              context,
            ).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            t.tagline,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colors.textMuted,
              height: 1.5,
            ),
          ),
          const Spacer(flex: 4),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () async {
                await auth.signInWithGoogle();
                if (context.mounted) settings.setSeenWelcome(true);
              },
              icon: Container(
                width: 24,
                height: 24,
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: SvgPicture.asset('assets/google_logo.svg'),
              ),
              label: Text(t.continueWithGoogle),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => settings.setSeenWelcome(true),
            child: Text(t.continueAsGuest),
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Shared: Next button
// ────────────────────────────────────────────────────────────
class _NextButton extends StatelessWidget {
  const _NextButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(onPressed: onTap, child: Text(label)),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Shared: floating background emoji (purely decorative)
// ────────────────────────────────────────────────────────────
class _FloatingEmoji extends StatelessWidget {
  const _FloatingEmoji({
    required this.emoji,
    required this.left,
    required this.top,
    required this.t,
    required this.speed,
    required this.size,
  });

  /// Fractional position (0-1) of the screen.
  final double left;
  final double top;
  final String emoji;

  /// Current animation value (0-1, repeating).
  final double t;
  final double speed;
  final double size;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final phase = (t * speed) % 1.0;
    final dy = sin(phase * 2 * pi) * 14;

    return Positioned(
      left: left * screen.width,
      top: top * screen.height + dy,
      child: Opacity(
        opacity: 0.18,
        child: Text(emoji, style: TextStyle(fontSize: size)),
      ),
    );
  }
}

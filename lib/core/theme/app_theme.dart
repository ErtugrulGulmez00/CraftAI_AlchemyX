import 'package:flutter/material.dart';

/// A full set of named colors for one brightness mode (light or dark).
class AppPalette {
  const AppPalette({
    required this.primary,
    required this.primaryDark,
    required this.secondary,
    required this.accent,
    required this.background,
    required this.surface,
    required this.canvasTop,
    required this.canvasBottom,
    required this.textPrimary,
    required this.textMuted,
  });

  final Color primary;
  final Color primaryDark;
  final Color secondary;
  final Color accent; // first-discovery gold
  final Color background;
  final Color surface;
  final Color canvasTop;
  final Color canvasBottom;
  final Color textPrimary;
  final Color textMuted;
}

class AppColors {
  AppColors._();

  static const AppPalette light = AppPalette(
    primary: Color(0xFF6C5CE7),
    primaryDark: Color(0xFF4834D4),
    secondary: Color(0xFF00CEC9),
    accent: Color(0xFFFFA62B),
    background: Color(0xFFF4F2FB),
    surface: Color(0xFFFFFFFF),
    canvasTop: Color(0xFFEDE9FE),
    canvasBottom: Color(0xFFF7F5FF),
    textPrimary: Color(0xFF2D2A4A),
    textMuted: Color(0xFF8A87A6),
  );

  static const AppPalette dark = AppPalette(
    primary: Color(0xFF8C7AFF),
    primaryDark: Color(0xFFC2B8FF),
    secondary: Color(0xFF3DEDE8),
    accent: Color(0xFFFFC266),
    background: Color(0xFF15131F),
    surface: Color(0xFF211F33),
    canvasTop: Color(0xFF252338),
    canvasBottom: Color(0xFF181725),
    textPrimary: Color(0xFFEEECFB),
    textMuted: Color(0xFF9794B8),
  );

  /// Returns the palette matching the current theme brightness, so
  /// widgets can stay correct in both light and dark mode.
  static AppPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(AppColors.light, Brightness.light);
  static ThemeData get dark => _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppPalette colors, Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: colors.primary,
      brightness: brightness,
    ).copyWith(secondary: colors.secondary, surface: colors.surface);

    const fontFamily = 'Nunito';
    final textTheme = TextTheme(
      displayLarge: TextStyle(
        fontFamily: fontFamily,
        color: colors.textPrimary,
      ),
      displayMedium: TextStyle(
        fontFamily: fontFamily,
        color: colors.textPrimary,
      ),
      displaySmall: TextStyle(
        fontFamily: fontFamily,
        color: colors.textPrimary,
      ),
      headlineLarge: TextStyle(
        fontFamily: fontFamily,
        color: colors.textPrimary,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
      headlineMedium: TextStyle(
        fontFamily: fontFamily,
        color: colors.textPrimary,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
      headlineSmall: TextStyle(
        fontFamily: fontFamily,
        color: colors.textPrimary,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
      titleLarge: TextStyle(
        fontFamily: fontFamily,
        color: colors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: TextStyle(
        fontFamily: fontFamily,
        color: colors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: TextStyle(
        fontFamily: fontFamily,
        color: colors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(fontFamily: fontFamily, color: colors.textPrimary),
      bodyMedium: TextStyle(fontFamily: fontFamily, color: colors.textPrimary),
      bodySmall: TextStyle(fontFamily: fontFamily, color: colors.textMuted),
      labelLarge: TextStyle(
        fontFamily: fontFamily,
        color: colors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
      labelMedium: TextStyle(fontFamily: fontFamily, color: colors.textMuted),
      labelSmall: TextStyle(fontFamily: fontFamily, color: colors.textMuted),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.background,
      fontFamily: fontFamily,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w800,
          fontSize: 22,
          letterSpacing: -0.5,
        ).copyWith(color: colors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.primary.withValues(alpha: 0.12),
        labelStyle: TextStyle(
          fontWeight: FontWeight.w700,
          color: colors.primaryDark,
        ),
        side: BorderSide.none,
        shape: const StadiumBorder(),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF2D2A4A),
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surface,
        indicatorColor: colors.primary.withValues(alpha: 0.14),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? colors.primaryDark : colors.textMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? colors.primary : colors.textMuted,
          );
        }),
      ),
    );
  }
}

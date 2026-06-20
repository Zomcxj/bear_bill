import 'package:flutter/material.dart';
import 'app_design_system.dart';

/// 小熊记账本 — Luminous Finance 主题
class AppTheme {
  static dynamic _themeProvider;
  static set themeProvider(dynamic tp) => _themeProvider = tp;

  // ── 主色 ──
  static const Color primary = DS.primary;
  static const Color primaryDark = DS.primaryContainer;
  static const Color primaryLight = DS.surfaceContainerHigh;
  static const Color primaryBg = DS.background;

  // ── 辅色 ──
  static const Color accent = DS.secondaryContainer;
  static const Color accentDark = DS.secondary;
  static const Color accentLight = Color(0xFFE0F5FF);

  // ── 状态色 ──
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color info = DS.secondaryContainer;
  static const Color infoLight = Color(0xFFE0F5FF);
  static const Color warning = Color(0xFFFFA726);
  static const Color warningLight = Color(0xFFFFF3E0);

  // ── 文字色 ──
  static const Color textPrimary = DS.onSurface;
  static const Color textSecondary = DS.onSurfaceVariant;
  static const Color textHint = DS.outline;
  static const Color textWhite = DS.onPrimary;

  // ── Hero 区域 ──
  static const Color heroTextMain = DS.onSurface;
  static const Color heroTextSub = Color(0xCC191C1E);
  static const Color heroTextMuted = Color(0x99191C1E);
  static const Color heroExpense = DS.error;
  static const Color heroIncome = DS.secondary;
  static const Color heroBalancePos = DS.secondary;
  static const Color heroBalanceNeg = DS.error;

  // ── 背景 ──
  static const Color bgPage = DS.background;
  static const Color bgCard = DS.surfaceContainerLowest;
  static const Color bgSection = DS.surfaceContainerLow;

  // ── 边框/分割线 ──
  static const Color border = DS.outlineVariant;
  static const Color divider = DS.outlineVariant;

  // ── 心情色 ──
  static const Map<String, Color> moodColors = {
    'happy': Color(0xFFFFD93D),
    'normal': Color(0xFF40C2FD),
    'sad': Color(0xFF90CAF9),
    'angry': Color(0xFFFF8A80),
    'surprised': Color(0xFFCE93D8),
  };

  // ── 渐变 ──
  static const LinearGradient candyGradient = DS.heroGradient;
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [DS.primary, DS.primaryContainer],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── ThemeData ──
  static ThemeData get currentTheme => DS.isDark ? darkTheme : lightTheme;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: DS.primary,
      scaffoldBackgroundColor: DS.background,
      fontFamily: DS.fontDisplay,
      colorScheme: const ColorScheme.light(
        primary: DS.primary,
        secondary: DS.secondaryContainer,
        surface: DS.surface,
        error: DS.error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: DS.background,
        foregroundColor: DS.onSurface,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardTheme(
        color: DS.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DS.radiusMd),
          side: const BorderSide(color: DS.outlineVariant, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DS.primary,
          foregroundColor: DS.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: DS.md, vertical: DS.sm),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DS.radiusFull),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: DS.primary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DS.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DS.radiusFull),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DS.radiusFull),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DS.radiusFull),
          borderSide: const BorderSide(color: DS.secondaryContainer, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: DS.md, vertical: DS.sm + 2),
        hintStyle: const TextStyle(
          fontFamily: DS.fontLabel, fontSize: 14, fontWeight: FontWeight.w600,
          color: DS.outline,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: DS.primary,
      scaffoldBackgroundColor: DS.darkBackground,
      fontFamily: DS.fontDisplay,
      colorScheme: const ColorScheme.dark(
        primary: DS.primary,
        secondary: DS.secondaryContainer,
        surface: DS.darkSurface,
        error: DS.error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: DS.darkBackground,
        foregroundColor: DS.darkOnSurface,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardTheme(
        color: DS.darkSurfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DS.radiusMd),
          side: const BorderSide(color: DS.darkOutlineVariant, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DS.primary,
          foregroundColor: DS.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: DS.md, vertical: DS.sm),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DS.radiusFull),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: DS.secondaryContainer),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DS.darkSurfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DS.radiusFull),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DS.radiusFull),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DS.radiusFull),
          borderSide: const BorderSide(color: DS.secondaryContainer, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: DS.md, vertical: DS.sm + 2),
        hintStyle: const TextStyle(
          fontFamily: DS.fontLabel, fontSize: 14, fontWeight: FontWeight.w600,
          color: DS.darkOutline,
        ),
      ),
    );
  }
}

class AppRadius {
  static const double sm = DS.radiusSm;
  static const double md = DS.radiusMd;
  static const double lg = DS.radiusLg;
  static const double xl = DS.radiusXl;
  static const double full = DS.radiusFull;
}

class AppSpacing {
  static const double xs = DS.xs;
  static const double sm = DS.base;
  static const double md = DS.gutter;
  static const double lg = DS.md;
  static const double xl = DS.lg;
  static const double xxl = DS.xl;
}

class AppShadow {
  static List<BoxShadow> get card => DS.shadowSm;
  static List<BoxShadow> get deep => DS.shadowMd;
  static List<BoxShadow> get float => DS.shadowLg;
  static List<BoxShadow> get navbar => DS.shadowSm;
}

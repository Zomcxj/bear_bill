import 'package:flutter/material.dart';
import 'app_design_system.dart';

/// 小熊记账本 — Luminous Finance 主题
class AppTheme {
  // ── 主色 ──
  static const Color primary = DS.primary;
  static const Color primaryDark = DS.primaryContainer;
  static Color get primaryLight => DS.surfaceContainerHigh;
  static Color get primaryBg => DS.background;

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
  static Color get textPrimary => DS.onSurface;
  static Color get textSecondary => DS.onSurfaceVariant;
  static Color get textHint => DS.outline;
  static const Color textWhite = DS.onPrimary;

  // ── Hero 区域 ──
  static Color get heroTextMain => DS.onSurface;
  static Color get heroTextSub => DS.onSurface.withOpacity(0.8);
  static Color get heroTextMuted => DS.onSurface.withOpacity(0.6);
  static const Color heroExpense = DS.error;
  static const Color heroIncome = DS.secondary;
  static const Color heroBalancePos = DS.secondary;
  static const Color heroBalanceNeg = DS.error;

  // ── 背景 ──
  static Color get bgPage => DS.background;
  static Color get bgCard => DS.surfaceContainerLowest;
  static Color get bgSection => DS.surfaceContainerLow;

  // ── 边框/分割线 ──
  static Color get border => DS.outlineVariant;
  static Color get divider => DS.outlineVariant;

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

  /// 构建主题（参数化，避免读取 DS 动态 getter 导致两个主题颜色相同）
  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color scaffoldBg,
    required Color onSurface,
    required Color surfaceContainerLowest,
    required Color outlineVariant,
    required Color surfaceContainerLow,
    required Color outline,
    required Color textButtonColor,
  }) {
    final isLight = brightness == Brightness.light;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      primaryColor: DS.primary,
      scaffoldBackgroundColor: scaffoldBg,
      fontFamily: DS.fontDisplay,
      colorScheme: isLight
          ? ColorScheme.light(
              primary: DS.primary,
              secondary: DS.secondaryContainer,
              surface: scaffoldBg,
              error: DS.error,
            )
          : ColorScheme.dark(
              primary: DS.primary,
              secondary: DS.secondaryContainer,
              surface: scaffoldBg,
              error: DS.error,
            ),
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBg,
        foregroundColor: onSurface,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardTheme(
        color: surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DS.radiusMd),
          side: BorderSide(color: outlineVariant, width: 1),
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
        style: TextButton.styleFrom(foregroundColor: textButtonColor),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainerLow,
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
        hintStyle: TextStyle(
          fontFamily: DS.fontLabel, fontSize: 14, fontWeight: FontWeight.w600,
          color: outline,
        ),
      ),
    );
  }

  static ThemeData get lightTheme => _buildTheme(
    brightness: Brightness.light,
    scaffoldBg: const Color(0xFFF7F9FB),
    onSurface: const Color(0xFF191C1E),
    surfaceContainerLowest: const Color(0xFFFFFFFF),
    outlineVariant: const Color(0xFFCFC4C5),
    surfaceContainerLow: const Color(0xFFF2F4F6),
    outline: const Color(0xFF7E7576),
    textButtonColor: DS.primary,
  );

  static ThemeData get darkTheme => _buildTheme(
    brightness: Brightness.dark,
    scaffoldBg: const Color(0xFF121218),
    onSurface: const Color(0xFFE8E8EC),
    surfaceContainerLowest: const Color(0xFF141418),
    outlineVariant: const Color(0xFF3A3A44),
    surfaceContainerLow: const Color(0xFF181820),
    outline: const Color(0xFF6A6A72),
    textButtonColor: DS.secondaryContainer,
  );
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

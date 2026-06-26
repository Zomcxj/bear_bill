import 'package:flutter/material.dart';

/// Luminous Finance 设计系统 Token
class DS {
  DS._();

  // ── 深色模式 ──
  static bool _isDark = false;
  static bool get isDark => _isDark;
  static void setDarkMode(bool value) => _isDark = value;

  // ── 字体 ──
  static const String fontDisplay = 'PlusJakartaSans';
  static const String fontLabel = 'Manrope';

  // ── 强调色（亮色，不变） ──
  static const Color primary = Color(0xFF000000);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF1B1B1B);
  static const Color secondary = Color(0xFF00668A);
  static const Color secondaryContainer = Color(0xFF40C2FD);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF004D6A);
  static const Color tertiary = Color(0xFFD3579A);
  static const Color tertiaryContainer = Color(0xFF3D0026);
  static const Color onTertiaryContainer = Color(0xFFD3579A);
  static const Color tertiaryFixed = Color(0xFFFFD8E7);
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);

  // ── 表面色（动态，随深色模式切换） ──
  static Color get background => _isDark ? const Color(0xFF121218) : const Color(0xFFF7F9FB);
  static Color get surface => _isDark ? const Color(0xFF121218) : const Color(0xFFF7F9FB);
  static Color get surfaceBright => _isDark ? const Color(0xFF121218) : const Color(0xFFF7F9FB);
  static Color get surfaceDim => _isDark ? const Color(0xFF181820) : const Color(0xFFD8DADC);
  static Color get surfaceContainer => _isDark ? const Color(0xFF1E1E28) : const Color(0xFFECEEF0);
  static Color get surfaceContainerLow => _isDark ? const Color(0xFF181820) : const Color(0xFFF2F4F6);
  static Color get surfaceContainerLowest => _isDark ? const Color(0xFF141418) : const Color(0xFFFFFFFF);
  static Color get surfaceContainerHigh => _isDark ? const Color(0xFF242430) : const Color(0xFFE6E8EA);
  static Color get surfaceContainerHighest => _isDark ? const Color(0xFF2A2A36) : const Color(0xFFE0E3E5);
  static Color get surfaceVariant => _isDark ? const Color(0xFF2A2A36) : const Color(0xFFE0E3E5);

  // ── 文字色（动态，随深色模式切换） ──
  static Color get onSurface => _isDark ? const Color(0xFFE8E8EC) : const Color(0xFF191C1E);
  static Color get onSurfaceVariant => _isDark ? const Color(0xFF9A9AA0) : const Color(0xFF4C4546);
  static Color get outline => _isDark ? const Color(0xFF6A6A72) : const Color(0xFF7E7576);
  static Color get outlineVariant => _isDark ? const Color(0xFF3A3A44) : const Color(0xFFCFC4C5);

  // ── 辅助 ──
  static const Color inverseSurface = Color(0xFF2D3133);
  static const Color inverseOnSurface = Color(0xFFEFF1F3);

  // ── 圆角 ──
  static const double radiusXs = 8;
  static const double radiusSm = 12;
  static const double radiusMd = 16;
  static const double radiusLg = 32;
  static const double radiusXl = 48;
  static const double radiusFull = 999;

  // ── 间距 ──
  static const double xs = 4;
  static const double base = 8;
  static const double sm = 12;
  static const double gutter = 16;
  static const double md = 24;
  static const double lg = 40;
  static const double xl = 64;
  static const double containerMargin = 20;

  // ── 阴影 ──
  static List<BoxShadow> get shadowSm => [
    BoxShadow(
      color: Colors.black.withOpacity(_isDark ? 0.3 : 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get shadowMd => [
    BoxShadow(
      color: Colors.black.withOpacity(_isDark ? 0.4 : 0.08),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get shadowLg => [
    BoxShadow(
      color: Colors.black.withOpacity(_isDark ? 0.5 : 0.12),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  // ── 渐变 ──
  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFFFFF9C4), Color(0xFFF8BBD0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradientDark = LinearGradient(
    colors: [Color(0xFF2A2420), Color(0xFF2A2028)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get heroGradientCurrent => _isDark ? heroGradientDark : heroGradient;

  static const LinearGradient heroGradientBlue = LinearGradient(
    colors: [Color(0xFFE0F5FF), Color(0xFFF8BBD0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradientBlueDark = LinearGradient(
    colors: [Color(0xFF1A2030), Color(0xFF2A2028)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get heroGradientBlueCurrent => _isDark ? heroGradientBlueDark : heroGradientBlue;

  // ── Hero 卡片色（动态） ──
  static Color get heroCardBg => _isDark
      ? Colors.white.withOpacity(0.08)
      : Colors.white.withOpacity(0.6);
  static Color get heroCardBorder => _isDark
      ? Colors.white.withOpacity(0.08)
      : Colors.black.withOpacity(0.08);

  // ── 动态语义色 ──
  static Color get errorDynamic => _isDark
      ? const Color(0xFFFFB4AB)
      : const Color(0xFFBA1A1A);

  // ── 毛玻璃装饰 ──
  static BoxDecoration get glassDecoration => BoxDecoration(
    color: _isDark ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.7),
    borderRadius: BorderRadius.circular(radiusMd),
    border: Border.all(color: _isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08)),
  );

  static BoxDecoration get glassDecorationLight => BoxDecoration(
    color: _isDark ? Colors.white.withOpacity(0.04) : Colors.white.withOpacity(0.6),
    borderRadius: BorderRadius.circular(radiusMd),
    border: Border.all(color: _isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05)),
  );

  // ── 文字样式 ──
  static const TextStyle displayLg = TextStyle(
    fontFamily: fontDisplay, fontSize: 48, fontWeight: FontWeight.w800,
    height: 56 / 48, letterSpacing: -0.02,
  );
  static const TextStyle displayLgMobile = TextStyle(
    fontFamily: fontDisplay, fontSize: 36, fontWeight: FontWeight.w800, height: 44 / 36,
  );
  static const TextStyle headlineLg = TextStyle(
    fontFamily: fontDisplay, fontSize: 32, fontWeight: FontWeight.w700,
    height: 40 / 32, letterSpacing: -0.01,
  );
  static const TextStyle headlineMd = TextStyle(
    fontFamily: fontDisplay, fontSize: 24, fontWeight: FontWeight.w700, height: 32 / 24,
  );
  static const TextStyle headlineSm = TextStyle(
    fontFamily: fontDisplay, fontSize: 20, fontWeight: FontWeight.w600, height: 28 / 20,
  );
  static const TextStyle bodyLg = TextStyle(
    fontFamily: fontDisplay, fontSize: 18, fontWeight: FontWeight.w400, height: 26 / 18,
  );
  static const TextStyle bodyMd = TextStyle(
    fontFamily: fontDisplay, fontSize: 16, fontWeight: FontWeight.w400, height: 24 / 16,
  );
  static const TextStyle labelMd = TextStyle(
    fontFamily: fontLabel, fontSize: 14, fontWeight: FontWeight.w600,
    height: 20 / 14, letterSpacing: 0.01,
  );
  static const TextStyle labelSm = TextStyle(
    fontFamily: fontLabel, fontSize: 12, fontWeight: FontWeight.w500, height: 16 / 12,
  );
}

import 'package:flutter/material.dart';
import '../providers/theme_provider.dart';

/// 小熊记账本 - 软萌粉糖色系主题（对齐小程序版）
/// 主色相关颜色由 ThemeProvider 动态生成，其他颜色保持静态
class AppTheme {
  // ThemeProvider 引用（main.dart 中设置）
  static ThemeProvider? _themeProvider;
  static set themeProvider(ThemeProvider? tp) => _themeProvider = tp;

  // ── 主色：蜜桃粉（动态） ──
  static Color get primary => _themeProvider?.primaryColor ?? const Color(0xFFFF8FAB);
  static Color get primaryDark => _themeProvider?.primaryDark ?? const Color(0xFFE8607A);
  static Color get primaryLight => _themeProvider?.primaryLight ?? const Color(0xFFFFD6E0);
  static Color get primaryBg => _themeProvider?.primaryBg ?? const Color(0xFFFFF0F4);

  // ── 辅色：奶油黄 ──
  static const Color accent = Color(0xFFFFD93D);
  static const Color accentDark = Color(0xFFF4B400);
  static const Color accentLight = Color(0xFFFFF7D1);

  // ── 成功绿：薄荷绿 ──
  static const Color success = Color(0xFF6BCB77);
  static const Color successLight = Color(0xFFD9F7DC);

  // ── 信息蓝：天空蓝 ──
  static const Color info = Color(0xFF74C0FC);
  static const Color infoLight = Color(0xFFDDEEFF);

  // ── 警告橙 ──
  static const Color warning = Color(0xFFFFA94D);
  static const Color warningLight = Color(0xFFFFE8CC);

  // ── 文字色 ──
  static const Color textPrimary = Color(0xFF3D2C2C);
  static const Color textSecondary = Color(0xFF8B6B6B);
  static const Color textHint = Color(0xFFC4A4A4);
  static const Color textWhite = Color(0xFFFFFFFF);

  // ── Hero 区域专用白色文字（在渐变背景上） ──
  static const Color heroTextMain = Color(0xFFFFFFFF);
  static const Color heroTextSub = Color(0xE6FFFFFF);
  static const Color heroTextMuted = Color(0xF0FFFFFF);
  static const Color heroExpense = Color(0xFFFFECF0);
  static const Color heroIncome = Color(0xFFEFFFEF);
  static const Color heroBalancePos = Color(0xFFFFFDE0);
  static const Color heroBalanceNeg = Color(0xFFFFD0D0);

  // ── 背景（动态） ──
  static Color get bgPage => _themeProvider?.bgPage ?? const Color(0xFFFFF5F7);
  static const Color bgCard = Color(0xFFFFFFFF);
  static Color get bgSection => _themeProvider?.bgSection ?? const Color(0xFFF9F0F2);

  // ── 边框/分割线（动态） ──
  static Color get border => _themeProvider?.border ?? const Color(0xFFFFE0E8);
  static Color get divider => _themeProvider?.divider ?? const Color(0xFFFFF0F4);

  // ── 心情色 ──
  static const Map<String, Color> moodColors = {
    'happy': Color(0xFFFFD93D),
    'normal': Color(0xFF74C0FC),
    'sad': Color(0xFFB2F2BB),
    'angry': Color(0xFFFFA94D),
    'surprised': Color(0xFFD0BFFF),
  };

  // ══════════════════════════════════════
  //  渐变组（动态）
  // ══════════════════════════════════════

  static LinearGradient get candyGradient =>
      _themeProvider?.candyGradient ?? const LinearGradient(
        colors: [Color(0xFFFF8FAB), Color(0xFFFFC2D3), Color(0xFFFFD6E4)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );

  static LinearGradient get primaryGradient =>
      _themeProvider?.primaryGradient ?? const LinearGradient(
        colors: [Color(0xFFFF8FAB), Color(0xFFFFB3C6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get primaryDeepGradient =>
      _themeProvider?.primaryDeepGradient ?? const LinearGradient(
        colors: [Color(0xFFFF6B8A), Color(0xFFFF8FAB)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get budgetGradient =>
      _themeProvider?.budgetGradient ?? const LinearGradient(
        colors: [Color(0xFFFF8FAB), Color(0xFFFFD93D)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      );

  static const LinearGradient overBudgetGradient = LinearGradient(
    colors: [Color(0xFFFF6B6B), Color(0xFFFF4444)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static LinearGradient get weekBarGradient =>
      _themeProvider?.weekBarGradient ?? const LinearGradient(
        colors: [Color(0xFFFF8FAB), Color(0xFFFFB3C6)],
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
      );

  static LinearGradient get weekBarTodayGradient =>
      _themeProvider?.weekBarTodayGradient ?? const LinearGradient(
        colors: [Color(0xFFE8607A), Color(0xFFFF8FAB)],
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
      );

  // ══════════════════════════════════════
  //  ThemeData（动态）
  // ══════════════════════════════════════

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: bgPage,
      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: accent,
        surface: bgCard,
        error: const Color(0xFFE8607A),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        foregroundColor: textWhite,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textWhite,
        ),
      ),
      cardTheme: CardTheme(
        color: bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: border, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: textWhite,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: bgCard,
        selectedItemColor: primary,
        unselectedItemColor: textHint,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      fontFamily: '.SF Pro Text',
    );
  }
}

/// 圆角尺寸（对齐小程序 WXSS）
class AppRadius {
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double full = 999;
}

/// 间距尺寸
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// 阴影（对齐小程序 box-shadow）
class AppShadow {
  static List<BoxShadow> get card => [
        BoxShadow(
          color: AppTheme.primary.withOpacity(0.06),
          blurRadius: 12,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get deep => [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get float => [
        BoxShadow(
          color: AppTheme.primary.withOpacity(0.30),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get navbar => [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 10,
          offset: const Offset(0, -1),
        ),
      ];
}

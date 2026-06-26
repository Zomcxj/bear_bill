import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../theme/app_design_system.dart';

/// 主题颜色管理 - 从单一主色自动生成完整主题
class ThemeProvider extends ChangeNotifier {
  static const String _storageKey = 'themePrimaryColor';
  static const String _darkModeKey = 'themeDarkMode';
  static const int _defaultPrimary = 0xFFFF8FAB;

  Color _primaryColor = const Color(_defaultPrimary);
  Color get primaryColor => _primaryColor;

  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadFromStorage();
  }

  void _loadFromStorage() {
    final saved = StorageService.instance.getInt(_storageKey);
    if (saved != null && saved != 0) {
      _primaryColor = Color(saved);
    }
    final darkSaved = StorageService.instance.getInt(_darkModeKey);
    _isDarkMode = darkSaved == 1;
    DS.setDarkMode(_isDarkMode);
  }

  void setPrimaryColor(Color color) {
    _primaryColor = color;
    StorageService.instance.setInt(_storageKey, color.value);
    notifyListeners();
  }

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    DS.setDarkMode(_isDarkMode);
    StorageService.instance.setInt(_darkModeKey, _isDarkMode ? 1 : 0);
    notifyListeners();
  }

  // ── 派生颜色（HSL 色彩空间） ──

  Color get primaryDark {
    if (_isDarkMode) {
      final hsl = HSLColor.fromColor(_primaryColor);
      return hsl.withLightness((hsl.lightness + 0.10).clamp(0.0, 1.0)).toColor();
    }
    final hsl = HSLColor.fromColor(_primaryColor);
    return hsl.withLightness((hsl.lightness - 0.12).clamp(0.0, 1.0)).toColor();
  }

  Color get primaryLight {
    if (_isDarkMode) {
      final hsl = HSLColor.fromColor(_primaryColor);
      return hsl
          .withLightness((hsl.lightness - 0.10).clamp(0.0, 1.0))
          .withSaturation((hsl.saturation + 0.10).clamp(0.0, 1.0))
          .toColor();
    }
    final hsl = HSLColor.fromColor(_primaryColor);
    return hsl
        .withLightness((hsl.lightness + 0.25).clamp(0.0, 1.0))
        .withSaturation((hsl.saturation - 0.15).clamp(0.0, 1.0))
        .toColor();
  }

  Color get primaryBg {
    if (_isDarkMode) return const Color(0xFF1A1A2E);
    final hsl = HSLColor.fromColor(_primaryColor);
    return hsl.withLightness(0.97).withSaturation(0.4).toColor();
  }

  // ── 派生边框/背景色 ──

  Color get border {
    if (_isDarkMode) return const Color(0xFF2A2A3E);
    final hsl = HSLColor.fromColor(_primaryColor);
    return hsl.withLightness(0.90).withSaturation(0.6).toColor();
  }

  Color get divider {
    if (_isDarkMode) return const Color(0xFF252538);
    final hsl = HSLColor.fromColor(_primaryColor);
    return hsl.withLightness(0.95).withSaturation(0.5).toColor();
  }

  Color get bgPage {
    if (_isDarkMode) return const Color(0xFF121220);
    final hsl = HSLColor.fromColor(_primaryColor);
    return hsl.withLightness(0.98).withSaturation(0.35).toColor();
  }

  Color get bgSection {
    if (_isDarkMode) return const Color(0xFF1E1E30);
    final hsl = HSLColor.fromColor(_primaryColor);
    return hsl.withLightness(0.96).withSaturation(0.25).toColor();
  }

  // ── 渐变 ──

  LinearGradient get candyGradient => LinearGradient(
        colors: [_primaryColor, primaryLight, primaryBg],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );

  LinearGradient get primaryGradient => LinearGradient(
        colors: [_primaryColor, primaryLight],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  LinearGradient get primaryDeepGradient => LinearGradient(
        colors: [primaryDark, _primaryColor],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  LinearGradient get budgetGradient => LinearGradient(
        colors: [_primaryColor, const Color(0xFFFFD93D)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      );

  LinearGradient get overBudgetGradient => const LinearGradient(
        colors: [Color(0xFFFF6B6B), Color(0xFFFF4444)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      );

  LinearGradient get weekBarGradient => LinearGradient(
        colors: [_primaryColor, primaryLight],
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
      );

  LinearGradient get weekBarTodayGradient => LinearGradient(
        colors: [primaryDark, _primaryColor],
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
      );

  // ── 预设调色盘 ──

  static const List<Color> paletteColors = [
    Color(0xFFFF8FAB), // 蜜桃粉（默认）
    Color(0xFF74C0FC), // 天空蓝
    Color(0xFF6BCB77), // 薄荷绿
    Color(0xFFFFA94D), // 活力橙
    Color(0xFFFFD93D), // 奶油黄
    Color(0xFFFF6B6B), // 珊瑚红
    Color(0xFF9B59B6), // 紫罗兰
    Color(0xFF2D3436), // 曜石黑
  ];
}

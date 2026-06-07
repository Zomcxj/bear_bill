import 'package:flutter/material.dart';
import '../services/storage_service.dart';

/// 主题颜色管理 - 从单一主色自动生成完整主题
class ThemeProvider extends ChangeNotifier {
  static const String _storageKey = 'themePrimaryColor';
  static const int _defaultPrimary = 0xFFFF8FAB;

  Color _primaryColor = const Color(_defaultPrimary);
  Color get primaryColor => _primaryColor;

  ThemeProvider() {
    _loadFromStorage();
  }

  void _loadFromStorage() {
    final saved = StorageService.instance.getInt(_storageKey);
    if (saved != null && saved != 0) {
      _primaryColor = Color(saved);
    }
  }

  void setPrimaryColor(Color color) {
    _primaryColor = color;
    StorageService.instance.setInt(_storageKey, color.value);
    notifyListeners();
  }

  // ── 派生颜色（HSL 色彩空间） ──

  Color get primaryDark {
    final hsl = HSLColor.fromColor(_primaryColor);
    return hsl.withLightness((hsl.lightness - 0.12).clamp(0.0, 1.0)).toColor();
  }

  Color get primaryLight {
    final hsl = HSLColor.fromColor(_primaryColor);
    return hsl
        .withLightness((hsl.lightness + 0.25).clamp(0.0, 1.0))
        .withSaturation((hsl.saturation - 0.15).clamp(0.0, 1.0))
        .toColor();
  }

  Color get primaryBg {
    final hsl = HSLColor.fromColor(_primaryColor);
    return hsl.withLightness(0.97).withSaturation(0.4).toColor();
  }

  // ── 派生边框/背景色 ──

  Color get border {
    final hsl = HSLColor.fromColor(_primaryColor);
    return hsl.withLightness(0.90).withSaturation(0.6).toColor();
  }

  Color get divider {
    final hsl = HSLColor.fromColor(_primaryColor);
    return hsl.withLightness(0.95).withSaturation(0.5).toColor();
  }

  Color get bgPage {
    final hsl = HSLColor.fromColor(_primaryColor);
    return hsl.withLightness(0.98).withSaturation(0.35).toColor();
  }

  Color get bgSection {
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

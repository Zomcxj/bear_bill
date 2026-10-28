import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../theme/app_design_system.dart';
import '../theme/glass_materials.dart';

/// Theme color management - derives a full theme from a single primary color
class ThemeProvider extends ChangeNotifier {
  static const String _storageKey = 'themePrimaryColor';
  static const String _darkModeKey = 'themeDarkMode';
  static const String _liquidGlassKey = 'liquidGlassEnabled';
  static const String _glassStyleKey = 'glassStyle';
  static const int _defaultPrimary = 0xFFFF8FAB;

  Color _primaryColor = const Color(_defaultPrimary);
  Color get primaryColor => _primaryColor;

  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  AppGlassStyle _glassStyle = AppGlassStyle.classic;
  AppGlassStyle get glassStyle => _glassStyle;

  /// Backward-compatible for legacy call sites: anything other than classic means "glass enabled"
  bool get liquidGlassEnabled => _glassStyle != AppGlassStyle.classic;

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
    // Three glass styles: prefer the new key; when missing, migrate from the legacy boolean key
    // (legacy 1 = on -> thin glass; 0/missing -> classic solid), keeping the visuals unchanged after upgrade
    final styleSaved = StorageService.instance.getInt(_glassStyleKey);
    // Legacy enum classic(0)/thin(1)/thick(2)/solid(3); after removing thick, solid shifts down to 2.
    // Legacy value 3 (solid) migrates to 2; legacy value 2 (former thick, removed) also folds into solid.
    final idx = styleSaved == 3 ? AppGlassStyle.solid.index : styleSaved;
    if (idx != null &&
        idx >= 0 &&
        idx < AppGlassStyle.values.length) {
      _glassStyle = AppGlassStyle.values[idx];
    } else {
      final legacy = StorageService.instance.getInt(_liquidGlassKey);
      _glassStyle = legacy == 1 ? AppGlassStyle.thin : AppGlassStyle.classic;
    }
    GlassMaterials.setStyle(_glassStyle);
  }

  void setGlassStyle(AppGlassStyle value) {
    _glassStyle = value;
    GlassMaterials.setStyle(value);
    StorageService.instance.setInt(_glassStyleKey, value.index);
    // Update the legacy key as well so behavior stays sane when downgrading to an older version
    StorageService.instance
        .setInt(_liquidGlassKey, value == AppGlassStyle.classic ? 0 : 1);
    notifyListeners();
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

  // ── Derived colors (HSL color space) ──

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

  // ── Derived border/background colors ──

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

  // ── Gradients ──

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

  // ── Preset palette ──

  static const List<Color> paletteColors = [
    Color(0xFFFF8FAB), // Peach pink (default)
    Color(0xFF74C0FC), // Sky blue
    Color(0xFF6BCB77), // Mint green
    Color(0xFFFFA94D), // Vibrant orange
    Color(0xFFFFD93D), // Cream yellow
    Color(0xFFFF6B6B), // Coral red
    Color(0xFF9B59B6), // Violet
    Color(0xFF2D3436), // Obsidian black
  ];
}

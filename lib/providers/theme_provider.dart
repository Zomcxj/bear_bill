import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../theme/app_design_system.dart';
import '../theme/glass_materials.dart';

/// Theme management - dark mode and the three liquid glass styles
class ThemeProvider extends ChangeNotifier {
  static const String _darkModeKey = 'themeDarkMode';
  static const String _liquidGlassKey = 'liquidGlassEnabled';
  static const String _glassStyleKey = 'glassStyle';

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

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    DS.setDarkMode(_isDarkMode);
    StorageService.instance.setInt(_darkModeKey, _isDarkMode ? 1 : 0);
    notifyListeners();
  }
}

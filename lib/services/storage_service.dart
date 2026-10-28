import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Local storage service
class StorageService {
  static final StorageService instance = StorageService._init();
  StorageService._init();

  final Map<String, dynamic> _cache = {};

  Future<void> load() async {
    // On init, try to load common keys into the in-memory cache (improves check-in/book memory, etc.)
    try {
      final lastCheckIn = await _loadFromFile('lastCheckInDate');
      if (lastCheckIn != null) _cache['lastCheckInDate'] = lastCheckIn;

      final checkInDays = await _loadFromFile('checkInDays');
      if (checkInDays != null) {
        final parsed = int.tryParse(checkInDays);
        if (parsed != null) _cache['checkInDays'] = parsed;
      }

      final currentBookId = await _loadFromFile('currentBookId');
      if (currentBookId != null) _cache['currentBookId'] = currentBookId;

      final fontSize = await _loadFromFile('fontSize');
      if (fontSize != null) _cache['fontSize'] = fontSize;

      final themeColor = await _loadFromFile('themePrimaryColor');
      if (themeColor != null) {
        final parsed = int.tryParse(themeColor);
        if (parsed != null) _cache['themePrimaryColor'] = parsed;
      }

      final darkMode = await _loadFromFile('themeDarkMode');
      if (darkMode != null) {
        final parsed = int.tryParse(darkMode);
        if (parsed != null) _cache['themeDarkMode'] = parsed;
      }

      final liquidGlass = await _loadFromFile('liquidGlassEnabled');
      if (liquidGlass != null) {
        final parsed = int.tryParse(liquidGlass);
        if (parsed != null) _cache['liquidGlassEnabled'] = parsed;
      }

      final glassStyle = await _loadFromFile('glassStyle');
      if (glassStyle != null) {
        final parsed = int.tryParse(glassStyle);
        if (parsed != null) _cache['glassStyle'] = parsed;
      }

      final reminderHour = await _loadFromFile('reminderHour');
      if (reminderHour != null) _cache['reminderHour'] = reminderHour;

      final reminderMinute = await _loadFromFile('reminderMinute');
      if (reminderMinute != null) _cache['reminderMinute'] = reminderMinute;
    } catch (e) {
      // Ignore load errors and keep running
    }
  }

  // String operations
  String? getString(String key) => _cache[key] as String?;

  /// Async read: check the in-memory cache first, then fall back to the file (for dynamic keys not preloaded by load())
  Future<String?> getStringAsync(String key) async {
    final cached = _cache[key];
    if (cached != null) return cached as String;
    return _loadFromFile(key);
  }

  void setString(String key, String value) {
    _cache[key] = value;
    _saveToFile(key, value);
  }

  // int operations
  int? getInt(String key) => _cache[key] as int?;

  void setInt(String key, int value) {
    _cache[key] = value;
    _saveToFile(key, value.toString());
  }

  // bool operations
  bool? getBool(String key) => _cache[key] as bool?;

  void setBool(String key, bool value) {
    _cache[key] = value;
    _saveToFile(key, value.toString());
  }

  // double operations
  double? getDouble(String key) {
    final val = _cache[key];
    if (val is num) return val.toDouble();
    return null;
  }

  void setDouble(String key, double value) {
    _cache[key] = value;
    _saveToFile(key, value.toString());
  }

  void remove(String key) {
    _cache.remove(key);
  }

  void _saveToFile(String key, String value) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/bear_bill_$key.txt');
      await file.writeAsString(value);
    } catch (e) {
      // Ignore write errors
    }
  }

  Future<String?> _loadFromFile(String key) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/bear_bill_$key.txt');
      if (await file.exists()) {
        return await file.readAsString();
      }
    } catch (e) {
      // Ignore read errors
    }
    return null;
  }
}

/// Export service
class ExportService {
  /// Share CSV data
  static Future<void> shareCSV(String csvContent, String fileName) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName.csv');
      await file.writeAsString(csvContent);
      await Share.shareXFiles([XFile(file.path)], text: '小熊记账本导出数据 🐻');
    } catch (e) {
      throw Exception('导出失败: $e');
    }
  }

  /// Share text content
  static Future<void> shareText(String text) async {
    await Share.share(text, subject: '小熊记账本 🐻');
  }
}

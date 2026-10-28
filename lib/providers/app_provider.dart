import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../services/notification_service.dart';
import '../services/services.dart';
import '../utils/utils.dart';

/// Global app state management - Provider
class AppProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;

  // User info
  UserModel? _user;
  UserModel? get user => _user;

  // Current book
  String _currentBookId = '';
  String get currentBookId => _currentBookId;

  // Check-in status
  int _checkInDays = 0;
  bool _todayChecked = false;
  int get checkInDays => _checkInDays;
  bool get todayChecked => _todayChecked;

  // Achievement list
  List<String> _unlockedAchievements = [];
  List<String> get unlockedAchievements => _unlockedAchievements;

  // Newly unlocked achievements (for the dialog prompt)
  List<AchievementModel> _newAchievements = [];
  List<AchievementModel> get newAchievements => _newAchievements;

  AppProvider() {
    _init();
  }

  /// Initialize - load user data and state
  Future<void> _init() async {
    await _loadUser();
    await _loadCheckInStatus();
    // Check level-up on startup (handles the case of already-surplus exp)
    await levelUp();
    // Sync-check all achievements on startup
    await _syncAllAchievements();
    // Refresh today's bookkeeping summary on startup (for the reminder summary)
    NotificationService.instance.refreshTodaySummary();
  }

  /// Sync all achievement states on startup
  Future<void> _syncAllAchievements() async {
    if (_user == null) return;

    final wishes = await _db.getAllWishes();
    final hasCreatedWish = wishes.isNotEmpty;
    final completedWishes = wishes.where((w) => w.isCompleted).length;

    final book = await getCurrentBook();
    final budget = book?.budget ?? 0.0;
    final hasBudget = budget > 0;

    // Compute this month's expense ratio
    double expenseRatio = 0.0;
    if (hasBudget) {
      final now = DateTime.now();
      final monthStr = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      final stats = await _db.getMonthStatistics(monthStr, bookId: _currentBookId);
      final expense = (stats['expense'] ?? 0.0) as double;
      expenseRatio = (expense / budget) * 100;
    }

    final totalImages = await _db.getTotalImagesCount();
    final locationCount = await _db.getRecordsWithLocationCount();
    final moodCount = await _db.getRecordsWithMoodCount();
    final uniqueCategories = await _db.getUniqueCategoriesCount();

    final newAchievements = AchievementChecker.checkAllAchievements(
      checkInDays: _checkInDays,
      totalRecords: _user!.totalRecords,
      hasBudget: hasBudget,
      expenseRatio: expenseRatio,
      completedWishes: completedWishes,
      hasCreatedWish: hasCreatedWish,
      totalImages: totalImages,
      locationCount: locationCount,
      moodCount: moodCount,
      uniqueCategories: uniqueCategories,
      unlockedIds: _unlockedAchievements,
    );

    if (newAchievements.isNotEmpty) {
      _unlockedAchievements.addAll(newAchievements.map((a) => a.id));
      final updatedUser = _user!.copyWith(achievements: _unlockedAchievements);
      await _db.updateUser(updatedUser);
      _user = updatedUser;
      notifyListeners();
    }
  }

  /// Load user info
  Future<void> _loadUser() async {
    _user = await _db.getDefaultUser();
    if (_user != null) {
      _currentBookId = _user!.defaultBookId;
      _checkInDays = _user!.checkInDays;
      _unlockedAchievements = List.from(_user!.achievements);

      // If the check-in days in the database are 0, try to restore from the file cache
      if (_checkInDays == 0) {
        final cachedDays = StorageService.instance.getInt('checkInDays');
        if (cachedDays != null && cachedDays > 0) {
          _checkInDays = cachedDays;
          // Sync back to the database
          final updatedUser = _user!.copyWith(checkInDays: cachedDays);
          await _db.updateUser(updatedUser);
          _user = updatedUser;
        }
      }

      // Calibrate totalRecords (fix historically inflated data)
      try {
        final actualCount = await _db.getTotalRecordsCount();
        if (_user!.totalRecords != actualCount) {
          final fixed = _user!.copyWith(totalRecords: actualCount);
          await _db.updateUser(fixed);
          _user = fixed;
        }
      } catch (_) {}

      notifyListeners();
    }
  }

  /// Load check-in status
  Future<void> _loadCheckInStatus() async {
    final today = DateUtils.getToday();
    final lastCheckIn =
        StorageService.instance.getString('lastCheckInDate') ?? '';
    _todayChecked = (lastCheckIn == today);
    notifyListeners();
  }

  /// Switch book
  Future<void> switchBook(String bookId) async {
    _currentBookId = bookId;
    StorageService.instance.setString('currentBookId', bookId);

    // Update the user's default book
    if (_user != null) {
      final updatedUser = _user!.copyWith(defaultBookId: bookId);
      await _db.updateUser(updatedUser);
      _user = updatedUser;
    }

    notifyListeners();
  }

  /// Refresh current book info (used after the book name is changed)
  void refreshCurrentBook() {
    notifyListeners();
  }

  /// Check in after recording
  Future<List<AchievementModel>> recordCheckIn() async {
    final today = DateUtils.getToday();
    final yesterday = DateUtils.getYesterday();
    final lastCheckIn =
        StorageService.instance.getString('lastCheckInDate') ?? '';

    if (lastCheckIn == today) {
      _todayChecked = true;
      notifyListeners();
      return [];
    }

    int newDays = _checkInDays;
    if (lastCheckIn == yesterday) {
      newDays += 1; // consecutive check-in
    } else {
      newDays = 1; // streak broken, restart counting
    }

    StorageService.instance.setString('lastCheckInDate', today);
    StorageService.instance.setInt('checkInDays', newDays);

    _checkInDays = newDays;
    _todayChecked = true;

    // Update user data
    if (_user != null) {
      final updatedUser = _user!.copyWith(
        checkInDays: newDays,
        lastCheckIn: today,
        exp: _user!.exp + 10, // 10 exp for checking in
      );
      await _db.updateUser(updatedUser);
      _user = updatedUser;
      await levelUp();
    }

    // Check achievements
    _newAchievements = AchievementChecker.checkCheckInAchievements(
      newDays,
      _unlockedAchievements,
    );

    if (_newAchievements.isNotEmpty) {
      _unlockedAchievements.addAll(_newAchievements.map((a) => a.id));
      if (_user != null) {
        final updatedUser =
            _user!.copyWith(achievements: _unlockedAchievements);
        await _db.updateUser(updatedUser);
        _user = updatedUser;
      }
    }

    notifyListeners();
    return _newAchievements;
  }

  /// Update stats after recording
  Future<List<AchievementModel>> onRecordAdded({
    required String type,
    required double amount,
  }) async {
    if (_user == null) return [];

    final newTotalRecords = _user!.totalRecords + 1;
    final newExp = _user!.exp + 5; // 5 exp for recording

    final updatedUser = _user!.copyWith(
      totalRecords: newTotalRecords,
      exp: newExp,
    );
    await _db.updateUser(updatedUser);
    _user = updatedUser;
    await levelUp();

    // Check record-count achievements
    _newAchievements = AchievementChecker.checkRecordsAchievements(
      newTotalRecords,
      _unlockedAchievements,
    );

    // Check record-stat achievements (images/location/mood/categories)
    final totalImages = await _db.getTotalImagesCount();
    final locationCount = await _db.getRecordsWithLocationCount();
    final moodCount = await _db.getRecordsWithMoodCount();
    final uniqueCategories = await _db.getUniqueCategoriesCount();

    final statsAchievements = AchievementChecker.checkRecordStatsAchievements(
      totalImages: totalImages,
      locationCount: locationCount,
      moodCount: moodCount,
      uniqueCategories: uniqueCategories,
      unlockedIds: _unlockedAchievements,
    );
    _newAchievements.addAll(statsAchievements);

    if (_newAchievements.isNotEmpty) {
      _unlockedAchievements.addAll(_newAchievements.map((a) => a.id));
      final finalUser = _user!.copyWith(achievements: _unlockedAchievements);
      await _db.updateUser(finalUser);
      _user = finalUser;
    }

    notifyListeners();
    return _newAchievements;
  }

  /// Update stats after deleting a record
  Future<void> onRecordDeleted() async {
    if (_user == null) return;

    final newTotal = (_user!.totalRecords - 1).clamp(0, 999999);
    final updatedUser = _user!.copyWith(totalRecords: newTotal);
    await _db.updateUser(updatedUser);
    _user = updatedUser;
    notifyListeners();
  }

  /// Clear the new achievement list (called after the dialog closes)
  void clearNewAchievements() {
    _newAchievements = [];
    notifyListeners();
  }

  /// Check wish jar achievements (called after creating/completing a wish)
  Future<void> checkWishAchievements() async {
    if (_user == null) return;

    final wishes = await _db.getAllWishes();
    final hasCreatedWish = wishes.isNotEmpty;
    final completedWishes = wishes.where((w) => w.isCompleted).length;

    final newAchievements = AchievementChecker.checkWishAchievements(
      completedWishes: completedWishes,
      hasCreatedWish: hasCreatedWish,
      unlockedIds: _unlockedAchievements,
    );

    if (newAchievements.isNotEmpty) {
      _unlockedAchievements.addAll(newAchievements.map((a) => a.id));
      _newAchievements = newAchievements;
      final updatedUser = _user!.copyWith(achievements: _unlockedAchievements);
      await _db.updateUser(updatedUser);
      _user = updatedUser;
      notifyListeners();
    }
  }

  /// Check budget achievements (called after setting a budget)
  Future<void> checkBudgetAchievements() async {
    if (_user == null) return;

    final book = await getCurrentBook();
    final budget = book?.budget ?? 0.0;
    final hasBudget = budget > 0;

    // Compute this month's expense ratio
    double expenseRatio = 0.0;
    if (hasBudget) {
      final now = DateTime.now();
      final monthStr = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      final stats = await _db.getMonthStatistics(monthStr, bookId: _currentBookId);
      final expense = (stats['expense'] ?? 0.0) as double;
      expenseRatio = (expense / budget) * 100;
    }

    final newAchievements = AchievementChecker.checkBudgetAchievements(
      hasBudget: hasBudget,
      expenseRatio: expenseRatio,
      unlockedIds: _unlockedAchievements,
    );

    if (newAchievements.isNotEmpty) {
      _unlockedAchievements.addAll(newAchievements.map((a) => a.id));
      _newAchievements = newAchievements;
      final updatedUser = _user!.copyWith(achievements: _unlockedAchievements);
      await _db.updateUser(updatedUser);
      _user = updatedUser;
      notifyListeners();
    }
  }

  /// Update user data (used externally to update user stats)
  Future<void> updateUserStats(UserModel updatedUser) async {
    await _db.updateUser(updatedUser);
    _user = updatedUser;
    notifyListeners();
  }

  Future<void> updateUserProfile({
    String? nickname,
    String? avatar,
  }) async {
    if (_user == null) return;

    final updatedUser = _user!.copyWith(
      nickname: nickname ?? _user!.nickname,
      avatar: avatar ?? _user!.avatar,
    );
    await _db.updateUser(updatedUser);
    _user = updatedUser;
    notifyListeners();
  }

  /// Get current book info
  Future<BookModel?> getCurrentBook() async {
    if (_currentBookId.isEmpty) return null;
    final books = await _db.getAllBooks();
    return books.firstWhere(
      (book) => book.id == _currentBookId,
      orElse: () => books.first,
    );
  }

  /// Level-up check
  bool get shouldLevelUp => _user?.shouldLevelUp ?? false;

  /// Perform level-up (supports consecutive level-ups)
  Future<void> levelUp() async {
    while (_user != null && _user!.shouldLevelUp) {
      final newLevel = _user!.level + 1;
      final newExp = _user!.exp - _user!.expForNextLevel;

      final updatedUser = _user!.copyWith(level: newLevel, exp: newExp);
      await _db.updateUser(updatedUser);
      _user = updatedUser;
    }
    notifyListeners();
  }
}

import '../models/models.dart';

/// Achievement checking utility
class AchievementChecker {
  /// Check consecutive check-in achievements
  static List<AchievementModel> checkCheckInAchievements(int days, List<String> unlockedIds) {
    final newAchievements = <AchievementModel>[];
    final milestones = [3, 7, 14, 30, 60, 100, 365];
    
    for (final milestone in milestones) {
      if (days >= milestone) {
        final achievementId = 'checkin_$milestone';
        if (!unlockedIds.contains(achievementId)) {
          final achievement = AchievementDefinitions.findById(achievementId);
          if (achievement != null) {
            newAchievements.add(achievement.copyWith(unlockedAt: DateTime.now()));
          }
        }
      }
    }
    
    return newAchievements;
  }

  /// Check record count achievements
  static List<AchievementModel> checkRecordsAchievements(int totalRecords, List<String> unlockedIds) {
    final newAchievements = <AchievementModel>[];
    final milestones = [10, 50, 100, 500];
    
    for (final milestone in milestones) {
      if (totalRecords >= milestone) {
        final achievementId = 'records_$milestone';
        if (!unlockedIds.contains(achievementId)) {
          final achievement = AchievementDefinitions.findById(achievementId);
          if (achievement != null) {
            newAchievements.add(achievement.copyWith(unlockedAt: DateTime.now()));
          }
        }
      }
    }
    
    return newAchievements;
  }

  /// Check budget achievements
  static List<AchievementModel> checkBudgetAchievements({
    required bool hasBudget,
    required double expenseRatio,
    required List<String> unlockedIds,
  }) {
    final newAchievements = <AchievementModel>[];
    
    // First time setting a budget
    if (hasBudget && !unlockedIds.contains('budget_1')) {
      final achievement = AchievementDefinitions.findById('budget_1');
      if (achievement != null) {
        newAchievements.add(achievement.copyWith(unlockedAt: DateTime.now()));
      }
    }
    
    // Thrifty saver (spending below 80% of the budget)
    if (expenseRatio <= 80 && !unlockedIds.contains('budget_save')) {
      final achievement = AchievementDefinitions.findById('budget_save');
      if (achievement != null) {
        newAchievements.add(achievement.copyWith(unlockedAt: DateTime.now()));
      }
    }
    
    return newAchievements;
  }

  /// Check wish jar achievements
  static List<AchievementModel> checkWishAchievements({
    required int completedWishes,
    required bool hasCreatedWish,
    required List<String> unlockedIds,
  }) {
    final newAchievements = <AchievementModel>[];

    // Create the first wish
    if (hasCreatedWish && !unlockedIds.contains('wish_1')) {
      final achievement = AchievementDefinitions.findById('wish_1');
      if (achievement != null) {
        newAchievements.add(achievement.copyWith(unlockedAt: DateTime.now()));
      }
    }

    // Complete the first wish
    if (completedWishes >= 1 && !unlockedIds.contains('wish_complete')) {
      final achievement = AchievementDefinitions.findById('wish_complete');
      if (achievement != null) {
        newAchievements.add(achievement.copyWith(unlockedAt: DateTime.now()));
      }
    }

    // Complete 5 wishes
    if (completedWishes >= 5 && !unlockedIds.contains('wish_5')) {
      final achievement = AchievementDefinitions.findById('wish_5');
      if (achievement != null) {
        newAchievements.add(achievement.copyWith(unlockedAt: DateTime.now()));
      }
    }

    return newAchievements;
  }

  /// Check record statistics achievements (images/location/mood/category)
  static List<AchievementModel> checkRecordStatsAchievements({
    required int totalImages,
    required int locationCount,
    required int moodCount,
    required int uniqueCategories,
    required List<String> unlockedIds,
  }) {
    final newAchievements = <AchievementModel>[];

    // Image achievements
    for (final milestone in [10, 50]) {
      if (totalImages >= milestone) {
        final id = 'images_$milestone';
        if (!unlockedIds.contains(id)) {
          final achievement = AchievementDefinitions.findById(id);
          if (achievement != null) {
            newAchievements.add(achievement.copyWith(unlockedAt: DateTime.now()));
          }
        }
      }
    }

    // Location achievements
    for (final milestone in [10, 50]) {
      if (locationCount >= milestone) {
        final id = 'location_$milestone';
        if (!unlockedIds.contains(id)) {
          final achievement = AchievementDefinitions.findById(id);
          if (achievement != null) {
            newAchievements.add(achievement.copyWith(unlockedAt: DateTime.now()));
          }
        }
      }
    }

    // Mood achievements
    for (final milestone in [10, 50]) {
      if (moodCount >= milestone) {
        final id = 'mood_$milestone';
        if (!unlockedIds.contains(id)) {
          final achievement = AchievementDefinitions.findById(id);
          if (achievement != null) {
            newAchievements.add(achievement.copyWith(unlockedAt: DateTime.now()));
          }
        }
      }
    }

    // Category achievements
    for (final milestone in [10, 50]) {
      if (uniqueCategories >= milestone) {
        final id = 'category_$milestone';
        if (!unlockedIds.contains(id)) {
          final achievement = AchievementDefinitions.findById(id);
          if (achievement != null) {
            newAchievements.add(achievement.copyWith(unlockedAt: DateTime.now()));
          }
        }
      }
    }

    return newAchievements;
  }

  /// Check all achievements in bulk
  static List<AchievementModel> checkAllAchievements({
    required int checkInDays,
    required int totalRecords,
    required bool hasBudget,
    required double expenseRatio,
    required int completedWishes,
    required bool hasCreatedWish,
    required int totalImages,
    required int locationCount,
    required int moodCount,
    required int uniqueCategories,
    required List<String> unlockedIds,
  }) {
    final allNewAchievements = <AchievementModel>[];

    allNewAchievements.addAll(checkCheckInAchievements(checkInDays, unlockedIds));
    allNewAchievements.addAll(checkRecordsAchievements(totalRecords, unlockedIds));
    allNewAchievements.addAll(checkBudgetAchievements(
      hasBudget: hasBudget,
      expenseRatio: expenseRatio,
      unlockedIds: unlockedIds,
    ));
    allNewAchievements.addAll(checkWishAchievements(
      completedWishes: completedWishes,
      hasCreatedWish: hasCreatedWish,
      unlockedIds: unlockedIds,
    ));
    allNewAchievements.addAll(checkRecordStatsAchievements(
      totalImages: totalImages,
      locationCount: locationCount,
      moodCount: moodCount,
      uniqueCategories: uniqueCategories,
      unlockedIds: unlockedIds,
    ));

    return allNewAchievements;
  }
}

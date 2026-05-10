import '../models/models.dart';

/// 成就检查工具
class AchievementChecker {
  /// 检查连续打卡成就
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

  /// 检查记账次数成就
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

  /// 检查预算成就
  static List<AchievementModel> checkBudgetAchievements({
    required bool hasBudget,
    required double expenseRatio,
    required List<String> unlockedIds,
  }) {
    final newAchievements = <AchievementModel>[];
    
    // 首次设置预算
    if (hasBudget && !unlockedIds.contains('budget_1')) {
      final achievement = AchievementDefinitions.findById('budget_1');
      if (achievement != null) {
        newAchievements.add(achievement.copyWith(unlockedAt: DateTime.now()));
      }
    }
    
    // 省钱小能手（支出低于预算80%）
    if (expenseRatio <= 80 && !unlockedIds.contains('budget_save')) {
      final achievement = AchievementDefinitions.findById('budget_save');
      if (achievement != null) {
        newAchievements.add(achievement.copyWith(unlockedAt: DateTime.now()));
      }
    }
    
    return newAchievements;
  }

  /// 检查心愿罐成就
  static List<AchievementModel> checkWishAchievements({
    required int completedWishes,
    required bool hasCreatedWish,
    required List<String> unlockedIds,
  }) {
    final newAchievements = <AchievementModel>[];
    
    // 创建第一个心愿
    if (hasCreatedWish && !unlockedIds.contains('wish_1')) {
      final achievement = AchievementDefinitions.findById('wish_1');
      if (achievement != null) {
        newAchievements.add(achievement.copyWith(unlockedAt: DateTime.now()));
      }
    }
    
    // 完成第一个心愿
    if (completedWishes >= 1 && !unlockedIds.contains('wish_complete')) {
      final achievement = AchievementDefinitions.findById('wish_complete');
      if (achievement != null) {
        newAchievements.add(achievement.copyWith(unlockedAt: DateTime.now()));
      }
    }
    
    // 完成5个心愿
    if (completedWishes >= 5 && !unlockedIds.contains('wish_5')) {
      final achievement = AchievementDefinitions.findById('wish_5');
      if (achievement != null) {
        newAchievements.add(achievement.copyWith(unlockedAt: DateTime.now()));
      }
    }
    
    return newAchievements;
  }

  /// 批量检查所有成就
  static List<AchievementModel> checkAllAchievements({
    required int checkInDays,
    required int totalRecords,
    required bool hasBudget,
    required double expenseRatio,
    required int completedWishes,
    required bool hasCreatedWish,
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
    
    return allNewAchievements;
  }
}

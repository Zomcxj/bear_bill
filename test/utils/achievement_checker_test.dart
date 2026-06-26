import 'package:flutter_test/flutter_test.dart';
import 'package:bear_bill/utils/achievement_checker.dart';

void main() {
  group('AchievementChecker.checkCheckInAchievements', () {
    test('连续 3 天解锁 checkin_3', () {
      final result = AchievementChecker.checkCheckInAchievements(3, []);
      expect(result.any((a) => a.id == 'checkin_3'), true);
    });

    test('连续 7 天同时解锁 checkin_3 和 checkin_7', () {
      final result = AchievementChecker.checkCheckInAchievements(7, []);
      expect(result.any((a) => a.id == 'checkin_3'), true);
      expect(result.any((a) => a.id == 'checkin_7'), true);
    });

    test('已解锁的成就不重复解锁', () {
      final result = AchievementChecker.checkCheckInAchievements(7, ['checkin_3']);
      expect(result.any((a) => a.id == 'checkin_3'), false);
      expect(result.any((a) => a.id == 'checkin_7'), true);
    });

    test('全部已解锁返回空', () {
      final result = AchievementChecker.checkCheckInAchievements(
        365,
        ['checkin_3', 'checkin_7', 'checkin_14', 'checkin_30', 'checkin_60', 'checkin_100', 'checkin_365'],
      );
      expect(result, isEmpty);
    });

    test('连续 2 天不解锁任何成就', () {
      final result = AchievementChecker.checkCheckInAchievements(2, []);
      expect(result, isEmpty);
    });
  });

  group('AchievementChecker.checkRecordsAchievements', () {
    test('10 次记账解锁 records_10', () {
      final result = AchievementChecker.checkRecordsAchievements(10, []);
      expect(result.any((a) => a.id == 'records_10'), true);
    });

    test('100 次记账解锁多个', () {
      final result = AchievementChecker.checkRecordsAchievements(100, []);
      expect(result.length, 3); // records_10, records_50, records_100
    });

    test('5 次记账不解锁', () {
      final result = AchievementChecker.checkRecordsAchievements(5, []);
      expect(result, isEmpty);
    });
  });

  group('AchievementChecker.checkBudgetAchievements', () {
    test('首次设置预算解锁 budget_1', () {
      final result = AchievementChecker.checkBudgetAchievements(
        hasBudget: true,
        expenseRatio: 100,
        unlockedIds: [],
      );
      expect(result.any((a) => a.id == 'budget_1'), true);
    });

    test('未设置预算不解锁', () {
      final result = AchievementChecker.checkBudgetAchievements(
        hasBudget: false,
        expenseRatio: 100,
        unlockedIds: [],
      );
      expect(result, isEmpty);
    });

    test('支出低于 80% 解锁 budget_save', () {
      final result = AchievementChecker.checkBudgetAchievements(
        hasBudget: true,
        expenseRatio: 75,
        unlockedIds: [],
      );
      expect(result.any((a) => a.id == 'budget_save'), true);
      expect(result.any((a) => a.id == 'budget_1'), true);
    });

    test('已解锁不解锁', () {
      final result = AchievementChecker.checkBudgetAchievements(
        hasBudget: true,
        expenseRatio: 75,
        unlockedIds: ['budget_1', 'budget_save'],
      );
      expect(result, isEmpty);
    });
  });

  group('AchievementChecker.checkWishAchievements', () {
    test('创建心愿解锁 wish_1', () {
      final result = AchievementChecker.checkWishAchievements(
        completedWishes: 0,
        hasCreatedWish: true,
        unlockedIds: [],
      );
      expect(result.any((a) => a.id == 'wish_1'), true);
    });

    test('完成心愿解锁 wish_complete', () {
      final result = AchievementChecker.checkWishAchievements(
        completedWishes: 1,
        hasCreatedWish: true,
        unlockedIds: [],
      );
      expect(result.any((a) => a.id == 'wish_complete'), true);
    });

    test('完成 5 个心愿解锁 wish_5', () {
      final result = AchievementChecker.checkWishAchievements(
        completedWishes: 5,
        hasCreatedWish: true,
        unlockedIds: [],
      );
      expect(result.length, 3); // wish_1, wish_complete, wish_5
    });
  });

  group('AchievementChecker.checkRecordStatsAchievements', () {
    test('10 张图片解锁 images_10', () {
      final result = AchievementChecker.checkRecordStatsAchievements(
        totalImages: 10,
        locationCount: 0,
        moodCount: 0,
        uniqueCategories: 0,
        unlockedIds: [],
      );
      expect(result.any((a) => a.id == 'images_10'), true);
    });

    test('50 次位置解锁 location_50', () {
      final result = AchievementChecker.checkRecordStatsAchievements(
        totalImages: 0,
        locationCount: 50,
        moodCount: 0,
        uniqueCategories: 0,
        unlockedIds: [],
      );
      expect(result.any((a) => a.id == 'location_10'), true);
      expect(result.any((a) => a.id == 'location_50'), true);
    });

    test('全部为 0 不解锁', () {
      final result = AchievementChecker.checkRecordStatsAchievements(
        totalImages: 0,
        locationCount: 0,
        moodCount: 0,
        uniqueCategories: 0,
        unlockedIds: [],
      );
      expect(result, isEmpty);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:bear_bill/models/achievement_model.dart';

void main() {
  group('AchievementModel', () {
    test('toMap/fromMap 往返一致', () {
      final now = DateTime(2026, 6, 24);
      final achievement = AchievementModel(
        id: 'checkin_7',
        type: 'checkIn',
        title: '小有成就',
        description: '连续记账 7 天',
        emoji: '🌟',
        threshold: 7,
        unlockedAt: now,
      );

      final map = achievement.toMap();
      final restored = AchievementModel.fromMap(map);

      expect(restored.id, achievement.id);
      expect(restored.type, achievement.type);
      expect(restored.title, achievement.title);
      expect(restored.description, achievement.description);
      expect(restored.emoji, achievement.emoji);
      expect(restored.threshold, achievement.threshold);
      expect(restored.unlockedAt, achievement.unlockedAt);
    });

    test('isUnlocked — 已解锁', () {
      final unlocked = AchievementModel(
        id: 'test',
        type: 'checkIn',
        title: '测试',
        description: '测试',
        emoji: '⭐',
        threshold: 1,
        unlockedAt: DateTime.now(),
      );
      expect(unlocked.isUnlocked, true);
    });

    test('isUnlocked — 未解锁', () {
      const locked = AchievementModel(
        id: 'test',
        type: 'checkIn',
        title: '测试',
        description: '测试',
        emoji: '⭐',
        threshold: 1,
      );
      expect(locked.isUnlocked, false);
    });

    test('copyWith 设置 unlockedAt', () {
      const locked = AchievementModel(
        id: 'test',
        type: 'checkIn',
        title: '测试',
        description: '测试',
        emoji: '⭐',
        threshold: 1,
      );
      final now = DateTime.now();
      final unlocked = locked.copyWith(unlockedAt: now);
      expect(unlocked.isUnlocked, true);
      expect(unlocked.id, locked.id);
    });

    test('fromMap null unlockedAt', () {
      final map = {
        'id': 'test',
        'type': 'checkIn',
        'title': '测试',
        'description': '测试',
        'emoji': '⭐',
        'threshold': 1,
      };
      final restored = AchievementModel.fromMap(map);
      expect(restored.unlockedAt, isNull);
      expect(restored.isUnlocked, false);
    });
  });

  group('AchievementDefinitions', () {
    test('成就列表不为空', () {
      expect(AchievementDefinitions.all, isNotEmpty);
    });

    test('findById 找到已有成就', () {
      final achievement = AchievementDefinitions.findById('checkin_7');
      expect(achievement, isNotNull);
      expect(achievement!.title, '小有成就');
      expect(achievement.emoji, '🌟');
    });

    test('findById 不存在返回 null', () {
      expect(AchievementDefinitions.findById('nonexistent'), isNull);
    });

    test('getByType 返回正确类型', () {
      final checkInAchievements = AchievementDefinitions.getByType('checkIn');
      expect(checkInAchievements, isNotEmpty);
      expect(checkInAchievements.every((a) => a.type == 'checkIn'), true);
    });

    test('getByType 不存在的类型返回空', () {
      expect(AchievementDefinitions.getByType('nonexistent'), isEmpty);
    });

    test('所有成就 ID 唯一', () {
      final ids = AchievementDefinitions.all.map((a) => a.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('打卡成就按阈值递增', () {
      final checkIn = AchievementDefinitions.getByType('checkIn');
      for (int i = 1; i < checkIn.length; i++) {
        expect(checkIn[i].threshold, greaterThan(checkIn[i - 1].threshold));
      }
    });
  });
}

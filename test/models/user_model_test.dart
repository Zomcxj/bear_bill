import 'package:flutter_test/flutter_test.dart';
import 'package:bear_bill/models/user_model.dart';

void main() {
  group('UserModel', () {
    late UserModel user;
    late DateTime testDate;

    setUp(() {
      testDate = DateTime(2026, 6, 23, 14, 30);
      user = UserModel(
        id: 'local-user',
        nickname: '小熊主人',
        avatar: 'https://example.com/avatar.png',
        checkInDays: 7,
        lastCheckIn: '2026-06-23',
        achievements: ['first_record', 'streak_7'],
        totalRecords: 42,
        level: 3,
        exp: 150,
        defaultBookId: 'default_book',
        createdAt: testDate,
        lastActiveAt: testDate,
      );
    });

    test('默认值正确', () {
      final defaultUser = UserModel(defaultBookId: 'default_book');
      expect(defaultUser.id, 'local-user');
      expect(defaultUser.nickname, '小熊主人');
      expect(defaultUser.avatar, '');
      expect(defaultUser.checkInDays, 0);
      expect(defaultUser.lastCheckIn, '');
      expect(defaultUser.achievements, isEmpty);
      expect(defaultUser.totalRecords, 0);
      expect(defaultUser.level, 1);
      expect(defaultUser.exp, 0);
    });

    test('toMap/fromMap 往返一致', () {
      final map = user.toMap();
      final restored = UserModel.fromMap(map);

      expect(restored.id, user.id);
      expect(restored.nickname, user.nickname);
      expect(restored.avatar, user.avatar);
      expect(restored.checkInDays, user.checkInDays);
      expect(restored.lastCheckIn, user.lastCheckIn);
      expect(restored.achievements, user.achievements);
      expect(restored.totalRecords, user.totalRecords);
      expect(restored.level, user.level);
      expect(restored.exp, user.exp);
      expect(restored.defaultBookId, user.defaultBookId);
    });

    test('achievements 逗号分隔序列化', () {
      final map = user.toMap();
      expect(map['achievements'], 'first_record,streak_7');

      final restored = UserModel.fromMap(map);
      expect(restored.achievements, ['first_record', 'streak_7']);
    });

    test('空 achievements 序列化为空字符串', () {
      final noAch = user.copyWith(achievements: []);
      final map = noAch.toMap();
      expect(map['achievements'], '');

      final restored = UserModel.fromMap(map);
      expect(restored.achievements, isEmpty);
    });

    test('copyWith 部分更新', () {
      final updated = user.copyWith(nickname: '新名字', level: 5);
      expect(updated.nickname, '新名字');
      expect(updated.level, 5);
      expect(updated.exp, user.exp);
      expect(updated.id, user.id);
    });

    test('expForNextLevel 计算', () {
      expect(user.expForNextLevel, 300); // level 3 * 100
    });

    test('expProgress 计算', () {
      expect(user.expProgress, closeTo(0.5, 0.01)); // 150 / 300
    });

    test('shouldLevelUp 判断', () {
      expect(user.shouldLevelUp, false); // 150 < 300

      final ready = user.copyWith(exp: 300);
      expect(ready.shouldLevelUp, true);

      final over = user.copyWith(exp: 500);
      expect(over.shouldLevelUp, true);
    });

    test('fromMap 缺失字段使用默认值', () {
      final minimal = {
        'id': 'u1',
        'defaultBookId': 'b1',
        'createdAt': 0,
        'lastActiveAt': 0,
      };
      final restored = UserModel.fromMap(minimal);
      expect(restored.nickname, '小熊主人');
      expect(restored.level, 1);
      expect(restored.exp, 0);
      expect(restored.achievements, isEmpty);
    });
  });
}

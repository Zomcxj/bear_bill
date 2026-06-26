import 'package:flutter_test/flutter_test.dart';
import 'package:bear_bill/models/wish_model.dart';

void main() {
  group('WishModel', () {
    late WishModel wish;
    late DateTime testDate;

    setUp(() {
      testDate = DateTime(2026, 6, 23);
      wish = WishModel(
        id: 'wish_001',
        bookId: 'default_book',
        title: '买新耳机',
        description: 'AirPods Pro',
        targetAmount: 1500,
        currentAmount: 600,
        priority: 2,
        isCompleted: false,
        createdAt: testDate,
        deadline: DateTime(2026, 12, 31),
        depositHistory: ['2026-06-01:200', '2026-06-15:400'],
      );
    });

    test('默认值正确', () {
      final defaultWish = WishModel(
        id: 'w1',
        bookId: 'b1',
        title: '测试',
        targetAmount: 100,
      );
      expect(defaultWish.currentAmount, 0);
      expect(defaultWish.priority, 1);
      expect(defaultWish.isCompleted, false);
      expect(defaultWish.depositHistory, isEmpty);
      expect(defaultWish.description, isNull);
      expect(defaultWish.deadline, isNull);
      expect(defaultWish.completedAt, isNull);
    });

    test('toMap/fromMap 往返一致', () {
      final map = wish.toMap();
      final restored = WishModel.fromMap(map);

      expect(restored.id, wish.id);
      expect(restored.bookId, wish.bookId);
      expect(restored.title, wish.title);
      expect(restored.description, wish.description);
      expect(restored.targetAmount, wish.targetAmount);
      expect(restored.currentAmount, wish.currentAmount);
      expect(restored.priority, wish.priority);
      expect(restored.isCompleted, wish.isCompleted);
      expect(restored.deadline, wish.deadline);
      expect(restored.depositHistory, wish.depositHistory);
    });

    test('isCompleted 序列化为 int', () {
      final map = wish.toMap();
      expect(map['isCompleted'], 0);

      final completed = wish.copyWith(isCompleted: true);
      expect(completed.toMap()['isCompleted'], 1);
    });

    test('depositHistory 逗号分隔序列化', () {
      final map = wish.toMap();
      expect(map['depositHistory'], '2026-06-01:200,2026-06-15:400');

      final restored = WishModel.fromMap(map);
      expect(restored.depositHistory, ['2026-06-01:200', '2026-06-15:400']);
    });

    test('progress 计算', () {
      expect(wish.progress, closeTo(0.4, 0.01)); // 600/1500

      final full = wish.copyWith(currentAmount: 1500);
      expect(full.progress, 1.0);

      final over = wish.copyWith(currentAmount: 2000);
      expect(over.progress, 1.0); // clamped

      final zero = wish.copyWith(targetAmount: 0);
      expect(zero.progress, 0.0);
    });

    test('priorityLabel 显示', () {
      expect(wish.priorityLabel, '🟡 重要');

      expect(wish.copyWith(priority: 1).priorityLabel, '🟢 普通');
      expect(wish.copyWith(priority: 3).priorityLabel, '🔴 紧急');
    });

    test('copyWith 部分更新', () {
      final updated = wish.copyWith(currentAmount: 1000, priority: 3);
      expect(updated.currentAmount, 1000);
      expect(updated.priority, 3);
      expect(updated.title, wish.title);
      expect(updated.targetAmount, wish.targetAmount);
    });

    test('fromMap null deadline 和 completedAt', () {
      final map = wish.toMap();
      map.remove('deadline');
      map.remove('completedAt');
      final restored = WishModel.fromMap(map);
      expect(restored.deadline, isNull);
      expect(restored.completedAt, isNull);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:bear_bill/models/record_model.dart';

void main() {
  group('RecordModel', () {
    late RecordModel record;
    late DateTime testDate;

    setUp(() {
      testDate = DateTime(2026, 6, 23, 14, 30);
      record = RecordModel(
        id: 'test_001',
        bookId: 'default',
        type: 'expense',
        amount: 25.5,
        categoryId: 'food',
        categoryName: '餐饮',
        categoryIcon: '🍜',
        categoryColor: '#FF6B6B',
        remark: '午餐',
        date: '2026-06-23',
        month: '2026-06',
        dateTs: testDate.millisecondsSinceEpoch,
        mood: 'happy',
        moodEmoji: '😊',
        images: ['img1.jpg', 'img2.jpg'],
        location: '公司食堂',
        latitude: 39.9,
        longitude: 116.3,
        tags: ['工作餐', '午餐'],
        createdAt: testDate,
      );
    });

    test('基本属性正确', () {
      expect(record.id, 'test_001');
      expect(record.bookId, 'default');
      expect(record.type, 'expense');
      expect(record.amount, 25.5);
      expect(record.categoryId, 'food');
      expect(record.categoryName, '餐饮');
      expect(record.remark, '午餐');
    });

    test('isExpense 和 isIncome', () {
      expect(record.isExpense, true);
      expect(record.isIncome, false);

      final incomeRecord = record.copyWith(type: 'income');
      expect(incomeRecord.isExpense, false);
      expect(incomeRecord.isIncome, true);
    });

    test('isToday 判断正确', () {
      final now = DateTime.now();
      final todayStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final todayRecord = record.copyWith(date: todayStr);
      expect(todayRecord.isToday, true);

      final yesterdayRecord = record.copyWith(date: '2020-01-01');
      expect(yesterdayRecord.isToday, false);
    });

    test('toMap 正确序列化', () {
      final map = record.toMap();
      expect(map['id'], 'test_001');
      expect(map['type'], 'expense');
      expect(map['amount'], 25.5);
      expect(map['categoryId'], 'food');
      expect(map['images'], 'img1.jpg,img2.jpg');
      expect(map['tags'], '工作餐,午餐');
      expect(map['location'], '公司食堂');
      expect(map['latitude'], 39.9);
      expect(map['longitude'], 116.3);
    });

    test('fromMap 正确反序列化', () {
      final map = record.toMap();
      final restored = RecordModel.fromMap(map);

      expect(restored.id, record.id);
      expect(restored.type, record.type);
      expect(restored.amount, record.amount);
      expect(restored.categoryId, record.categoryId);
      expect(restored.images, record.images);
      expect(restored.tags, record.tags);
      expect(restored.location, record.location);
      expect(restored.latitude, record.latitude);
      expect(restored.longitude, record.longitude);
      expect(restored.mood, record.mood);
    });

    test('fromMap 处理空 images 和 tags', () {
      final map = record.toMap();
      map['images'] = '';
      map['tags'] = '';
      final restored = RecordModel.fromMap(map);
      expect(restored.images, isEmpty);
      expect(restored.tags, isEmpty);
    });

    test('fromMap 处理 null images 和 tags', () {
      final map = record.toMap();
      map['images'] = null;
      map['tags'] = null;
      final restored = RecordModel.fromMap(map);
      expect(restored.images, isEmpty);
      expect(restored.tags, isEmpty);
    });

    test('copyWith 只修改指定字段', () {
      final updated = record.copyWith(amount: 100.0, remark: '晚餐');
      expect(updated.amount, 100.0);
      expect(updated.remark, '晚餐');
      // 其他字段不变
      expect(updated.id, record.id);
      expect(updated.type, record.type);
      expect(updated.categoryId, record.categoryId);
    });

    test('toMap -> fromMap 往返一致', () {
      final map = record.toMap();
      final restored = RecordModel.fromMap(map);
      final map2 = restored.toMap();
      expect(map, map2);
    });
  });
}

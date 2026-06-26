import 'package:flutter_test/flutter_test.dart';
import 'package:bear_bill/models/book_model.dart';

void main() {
  group('BookModel', () {
    late BookModel book;
    late DateTime testDate;

    setUp(() {
      testDate = DateTime(2026, 1, 1);
      book = BookModel(
        id: 'book_001',
        name: '主账本',
        icon: '📒',
        color: '#4ECDC4',
        memberOpenids: ['user1'],
        budget: 5000.0,
        totalRecords: 42,
        createdAt: testDate,
      );
    });

    test('基本属性正确', () {
      expect(book.id, 'book_001');
      expect(book.name, '主账本');
      expect(book.icon, '📒');
      expect(book.color, '#4ECDC4');
      expect(book.budget, 5000.0);
      expect(book.totalRecords, 42);
    });

    test('默认值正确', () {
      final defaultBook = BookModel(id: 'default', name: '默认');
      expect(defaultBook.icon, '🐻');
      expect(defaultBook.color, '#FF8FAB');
      expect(defaultBook.memberOpenids, isEmpty);
      expect(defaultBook.budget, 0.0);
      expect(defaultBook.totalRecords, 0);
    });

    test('toMap 正确序列化', () {
      final map = book.toMap();
      expect(map['id'], 'book_001');
      expect(map['name'], '主账本');
      expect(map['icon'], '📒');
      expect(map['color'], '#4ECDC4');
      expect(map['memberOpenids'], 'user1');
      expect(map['budget'], 5000.0);
      expect(map['totalRecords'], 42);
    });

    test('fromMap 正确反序列化', () {
      final map = book.toMap();
      final restored = BookModel.fromMap(map);
      expect(restored.id, book.id);
      expect(restored.name, book.name);
      expect(restored.icon, book.icon);
      expect(restored.color, book.color);
      expect(restored.memberOpenids, book.memberOpenids);
      expect(restored.budget, book.budget);
      expect(restored.totalRecords, book.totalRecords);
    });

    test('fromMap 处理 null 可选字段', () {
      final map = {
        'id': 'test',
        'name': '测试',
        'createdAt': 0,
      };
      final restored = BookModel.fromMap(map);
      expect(restored.icon, '🐻');
      expect(restored.color, '#FF8FAB');
      expect(restored.memberOpenids, isEmpty);
      expect(restored.budget, 0.0);
      expect(restored.totalRecords, 0);
    });

    test('copyWith 只修改指定字段', () {
      final updated = book.copyWith(name: '新名称', icon: '📕');
      expect(updated.name, '新名称');
      expect(updated.icon, '📕');
      expect(updated.id, book.id);
      expect(updated.color, book.color);
      expect(updated.budget, book.budget);
    });

    test('toMap -> fromMap 往返一致', () {
      final map = book.toMap();
      final restored = BookModel.fromMap(map);
      final map2 = restored.toMap();
      expect(map, map2);
    });

    test('多个成员序列化', () {
      final multiMember = book.copyWith(memberOpenids: ['u1', 'u2', 'u3']);
      final map = multiMember.toMap();
      expect(map['memberOpenids'], 'u1,u2,u3');
      final restored = BookModel.fromMap(map);
      expect(restored.memberOpenids, ['u1', 'u2', 'u3']);
    });
  });
}

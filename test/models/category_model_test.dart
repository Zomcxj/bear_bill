import 'package:flutter_test/flutter_test.dart';
import 'package:bear_bill/models/category_model.dart';

void main() {
  group('CategoryModel', () {
    test('支出分类列表不为空', () {
      expect(expenseCategories, isNotEmpty);
      expect(expenseCategories.length, greaterThanOrEqualTo(10));
    });

    test('收入分类列表不为空', () {
      expect(incomeCategories, isNotEmpty);
      expect(incomeCategories.length, greaterThanOrEqualTo(5));
    });

    test('支出分类 isExpense 全部为 true', () {
      for (final cat in expenseCategories) {
        expect(cat.isExpense, true, reason: '${cat.name} 应为支出');
      }
    });

    test('收入分类 isExpense 全部为 false', () {
      for (final cat in incomeCategories) {
        expect(cat.isExpense, false, reason: '${cat.name} 应为收入');
      }
    });

    test('分类 ID 唯一', () {
      final allIds = [
        ...expenseCategories.map((c) => c.id),
        ...incomeCategories.map((c) => c.id),
      ];
      final uniqueIds = allIds.toSet();
      expect(allIds.length, uniqueIds.length, reason: '分类ID存在重复');
    });
  });

  group('getCategoryById', () {
    test('查找存在的支出分类', () {
      final cat = getCategoryById('food', isExpense: true);
      expect(cat, isNotNull);
      expect(cat!.name, '餐饮');
      expect(cat.icon, '🍜');
      expect(cat.isExpense, true);
    });

    test('查找存在的收入分类', () {
      final cat = getCategoryById('salary', isExpense: false);
      expect(cat, isNotNull);
      expect(cat!.name, '工资');
      expect(cat.icon, '💼');
      expect(cat.isExpense, false);
    });

    test('查找不存在的分类返回 null', () {
      final cat = getCategoryById('nonexistent', isExpense: true);
      expect(cat, isNull);
    });

    test('在错误的列表中查找返回 null', () {
      // food 是支出分类，在收入列表中找不到
      final cat = getCategoryById('food', isExpense: false);
      expect(cat, isNull);
    });

    test('遍历所有支出分类都能找到', () {
      for (final expected in expenseCategories) {
        final cat = getCategoryById(expected.id, isExpense: true);
        expect(cat, isNotNull, reason: '找不到支出分类: ${expected.id}');
        expect(cat!.name, expected.name);
      }
    });

    test('遍历所有收入分类都能找到', () {
      for (final expected in incomeCategories) {
        final cat = getCategoryById(expected.id, isExpense: false);
        expect(cat, isNotNull, reason: '找不到收入分类: ${expected.id}');
        expect(cat!.name, expected.name);
      }
    });
  });

  group('MoodModel', () {
    test('心情列表有 5 种', () {
      expect(moods.length, 5);
    });

    test('getMoodById 查找存在的心情', () {
      final mood = getMoodById('happy');
      expect(mood, isNotNull);
      expect(mood!.emoji, '😊');
      expect(mood.label, '开心');
    });

    test('getMoodById 查找不存在的心情返回 null', () {
      final mood = getMoodById('nonexistent');
      expect(mood, isNull);
    });

    test('遍历所有心情都能找到', () {
      for (final expected in moods) {
        final mood = getMoodById(expected.id);
        expect(mood, isNotNull, reason: '找不到心情: ${expected.id}');
        expect(mood!.emoji, expected.emoji);
      }
    });
  });
}

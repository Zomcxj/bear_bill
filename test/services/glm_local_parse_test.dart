import 'package:flutter_test/flutter_test.dart';
import 'package:bear_bill/services/glm_service.dart';

/// Offline (keyword) parser regression tests.
///
/// These never hit the network: [GlmService.parseLocalForTest] calls the
/// local parser directly.
AiParseResult parse(String input) =>
    GlmService.instance.parseLocalForTest(input);

void main() {
  final today = DateTime.now();
  String ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  group('amount extraction', () {
    test('simple amount', () {
      final r = parse('午餐花了25');
      expect(r.isRecord, isTrue);
      expect(r.amount, 25);
      expect(r.categoryId, 'food');
    });

    test('ignores item counts', () {
      final r = parse('买2个苹果花10块');
      expect(r.isRecord, isTrue);
      expect(r.amount, 10);
      expect(r.categoryId, 'fruit');
    });

    test('ignores head counts', () {
      final r = parse('3个人吃饭150');
      expect(r.amount, 150);
      expect(r.categoryId, 'food');
    });

    test('prefers the number with a currency unit', () {
      final r = parse('买了3杯奶茶36元');
      expect(r.amount, 36);
      expect(r.categoryId, 'milk_tea');
    });

    test('Chinese numerals with a unit', () {
      final r = parse('打车二十五块');
      expect(r.amount, 25);
      expect(r.categoryId, 'transport');
    });

    test('a date is not an amount', () {
      final r = parse('6月1号吃饭');
      expect(r.amount, isNull);
      expect(r.intent, 'record');
      expect(r.categoryId, 'food');
    });
  });

  group('category detection', () {
    test('聚餐 is social, not food', () {
      expect(parse('聚餐花了200').categoryId, 'social');
    });

    test('buying medicine is health, not shopping', () {
      final r = parse('买药30元');
      expect(r.categoryId, 'health');
    });

    test('fruit category is reachable', () {
      expect(parse('买水果15块').categoryId, 'fruit');
    });

    test('plain shopping still works', () {
      expect(parse('超市买日用品50').categoryId, 'shopping');
    });

    test('a bare category name is recognised', () {
      expect(parse('交通').categoryId, 'transport');
      expect(parse('购物').categoryId, 'shopping');
      expect(parse('餐饮').categoryId, 'food');
    });

    test('the category name works inside a query', () {
      expect(parse('交通花了多少').queryCategoryId, 'transport');
      expect(parse('加油花了多少').queryCategoryId, 'transport');
    });
  });

  group('income detection', () {
    test('receiving a red packet is income', () {
      final r = parse('收红包200');
      expect(r.type, 'income');
      expect(r.categoryId, 'red_packet');
    });

    test('sending a red packet is expense', () {
      final r = parse('发红包50');
      expect(r.type, 'expense');
      expect(r.categoryId, 'red_packet');
    });

    test('refund is income', () {
      final r = parse('退款88');
      expect(r.type, 'income');
    });

    test('salary is income', () {
      final r = parse('工资8000');
      expect(r.type, 'income');
      expect(r.categoryId, 'salary');
    });
  });

  group('query keeps its filters', () {
    test('category filter is kept', () {
      final r = parse('这个月餐饮花了多少');
      expect(r.isQuery, isTrue);
      expect(r.queryCategoryId, 'food');
      expect(r.queryPeriod, 'month');
    });

    test('mood filter is kept', () {
      final r = parse('开心时候的消费');
      expect(r.isQuery, isTrue);
      expect(r.queryMood, 'happy');
    });

    test('location filter is kept', () {
      final r = parse('在公司楼下的消费');
      expect(r.isQuery, isTrue);
      expect(r.queryLocation, '公司楼下');
    });

    test('a location that is also a category is not added as a filter', () {
      final r = parse('在星巴克的消费');
      expect(r.isQuery, isTrue);
      expect(r.queryLocation, isNull);
      expect(r.queryCategoryId, 'milk_tea');
    });

    test('explicit month/day range', () {
      final r = parse('6月1号到6月10号的账单');
      expect(r.isQuery, isTrue);
      expect(r.queryStartDate, '${today.year}-06-01');
      expect(r.queryEndDate, '${today.year}-06-10');
    });

    test('last month range', () {
      final r = parse('上个月花了多少');
      expect(r.isQuery, isTrue);
      final firstPrev = DateTime(today.year, today.month - 1, 1);
      final lastPrev = DateTime(today.year, today.month, 0);
      expect(r.queryStartDate, ymd(firstPrev));
      expect(r.queryEndDate, ymd(lastPrev));
    });
  });

  group('dates', () {
    test('yesterday', () {
      final r = parse('昨天打车18');
      expect(r.date, ymd(today.subtract(const Duration(days: 1))));
    });

    test('basic food', () {
      expect(parse('晚餐30').categoryId, 'food');
    });
  });

  group('filter-only phrasings are queries, not records', () {
    test('有定位的消费', () {
      final r = parse('有定位的消费');
      expect(r.isQuery, isTrue);
      expect(r.intent, 'query');
    });

    test('带定位的账单', () {
      expect(parse('带定位的账单').isQuery, isTrue);
    });

    test('开心的消费 keeps the mood filter', () {
      final r = parse('开心的消费');
      expect(r.isQuery, isTrue);
      expect(r.queryMood, 'happy');
    });
  });

  group('Chinese numeral conversion (amount follow-up)', () {
    test('二十五', () {
      expect(GlmService.instance.parseChineseNumber('二十五'), 25);
    });

    test('一百二', () {
      expect(GlmService.instance.parseChineseNumber('一百二'), 102);
    });

    test('三十', () {
      expect(GlmService.instance.parseChineseNumber('三十'), 30);
    });
  });

  group('multiple records in one sentence', () {
    test('splits on currency units', () {
      final r = parse('早餐10块午餐25');
      expect(r.items.length, 2);
      expect(r.items[0].amount, 10);
      expect(r.items[0].categoryId, 'food');
      expect(r.items[1].amount, 25);
      expect(r.items[1].categoryId, 'food');
    });

    test('single amount is not split', () {
      expect(parse('午餐花了25').items, isEmpty);
    });

    test('mixed categories split correctly', () {
      final r = parse('打车20块奶茶15');
      expect(r.items.length, 2);
      expect(r.items[0].categoryId, 'transport');
      expect(r.items[1].categoryId, 'milk_tea');
    });
  });
}

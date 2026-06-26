import 'package:flutter_test/flutter_test.dart';
import 'package:bear_bill/services/glm_service.dart';

void main() {
  group('AiParseResult', () {
    test('isRecord — 有效记账', () {
      const result = AiParseResult(
        intent: 'record',
        type: 'expense',
        amount: 25.5,
        categoryId: 'food',
      );
      expect(result.isRecord, true);
      expect(result.isQuery, false);
    });

    test('isRecord — 金额为 null 不算记账', () {
      const result = AiParseResult(
        intent: 'record',
        type: 'expense',
        categoryId: 'food',
      );
      expect(result.isRecord, false);
    });

    test('isRecord — 金额为 0 不算记账', () {
      const result = AiParseResult(
        intent: 'record',
        type: 'expense',
        amount: 0,
        categoryId: 'food',
      );
      expect(result.isRecord, false);
    });

    test('isQuery — 查询意图', () {
      const result = AiParseResult(
        intent: 'query',
        queryPeriod: 'month',
      );
      expect(result.isQuery, true);
      expect(result.isRecord, false);
    });

    test('resolvedDate — 有效日期字符串', () {
      const result = AiParseResult(
        intent: 'record',
        date: '2026-06-23',
      );
      final d = result.resolvedDate;
      expect(d.year, 2026);
      expect(d.month, 6);
      expect(d.day, 23);
    });

    test('resolvedDate — null 时返回今天', () {
      const result = AiParseResult(intent: 'record');
      final d = result.resolvedDate;
      final now = DateTime.now();
      expect(d.year, now.year);
      expect(d.month, now.month);
      expect(d.day, now.day);
    });

    test('resolvedDate — 无效日期返回今天', () {
      const result = AiParseResult(intent: 'record', date: 'invalid');
      final d = result.resolvedDate;
      final now = DateTime.now();
      expect(d.year, now.year);
    });

    test('查询筛选条件', () {
      const result = AiParseResult(
        intent: 'query',
        queryCategoryId: 'food',
        queryMood: 'happy',
        queryLocation: '星巴克',
        queryStartDate: '2026-06-01',
        queryEndDate: '2026-06-30',
      );
      expect(result.queryCategoryId, 'food');
      expect(result.queryMood, 'happy');
      expect(result.queryLocation, '星巴克');
      expect(result.queryStartDate, '2026-06-01');
      expect(result.queryEndDate, '2026-06-30');
    });
  });
}

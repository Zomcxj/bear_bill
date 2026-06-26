import 'package:flutter_test/flutter_test.dart';
import 'package:bear_bill/utils/date_utils.dart';

void main() {
  group('DateUtils', () {
    test('formatDate 格式化', () {
      expect(DateUtils.formatDate(DateTime(2026, 6, 5)), '2026-06-05');
      expect(DateUtils.formatDate(DateTime(2026, 12, 25)), '2026-12-25');
      expect(DateUtils.formatDate(DateTime(2026, 1, 1)), '2026-01-01');
    });

    test('formatMonth 格式化', () {
      expect(DateUtils.formatMonth(DateTime(2026, 6, 15)), '2026-06');
      expect(DateUtils.formatMonth(DateTime(2026, 1, 1)), '2026-01');
    });

    test('formatMonthCN 中文格式', () {
      expect(DateUtils.formatMonthCN('2026-06'), '2026年6月');
      expect(DateUtils.formatMonthCN('2026-01'), '2026年1月');
      expect(DateUtils.formatMonthCN('2025-12'), '2025年12月');
    });

    test('formatDayCN 中文格式', () {
      expect(DateUtils.formatDayCN('2026-06-05'), '6月5日');
      expect(DateUtils.formatDayCN('2026-12-25'), '12月25日');
    });

    test('getWeekday 星期几', () {
      // 2026-06-23 是周二
      expect(DateUtils.getWeekday(DateTime(2026, 6, 23)), '周二');
      // 2026-06-22 是周一
      expect(DateUtils.getWeekday(DateTime(2026, 6, 22)), '周一');
      // 2026-06-28 是周日
      expect(DateUtils.getWeekday(DateTime(2026, 6, 28)), '周日');
    });

    test('daysBetween 天数差', () {
      final from = DateTime(2026, 6, 1);
      final to = DateTime(2026, 6, 10);
      expect(DateUtils.daysBetween(from, to), 9);

      final same = DateTime(2026, 6, 1);
      expect(DateUtils.daysBetween(same, same), 0);

      final crossMonth = DateTime(2026, 5, 30);
      final nextMonth = DateTime(2026, 6, 2);
      expect(DateUtils.daysBetween(crossMonth, nextMonth), 3);
    });

    test('parseDate 解析', () {
      final d = DateUtils.parseDate('2026-06-23');
      expect(d.year, 2026);
      expect(d.month, 6);
      expect(d.day, 23);
    });
  });
}

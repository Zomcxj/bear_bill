import 'package:flutter_test/flutter_test.dart';
import 'package:bear_bill/utils/format_utils.dart';

void main() {
  group('FormatUtils', () {
    test('formatAmount 两位小数', () {
      expect(FormatUtils.formatAmount(25.5), '25.50');
      expect(FormatUtils.formatAmount(100), '100.00');
      expect(FormatUtils.formatAmount(0), '0.00');
      expect(FormatUtils.formatAmount(0.1), '0.10');
    });

    test('formatAmountWithSign 带符号', () {
      expect(FormatUtils.formatAmountWithSign(25.5, type: 'expense'), '-25.50');
      expect(FormatUtils.formatAmountWithSign(100, type: 'income'), '+100.00');
    });

    test('formatAmountWithComma 千分位', () {
      expect(FormatUtils.formatAmountWithComma(1234567), '1,234,567');
      expect(FormatUtils.formatAmountWithComma(1000), '1,000');
      expect(FormatUtils.formatAmountWithComma(999), '999');
      expect(FormatUtils.formatAmountWithComma(1234.5), '1,234.5');
      expect(FormatUtils.formatAmountWithComma(1234.56), '1,234.56');
    });

    test('handleAmountInput 数字输入', () {
      expect(FormatUtils.handleAmountInput('', '5'), '5');
      expect(FormatUtils.handleAmountInput('0', '5'), '5');
      expect(FormatUtils.handleAmountInput('12', '3'), '123');
    });

    test('handleAmountInput 小数点', () {
      expect(FormatUtils.handleAmountInput('', '.'), '0.');
      expect(FormatUtils.handleAmountInput('5', '.'), '5.');
      expect(FormatUtils.handleAmountInput('5.1', '.'), '5.1'); // 已有小数点
    });

    test('handleAmountInput 删除', () {
      expect(FormatUtils.handleAmountInput('123', '⌫'), '12');
      expect(FormatUtils.handleAmountInput('1', '⌫'), '');
      expect(FormatUtils.handleAmountInput('', '⌫'), '');
    });

    test('handleAmountInput 双零', () {
      expect(FormatUtils.handleAmountInput('', '00'), '');
      expect(FormatUtils.handleAmountInput('0', '00'), '0');
      expect(FormatUtils.handleAmountInput('5', '00'), '500');
      expect(FormatUtils.handleAmountInput('5.', '00'), '5.00');
    });

    test('handleAmountInput 最大长度限制', () {
      final maxed = '1234567890';
      expect(FormatUtils.handleAmountInput(maxed, '1'), maxed);
    });

    test('calculatePercentage 百分比', () {
      expect(FormatUtils.calculatePercentage(25, 100), 25.0);
      expect(FormatUtils.calculatePercentage(1, 3), closeTo(33.3, 0.1));
      expect(FormatUtils.calculatePercentage(0, 100), 0.0);
      expect(FormatUtils.calculatePercentage(50, 0), 0.0);
    });

    test('formatPercentage 格式化', () {
      expect(FormatUtils.formatPercentage(25), '25%');
      expect(FormatUtils.formatPercentage(25.5), '25.5%');
      expect(FormatUtils.formatPercentage(100), '100%');
      expect(FormatUtils.formatPercentage(0), '0%');
    });
  });
}

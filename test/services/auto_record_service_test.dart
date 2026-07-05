import 'package:flutter_test/flutter_test.dart';
import 'package:bear_bill/services/auto_record_service.dart';

void main() {
  group('AutoRecordService.parsePaymentForTest', () {
    test('解析支付宝支出并归类餐饮', () {
      final result = AutoRecordService.parsePaymentForTest(
        '支付宝',
        '你有一笔25.00元的支出，瑞幸咖啡',
      );

      expect(result?.type, 'expense');
      expect(result?.amount, 25);
      expect(result?.categoryId, 'milk_tea');
    });

    test('解析银行收入', () {
      final result = AutoRecordService.parsePaymentForTest(
        '银行动账提醒',
        '收入人民币3000.00元，工资到账',
      );

      expect(result?.type, 'income');
      expect(result?.amount, 3000);
      expect(result?.categoryId, 'salary');
    });

    test('余额通知不生成账单', () {
      final result = AutoRecordService.parsePaymentForTest(
        '银行动账提醒',
        '账户余额人民币8888.00元',
      );

      expect(result, isNull);
    });
  });
}

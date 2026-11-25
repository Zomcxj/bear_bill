import 'package:flutter_test/flutter_test.dart';
import 'package:bear_bill/services/glm_service.dart';

/// Regression tests for the model-JSON mapper and keyword overrides.
///
/// These never hit the network: the service exposes `@visibleForTesting`
/// hooks that call the internal mappers directly.
void main() {
  final svc = GlmService.instance;

  group('_fromJson — flat payload', () {
    test('maps every field of a record', () {
      final r = svc.parseJsonForTest({
        'intent': 'record',
        'type': 'expense',
        'amount': 25.5,
        'categoryId': 'food',
        'remark': '午餐',
        'date': '2026-11-25',
      });
      expect(r.intent, 'record');
      expect(r.type, 'expense');
      expect(r.amount, 25.5);
      expect(r.categoryId, 'food');
      expect(r.remark, '午餐');
      expect(r.date, '2026-11-25');
      expect(r.items, isEmpty);
    });

    test('missing intent falls back to unknown', () {
      expect(svc.parseJsonForTest({}).intent, 'unknown');
    });

    test('query filters survive the mapping', () {
      final r = svc.parseJsonForTest({
        'intent': 'query',
        'queryPeriod': 'month',
        'queryCategoryId': 'transport',
        'queryMood': 'happy',
        'queryLocation': '公司楼下',
        'queryStartDate': '2026-06-01',
        'queryEndDate': '2026-06-10',
        'queryRequireLocation': true,
      });
      expect(r.isQuery, isTrue);
      expect(r.queryPeriod, 'month');
      expect(r.queryCategoryId, 'transport');
      expect(r.queryMood, 'happy');
      expect(r.queryLocation, '公司楼下');
      expect(r.queryStartDate, '2026-06-01');
      expect(r.queryEndDate, '2026-06-10');
      expect(r.queryRequireLocation, isTrue);
    });

    test('queryRequireLocation is false unless explicitly true', () {
      expect(
        svc.parseJsonForTest({'intent': 'query'}).queryRequireLocation,
        isFalse,
      );
      expect(
        svc.parseJsonForTest({'intent': 'query', 'queryRequireLocation': 1})
            .queryRequireLocation,
        isFalse,
      );
    });
  });

  group('_fromJson — nested items', () {
    test('parses a multi-record payload', () {
      final r = svc.parseJsonForTest({
        'intent': 'record',
        'items': [
          {'amount': 10, 'categoryId': 'food', 'remark': '早餐'},
          {'amount': 25, 'categoryId': 'food', 'remark': '午餐'},
        ],
      });
      expect(r.items.length, 2);
      expect(r.items[0].amount, 10);
      expect(r.items[0].remark, '早餐');
      expect(r.items[1].amount, 25);
      // Each nested item defaults to intent=record so isRecord works
      expect(r.items[0].intent, 'record');
      expect(r.items[0].isRecord, isTrue);
      expect(r.items[1].isRecord, isTrue);
    });

    test('keeps an explicit intent on a nested item', () {
      final r = svc.parseJsonForTest({
        'intent': 'record',
        'items': [
          {'intent': 'query', 'queryPeriod': 'month'},
        ],
      });
      expect(r.items.single.intent, 'query');
    });

    test('non-map entries in items are skipped', () {
      final r = svc.parseJsonForTest({
        'intent': 'record',
        'items': ['oops', 42, null],
      });
      expect(r.items, isEmpty);
    });

    test('items that are not a list are ignored', () {
      final r = svc.parseJsonForTest({'intent': 'record', 'items': 'nope'});
      expect(r.items, isEmpty);
    });
  });

  group('_toDouble', () {
    test('accepts num', () {
      expect(svc.toDoubleForTest(25), 25.0);
      expect(svc.toDoubleForTest(25.5), 25.5);
    });

    test('accepts numeric strings', () {
      expect(svc.toDoubleForTest('25.5'), 25.5);
      expect(svc.toDoubleForTest('25'), 25.0);
    });

    test('rejects junk and null', () {
      expect(svc.toDoubleForTest(null), isNull);
      expect(svc.toDoubleForTest('abc'), isNull);
      expect(svc.toDoubleForTest(''), isNull);
    });
  });

  group('_cleanRemark', () {
    test('drops a trailing comma left by the model', () {
      expect(svc.cleanRemarkForTest('打车，'), '打车');
      expect(svc.cleanRemarkForTest('打车,'), '打车');
    });

    test('drops trailing whitespace and sentence punctuation', () {
      expect(svc.cleanRemarkForTest('  午餐  '), '午餐');
      expect(svc.cleanRemarkForTest('午餐。'), '午餐');
      expect(svc.cleanRemarkForTest('奶茶！'), '奶茶');
    });

    test('keeps inner punctuation', () {
      expect(svc.cleanRemarkForTest('和朋友，一起吃饭'), '和朋友，一起吃饭');
    });

    test('empty and null become null', () {
      expect(svc.cleanRemarkForTest(null), isNull);
      expect(svc.cleanRemarkForTest(''), isNull);
      expect(svc.cleanRemarkForTest('  ，, '), isNull);
    });

    test('is applied by the JSON mapper', () {
      final r = svc.parseJsonForTest({
        'intent': 'record',
        'amount': 25,
        'remark': '打车，',
      });
      expect(r.remark, '打车');
    });
  });

  group('_correct — strong keyword overrides', () {
    AiParseResult record({String? categoryId, double amount = 10}) =>
        AiParseResult(
          intent: 'record',
          type: 'expense',
          amount: amount,
          categoryId: categoryId,
        );

    test('聚餐 overrides a food guess with social', () {
      final r = svc.correctForTest('聚餐花了200', record(categoryId: 'food'));
      expect(r.categoryId, 'social');
    });

    test('买药 overrides shopping with health', () {
      final r = svc.correctForTest('买药30元', record(categoryId: 'shopping'));
      expect(r.categoryId, 'health');
    });

    test('a correct guess is left untouched', () {
      final r = svc.correctForTest('打车25', record(categoryId: 'transport'));
      expect(r.categoryId, 'transport');
    });

    test('no strong keyword keeps the model answer', () {
      final r = svc.correctForTest('随便花点', record(categoryId: 'shopping'));
      expect(r.categoryId, 'shopping');
    });

    test('the longest keyword wins', () {
      // "猫粮" (pet) and "粮" would both be candidates; longest match wins.
      final r = svc.correctForTest('买猫粮80', record(categoryId: 'shopping'));
      expect(r.categoryId, 'pet');
    });

    test('multi-record input splits instead of overriding', () {
      final r = svc.correctForTest('早餐10块午餐25', record(categoryId: 'food'));
      expect(r.items.length, 2);
      expect(r.items[0].amount, 10);
      expect(r.items[1].amount, 25);
    });

    test('query results are never overridden', () {
      const q = AiParseResult(intent: 'query', queryPeriod: 'month');
      final r = svc.correctForTest('聚餐花了多少', q);
      expect(r.intent, 'query');
      expect(r.categoryId, isNull);
    });
  });

  group('_correct — nested items are not re-split (regression)', () {
    // A model reply with several nested items must keep each item's own amount.
    // Re-running the whole-sentence splitter on every nested item used to wipe
    // all amounts (items became amount-less sub-results) and the chat page
    // replied "请问消费花了多少钱？" instead of saving two records.
    AiParseResult apiReply() => svc.parseJsonForTest({
          'intent': 'record',
          'items': [
            {
              'type': 'expense',
              'amount': 25,
              'categoryId': 'transport',
              'remark': '打车',
            },
            {
              'type': 'expense',
              'amount': 15,
              'categoryId': 'milk_tea',
              'remark': '奶茶',
            },
          ],
        });

    test('every item keeps its amount and stays a record', () {
      final r = svc.correctForTest('打车25块，奶茶15', apiReply());
      expect(r.items.length, 2);
      for (final item in r.items) {
        expect(item.amount, isNotNull);
        expect(item.isRecord, isTrue);
        expect(item.items, isEmpty);
      }
      expect(r.items[0].amount, 25);
      expect(r.items[1].amount, 15);
    });

    test('each item keeps its own category', () {
      final r = svc.correctForTest('打车25块，奶茶15', apiReply());
      expect(r.items[0].categoryId, 'transport');
      expect(r.items[1].categoryId, 'milk_tea');
    });

    test('one item keyword does not leak into the others', () {
      // "奶茶" appears only in the second item; the first must stay transport.
      final r = svc.correctForTest('打车25块，奶茶15', apiReply());
      expect(r.items[0].categoryId, isNot('milk_tea'));
      expect(r.items[1].categoryId, 'milk_tea');
    });

    test('an item without a remark keeps the model answer', () {
      final api = svc.parseJsonForTest({
        'intent': 'record',
        'items': [
          {'amount': 25, 'categoryId': 'transport'},
        ],
      });
      final r = svc.correctForTest('打车25块，奶茶15', api);
      expect(r.items.single.categoryId, 'transport');
      expect(r.items.single.amount, 25);
    });
  });

  group('parseUserInput — local fallback keeps lastError clean', () {
    test('an unconfigured service returns a local parse', () async {
      // aiApiKey is empty in the test environment, so no network call happens.
      final r = await svc.parseUserInput('午餐花了25');
      expect(r.isRecord, isTrue);
      expect(r.amount, 25);
      expect(r.categoryId, 'food');
    });

    test('a successful parse clears lastError', () async {
      await svc.parseUserInput('午餐花了25');
      expect(svc.lastError, isNull);
    });

    test('empty input yields unknown intent', () async {
      final r = await svc.parseUserInput('   ');
      expect(r.intent, 'unknown');
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:bear_bill/services/storage_service.dart';

void main() {
  group('StorageService', () {
    late StorageService storage;

    setUp(() {
      storage = StorageService.instance;
    });

    group('String 操作', () {
      test('getString 未设置时返回 null', () {
        // 使用不太可能存在的 key
        final val = storage.getString('_test_nonexistent_key_');
        expect(val, isNull);
      });

      test('setString 后 getString 能读取', () {
        storage.setString('_test_key_', 'hello');
        expect(storage.getString('_test_key_'), 'hello');
      });

      test('setString 覆盖旧值', () {
        storage.setString('_test_key_', 'v1');
        storage.setString('_test_key_', 'v2');
        expect(storage.getString('_test_key_'), 'v2');
      });
    });

    group('Int 操作', () {
      test('getInt 未设置时返回 null', () {
        expect(storage.getInt('_test_int_key_'), isNull);
      });

      test('setInt 后 getInt 能读取', () {
        storage.setInt('_test_int_key_', 42);
        expect(storage.getInt('_test_int_key_'), 42);
      });
    });

    group('Bool 操作', () {
      test('getBool 未设置时返回 null', () {
        expect(storage.getBool('_test_bool_key_'), isNull);
      });

      test('setBool 后 getBool 能读取', () {
        storage.setBool('_test_bool_key_', true);
        expect(storage.getBool('_test_bool_key_'), true);

        storage.setBool('_test_bool_key_', false);
        expect(storage.getBool('_test_bool_key_'), false);
      });
    });

    group('Double 操作', () {
      test('getDouble 未设置时返回 null', () {
        expect(storage.getDouble('_test_double_key_'), isNull);
      });

      test('setDouble 后 getDouble 能读取', () {
        storage.setDouble('_test_double_key_', 3.14);
        expect(storage.getDouble('_test_double_key_'), closeTo(3.14, 0.001));
      });
    });

    group('remove 操作', () {
      test('remove 后读取为 null', () {
        storage.setString('_test_rm_key_', 'to_be_removed');
        expect(storage.getString('_test_rm_key_'), 'to_be_removed');

        storage.remove('_test_rm_key_');
        expect(storage.getString('_test_rm_key_'), isNull);
      });
    });
  });
}

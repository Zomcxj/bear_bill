import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('database schema uses v4 with required indexes', () {
    final source = File('lib/services/database_service.dart').readAsStringSync();

    expect(source, contains('version: 4'));
    expect(source, contains('onConfigure:'));
    expect(source, contains('PRAGMA foreign_keys = ON'));
    expect(source, contains('onOpen:'));
    expect(source, contains('PRAGMA journal_mode=WAL'));
    expect(source, contains('PRAGMA synchronous=NORMAL'));

    for (final index in [
      'idx_records_dateTs',
      'idx_records_book_date',
      'idx_records_month',
      'idx_records_category',
      'idx_wishes_book',
    ]) {
      expect(source, contains(index), reason: 'missing index $index');
    }

    expect(source, contains('if (oldVersion < 4)'));
    expect(source, contains('await _createIndexes(db)'));
  });
}

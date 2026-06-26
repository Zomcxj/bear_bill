import 'package:sqflite/sqflite.dart';

import '../models/models.dart';
import 'database_service.dart';

/// 数据库服务 - 账单记录相关方法
mixin DatabaseRecordMixin on DatabaseServiceCore {
  Future<void> insertRecord(RecordModel record) async {
    final db = await database;
    await db.insert('records', record.toMap());
  }

  Future<void> updateRecord(RecordModel record) async {
    final db = await database;
    await db.update(
      'records',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<void> deleteRecord(String id) async {
    final db = await database;
    await db.delete('records', where: 'id = ?', whereArgs: [id]);
  }

  Future<RecordModel?> getRecordById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'records',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return RecordModel.fromMap(maps.first);
  }

  Future<List<RecordModel>> getMonthRecords(String month,
      {String? bookId}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'records',
      where: bookId != null ? 'month = ? AND bookId = ?' : 'month = ?',
      whereArgs: bookId != null ? [month, bookId] : [month],
      orderBy: 'dateTs DESC',
    );
    return maps.map((m) => RecordModel.fromMap(m)).toList();
  }

  Future<List<RecordModel>> getTodayRecords({String? bookId}) async {
    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return getRecordsByDate(date: dateStr, bookId: bookId);
  }

  Future<List<RecordModel>> getRecordsByDate(
      {required String date, String? bookId}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'records',
      where: bookId != null ? 'date = ? AND bookId = ?' : 'date = ?',
      whereArgs: bookId != null ? [date, bookId] : [date],
      orderBy: 'createdAt DESC',
    );
    return maps.map((m) => RecordModel.fromMap(m)).toList();
  }

  Future<List<RecordModel>> getWeekRecords({String? bookId}) async {
    final db = await database;
    final today = DateTime.now();
    final start = today.subtract(const Duration(days: 6));
    final startStr =
        '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';

    final List<Map<String, dynamic>> maps = await db.query(
      'records',
      where: bookId != null ? 'date >= ? AND bookId = ?' : 'date >= ?',
      whereArgs: bookId != null ? [startStr, bookId] : [startStr],
      orderBy: 'dateTs ASC',
    );
    return maps.map((m) => RecordModel.fromMap(m)).toList();
  }

  Future<int> clearRecordsByBook(String bookId) async {
    final db = await database;
    return await db
        .delete('records', where: 'bookId = ?', whereArgs: [bookId]);
  }

  Future<int> getTotalRecordsCount({String? bookId}) async {
    final db = await database;
    final result = await db.rawQuery(
      bookId != null
          ? 'SELECT COUNT(*) as count FROM records WHERE bookId = ?'
          : 'SELECT COUNT(*) as count FROM records',
      bookId != null ? [bookId] : [],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// 灵活查询记录（支持分类/心情/位置/日期范围/类型筛选）
  Future<List<RecordModel>> queryRecords({
    String? categoryId,
    String? mood,
    String? locationKeyword,
    String? startDate,
    String? endDate,
    String? type,
    String? bookId,
    int? limit,
  }) async {
    final db = await database;
    final where = <String>[];
    final args = <dynamic>[];

    if (categoryId != null) {
      where.add('categoryId = ?');
      args.add(categoryId);
    }
    if (mood != null) {
      where.add('mood = ?');
      args.add(mood);
    }
    if (locationKeyword != null && locationKeyword.isNotEmpty) {
      where.add('location LIKE ?');
      args.add('%$locationKeyword%');
    }
    if (startDate != null) {
      where.add('date >= ?');
      args.add(startDate);
    }
    if (endDate != null) {
      where.add('date <= ?');
      args.add(endDate);
    }
    if (type != null) {
      where.add('type = ?');
      args.add(type);
    }
    if (bookId != null) {
      where.add('bookId = ?');
      args.add(bookId);
    }

    final result = await db.query(
      'records',
      where: where.isNotEmpty ? where.join(' AND ') : null,
      whereArgs: args.isNotEmpty ? args : null,
      orderBy: 'dateTs DESC',
      limit: limit,
    );
    return result.map((map) => RecordModel.fromMap(map)).toList();
  }

  Future<List<RecordModel>> getRecordsWithLocation(
      {String? categoryId, String? bookId}) async {
    final db = await database;
    final where = <String>['latitude IS NOT NULL', 'longitude IS NOT NULL'];
    final args = <dynamic>[];
    if (categoryId != null) {
      where.add('categoryId = ?');
      args.add(categoryId);
    }
    if (bookId != null) {
      where.add('bookId = ?');
      args.add(bookId);
    }
    final result = await db.query(
      'records',
      where: where.join(' AND '),
      whereArgs: args,
      orderBy: 'dateTs DESC',
    );
    return result.map((map) => RecordModel.fromMap(map)).toList();
  }
}

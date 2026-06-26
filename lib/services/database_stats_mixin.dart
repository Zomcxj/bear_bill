import 'package:sqflite/sqflite.dart';

import '../models/models.dart';
import 'database_service.dart';

/// 数据库服务 - 统计相关方法
mixin DatabaseStatsMixin on DatabaseServiceCore {
  Future<Map<String, dynamic>> getMonthStatistics(String month,
      {String? bookId}) async {
    final records =
        await (this as dynamic).getMonthRecords(month, bookId: bookId)
            as List<RecordModel>;

    double totalExpense = 0;
    double totalIncome = 0;
    Map<String, Map<String, dynamic>> categoryMap = {};

    for (final r in records) {
      if (r.type == 'expense') {
        totalExpense += r.amount;
      } else {
        totalIncome += r.amount;
      }

      if (!categoryMap.containsKey(r.categoryId)) {
        categoryMap[r.categoryId] = {
          'id': r.categoryId,
          'name': r.categoryName,
          'icon': r.categoryIcon,
          'amount': 0.0,
          'count': 0,
          'type': r.type,
        };
      }
      categoryMap[r.categoryId]!['amount'] =
          (categoryMap[r.categoryId]!['amount'] as double) + r.amount;
      categoryMap[r.categoryId]!['count'] =
          (categoryMap[r.categoryId]!['count'] as int) + 1;
    }

    final categories = categoryMap.values
        .map((c) => {
              'id': c['id'],
              'name': c['name'],
              'icon': c['icon'],
              'amount': c['amount'],
              'count': c['count'],
              'type': c['type'],
            })
        .toList()
      ..sort(
          (a, b) => (b['amount'] as double).compareTo(a['amount'] as double));

    return {
      'totalExpense': totalExpense,
      'totalIncome': totalIncome,
      'expense': totalExpense,
      'income': totalIncome,
      'balance': totalIncome - totalExpense,
      'categories': categories,
      'records': records,
    };
  }

  Future<Map<String, dynamic>> getYearStatistics(String year,
      {String? bookId}) async {
    final db = await database;

    String whereClause = 'month LIKE ?';
    List<dynamic> whereArgs = ['$year-%'];
    if (bookId != null && bookId.isNotEmpty) {
      whereClause += ' AND bookId = ?';
      whereArgs.add(bookId);
    }

    final maps = await db.query('records',
        where: whereClause, whereArgs: whereArgs);

    double totalExpense = 0;
    double totalIncome = 0;
    Map<String, double> monthlyExpense = {};
    Map<String, double> monthlyIncome = {};
    Map<String, Map<String, dynamic>> categoryMap = {};

    for (final m in maps) {
      final type = m['type'] as String;
      final amount = (m['amount'] as num).toDouble();
      final month = m['month'] as String;

      if (type == 'expense') {
        totalExpense += amount;
        monthlyExpense[month] = (monthlyExpense[month] ?? 0) + amount;
      } else {
        totalIncome += amount;
        monthlyIncome[month] = (monthlyIncome[month] ?? 0) + amount;
      }

      final catId = m['categoryId'] as String;
      if (!categoryMap.containsKey(catId)) {
        categoryMap[catId] = {
          'id': catId,
          'name': m['categoryName'],
          'icon': m['categoryIcon'],
          'amount': 0.0,
          'count': 0,
          'type': type,
        };
      }
      categoryMap[catId]!['amount'] =
          (categoryMap[catId]!['amount'] as double) + amount;
      categoryMap[catId]!['count'] =
          (categoryMap[catId]!['count'] as int) + 1;
    }

    final monthlyData = List.generate(12, (i) {
      final monthStr = '$year-${(i + 1).toString().padLeft(2, '0')}';
      return {
        'month': i + 1,
        'expense': monthlyExpense[monthStr] ?? 0.0,
        'income': monthlyIncome[monthStr] ?? 0.0,
      };
    });

    final categories = categoryMap.values.toList()
      ..sort((a, b) =>
          (b['amount'] as double).compareTo(a['amount'] as double));

    return {
      'totalExpense': totalExpense,
      'totalIncome': totalIncome,
      'balance': totalIncome - totalExpense,
      'monthlyData': monthlyData,
      'categories': categories,
    };
  }

  Future<int> getTotalImagesCount() async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT images FROM records WHERE images IS NOT NULL AND images != ''",
    );
    int count = 0;
    for (final row in result) {
      final images = row['images'] as String?;
      if (images != null && images.isNotEmpty) {
        count += images.split(',').where((e) => e.isNotEmpty).length;
      }
    }
    return count;
  }

  Future<int> getRecordsWithLocationCount() async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as cnt FROM records WHERE location IS NOT NULL AND location != ''",
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getRecordsWithMoodCount() async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as cnt FROM records WHERE mood IS NOT NULL AND mood != ''",
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getUniqueCategoriesCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(DISTINCT categoryId) as cnt FROM records',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/models.dart';

/// 数据库服务 - SQLite 本地存储
class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;
  static String? _dbDir; // 缓存数据库目录路径

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('bear_bill.db');
    return _database!;
  }

  /// 获取数据库存储目录（使用 app-specific 内部存储，更新时保留数据）
  Future<String> getDbDirectory() async {
    if (_dbDir != null) return _dbDir!;

    // 使用默认的 app-specific 内部存储路径
    _dbDir = await getDatabasesPath();

    // Android: 从旧的公共存储路径迁移数据（一次性操作）
    if (Platform.isAndroid) {
      await _migrateFromPublicPath(_dbDir!);
    }

    return _dbDir!;
  }

  /// 尝试从指定目录复制数据库到目标目录，返回是否成功
  Future<bool> _tryCopyDbFrom(String srcDir, String dstDir) async {
    try {
      final srcDb = File(join(srcDir, 'bear_bill.db'));
      if (!srcDb.existsSync()) return false;

      final dstDb = File(join(dstDir, 'bear_bill.db'));
      await srcDb.copy(dstDb.path);

      // 连带复制 WAL 和 SHM
      for (final suffix in ['-wal', '-shm']) {
        final srcFile = File(join(srcDir, 'bear_bill.db$suffix'));
        if (srcFile.existsSync()) {
          await srcFile.copy(join(dstDir, 'bear_bill.db$suffix'));
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 从旧的公共存储路径迁移数据库到 app-specific 内部存储（一次性操作）
  Future<void> _migrateFromPublicPath(String internalDbDir) async {
    try {
      final internalDb = File(join(internalDbDir, 'bear_bill.db'));
      if (internalDb.existsSync()) return; // 内部存储已有数据库，无需迁移

      final extDir = await getExternalStorageDirectory();
      if (extDir == null) return;

      final publicDbDir = join(extDir.path.split('/Android/')[0], 'BearBill', 'databases');
      final publicDb = File(join(publicDbDir, 'bear_bill.db'));
      if (!publicDb.existsSync()) return; // 公共路径没有旧数据库

      // 确保内部存储目录存在
      final dir = Directory(internalDbDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      // 复制数据库文件
      await publicDb.copy(internalDb.path);
      for (final suffix in ['-wal', '-shm']) {
        final srcFile = File(join(publicDbDir, 'bear_bill.db$suffix'));
        if (srcFile.existsSync()) {
          await srcFile.copy(join(internalDbDir, 'bear_bill.db$suffix'));
        }
      }

      // 迁移成功后删除旧的公共路径文件
      try {
        await publicDb.delete();
        for (final suffix in ['-wal', '-shm']) {
          final f = File(join(publicDbDir, 'bear_bill.db$suffix'));
          if (f.existsSync()) await f.delete();
        }
        // 尝试删除空目录
        final publicDir = Directory(publicDbDir);
        if (await publicDir.exists() && (await publicDir.list().isEmpty)) {
          await publicDir.delete();
        }
      } catch (_) {}
    } catch (_) {}
  }

  /// 获取数据库文件路径
  Future<String> get databasePath async {
    final dbDir = await getDbDirectory();
    return join(dbDir, 'bear_bill.db');
  }

  /// 重置数据库连接（用于导入后重建）
  void resetConnection() {
    _database = null;
  }

  Future<Database> _initDB(String filePath) async {
    final dbDir = await getDbDirectory();
    final dbPath = join(dbDir, filePath);

    return await openDatabase(
      dbPath,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 账单记录表
    await db.execute('''
      CREATE TABLE records (
        id TEXT PRIMARY KEY,
        bookId TEXT NOT NULL,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        categoryId TEXT NOT NULL,
        categoryName TEXT NOT NULL,
        categoryIcon TEXT NOT NULL,
        categoryColor TEXT,
        remark TEXT,
        date TEXT NOT NULL,
        month TEXT NOT NULL,
        dateTs INTEGER NOT NULL,
        mood TEXT,
        moodEmoji TEXT,
        images TEXT,
        location TEXT,
        tags TEXT,
        createdAt INTEGER NOT NULL
      )
    ''');

    // 账本表
    await db.execute('''
      CREATE TABLE books (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon TEXT DEFAULT '🐻',
        color TEXT DEFAULT '#FF8FAB',
        memberOpenids TEXT,
        budget REAL DEFAULT 0,
        totalRecords INTEGER DEFAULT 0,
        createdAt INTEGER NOT NULL
      )
    ''');

    // 心愿罐表
    await db.execute('''
      CREATE TABLE wishes (
        id TEXT PRIMARY KEY,
        bookId TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        targetAmount REAL NOT NULL,
        currentAmount REAL DEFAULT 0,
        priority INTEGER DEFAULT 1,
        isCompleted INTEGER DEFAULT 0,
        createdAt INTEGER NOT NULL,
        completedAt INTEGER,
        deadline INTEGER,
        depositHistory TEXT
      )
    ''');

    // 用户表
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        nickname TEXT DEFAULT '小熊主人',
        avatar TEXT DEFAULT '',
        checkInDays INTEGER DEFAULT 0,
        lastCheckIn TEXT DEFAULT '',
        achievements TEXT,
        totalRecords INTEGER DEFAULT 0,
        level INTEGER DEFAULT 1,
        exp INTEGER DEFAULT 0,
        defaultBookId TEXT NOT NULL,
        createdAt INTEGER NOT NULL,
        lastActiveAt INTEGER NOT NULL
      )
    ''');

    // 创建默认账本
    final defaultBook = BookModel(
      id: 'default_book',
      name: '小熊账本 🐻',
      icon: '🐻',
      color: '#FF8FAB',
      budget: 0.0,
      totalRecords: 0,
    );
    await db.insert('books', defaultBook.toMap());

    // 创建默认用户
    final defaultUser = UserModel(
      id: 'local-user',
      nickname: '小熊主人',
      defaultBookId: 'default_book',
    );
    await db.insert('users', defaultUser.toMap());
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // 版本 2 升级：给 wishes 表添加 deadline 字段
      await db.execute('ALTER TABLE wishes ADD COLUMN deadline INTEGER');
    }
  }

  // ─── 账单记录 CRUD ───

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

  Future<Map<String, dynamic>> getMonthStatistics(String month,
      {String? bookId}) async {
    final records = await getMonthRecords(month, bookId: bookId);

    double totalExpense = 0;
    double totalIncome = 0;
    Map<String, Map<String, dynamic>> categoryMap = {};

    for (final r in records) {
      // accumulate totals
      if (r.type == 'expense') {
        totalExpense += r.amount;
      } else {
        totalIncome += r.amount;
      }

      // collect categories for both expense and income, include type for compatibility
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

    // 保留向后兼容键名：expense/income
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

  /// 获取年度统计数据
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

    // 构建 12 个月数据
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

  // ─── 记账统计查询（成就用） ───

  /// 获取总图片数
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

  /// 获取带位置的记录数
  Future<int> getRecordsWithLocationCount() async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as cnt FROM records WHERE location IS NOT NULL AND location != ''",
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// 获取带心情的记录数
  Future<int> getRecordsWithMoodCount() async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as cnt FROM records WHERE mood IS NOT NULL AND mood != ''",
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// 获取使用的不同分类数
  Future<int> getUniqueCategoriesCount() async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT COUNT(DISTINCT categoryId) as cnt FROM records",
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ─── 账本 CRUD ───

  Future<void> insertBook(BookModel book) async {
    final db = await database;
    await db.insert('books', book.toMap());
  }

  Future<void> updateBook(BookModel book) async {
    final db = await database;
    await db
        .update('books', book.toMap(), where: 'id = ?', whereArgs: [book.id]);
  }

  Future<void> deleteBook(String id) async {
    final db = await database;
    await db.delete('books', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<BookModel>> getAllBooks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('books', orderBy: 'createdAt DESC');
    return maps.map((m) => BookModel.fromMap(m)).toList();
  }

  Future<BookModel?> getDefaultBook() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'books',
      where: 'isDefault = ?',
      whereArgs: [1],
      limit: 1,
    );
    return maps.isNotEmpty ? BookModel.fromMap(maps.first) : null;
  }

  // ─── 心愿罐 CRUD ───

  Future<void> insertWish(WishModel wish) async {
    final db = await database;
    await db.insert('wishes', wish.toMap());
  }

  Future<void> updateWish(WishModel wish) async {
    final db = await database;
    await db
        .update('wishes', wish.toMap(), where: 'id = ?', whereArgs: [wish.id]);
  }

  Future<void> deleteWish(String id) async {
    final db = await database;
    await db.delete('wishes', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<WishModel>> getAllWishes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'wishes',
      orderBy: 'isCompleted ASC, priority DESC, completedAt DESC, createdAt DESC',
    );
    return maps.map((m) => WishModel.fromMap(m)).toList();
  }

  Future<List<WishModel>> getCompletedWishes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'wishes',
      where: 'isCompleted = ?',
      whereArgs: [1],
      orderBy: 'completedAt DESC',
    );
    return maps.map((m) => WishModel.fromMap(m)).toList();
  }

  // ─── 用户 CRUD ───

  Future<void> insertUser(UserModel user) async {
    final db = await database;
    await db.insert('users', user.toMap());
  }

  Future<void> updateUser(UserModel user) async {
    final db = await database;
    await db
        .update('users', user.toMap(), where: 'id = ?', whereArgs: [user.id]);
  }

  Future<UserModel?> getUser(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return maps.isNotEmpty ? UserModel.fromMap(maps.first) : null;
  }

  Future<UserModel?> getDefaultUser() async {
    return await getUser('local-user');
  }

  // ─── 清空账单 ───

  Future<int> clearRecordsByBook(String bookId) async {
    final db = await database;
    return await db.delete('records', where: 'bookId = ?', whereArgs: [bookId]);
  }

  // ─── 统计查询 ───

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

  // ─── 导出功能 ───

  Future<String> exportToCSV() async {
    final records =
        await getMonthRecords(DateTime.now().toString().substring(0, 7));
    final buffer = StringBuffer();
    buffer.writeln('日期,类型,分类,金额,备注,心情,地点');

    for (final r in records) {
      buffer.writeln(
          '${r.date},${r.type},${r.categoryName},${r.amount},${r.remark ?? ''},${r.moodEmoji ?? ''},${r.location ?? ''}');
    }

    return buffer.toString();
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/models.dart';
import 'database_book_mixin.dart';
import 'database_location_mixin.dart';
import 'database_record_mixin.dart';
import 'database_stats_mixin.dart';
import 'database_wish_user_mixin.dart';

/// 数据库服务核心 - 初始化、迁移、关闭
abstract class DatabaseServiceCore {
  static Database? _database;
  static String? _dbDir;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('bear_bill.db');
    return _database!;
  }

  Future<String> getDbDirectory() async {
    if (_dbDir != null) return _dbDir!;
    _dbDir = await getDatabasesPath();
    if (Platform.isAndroid) {
      await _migrateFromPublicPath(_dbDir!);
    }
    return _dbDir!;
  }

  Future<void> _migrateFromPublicPath(String internalDbDir) async {
    try {
      final internalDb = File(join(internalDbDir, 'bear_bill.db'));
      if (internalDb.existsSync()) return;

      final extDir = await getExternalStorageDirectory();
      if (extDir == null) return;

      final publicDbDir =
          join(extDir.path.split('/Android/')[0], 'BearBill', 'databases');
      final publicDb = File(join(publicDbDir, 'bear_bill.db'));
      if (!publicDb.existsSync()) return;

      final dir = Directory(internalDbDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      await publicDb.copy(internalDb.path);
      for (final suffix in ['-wal', '-shm']) {
        final srcFile = File(join(publicDbDir, 'bear_bill.db$suffix'));
        if (srcFile.existsSync()) {
          await srcFile.copy(join(internalDbDir, 'bear_bill.db$suffix'));
        }
      }

      try {
        await publicDb.delete();
        for (final suffix in ['-wal', '-shm']) {
          final f = File(join(publicDbDir, 'bear_bill.db$suffix'));
          if (f.existsSync()) await f.delete();
        }
        final publicDir = Directory(publicDbDir);
        if (await publicDir.exists() && (await publicDir.list().isEmpty)) {
          await publicDir.delete();
        }
      } catch (_) {}
    } catch (_) {}
  }

  Future<String> get databasePath async {
    final dbDir = await getDbDirectory();
    return join(dbDir, 'bear_bill.db');
  }

  void resetConnection() {
    _database = null;
  }

  Future<Database> _initDB(String filePath) async {
    final dbDir = await getDbDirectory();
    final dbPath = join(dbDir, filePath);

    return await openDatabase(
      dbPath,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
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
        latitude REAL,
        longitude REAL,
        tags TEXT,
        createdAt INTEGER NOT NULL
      )
    ''');

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

    await db.execute('''
      CREATE TABLE favorite_locations (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        address TEXT,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        useCount INTEGER DEFAULT 1,
        lastUsedAt INTEGER NOT NULL,
        createdAt INTEGER NOT NULL
      )
    ''');

    final defaultBook = BookModel(
      id: 'default_book',
      name: '小熊账本 🐻',
      icon: '🐻',
      color: '#FF8FAB',
      budget: 0.0,
      totalRecords: 0,
    );
    await db.insert('books', defaultBook.toMap());

    final defaultUser = UserModel(
      id: 'local-user',
      nickname: '小熊主人',
      defaultBookId: 'default_book',
    );
    await db.insert('users', defaultUser.toMap());
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE wishes ADD COLUMN deadline INTEGER');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE records ADD COLUMN latitude REAL');
      await db.execute('ALTER TABLE records ADD COLUMN longitude REAL');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS favorite_locations (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          address TEXT,
          latitude REAL NOT NULL,
          longitude REAL NOT NULL,
          useCount INTEGER DEFAULT 1,
          lastUsedAt INTEGER NOT NULL,
          createdAt INTEGER NOT NULL
        )
      ''');
    }
  }

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

  /// 供 mixin 内部调用
  Future<List<RecordModel>> getMonthRecords(String month,
      {String? bookId});
}

/// 数据库服务 - 合并所有 mixin
class DatabaseService extends DatabaseServiceCore
    with
        DatabaseRecordMixin,
        DatabaseStatsMixin,
        DatabaseBookMixin,
        DatabaseWishUserMixin,
        DatabaseLocationMixin {
  static final DatabaseService instance = DatabaseService._init();
  DatabaseService._init();
}

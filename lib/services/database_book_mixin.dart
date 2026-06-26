import '../models/models.dart';
import 'database_service.dart';

/// 数据库服务 - 账本相关方法
mixin DatabaseBookMixin on DatabaseServiceCore {
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
}

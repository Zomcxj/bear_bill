import '../models/models.dart';
import 'database_service.dart';

/// 数据库服务 - 心愿罐 & 用户相关方法
mixin DatabaseWishUserMixin on DatabaseServiceCore {
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
      orderBy:
          'isCompleted ASC, priority DESC, completedAt DESC, createdAt DESC',
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
}

import '../models/models.dart';
import 'database_service.dart';

/// 数据库服务 - 常去地点相关方法
mixin DatabaseLocationMixin on DatabaseServiceCore {
  Future<void> insertFavoriteLocation(FavoriteLocationModel loc) async {
    final db = await database;
    await db.insert('favorite_locations', loc.toMap());
  }

  Future<void> updateFavoriteLocation(FavoriteLocationModel loc) async {
    final db = await database;
    await db.update(
      'favorite_locations',
      loc.toMap(),
      where: 'id = ?',
      whereArgs: [loc.id],
    );
  }

  Future<void> deleteFavoriteLocation(String id) async {
    final db = await database;
    await db.delete('favorite_locations', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<FavoriteLocationModel>> getFavoriteLocations(
      {int limit = 10}) async {
    final db = await database;
    final result = await db.query(
      'favorite_locations',
      orderBy: 'useCount DESC, lastUsedAt DESC',
      limit: limit,
    );
    return result.map((map) => FavoriteLocationModel.fromMap(map)).toList();
  }

  Future<void> incrementLocationUseCount(String id) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE favorite_locations SET useCount = useCount + 1, lastUsedAt = ? WHERE id = ?',
      [DateTime.now().millisecondsSinceEpoch, id],
    );
  }

  Future<void> upsertFavoriteLocation({
    required String name,
    String? address,
    required double latitude,
    required double longitude,
  }) async {
    final db = await database;
    final existing = await db.rawQuery(
      'SELECT * FROM favorite_locations WHERE ABS(latitude - ?) < 0.001 AND ABS(longitude - ?) < 0.001 LIMIT 1',
      [latitude, longitude],
    );
    if (existing.isNotEmpty) {
      await incrementLocationUseCount(existing.first['id'] as String);
    } else {
      await insertFavoriteLocation(FavoriteLocationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        address: address,
        latitude: latitude,
        longitude: longitude,
      ));
    }
  }
}

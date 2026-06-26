import 'package:flutter_test/flutter_test.dart';
import 'package:bear_bill/models/location_model.dart';

void main() {
  group('FavoriteLocationModel', () {
    late FavoriteLocationModel loc;
    late DateTime testDate;

    setUp(() {
      testDate = DateTime(2026, 6, 23, 10, 0);
      loc = FavoriteLocationModel(
        id: 'loc_001',
        name: '星巴克',
        address: '朝阳区建国路88号',
        latitude: 39.9042,
        longitude: 116.4074,
        useCount: 5,
        lastUsedAt: testDate,
        createdAt: testDate,
      );
    });

    test('默认值正确', () {
      final defaultLoc = FavoriteLocationModel(
        id: 'l1',
        name: '地点',
        latitude: 39.9,
        longitude: 116.3,
      );
      expect(defaultLoc.address, isNull);
      expect(defaultLoc.useCount, 1);
    });

    test('toMap/fromMap 往返一致', () {
      final map = loc.toMap();
      final restored = FavoriteLocationModel.fromMap(map);

      expect(restored.id, loc.id);
      expect(restored.name, loc.name);
      expect(restored.address, loc.address);
      expect(restored.latitude, loc.latitude);
      expect(restored.longitude, loc.longitude);
      expect(restored.useCount, loc.useCount);
    });

    test('坐标精度保持', () {
      final map = loc.toMap();
      final restored = FavoriteLocationModel.fromMap(map);
      expect(restored.latitude, closeTo(39.9042, 0.0001));
      expect(restored.longitude, closeTo(116.4074, 0.0001));
    });

    test('copyWith 部分更新', () {
      final updated = loc.copyWith(useCount: 10, name: '新地点');
      expect(updated.useCount, 10);
      expect(updated.name, '新地点');
      expect(updated.latitude, loc.latitude);
      expect(updated.id, loc.id);
    });

    test('fromMap 缺失 useCount 默认为 1', () {
      final map = loc.toMap();
      map.remove('useCount');
      final restored = FavoriteLocationModel.fromMap(map);
      expect(restored.useCount, 1);
    });
  });
}

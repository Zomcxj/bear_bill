/// 常去地点模型
class FavoriteLocationModel {
  final String id;
  final String name;
  final String? address;
  final double latitude;
  final double longitude;
  final int useCount;
  final DateTime lastUsedAt;
  final DateTime createdAt;

  FavoriteLocationModel({
    required this.id,
    required this.name,
    this.address,
    required this.latitude,
    required this.longitude,
    this.useCount = 1,
    DateTime? lastUsedAt,
    DateTime? createdAt,
  })  : lastUsedAt = lastUsedAt ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  factory FavoriteLocationModel.fromMap(Map<String, dynamic> map) {
    return FavoriteLocationModel(
      id: map['id'] as String,
      name: map['name'] as String,
      address: map['address'] as String?,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      useCount: map['useCount'] as int? ?? 1,
      lastUsedAt: DateTime.fromMillisecondsSinceEpoch(map['lastUsedAt'] as int? ?? 0),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int? ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'useCount': useCount,
      'lastUsedAt': lastUsedAt.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  FavoriteLocationModel copyWith({
    String? id,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    int? useCount,
    DateTime? lastUsedAt,
    DateTime? createdAt,
  }) {
    return FavoriteLocationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      useCount: useCount ?? this.useCount,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

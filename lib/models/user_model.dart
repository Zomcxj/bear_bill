/// User model - local storage version (no cloud backend)
class UserModel {
  final String id; // Local user ID (fixed to 'local-user')
  final String nickname; // Nickname
  final String avatar; // Avatar URL
  final int checkInDays; // Consecutive check-in days
  final String lastCheckIn; // Last check-in date 'YYYY-MM-DD'
  final List<String> achievements; // Unlocked achievement IDs
  final int totalRecords; // Total number of records
  final int level; // Level
  final int exp; // Experience points
  final String defaultBookId; // Default book ID
  final DateTime createdAt;
  final DateTime lastActiveAt; // Last active time
  
  UserModel({
    this.id = 'local-user',
    this.nickname = '小熊主人',
    this.avatar = '',
    this.checkInDays = 0,
    this.lastCheckIn = '',
    this.achievements = const [],
    this.totalRecords = 0,
    this.level = 1,
    this.exp = 0,
    required this.defaultBookId,
    DateTime? createdAt,
    DateTime? lastActiveAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       lastActiveAt = lastActiveAt ?? DateTime.now();
  
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String? ?? 'local-user',
      nickname: map['nickname'] as String? ?? '小熊主人',
      avatar: map['avatar'] as String? ?? '',
      checkInDays: map['checkInDays'] as int? ?? 0,
      lastCheckIn: map['lastCheckIn'] as String? ?? '',
      achievements: (map['achievements'] as String?)?.split(',').where((e) => e.isNotEmpty).toList() ?? [],
      totalRecords: map['totalRecords'] as int? ?? 0,
      level: map['level'] as int? ?? 1,
      exp: map['exp'] as int? ?? 0,
      defaultBookId: map['defaultBookId'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int? ?? 0),
      lastActiveAt: DateTime.fromMillisecondsSinceEpoch(map['lastActiveAt'] as int? ?? 0),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nickname': nickname,
      'avatar': avatar,
      'checkInDays': checkInDays,
      'lastCheckIn': lastCheckIn,
      'achievements': achievements.join(','),
      'totalRecords': totalRecords,
      'level': level,
      'exp': exp,
      'defaultBookId': defaultBookId,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastActiveAt': lastActiveAt.millisecondsSinceEpoch,
    };
  }
  
  UserModel copyWith({
    String? id,
    String? nickname,
    String? avatar,
    int? checkInDays,
    String? lastCheckIn,
    List<String>? achievements,
    int? totalRecords,
    int? level,
    int? exp,
    String? defaultBookId,
    DateTime? createdAt,
    DateTime? lastActiveAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      avatar: avatar ?? this.avatar,
      checkInDays: checkInDays ?? this.checkInDays,
      lastCheckIn: lastCheckIn ?? this.lastCheckIn,
      achievements: achievements ?? this.achievements,
      totalRecords: totalRecords ?? this.totalRecords,
      level: level ?? this.level,
      exp: exp ?? this.exp,
      defaultBookId: defaultBookId ?? this.defaultBookId,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }
  
  /// Experience required for the next level
  int get expForNextLevel => level * 100;
  
  /// Experience progress percentage
  double get expProgress => exp / expForNextLevel;
  
  /// Whether the user should level up
  bool get shouldLevelUp => exp >= expForNextLevel;
}

/// 用户模型 - 本地存储版本（无云开发）
class UserModel {
  final String id; // 本地用户ID（固定为 'local-user'）
  final String nickname; // 昵称
  final String avatar; // 头像URL
  final int checkInDays; // 连续打卡天数
  final String lastCheckIn; // 最后打卡日期 'YYYY-MM-DD'
  final List<String> achievements; // 已解锁成就ID列表
  final int totalRecords; // 总记账次数
  final int level; // 等级
  final int exp; // 经验值
  final String defaultBookId; // 默认账本ID
  final DateTime createdAt;
  final DateTime lastActiveAt; // 最后活跃时间
  
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
  
  /// 计算下一级所需经验值
  int get expForNextLevel => level * 100;
  
  /// 经验进度百分比
  double get expProgress => exp / expForNextLevel;
  
  /// 判断是否升级
  bool get shouldLevelUp => exp >= expForNextLevel;
}

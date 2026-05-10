/// 成就模型
class AchievementModel {
  final String id; // 成就ID
  final String type; // 'checkIn' | 'records' | 'budget' | 'wish'
  final String title; // 成就标题
  final String description; // 成就描述
  final String emoji; // 成就图标（Emoji）
  final int threshold; // 达成阈值
  final DateTime? unlockedAt; // 解锁时间
  
  const AchievementModel({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.emoji,
    required this.threshold,
    this.unlockedAt,
  });
  
  factory AchievementModel.fromMap(Map<String, dynamic> map) {
    return AchievementModel(
      id: map['id'] as String,
      type: map['type'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      emoji: map['emoji'] as String,
      threshold: map['threshold'] as int,
      unlockedAt: map['unlockedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['unlockedAt'] as int)
          : null,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'description': description,
      'emoji': emoji,
      'threshold': threshold,
      'unlockedAt': unlockedAt?.millisecondsSinceEpoch,
    };
  }
  
  /// 是否已解锁
  bool get isUnlocked => unlockedAt != null;
  
  AchievementModel copyWith({
    String? id,
    String? type,
    String? title,
    String? description,
    String? emoji,
    int? threshold,
    DateTime? unlockedAt,
  }) {
    return AchievementModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      emoji: emoji ?? this.emoji,
      threshold: threshold ?? this.threshold,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }
}

/// 预定义的成就列表
class AchievementDefinitions {
  static const List<AchievementModel> all = [
    // 连续打卡成就
    AchievementModel(
      id: 'checkin_3',
      type: 'checkIn',
      title: '初出茅庐',
      description: '连续记账 3 天',
      emoji: '⭐',
      threshold: 3,
    ),
    AchievementModel(
      id: 'checkin_7',
      type: 'checkIn',
      title: '小有成就',
      description: '连续记账 7 天',
      emoji: '🌟',
      threshold: 7,
    ),
    AchievementModel(
      id: 'checkin_14',
      type: 'checkIn',
      title: '坚持不懈',
      description: '连续记账 14 天',
      emoji: '💫',
      threshold: 14,
    ),
    AchievementModel(
      id: 'checkin_30',
      type: 'checkIn',
      title: '月度达人',
      description: '连续记账 30 天',
      emoji: '🥇',
      threshold: 30,
    ),
    AchievementModel(
      id: 'checkin_60',
      type: 'checkIn',
      title: '双月坚守',
      description: '连续记账 60 天',
      emoji: '🏅',
      threshold: 60,
    ),
    AchievementModel(
      id: 'checkin_100',
      type: 'checkIn',
      title: '百日传奇',
      description: '连续记账 100 天',
      emoji: '🏆',
      threshold: 100,
    ),
    AchievementModel(
      id: 'checkin_365',
      type: 'checkIn',
      title: '年度王者',
      description: '连续记账 365 天',
      emoji: '👑',
      threshold: 365,
    ),
    
    // 记账次数成就
    AchievementModel(
      id: 'records_10',
      type: 'records',
      title: '记账新手',
      description: '累计记账 10 次',
      emoji: '📝',
      threshold: 10,
    ),
    AchievementModel(
      id: 'records_50',
      type: 'records',
      title: '记账能手',
      description: '累计记账 50 次',
      emoji: '✍️',
      threshold: 50,
    ),
    AchievementModel(
      id: 'records_100',
      type: 'records',
      title: '百笔记录',
      description: '累计记账 100 次',
      emoji: '💯',
      threshold: 100,
    ),
    AchievementModel(
      id: 'records_500',
      type: 'records',
      title: '记账大师',
      description: '累计记账 500 次',
      emoji: '🎯',
      threshold: 500,
    ),
    
    // 预算管理成就
    AchievementModel(
      id: 'budget_1',
      type: 'budget',
      title: '预算先锋',
      description: '首次设置月度预算',
      emoji: '🎯',
      threshold: 1,
    ),
    AchievementModel(
      id: 'budget_save',
      type: 'budget',
      title: '省钱小能手',
      description: '月度支出低于预算 80%',
      emoji: '💰',
      threshold: 80,
    ),
    
    // 心愿罐成就
    AchievementModel(
      id: 'wish_1',
      type: 'wish',
      title: '心愿启航',
      description: '创建第一个心愿',
      emoji: '✨',
      threshold: 1,
    ),
    AchievementModel(
      id: 'wish_complete',
      type: 'wish',
      title: '梦想成真',
      description: '完成第一个心愿',
      emoji: '🎉',
      threshold: 1,
    ),
    AchievementModel(
      id: 'wish_5',
      type: 'wish',
      title: '心愿收集家',
      description: '完成 5 个心愿',
      emoji: '🌈',
      threshold: 5,
    ),
  ];
  
  /// 根据ID查找成就定义
  static AchievementModel? findById(String id) {
    try {
      return all.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }
  
  /// 获取某类型的所有成就
  static List<AchievementModel> getByType(String type) {
    return all.where((a) => a.type == type).toList();
  }
}

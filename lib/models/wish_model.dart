/// 心愿罐模型
class WishModel {
  final String id;
  final String bookId; // 所属账本ID
  final String title;
  final String? description;
  final double targetAmount;
  final double currentAmount;
  final int priority; // 1=普通，2=重要，3=紧急
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? deadline; // 心愿截止日期
  final List<String> depositHistory; // 存钱历史记录 'date:amount' 格式

  WishModel({
    required this.id,
    required this.bookId,
    required this.title,
    this.description,
    required this.targetAmount,
    this.currentAmount = 0,
    this.priority = 1,
    this.isCompleted = false,
    DateTime? createdAt,
    this.completedAt,
    this.deadline,
    this.depositHistory = const [],
  }) : createdAt = createdAt ?? DateTime.now();

  double get progress =>
      targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

  factory WishModel.fromMap(Map<String, dynamic> map) {
    return WishModel(
      id: map['id'] as String,
      bookId: map['bookId'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      targetAmount: (map['targetAmount'] as num).toDouble(),
      currentAmount: (map['currentAmount'] as num?)?.toDouble() ?? 0,
      priority: map['priority'] as int? ?? 1,
      isCompleted: (map['isCompleted'] as int? ?? 0) == 1,
      createdAt:
          DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int? ?? 0),
      completedAt: map['completedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['completedAt'] as int)
          : null,
      deadline: map['deadline'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['deadline'] as int)
          : null,
      depositHistory: (map['depositHistory'] as String?)
              ?.split(',')
              .where((e) => e.isNotEmpty)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookId': bookId,
      'title': title,
      'description': description,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'priority': priority,
      'isCompleted': isCompleted ? 1 : 0,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'completedAt': completedAt?.millisecondsSinceEpoch,
      'deadline': deadline?.millisecondsSinceEpoch,
      'depositHistory': depositHistory.join(','),
    };
  }

  WishModel copyWith({
    String? id,
    String? bookId,
    String? title,
    String? description,
    double? targetAmount,
    double? currentAmount,
    int? priority,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? completedAt,
    DateTime? deadline,
    List<String>? depositHistory,
  }) {
    return WishModel(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      title: title ?? this.title,
      description: description ?? this.description,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      deadline: deadline ?? this.deadline,
      depositHistory: depositHistory ?? this.depositHistory,
    );
  }

  String get priorityLabel {
    switch (priority) {
      case 3:
        return '🔴 紧急';
      case 2:
        return '🟡 重要';
      default:
        return '🟢 普通';
    }
  }
}

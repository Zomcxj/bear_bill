/// 账本模型
class BookModel {
  final String id;
  final String name;
  final String icon; // Emoji 图标
  final String color; // 主题色
  final List<String> memberOpenids; // 成员列表（本地版本为单用户）
  final double budget; // 月度预算
  final int totalRecords; // 总记录数
  final DateTime createdAt;
  
  BookModel({
    required this.id,
    required this.name,
    this.icon = '🐻',
    this.color = '#FF8FAB',
    this.memberOpenids = const [],
    this.budget = 0.0,
    this.totalRecords = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
  
  factory BookModel.fromMap(Map<String, dynamic> map) {
    return BookModel(
      id: map['id'] as String,
      name: map['name'] as String,
      icon: map['icon'] as String? ?? '🐻',
      color: map['color'] as String? ?? '#FF8FAB',
      memberOpenids: (map['memberOpenids'] as String?)?.split(',').where((e) => e.isNotEmpty).toList() ?? [],
      budget: (map['budget'] as num?)?.toDouble() ?? 0.0,
      totalRecords: map['totalRecords'] as int? ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int? ?? 0),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'memberOpenids': memberOpenids.join(','),
      'budget': budget,
      'totalRecords': totalRecords,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
  
  BookModel copyWith({
    String? id,
    String? name,
    String? icon,
    String? color,
    List<String>? memberOpenids,
    double? budget,
    int? totalRecords,
    DateTime? createdAt,
  }) {
    return BookModel(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      memberOpenids: memberOpenids ?? this.memberOpenids,
      budget: budget ?? this.budget,
      totalRecords: totalRecords ?? this.totalRecords,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

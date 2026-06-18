/// 账单记录模型
class RecordModel {
  final String id;
  final String bookId;
  final String type; // 'expense' 或 'income'
  final double amount;
  final String categoryId;
  final String categoryName;
  final String categoryIcon;
  final String? categoryColor;
  final String? remark;
  final String date; // 'YYYY-MM-DD'
  final String month; // 'YYYY-MM'
  final int dateTs;
  final String? mood; // 'happy', 'normal', 'sad', 'angry', 'anxious'
  final String? moodEmoji;
  final List<String> images;
  final String? location;
  final double? latitude;
  final double? longitude;
  final List<String> tags;
  final DateTime createdAt;
  
  RecordModel({
    required this.id,
    required this.bookId,
    required this.type,
    required this.amount,
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    this.categoryColor,
    this.remark,
    required this.date,
    required this.month,
    required this.dateTs,
    this.mood,
    this.moodEmoji,
    this.images = const [],
    this.location,
    this.latitude,
    this.longitude,
    this.tags = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
  
  factory RecordModel.fromMap(Map<String, dynamic> map) {
    return RecordModel(
      id: map['id'] as String,
      bookId: map['bookId'] as String,
      type: map['type'] as String,
      amount: (map['amount'] as num).toDouble(),
      categoryId: map['categoryId'] as String,
      categoryName: map['categoryName'] as String,
      categoryIcon: map['categoryIcon'] as String,
      categoryColor: map['categoryColor'] as String?,
      remark: map['remark'] as String?,
      date: map['date'] as String,
      month: map['month'] as String,
      dateTs: map['dateTs'] as int,
      mood: map['mood'] as String?,
      moodEmoji: map['moodEmoji'] as String?,
      images: (map['images'] as String?)?.split(',').where((e) => e.isNotEmpty).toList() ?? [],
      location: map['location'] as String?,
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      tags: (map['tags'] as String?)?.split(',').where((e) => e.isNotEmpty).toList() ?? [],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int? ?? 0),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookId': bookId,
      'type': type,
      'amount': amount,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'categoryIcon': categoryIcon,
      'categoryColor': categoryColor,
      'remark': remark,
      'date': date,
      'month': month,
      'dateTs': dateTs,
      'mood': mood,
      'moodEmoji': moodEmoji,
      'images': images.join(','),
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'tags': tags.join(','),
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
  
  RecordModel copyWith({
    String? id,
    String? bookId,
    String? type,
    double? amount,
    String? categoryId,
    String? categoryName,
    String? categoryIcon,
    String? categoryColor,
    String? remark,
    String? date,
    String? month,
    int? dateTs,
    String? mood,
    String? moodEmoji,
    List<String>? images,
    String? location,
    double? latitude,
    double? longitude,
    List<String>? tags,
    DateTime? createdAt,
  }) {
    return RecordModel(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      categoryColor: categoryColor ?? this.categoryColor,
      remark: remark ?? this.remark,
      date: date ?? this.date,
      month: month ?? this.month,
      dateTs: dateTs ?? this.dateTs,
      mood: mood ?? this.mood,
      moodEmoji: moodEmoji ?? this.moodEmoji,
      images: images ?? this.images,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
    );
  }
  
  /// 判断是否为支出
  bool get isExpense => type == 'expense';
  
  /// 判断是否为收入
  bool get isIncome => type == 'income';
  
  /// 判断是否为今天
  bool get isToday {
    final now = DateTime.now();
    final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return date == today;
  }
}

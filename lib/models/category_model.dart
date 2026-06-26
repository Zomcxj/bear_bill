/// 分类模型
class CategoryModel {
  final String id;
  final String name;
  final String icon;
  final String color;
  final bool isExpense; // true=支出，false=收入

  const CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.isExpense,
  });
}

/// 支出分类
const List<CategoryModel> expenseCategories = [
  CategoryModel(
      id: 'food', name: '餐饮', icon: '🍜', color: '#FF6B6B', isExpense: true),
  CategoryModel(
      id: 'transport',
      name: '交通',
      icon: '🚗',
      color: '#4ECDC4',
      isExpense: true),
  CategoryModel(
      id: 'shopping',
      name: '购物',
      icon: '🛍️',
      color: '#45B7D1',
      isExpense: true),
  CategoryModel(
      id: 'entertainment',
      name: '娱乐',
      icon: '🎮',
      color: '#96CEB4',
      isExpense: true),
  CategoryModel(
      id: 'health', name: '医疗', icon: '💊', color: '#FFEAA7', isExpense: true),
  CategoryModel(
      id: 'housing', name: '居住', icon: '🏠', color: '#DDA0DD', isExpense: true),
  CategoryModel(
      id: 'education',
      name: '教育',
      icon: '📚',
      color: '#98D8C8',
      isExpense: true),
  CategoryModel(
      id: 'digital', name: '数码', icon: '💻', color: '#74B9FF', isExpense: true),
  CategoryModel(
      id: 'clothing',
      name: '服装',
      icon: '👕',
      color: '#FD79A8',
      isExpense: true),
  CategoryModel(
      id: 'milk_tea',
      name: '奶茶',
      icon: '🧋',
      color: '#FDCB6E',
      isExpense: true),
  CategoryModel(
      id: 'snack', name: '零食', icon: '🍿', color: '#FDCB6E', isExpense: true),
  CategoryModel(
      id: 'pet', name: '宠物', icon: '🐾', color: '#A29BFE', isExpense: true),
  CategoryModel(
      id: 'sport', name: '运动', icon: '⚽', color: '#55EFC4', isExpense: true),
  CategoryModel(
      id: 'travel', name: '旅行', icon: '✈️', color: '#0984E3', isExpense: true),
  CategoryModel(
      id: 'social', name: '社交', icon: '🎉', color: '#E17055', isExpense: true),
  CategoryModel(
      id: 'transfer', name: '转账', icon: '💸', color: '#E67E22', isExpense: true),
  CategoryModel(
      id: 'red_packet', name: '红包', icon: '🧧', color: '#FF4757', isExpense: true),
  CategoryModel(
      id: 'other', name: '其他', icon: '📦', color: '#B0B0B0', isExpense: true),
];

/// 收入分类
const List<CategoryModel> incomeCategories = [
  CategoryModel(
      id: 'salary', name: '工资', icon: '💼', color: '#2ECC71', isExpense: false),
  CategoryModel(
      id: 'bonus', name: '奖金', icon: '🎁', color: '#F39C12', isExpense: false),
  CategoryModel(
      id: 'invest', name: '理财', icon: '📈', color: '#3498DB', isExpense: false),
  CategoryModel(
      id: 'part_time',
      name: '兼职',
      icon: '🔧',
      color: '#9B59B6',
      isExpense: false),
  CategoryModel(
      id: 'rent', name: '租金', icon: '🏢', color: '#1ABC9C', isExpense: false),
  CategoryModel(
      id: 'transfer',
      name: '转账',
      icon: '💸',
      color: '#E67E22',
      isExpense: false),
  CategoryModel(
      id: 'red_packet',
      name: '红包',
      icon: '🧧',
      color: '#FF4757',
      isExpense: false),
  CategoryModel(
      id: 'other_in',
      name: '其他',
      icon: '💰',
      color: '#95A5A6',
      isExpense: false),
];

/// 根据ID查找分类
CategoryModel? getCategoryById(String id, {bool isExpense = true}) {
  final list = isExpense ? expenseCategories : incomeCategories;
  return list.cast<CategoryModel?>().firstWhere(
        (c) => c?.id == id,
        orElse: () => null,
      );
}

/// 心情模型
class MoodModel {
  final String id;
  final String emoji;
  final String label;

  const MoodModel({
    required this.id,
    required this.emoji,
    required this.label,
  });
}

const List<MoodModel> moods = [
  MoodModel(id: 'happy', emoji: '😊', label: '开心'),
  MoodModel(id: 'normal', emoji: '😐', label: '一般'),
  MoodModel(id: 'sad', emoji: '😢', label: '难过'),
  MoodModel(id: 'angry', emoji: '😠', label: '生气'),
  MoodModel(id: 'anxious', emoji: '😰', label: '焦虑'),
];

MoodModel? getMoodById(String id) {
  return moods.cast<MoodModel?>().firstWhere(
        (m) => m?.id == id,
        orElse: () => null,
      );
}

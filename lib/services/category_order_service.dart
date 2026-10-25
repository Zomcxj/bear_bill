import 'package:flutter/foundation.dart';

import '../models/category_model.dart';
import 'storage_service.dart';

/// 支出分类排序服务
///
/// 用户在「我的 → 分类排序」长按拖拽调整支出分类顺序，
/// 顺序持久化到 SharedPreferences；收入分类不参与排序。
/// 默认顺序 = [expenseCategories] 常量表顺序。
class CategoryOrderService extends ChangeNotifier {
  CategoryOrderService._();

  static final CategoryOrderService instance = CategoryOrderService._();

  static const String _key = 'expenseCategoryOrder';

  /// 已排序的支出分类（[load] 之后同步可用；未 load 时回退默认顺序）
  List<CategoryModel> _expense = List.unmodifiable(expenseCategories);

  List<CategoryModel> get expense => _expense;

  /// 启动时加载持久化顺序；持久化值与常量表不一致时（版本增删分类），
  /// 缺失的分类按默认顺序补在末尾，多余的 id 丢弃。
  Future<void> load() async {
    final saved = StorageService.instance.getString(_key);
    if (saved == null || saved.isEmpty) return;
    final ids = saved.split(',');
    final byId = {for (final c in expenseCategories) c.id: c};
    final ordered = <CategoryModel>[
      for (final id in ids)
        if (byId[id] != null) byId[id]!,
      ...expenseCategories.where((c) => !ids.contains(c.id)),
    ];
    _expense = List.unmodifiable(ordered);
    notifyListeners();
  }

  /// 保存新顺序（id 列表），并广播给监听方（记一笔/筛选条等）
  Future<void> saveOrder(List<String> ids) async {
    final byId = {for (final c in expenseCategories) c.id: c};
    final ordered = <CategoryModel>[
      for (final id in ids)
        if (byId[id] != null) byId[id]!,
    ];
    if (ordered.length != expenseCategories.length) return; // 防脏数据
    _expense = List.unmodifiable(ordered);
    StorageService.instance.setString(_key, ids.join(','));
    notifyListeners();
  }
}

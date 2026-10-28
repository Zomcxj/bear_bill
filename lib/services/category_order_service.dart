import 'package:flutter/foundation.dart';

import '../models/category_model.dart';
import 'storage_service.dart';

/// Expense category ordering service
///
/// Users reorder expense categories by long-press dragging in
/// "Profile → Category order"; the order is persisted to SharedPreferences.
/// Income categories do not take part in ordering.
/// Default order = the order of the [expenseCategories] constant list.
class CategoryOrderService extends ChangeNotifier {
  CategoryOrderService._();

  static final CategoryOrderService instance = CategoryOrderService._();

  static const String _key = 'expenseCategoryOrder';

  /// Ordered expense categories (available synchronously after [load]; falls
  /// back to the default order when [load] has not run)
  List<CategoryModel> _expense = List.unmodifiable(expenseCategories);

  List<CategoryModel> get expense => _expense;

  /// Loads the persisted order at startup; when the persisted value differs from
  /// the constant list (categories added/removed between versions), missing
  /// categories are appended in default order and extra ids are dropped.
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

  /// Saves the new order (a list of ids) and broadcasts it to listeners
  /// (add-record page, filter bar, etc.)
  Future<void> saveOrder(List<String> ids) async {
    final byId = {for (final c in expenseCategories) c.id: c};
    final ordered = <CategoryModel>[
      for (final id in ids)
        if (byId[id] != null) byId[id]!,
    ];
    if (ordered.length != expenseCategories.length) return; // Guard against dirty data
    _expense = List.unmodifiable(ordered);
    StorageService.instance.setString(_key, ids.join(','));
    notifyListeners();
  }
}

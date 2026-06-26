import 'package:flutter/material.dart';

import '../../../theme/app_design_system.dart';
import '../bill_list_page.dart';

/// 账单列表页 - 筛选相关功能
mixin BillFilterMixin on State<BillListPage> {
  String keyword = '';
  String filterType = 'all';
  final List<String> filterCategories = [];
  double? minAmount;
  double? maxAmount;
  String filterLocation = '';

  bool matchesFilter(dynamic record) {
    if (keyword.isNotEmpty) {
      final keywordLower = keyword.toLowerCase();
      final matchCategory =
          record.categoryName.toLowerCase().contains(keywordLower);
      final matchNote =
          (record.remark ?? '').toLowerCase().contains(keywordLower);
      final matchAmount = record.amount.toString().contains(keyword);
      if (!matchCategory && !matchNote && !matchAmount) return false;
    }
    if (filterType != 'all' && record.type != filterType) return false;
    if (filterCategories.isNotEmpty &&
        !filterCategories.contains(record.categoryId)) return false;
    if (minAmount != null && record.amount < minAmount!) return false;
    if (maxAmount != null && record.amount > maxAmount!) return false;
    if (filterLocation.isNotEmpty) {
      final location = record.location ?? '';
      if (!location.toLowerCase().contains(filterLocation.toLowerCase())) {
        return false;
      }
    }
    return true;
  }

  void resetFilters() {
    setState(() {
      filterType = 'all';
      filterCategories.clear();
      minAmount = null;
      maxAmount = null;
      filterLocation = '';
    });
  }

  void showFilterDialog({
    required List<Map<String, dynamic>> Function() getAllCategories,
    required VoidCallback onApply,
  }) {
    final minController = TextEditingController(
        text: minAmount != null ? minAmount.toString() : '');
    final maxController = TextEditingController(
        text: maxAmount != null ? maxAmount.toString() : '');
    final locationController = TextEditingController(text: filterLocation);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.tune, size: 20),
                SizedBox(width: DS.xs),
                Text('筛选条件'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('收支类型', style: DS.labelMd),
                  SizedBox(height: DS.sm),
                  Wrap(
                    spacing: DS.sm,
                    children: [
                      _buildFilterChip(label: '全部', selected: filterType == 'all', onTap: () => setDialogState(() => filterType = 'all')),
                      _buildFilterChip(label: '支出', selected: filterType == 'expense', onTap: () => setDialogState(() => filterType = 'expense')),
                      _buildFilterChip(label: '收入', selected: filterType == 'income', onTap: () => setDialogState(() => filterType = 'income')),
                    ],
                  ),
                  SizedBox(height: DS.gutter),
                  Text('分类', style: DS.labelMd),
                  SizedBox(height: DS.sm),
                  Wrap(
                    spacing: DS.sm,
                    runSpacing: DS.sm,
                    children: [
                      _buildFilterChip(label: '清除分类', selected: false, onTap: () => setDialogState(() => filterCategories.clear())),
                      ...getAllCategories().map((category) {
                        final isSelected = filterCategories.contains(category['id']);
                        return _buildFilterChip(
                          label: '${category['emoji']} ${category['name']}',
                          selected: isSelected,
                          onTap: () => setDialogState(() {
                            if (isSelected) {
                              filterCategories.remove(category['id']);
                            } else {
                              filterCategories.add(category['id']);
                            }
                          }),
                        );
                      }),
                    ],
                  ),
                  SizedBox(height: DS.gutter),
                  Text('金额范围', style: DS.labelMd),
                  SizedBox(height: DS.sm),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: minController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(hintText: '最低金额', isDense: true),
                          style: DS.bodyMd,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: DS.sm),
                        child: Text('~', style: DS.bodyMd),
                      ),
                      Expanded(
                        child: TextField(
                          controller: maxController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(hintText: '最高金额', isDense: true),
                          style: DS.bodyMd,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: DS.gutter),
                  Text('位置', style: DS.labelMd),
                  SizedBox(height: DS.sm),
                  TextField(
                    controller: locationController,
                    decoration: const InputDecoration(
                      hintText: '按位置关键词筛选',
                      isDense: true,
                      prefixIcon: Icon(Icons.place, size: 18),
                    ),
                    style: DS.bodyMd,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  resetFilters();
                  Navigator.pop(context);
                  onApply();
                },
                child: Text('清除'),
              ),
              ElevatedButton(
                onPressed: () {
                  final min = double.tryParse(minController.text.trim());
                  final max = double.tryParse(maxController.text.trim());
                  setState(() {
                    minAmount = min;
                    maxAmount = max;
                    filterLocation = locationController.text.trim();
                  });
                  Navigator.pop(context);
                  onApply();
                },
                child: Text('确定'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: DS.sm, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? DS.primary : DS.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(DS.radiusFull),
          border: Border.all(
            color: selected ? DS.primary : DS.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: DS.fontLabel,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? DS.onPrimary : DS.onSurface,
          ),
        ),
      ),
    );
  }
}

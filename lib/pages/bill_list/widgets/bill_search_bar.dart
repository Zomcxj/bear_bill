import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_design_system.dart';
import '../../../providers/theme_provider.dart';

/// 账单搜索筛选栏
class BillSearchBar extends StatelessWidget {
  final String keyword;
  final String filterType;
  final List<String> filterCategories;
  final Function(String) onKeywordChanged;
  final VoidCallback onFilterTap;

  const BillSearchBar({
    super.key,
    required this.keyword,
    required this.filterType,
    required this.filterCategories,
    required this.onKeywordChanged,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>(); // theme rebuild
    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: DS.base, vertical: 8),
      decoration: BoxDecoration(
        color: DS.surfaceContainerLowest,
        border: Border(bottom: BorderSide(color: DS.outlineVariant)),
      ),
      child: Row(
        children: [
          // 搜索框
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: DS.background,
                borderRadius: BorderRadius.circular(DS.radiusSm),
                border: Border.all(color: DS.outlineVariant),
              ),
              child: TextField(
                onChanged: onKeywordChanged,
                decoration: InputDecoration(
                  hintText: '搜索分类、备注、金额...',
                  hintStyle: DS.labelSm.copyWith(
                    color: DS.outline,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    size: 20,
                    color: DS.onSurfaceVariant,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: InputBorder.none,
                ),
                style: DS.labelMd,
              ),
            ),
          ),

          SizedBox(width: DS.base),

          // 筛选按钮
          GestureDetector(
            onTap: onFilterTap,
            child: Container(
              height: 40,
              padding: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: filterType != 'all' || filterCategories.isNotEmpty
                    ? DS.surfaceContainerHigh
                    : DS.background,
                borderRadius: BorderRadius.circular(DS.radiusSm),
                border: Border.all(
                  color: filterType != 'all' || filterCategories.isNotEmpty
                      ? DS.primary
                      : DS.outlineVariant,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.filter_list,
                    size: 18,
                    color: filterType != 'all' || filterCategories.isNotEmpty
                        ? DS.primary
                        : DS.onSurfaceVariant,
                  ),
                  SizedBox(width: 4),
                  Text(
                    '筛选',
                    style: DS.labelMd.copyWith(
                      color: filterType != 'all' || filterCategories.isNotEmpty
                          ? DS.primary
                          : DS.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

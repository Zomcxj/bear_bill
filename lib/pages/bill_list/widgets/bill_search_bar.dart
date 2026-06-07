import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

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
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          // 搜索框
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.bgPage,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppTheme.border),
              ),
              child: TextField(
                onChanged: onKeywordChanged,
                decoration: InputDecoration(
                  hintText: '搜索分类、备注、金额...',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textHint,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    size: 20,
                    color: AppTheme.textSecondary,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: InputBorder.none,
                ),
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),

          const SizedBox(width: AppSpacing.sm),

          // 筛选按钮
          GestureDetector(
            onTap: onFilterTap,
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: filterType != 'all' || filterCategories.isNotEmpty
                    ? AppTheme.primaryLight
                    : AppTheme.bgPage,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: filterType != 'all' || filterCategories.isNotEmpty
                      ? AppTheme.primary
                      : AppTheme.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.filter_list,
                    size: 18,
                    color: filterType != 'all' || filterCategories.isNotEmpty
                        ? AppTheme.primary
                        : AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '筛选',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: filterType != 'all' || filterCategories.isNotEmpty
                          ? AppTheme.primary
                          : AppTheme.textSecondary,
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

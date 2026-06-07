import 'package:flutter/material.dart';

import '../../../models/category_model.dart';
import '../../../theme/app_theme.dart';

/// 将 hex 颜色字符串转换为 Color
Color _hexToColor(String hex) {
  final buffer = StringBuffer();
  if (hex.length == 6 || hex.length == 7) buffer.write('ff');
  buffer.write(hex.replaceFirst('#', ''));
  return Color(int.parse(buffer.toString(), radix: 16));
}

/// 搜索筛选栏
class SearchFilterBar extends StatefulWidget {
  final String keyword;
  final String filterType;
  final List<String> filterCategories;
  final bool showFilter;
  final Function(String) onSearchChanged;
  final Function(String) onFilterTypeChanged;
  final Function(String) onCategoryToggled;
  final VoidCallback onClearFilter;

  const SearchFilterBar({
    super.key,
    required this.keyword,
    required this.filterType,
    required this.filterCategories,
    required this.showFilter,
    required this.onSearchChanged,
    required this.onFilterTypeChanged,
    required this.onCategoryToggled,
    required this.onClearFilter,
  });

  @override
  State<SearchFilterBar> createState() => _SearchFilterBarState();
}

class _SearchFilterBarState extends State<SearchFilterBar> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.keyword);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 搜索栏
        Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: '搜索分类、备注或金额',
                      prefixIcon: const Icon(Icons.search, color: AppTheme.textHint),
                      suffixIcon: widget.keyword.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _controller.clear();
                                widget.onSearchChanged('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: widget.onSearchChanged,
                  ),
                ),
              ),
              
              const SizedBox(width: AppSpacing.xs),
              
              // 筛选按钮
              GestureDetector(
                onTap: () {
                  // Toggle filter panel visibility handled by parent
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: widget.showFilter 
                        ? AppTheme.primaryLight 
                        : Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: widget.showFilter 
                          ? AppTheme.primary 
                          : AppTheme.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '筛选',
                        style: TextStyle(
                          fontSize: 14,
                          color: widget.showFilter 
                              ? AppTheme.primaryDark 
                              : AppTheme.textSecondary,
                        ),
                      ),
                      if (widget.filterCategories.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                          child: Text(
                            '${widget.filterCategories.length}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // 筛选面板
        if (widget.showFilter) _buildFilterPanel(),
      ],
    );
  }

  Widget _buildFilterPanel() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 类型筛选
          const Text(
            '类型',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChip('全部', 'all'),
              _buildFilterChip('支出', 'expense'),
              _buildFilterChip('收入', 'income'),
            ],
          ),
          
          const SizedBox(height: AppSpacing.sm),
          
          // 分类筛选
          const Text(
            '分类',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...expenseCategories.map((c) => _buildCategoryChip(c)),
              ...incomeCategories.map((c) => _buildCategoryChip(c)),
            ],
          ),
          
          const SizedBox(height: AppSpacing.sm),
          
          // 清除筛选
          Center(
            child: GestureDetector(
              onTap: widget.onClearFilter,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.bgSection,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: const Text(
                  '清除筛选',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String type) {
    final isSelected = widget.filterType == type;
    return GestureDetector(
      onTap: () => widget.onFilterTypeChanged(type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isSelected ? AppTheme.primaryDark : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(CategoryModel category) {
    final isSelected = widget.filterCategories.contains(category.id);
    return GestureDetector(
      onTap: () => widget.onCategoryToggled(category.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? _hexToColor(category.color).withOpacity(0.2)
              : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: isSelected 
                ? _hexToColor(category.color)
                : AppTheme.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(category.icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              category.name,
              style: TextStyle(
                fontSize: 12,
                color: isSelected
                    ? _hexToColor(category.color)
                    : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

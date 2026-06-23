import 'package:flutter/material.dart';

import '../../../models/category_model.dart';
import '../../../theme/app_design_system.dart';
import '../../../theme/app_theme.dart';
import '../../../providers/theme_provider.dart';

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
    context.watch<ThemeProvider>(); // theme rebuild
    return Column(
      children: [
        // 搜索栏
        Padding(
          padding: EdgeInsets.all(DS.base),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: DS.glassDecoration.copyWith(
                    borderRadius: BorderRadius.circular(DS.radiusSm),
                  ),
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: '搜索分类、备注或金额',
                      prefixIcon: Icon(Icons.search, color: DS.outline),
                      suffixIcon: widget.keyword.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _controller.clear();
                                widget.onSearchChanged('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: widget.onSearchChanged,
                  ),
                ),
              ),

              SizedBox(width: DS.xs),

              // 筛选按钮
              GestureDetector(
                onTap: () {
                  // Toggle filter panel visibility handled by parent
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: widget.showFilter
                        ? DS.surfaceContainerHigh
                        : DS.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(DS.radiusSm),
                    border: Border.all(
                      color: widget.showFilter
                          ? DS.primary
                          : DS.outlineVariant,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '筛选',
                        style: DS.labelMd.copyWith(
                          color: widget.showFilter
                              ? DS.primaryContainer
                              : DS.onSurfaceVariant,
                        ),
                      ),
                      if (widget.filterCategories.isNotEmpty) ...[
                        SizedBox(width: 4),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: DS.primary,
                            borderRadius: BorderRadius.circular(DS.radiusFull),
                          ),
                          child: Text(
                            '${widget.filterCategories.length}',
                            style: TextStyle(
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
      margin: EdgeInsets.symmetric(horizontal: DS.sm),
      padding: EdgeInsets.all(DS.base),
      decoration: DS.glassDecoration.copyWith(
        borderRadius: BorderRadius.circular(DS.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 类型筛选
          Text(
            '类型',
            style: DS.labelMd.copyWith(
              color: DS.onSurface,
            ),
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChip('全部', 'all'),
              _buildFilterChip('支出', 'expense'),
              _buildFilterChip('收入', 'income'),
            ],
          ),

          SizedBox(height: DS.base),

          // 分类筛选
          Text(
            '分类',
            style: DS.labelMd.copyWith(
              color: DS.onSurface,
            ),
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...expenseCategories.map((c) => _buildCategoryChip(c)),
              ...incomeCategories.map((c) => _buildCategoryChip(c)),
            ],
          ),

          SizedBox(height: DS.base),

          // 清除筛选
          Center(
            child: GestureDetector(
              onTap: widget.onClearFilter,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: DS.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(DS.radiusFull),
                ),
                child: Text(
                  '清除筛选',
                  style: DS.labelSm.copyWith(
                    color: DS.onSurfaceVariant,
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
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? DS.surfaceContainerHigh : DS.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(DS.radiusFull),
          border: Border.all(
            color: isSelected ? DS.primary : DS.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: DS.labelSm.copyWith(
            color: isSelected ? DS.primaryContainer : DS.onSurfaceVariant,
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
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? _hexToColor(category.color).withOpacity(0.2)
              : DS.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(DS.radiusFull),
          border: Border.all(
            color: isSelected
                ? _hexToColor(category.color)
                : DS.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(category.icon, style: TextStyle(fontSize: 14)),
            SizedBox(width: 4),
            Text(
              category.name,
              style: DS.labelSm.copyWith(
                color: isSelected
                    ? _hexToColor(category.color)
                    : DS.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

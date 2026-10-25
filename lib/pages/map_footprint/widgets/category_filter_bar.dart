import 'package:flutter/material.dart';

import '../../../theme/app_design_system.dart';
import '../../../theme/glass_materials.dart';
import '../../../providers/theme_provider.dart';
import '../../../services/category_order_service.dart';
import 'package:provider/provider.dart';

/// 地图分类筛选条
class CategoryFilterBar extends StatelessWidget {
  final String? selectedCategoryId;
  final Function(String?) onFilter;

  const CategoryFilterBar({
    super.key,
    required this.selectedCategoryId,
    required this.onFilter,
  });

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>(); // theme rebuild
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: DS.surfaceContainerLowest,
        // 玻璃主题无边框；关闭态原样
        border: shouldUseLiquidGlass(context)
            ? null
            : Border(bottom: BorderSide(color: DS.outlineVariant)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 8),
        children: [
          _buildChip(context, null, '全部', Icons.all_inclusive),
          // 跟随用户自定义的分类顺序
          ...CategoryOrderService.instance.expense
              .map((c) => _buildChip(context, c.id, c.name, null, c.icon)),
        ],
      ),
    );
  }

  Widget _buildChip(
    BuildContext context,
    String? id,
    String label,
    IconData? icon, [
    String? emoji,
  ]) {
    final isSelected = id == selectedCategoryId;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: GestureDetector(
        onTap: () => onFilter(isSelected ? null : id),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected ? DS.emphasis : DS.background,
            borderRadius: BorderRadius.circular(DS.radiusFull),
            // 玻璃主题无边框，选中靠填充；关闭态原样
            border: shouldUseLiquidGlass(context)
                ? null
                : Border.all(
                    color: isSelected ? DS.emphasis : DS.outlineVariant,
                  ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (emoji != null)
                Text(emoji, style: TextStyle(fontSize: 14))
              else if (icon != null)
                Icon(
                    icon,
                    size: 14,
                    color: isSelected
                        ? (DS.isDark ? DS.background : Colors.white)
                        : DS.onSurfaceVariant),
              SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected
                      ? (DS.isDark ? DS.background : Colors.white)
                      : DS.onSurface,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

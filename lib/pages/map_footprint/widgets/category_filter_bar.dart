import 'package:flutter/material.dart';

import '../../../models/models.dart';
import '../../../theme/app_design_system.dart';

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
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: DS.surfaceContainerLowest,
        border: Border(bottom: BorderSide(color: DS.outlineVariant)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 8),
        children: [
          _buildChip(null, '全部', Icons.all_inclusive),
          ...expenseCategories.map((c) => _buildChip(c.id, c.name, null, c.icon)),
        ],
      ),
    );
  }

  Widget _buildChip(String? id, String label, IconData? icon, [String? emoji]) {
    final isSelected = id == selectedCategoryId;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: GestureDetector(
        onTap: () => onFilter(isSelected ? null : id),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected ? DS.primary : DS.background,
            borderRadius: BorderRadius.circular(DS.radiusFull),
            border: Border.all(
              color: isSelected ? DS.primary : DS.outlineVariant,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (emoji != null)
                Text(emoji, style: TextStyle(fontSize: 14))
              else if (icon != null)
                Icon(icon, size: 14, color: isSelected ? Colors.white : DS.onSurfaceVariant),
              SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.white : DS.onSurface,
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

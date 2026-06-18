import 'package:flutter/material.dart';

import '../../../models/models.dart';
import '../../../theme/app_theme.dart';

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
        color: AppTheme.bgCard,
        border: Border(bottom: BorderSide(color: AppTheme.divider)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
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
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: GestureDetector(
        onTap: () => onFilter(isSelected ? null : id),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : AppTheme.bgPage,
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(
              color: isSelected ? AppTheme.primary : AppTheme.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (emoji != null)
                Text(emoji, style: const TextStyle(fontSize: 14))
              else if (icon != null)
                Icon(icon, size: 14, color: isSelected ? Colors.white : AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.white : AppTheme.textPrimary,
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

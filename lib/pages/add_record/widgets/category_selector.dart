import 'package:flutter/material.dart';

import '../../../models/models.dart';
import '../../../theme/app_design_system.dart';
import '../../../providers/theme_provider.dart';
import 'package:provider/provider.dart';

/// 将 hex 颜色字符串转换为 Color
Color _hexToColor(String hex) {
  final buffer = StringBuffer();
  if (hex.length == 6 || hex.length == 7) buffer.write('ff');
  buffer.write(hex.replaceFirst('#', ''));
  return Color(int.parse(buffer.toString(), radix: 16));
}

/// 分类选择器
class CategorySelector extends StatelessWidget {
  final List<CategoryModel> categories;
  final CategoryModel? selectedCategory;
  final Function(CategoryModel) onSelect;

  const CategorySelector({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>(); // theme rebuild
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: DS.base, vertical: DS.xs),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: categories.map((category) {
            final isSelected = selectedCategory?.id == category.id;
            return GestureDetector(
              onTap: () => onSelect(category),
              child: Container(
                margin: EdgeInsets.only(right: DS.base),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _hexToColor(category.color).withOpacity(0.15)
                            : DS.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? _hexToColor(category.color)
                              : DS.outlineVariant,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          category.icon,
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      category.name,
                      style: TextStyle(
                        fontSize: 11,
                        color: isSelected
                            ? _hexToColor(category.color)
                            : DS.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

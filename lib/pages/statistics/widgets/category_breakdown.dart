import 'package:flutter/material.dart';

import '../../../theme/app_design_system.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/utils.dart';
import '../../../providers/theme_provider.dart';
import 'package:provider/provider.dart';

/// 分类明细列表
class CategoryBreakdown extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  final void Function(Map<String, dynamic> category)? onCategoryTap;

  const CategoryBreakdown({
    super.key,
    required this.categories,
    this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>(); // theme rebuild
    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(DS.gutter),
      decoration: DS.glassDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart, size: 18, color: DS.primary),
              SizedBox(width: 6),
              Text(
                '分类明细',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: DS.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: DS.base),
          ...categories.map((category) => _buildCategoryItem(category)),
        ],
      ),
    );
  }

  Color _hexToColor(String? hex) {
    if (hex == null || hex.isEmpty) return DS.primary;
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  Widget _buildCategoryItem(Map<String, dynamic> category) {
    final amount = category['amount'] as double;
    final percent = category['percent'] as double;
    final count = category['count'] as int? ?? 0;

    return GestureDetector(
      onTap: onCategoryTap != null ? () => onCategoryTap!(category) : null,
      behavior: HitTestBehavior.opaque,
      child: Padding(
      padding: EdgeInsets.only(bottom: DS.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 分类图标和名称
              Row(
                children: [
                  Text(category['icon'], style: TextStyle(fontSize: 20)),
                  SizedBox(width: 8),
                  Text(
                    category['name'],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: DS.onSurface,
                    ),
                  ),
                  SizedBox(width: 4),
                  Text(
                    '($count笔)',
                    style: TextStyle(
                      fontSize: 12,
                      color: DS.outline,
                    ),
                  ),
                ],
              ),

              Spacer(),

              // 金额和百分比
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '¥${FormatUtils.formatAmount(amount)}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: DS.onSurface,
                    ),
                  ),
                  Text(
                    '${percent.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: DS.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: 8),

          // 进度条
          ClipRRect(
            borderRadius: BorderRadius.circular(DS.radiusFull),
            child: LinearProgressIndicator(
              value: percent / 100,
              backgroundColor: DS.surfaceContainerLow,
              valueColor: AlwaysStoppedAnimation<Color>(
                _hexToColor(category['color'] as String?),
              ),
              minHeight: 8,
            ),
          ),
        ],
      ),
    ),
    );
  }
}

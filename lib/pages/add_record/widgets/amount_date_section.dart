import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/models.dart';
import '../../../theme/app_design_system.dart';
import '../../../providers/theme_provider.dart';

/// 金额展示 + 日期选择 + 快捷金额标签
class AmountDateSection extends StatelessWidget {
  final String amount;
  final String type;
  final CategoryModel? selectedCategory;
  final DateTime selectedDate;
  final ValueChanged<String> onAmountChanged;
  final VoidCallback onDateSelect;

  const AmountDateSection({
    super.key,
    required this.amount,
    required this.type,
    required this.selectedCategory,
    required this.selectedDate,
    required this.onAmountChanged,
    required this.onDateSelect,
  });

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>(); // theme rebuild
    final accentColor =
        type == 'expense' ? DS.error : DS.secondary;

    return Container(
      decoration: BoxDecoration(
        gradient: DS.heroGradientBlueCurrent,
      ),
      padding: EdgeInsets.all(DS.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(DS.gutter),
            decoration: BoxDecoration(
              color: DS.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(DS.radiusMd),
              border: Border.all(color: accentColor.withOpacity(0.12)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildInfoPill(
                      icon: selectedCategory?.icon ?? '🍜',
                      label: selectedCategory?.name ?? '餐饮',
                      backgroundColor: DS.primary,
                      textColor: Colors.white,
                    ),
                    SizedBox(width: DS.sm),
                    GestureDetector(
                      onTap: onDateSelect,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: DS.sm, vertical: 7),
                        decoration: BoxDecoration(
                          color: DS.heroCardBg,
                          borderRadius: BorderRadius.circular(DS.radiusFull),
                          border: Border.all(color: DS.heroCardBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.calendar_today, size: 14, color: DS.onSurface),
                            SizedBox(width: DS.xs),
                            Text(
                              '${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                fontFamily: DS.fontLabel,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: DS.onSurface,
                              ),
                            ),
                            SizedBox(width: 2),
                            Icon(Icons.chevron_right, size: 14, color: DS.outline),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: DS.gutter),
                Text(
                  amount.isEmpty ? '¥0' : '¥$amount',
                  style: TextStyle(
                    fontFamily: DS.fontDisplay,
                    fontSize: 36,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    color: DS.onSurface,
                    letterSpacing: -1.5,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: DS.base),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['10', '20', '50', '100', '200', '500'].map((quickAmount) {
                final isSelected = amount == quickAmount;
                return Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => onAmountChanged(quickAmount),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? accentColor : DS.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(DS.radiusFull),
                        border: Border.all(
                          color: isSelected
                              ? accentColor
                              : accentColor.withOpacity(0.18),
                        ),
                      ),
                      child: Text(
                        '¥$quickAmount',
                        style: TextStyle(
                          fontSize: 13,
                          color: isSelected ? Colors.white : accentColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// 胶囊形状的信息标签（私有辅助方法）
Widget _buildInfoPill({
  required String icon,
  required String label,
  required Color backgroundColor,
  required Color textColor,
  Widget? trailing,
}) {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(DS.radiusFull),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: TextStyle(fontSize: 16)),
        SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (trailing != null) ...[
          SizedBox(width: 2),
          trailing,
        ],
      ],
    ),
  );
}

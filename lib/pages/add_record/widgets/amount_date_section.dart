import 'package:flutter/material.dart';

import '../../../models/models.dart';
import '../../../theme/app_theme.dart';

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
    final panelColor = AppTheme.primaryLight;
    final accentColor =
        type == 'expense' ? AppTheme.primaryDark : AppTheme.primary;

    return Container(
      color: panelColor,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(AppRadius.lg),
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
                      backgroundColor: AppTheme.primary,
                      textColor: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: onDateSelect,
                      child: _buildInfoPill(
                        icon: '📅',
                        label:
                            '${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                        backgroundColor: AppTheme.bgSection,
                        textColor: AppTheme.textPrimary,
                        trailing: Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: AppTheme.textHint,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  amount.isEmpty ? '¥0' : '¥$amount',
                  style: TextStyle(
                    fontSize: 34,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                    letterSpacing: -1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['10', '20', '50', '100', '200', '500'].map((quickAmount) {
                final isSelected = amount == quickAmount;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => onAmountChanged(quickAmount),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? accentColor : AppTheme.bgCard,
                        borderRadius: BorderRadius.circular(AppRadius.full),
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
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(AppRadius.full),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 2),
          trailing,
        ],
      ],
    ),
  );
}

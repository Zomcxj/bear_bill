import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../utils/utils.dart' as utils;

/// 月份选择器 - 顶部切换条
class MonthSelector extends StatelessWidget {
  final String currentMonth;
  final double totalExpense;
  final double totalIncome;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<String>? onMonthPicked;

  const MonthSelector({
    super.key,
    required this.currentMonth,
    required this.totalExpense,
    required this.totalIncome,
    required this.onPrevMonth,
    required this.onNextMonth,
    this.onMonthPicked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          // 上一月按钮
          GestureDetector(
            onTap: onPrevMonth,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.bgSection,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Icon(Icons.chevron_left, color: AppTheme.textSecondary),
            ),
          ),
          
          const SizedBox(width: AppSpacing.sm),
          
          // 月份和统计信息
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: onMonthPicked != null
                      ? () => _pickYearMonth(context)
                      : null,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        utils.DateUtils.formatMonthCN(currentMonth),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      if (onMonthPicked != null)
                        Icon(Icons.unfold_more, size: 18, color: AppTheme.textHint),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '支 ¥${utils.FormatUtils.formatAmount(totalExpense)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryDark,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text('|', style: TextStyle(color: AppTheme.textHint)),
                    ),
                    Text(
                      '收 ¥${utils.FormatUtils.formatAmount(totalIncome)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.success,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(width: AppSpacing.sm),
          
          // 下一月按钮
          GestureDetector(
            onTap: onNextMonth,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.bgSection,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Icon(Icons.chevron_right, color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  void _pickYearMonth(BuildContext context) {
    final parts = currentMonth.split('-');
    int selectedYear = int.parse(parts[0]);
    int selectedMonth = int.parse(parts[1]);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => setState(() => selectedYear--),
                ),
                Text(
                  '$selectedYear 年',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: selectedYear < DateTime.now().year
                      ? () => setState(() => selectedYear++)
                      : null,
                ),
              ],
            ),
            content: SizedBox(
              width: 280,
              child: GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.4,
                ),
                itemCount: 12,
                itemBuilder: (_, i) {
                  final month = i + 1;
                  final isCurrent = month == selectedMonth;
                  final isFuture = selectedYear == DateTime.now().year &&
                      month > DateTime.now().month;
                  return GestureDetector(
                    onTap: isFuture
                        ? null
                        : () {
                            final m = month.toString().padLeft(2, '0');
                            onMonthPicked?.call('$selectedYear-$m');
                            Navigator.pop(ctx);
                          },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isCurrent ? AppTheme.primary : AppTheme.bgSection,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$month 月',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                          color: isFuture
                              ? AppTheme.textHint
                              : isCurrent
                                  ? Colors.white
                                  : AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

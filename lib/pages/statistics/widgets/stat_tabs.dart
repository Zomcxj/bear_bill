import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../utils/utils.dart';

/// 统计页 Tab 切换器
class StatTabs extends StatelessWidget {
  final String activeTab;
  final double totalExpense;
  final double totalIncome;
  final Function(String) onTabChanged;

  const StatTabs({
    super.key,
    required this.activeTab,
    required this.totalExpense,
    required this.totalIncome,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onTabChanged('expense'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: activeTab == 'expense'
                      ? AppTheme.primaryLight
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: activeTab == 'expense'
                        ? AppTheme.primary
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          '💸',
                          style: TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '支出',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: activeTab == 'expense'
                                ? AppTheme.primaryDark
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '¥${FormatUtils.formatAmount(totalExpense)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: activeTab == 'expense'
                            ? AppTheme.primaryDark
                            : AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: GestureDetector(
              onTap: () => onTabChanged('income'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: activeTab == 'income'
                      ? AppTheme.primaryLight
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: activeTab == 'income'
                        ? AppTheme.primary
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          '💰',
                          style: TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '收入',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: activeTab == 'income'
                                ? AppTheme.primaryDark
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '¥${FormatUtils.formatAmount(totalIncome)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: activeTab == 'income'
                            ? AppTheme.primaryDark
                            : AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

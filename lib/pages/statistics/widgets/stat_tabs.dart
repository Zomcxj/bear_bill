import 'package:flutter/material.dart';

import '../../../theme/app_design_system.dart';
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
      padding: EdgeInsets.all(DS.base),
      decoration: BoxDecoration(
        color: DS.surfaceContainerLowest,
        border: Border(bottom: BorderSide(color: DS.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onTabChanged('expense'),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: activeTab == 'expense'
                      ? DS.surfaceContainerHigh
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(DS.radiusMd),
                  border: Border.all(
                    color: activeTab == 'expense'
                        ? DS.primary
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
                        Icon(
                          Icons.trending_down,
                          size: 14,
                          color: activeTab == 'expense'
                              ? DS.primaryContainer
                              : DS.onSurfaceVariant,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '支出',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: activeTab == 'expense'
                                ? DS.primaryContainer
                                : DS.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      '¥${FormatUtils.formatAmount(totalExpense)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: activeTab == 'expense'
                            ? DS.primaryContainer
                            : DS.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: DS.base),
          Expanded(
            child: GestureDetector(
              onTap: () => onTabChanged('income'),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: activeTab == 'income'
                      ? DS.surfaceContainerHigh
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(DS.radiusMd),
                  border: Border.all(
                    color: activeTab == 'income'
                        ? DS.primary
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
                        Icon(
                          Icons.trending_up,
                          size: 14,
                          color: activeTab == 'income'
                              ? DS.primaryContainer
                              : DS.onSurfaceVariant,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '收入',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: activeTab == 'income'
                                ? DS.primaryContainer
                                : DS.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      '¥${FormatUtils.formatAmount(totalIncome)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: activeTab == 'income'
                            ? DS.primaryContainer
                            : DS.onSurface,
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

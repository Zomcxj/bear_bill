import 'package:flutter/material.dart';

import '../../../theme/app_design_system.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/utils.dart';

/// 收支结余概览卡片
class IncomeExpenseSummary extends StatelessWidget {
  final double expense;
  final double income;
  final double balance;

  const IncomeExpenseSummary({
    super.key,
    required this.expense,
    required this.income,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(DS.base),
      padding: EdgeInsets.symmetric(vertical: DS.gutter),
      decoration: BoxDecoration(
        gradient: DS.heroGradientBlueCurrent,
        borderRadius: BorderRadius.all(Radius.circular(DS.radiusMd)),
      ),
      child: Row(
        children: [
          // 支出
          Expanded(
            child: Column(
              children: [
                Icon(Icons.arrow_downward, size: 22, color: DS.primaryContainer),
                SizedBox(height: 4),
                Text(
                  '¥${FormatUtils.formatAmount(expense)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: DS.primaryContainer,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '支出',
                  style: TextStyle(
                    fontSize: 12,
                    color: DS.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // 分隔线
          Container(
            width: 1,
            height: 50,
            color: DS.outlineVariant,
          ),

          // 收入
          Expanded(
            child: Column(
              children: [
                Icon(Icons.arrow_upward, size: 22, color: DS.secondary),
                SizedBox(height: 4),
                Text(
                  '¥${FormatUtils.formatAmount(income)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: DS.secondary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '收入',
                  style: TextStyle(
                    fontSize: 12,
                    color: DS.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // 分隔线
          Container(
            width: 1,
            height: 50,
            color: DS.outlineVariant,
          ),

          // 结余
          Expanded(
            child: Column(
              children: [
                Icon(Icons.savings, size: 22, color: DS.secondary),
                SizedBox(height: 4),
                Text(
                  '¥${FormatUtils.formatAmount(balance)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: balance >= 0
                        ? const Color(0xFFE6A817)
                        : const Color(0xFFD32F2F),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '结余',
                  style: TextStyle(
                    fontSize: 12,
                    color: DS.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

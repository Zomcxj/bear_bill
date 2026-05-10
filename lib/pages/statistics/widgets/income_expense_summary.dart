import 'package:flutter/material.dart';

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
      margin: const EdgeInsets.all(AppSpacing.sm),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 支出
          Expanded(
            child: Column(
              children: [
                const Text('💸', style: TextStyle(fontSize: 22)),
                const SizedBox(height: 4),
                Text(
                  '¥${FormatUtils.formatAmount(expense)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFE8607A),
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  '支出',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
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
            color: AppTheme.border,
          ),

          // 收入
          Expanded(
            child: Column(
              children: [
                const Text('💰', style: TextStyle(fontSize: 22)),
                const SizedBox(height: 4),
                Text(
                  '¥${FormatUtils.formatAmount(income)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  '收入',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
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
            color: AppTheme.border,
          ),

          // 结余
          Expanded(
            child: Column(
              children: [
                const Text('🐷', style: TextStyle(fontSize: 22)),
                const SizedBox(height: 4),
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
                const SizedBox(height: 2),
                const Text(
                  '结余',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
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

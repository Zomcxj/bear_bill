import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/app_provider.dart';
import '../../../services/database_service.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/utils.dart' as utils;

/// 月度预算进度条卡片（对齐小程序 section-card 样式）
class BudgetProgressCard extends StatefulWidget {
  const BudgetProgressCard({super.key});

  @override
  State<BudgetProgressCard> createState() => _BudgetProgressCardState();
}

class _BudgetProgressCardState extends State<BudgetProgressCard> {
  double _budget = 0.0;
  double _totalExpense = 0.0;
  double _budgetPct = 0.0;
  bool _budgetOver = false;
  String _budgetRemain = '';

  @override
  void initState() {
    super.initState();
    _loadBudget();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      appProvider.addListener(_loadBudget);
    });
  }

  @override
  void dispose() {
    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      appProvider.removeListener(_loadBudget);
    } catch (_) {}
    super.dispose();
  }

  Future<void> _loadBudget() async {
    final appProvider = context.read<AppProvider>();
    final book = await appProvider.getCurrentBook();
    if (book == null || book.budget <= 0) {
      if (mounted) setState(() => _budget = 0.0);
      return;
    }

    final currentMonth = utils.DateUtils.getCurrentMonth();
    final stats = await DatabaseService.instance.getMonthStatistics(
      currentMonth,
      bookId: appProvider.currentBookId,
    );

    final expense = stats['expense'] ?? 0.0;
    final budget = book.budget;
    final pct = utils.FormatUtils.calculatePercentage(expense, budget);
    final remain = budget - expense;

    if (mounted) {
      setState(() {
        _budget = budget;
        _totalExpense = expense;
        _budgetPct = pct;
        _budgetOver = expense > budget;
        _budgetRemain = _budgetOver
            ? '已超支 ¥${utils.FormatUtils.formatAmount(-remain)}'
            : '剩余 ¥${utils.FormatUtils.formatAmount(remain)}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_budget <= 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppTheme.border, width: 1),
        boxShadow: AppShadow.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Text('🎯', style: TextStyle(fontSize: 16)),
                  SizedBox(width: 6),
                  Text(
                    '月预算',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    '¥${utils.FormatUtils.formatAmountWithComma(_totalExpense)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    ' / ¥${utils.FormatUtils.formatAmountWithComma(_budget)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textHint,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // 进度条轨道
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: AppTheme.bgSection,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOut,
                width: MediaQuery.of(context).size.width *
                    (_budgetPct.clamp(0, 100) / 100) *
                    0.8, // 相对容器宽度
                decoration: BoxDecoration(
                  color: _budgetOver
                      ? const Color(0xFFFF4444)
                      : AppTheme.primary,
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // 剩余金额
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              _budgetRemain,
              style: TextStyle(
                fontSize: 12,
                fontWeight: _budgetOver ? FontWeight.w600 : FontWeight.w500,
                color: _budgetOver ? const Color(0xFFFF4444) : AppTheme.success,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../theme/app_design_system.dart';
import '../../../utils/utils.dart';
import '../../../providers/theme_provider.dart';
import 'package:provider/provider.dart';

/// 月度总结 - 小熊助手文案
class MonthlySummary extends StatelessWidget {
  final double expense;
  final double income;
  final double balance;
  final Map<String, dynamic>? topCategory;

  const MonthlySummary({
    super.key,
    required this.expense,
    required this.income,
    required this.balance,
    this.topCategory,
  });

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>(); // theme rebuild
    final lines = _generateSummary();

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DS.background,
        borderRadius: BorderRadius.circular(DS.radiusLg),
        border: Border.all(color: DS.outlineVariant, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 20, color: DS.primary),
              SizedBox(width: 6),
              Text(
                '小熊助手报告',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: DS.primaryContainer,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          ...lines.map((line) => Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Text(
                  line,
                  style: TextStyle(
                    fontSize: 13,
                    color: DS.onSurface,
                    height: 1.5,
                  ),
                ),
              )),
        ],
      ),
    );
  }

  List<String> _generateSummary() {
    final lines = <String>[];

    // 结余情况
    if (balance > 0) {
      lines.add('本月结余 ¥${FormatUtils.formatAmount(balance)}，小熊为你鼓掌！🎉');
    } else if (balance == 0) {
      lines.add('本月收支完美平衡，厉害哦！⚖️');
    } else {
      lines.add('本月超支 ¥${FormatUtils.formatAmount(-balance)}，下月要省着点哦～😅');
    }

    // 最高分类
    if (topCategory != null && expense > 0) {
      final percent = topCategory!['percent'] as double;
      lines.add(
        '花费最多的是「${topCategory!['icon']}${topCategory!['name']}」，'
        '占总支出 ${percent.toStringAsFixed(1)}%',
      );
    }

    // 记账建议
    if (expense > income * 0.8 && income > 0) {
      lines.add('支出接近收入的80%了，记得留点钱存起来哦～💰');
    } else if (expense < income * 0.5 && income > 0) {
      lines.add('太棒了！支出控制在收入的一半以内，继续保持！✨');
    }

    return lines;
  }
}

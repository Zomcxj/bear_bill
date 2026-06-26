import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/app_provider.dart';
import '../../../services/database_service.dart';
import '../../../theme/app_design_system.dart';
import '../../../theme/app_theme.dart';

/// 显示月度预算设置对话框
Future<void> showBudgetDialog(BuildContext context) async {
  final appProvider = context.read<AppProvider>();
  final book = await appProvider.getCurrentBook();
  final currentBudget = book?.budget ?? 0.0;
  final controller = TextEditingController(
    text: currentBudget > 0 ? currentBudget.toStringAsFixed(0) : '',
  );

  if (!context.mounted) return;

  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.savings, color: DS.primary, size: 24),
          SizedBox(width: 8),
          Text('每月预算'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('设置当月消费预算上限，超支时会提醒。'),
          SizedBox(height: 16),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: false),
            decoration: const InputDecoration(
              hintText: '输入预算金额（元）',
              prefixText: '¥ ',
              border: OutlineInputBorder(),
            ),
          ),
          if (currentBudget > 0) ...[
            SizedBox(height: 8),
            Text(
              '当前预算：¥${currentBudget.toStringAsFixed(0)}',
              style: DS.labelSm.copyWith(color: DS.outline),
            ),
          ],
        ],
      ),
      actions: [
        if (currentBudget > 0)
          TextButton(
            onPressed: () async {
              final updated = book!.copyWith(budget: 0);
              await DatabaseService.instance.updateBook(updated);
              appProvider.refreshCurrentBook();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('已清除月度预算'),
                    backgroundColor: AppTheme.success,
                  ),
                );
              }
            },
            child: Text('清除预算', style: TextStyle(color: Colors.red)),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('取消'),
        ),
        TextButton(
          onPressed: () async {
            final value = double.tryParse(controller.text) ?? 0;
            if (value <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('请输入有效的预算金额')),
              );
              return;
            }
            final updated = book!.copyWith(budget: value);
            await DatabaseService.instance.updateBook(updated);
            appProvider.refreshCurrentBook();
            appProvider.checkBudgetAchievements();
            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('已设置月预算 ¥${value.toStringAsFixed(0)}'),
                  backgroundColor: AppTheme.success,
                ),
              );
            }
          },
          child: Text('确认', style: TextStyle(color: DS.primary)),
        ),
      ],
    ),
  );
}

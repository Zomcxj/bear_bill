import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/app_provider.dart';
import '../../../services/database_service.dart';
import '../../../theme/app_design_system.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/glass_dialog_shell.dart';

/// 显示月度预算设置对话框
Future<void> showBudgetDialog(BuildContext context) async {
  final appProvider = context.read<AppProvider>();
  final book = await appProvider.getCurrentBook();
  final currentBudget = book?.budget ?? 0.0;
  final controller = TextEditingController(
    text: currentBudget > 0 ? currentBudget.toStringAsFixed(0) : '',
  );

  if (!context.mounted) return;

  await showGlassDialog(
    context: context,
    title: '每月预算',
    maxWidth: 320,
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('设置当月消费预算上限，超支时会提醒。',
            style: DS.bodyMd.copyWith(color: DS.onSurfaceVariant)),
        SizedBox(height: DS.base),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: false),
          style: DS.bodyMd.copyWith(color: DS.onSurface),
          decoration: glassDialogInputDecoration(
            context,
            hintText: '输入预算金额（元）',
            prefixText: '¥ ',
          ),
        ),
        if (currentBudget > 0) ...[
          SizedBox(height: DS.sm),
          Text(
            '当前预算：¥${currentBudget.toStringAsFixed(0)}',
            style: DS.labelSm.copyWith(color: DS.onSurfaceVariant),
          ),
        ],
      ],
    ),
    buildActions: (ctx) => [
      if (currentBudget > 0)
        GlassDialogButton(
          label: '清除预算',
          isDestructive: true,
          onPressed: () async {
            final updated = book!.copyWith(budget: 0);
            await DatabaseService.instance.updateBook(updated);
            appProvider.refreshCurrentBook();
            if (!ctx.mounted) return;
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('已清除月度预算'),
                backgroundColor: AppTheme.success,
              ),
            );
          },
        ),
      GlassDialogButton(
        label: '取消',
        onPressed: () => Navigator.pop(ctx),
      ),
      GlassDialogButton(
        label: '确认',
        isPrimary: true,
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
          if (!ctx.mounted) return;
          Navigator.pop(ctx);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('已设置月预算 ¥${value.toStringAsFixed(0)}'),
              backgroundColor: AppTheme.success,
            ),
          );
        },
      ),
    ],
  );
}

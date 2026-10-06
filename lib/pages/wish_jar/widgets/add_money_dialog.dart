import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart'
    show GlassContainer, GlassDialogAction, GlassQuality;

import '../../../models/models.dart';
import '../../../theme/app_design_system.dart';
import '../../../theme/glass_materials.dart';
import '../../../utils/utils.dart';
import '../../../providers/theme_provider.dart';
import '../../../widgets/glass_dialog_shell.dart';
import 'package:provider/provider.dart';

/// 存钱对话框
class AddMoneyDialog extends StatefulWidget {
  final WishModel wish;
  final Function(double) onAdd;

  const AddMoneyDialog({
    super.key,
    required this.wish,
    required this.onAdd,
  });

  @override
  State<AddMoneyDialog> createState() => _AddMoneyDialogState();
}

class _AddMoneyDialogState extends State<AddMoneyDialog> {
  final _amountController = TextEditingController();

  static const List<double> _quickAmounts = [10, 50, 100, 200, 500];

  void _selectQuickAmount(double amount) {
    setState(() {
      _amountController.text = amount.toString();
    });
  }

  void _addMoney() {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效金额')),
      );
      return;
    }

    widget.onAdd(amount);
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>(); // theme rebuild
    final remaining = widget.wish.targetAmount - widget.wish.currentAmount;

    final body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 心愿信息
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(DS.base),
          decoration: BoxDecoration(
            color: shouldUseLiquidGlass(context)
                ? (DS.isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.white.withOpacity(0.45))
                : DS.surfaceContainerLow,
            borderRadius: BorderRadius.circular(DS.radiusSm),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.wish.title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: DS.onSurface,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '已存 ¥${FormatUtils.formatAmount(widget.wish.currentAmount)} / 心愿 ¥${FormatUtils.formatAmount(widget.wish.targetAmount)}',
                style: TextStyle(
                  fontSize: 13,
                  color: DS.onSurfaceVariant,
                ),
              ),
              if (remaining > 0) ...[
                SizedBox(height: 2),
                Text(
                  '还需 ¥${FormatUtils.formatAmount(remaining)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: DS.emphasis,
                  ),
                ),
              ],
            ],
          ),
        ),

        SizedBox(height: DS.gutter),

        // 快捷金额
        Text(
          '快捷金额：',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: shouldUseLiquidGlass(context)
                ? DS.onSurfaceVariant
                : DS.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _quickAmounts.map((amount) {
            final selected = _amountController.text == amount.toString();
            return GestureDetector(
              onTap: () => _selectQuickAmount(amount),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  // 玻璃态：托盘上的着色层（选中 = 强调填充，亮色下深色细边显形），
                  // 不做折射图层
                  color: shouldUseLiquidGlass(context)
                      ? (selected
                          ? (DS.isDark
                              ? Colors.white.withOpacity(0.22)
                              : Colors.white.withOpacity(0.75))
                          : (DS.isDark
                              ? Colors.white.withOpacity(0.12)
                              : Colors.white.withOpacity(0.45)))
                      : DS.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(DS.radiusFull),
                  border: shouldUseLiquidGlass(context)
                      ? (DS.isDark
                          ? Border.all(
                              color: Colors.white.withOpacity(0.16),
                            )
                          : Border.all(
                              color: Colors.black.withOpacity(0.10),
                            ))
                      : Border.all(color: DS.emphasis),
                ),
                child: Text(
                  '¥$amount',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: shouldUseLiquidGlass(context)
                        ? DS.onSurface
                        : DS.emphasis,
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        SizedBox(height: DS.gutter),

        // 自定义金额
        TextField(
          controller: _amountController,
          decoration: glassDialogInputDecoration(
            context,
            labelText: '存入金额',
            hintText: '输入金额',
            prefixIcon: const Icon(Icons.attach_money),
          ),
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
      ],
    );

    final actions = [
      GlassDialogAction(
        label: '取消',
        onPressed: () => Navigator.pop(context),
      ),
      GlassDialogAction(
        label: '确认存入',
        isPrimary: true,
        onPressed: _addMoney,
      ),
    ];

    if (!shouldUseLiquidGlass(context)) {
      return AlertDialog(
        title: Row(
          children: [
            Text(_getWishEmoji(widget.wish.title),
                style: TextStyle(fontSize: 24)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                '💰 存入心愿',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: body,
        actions: [
          TextButton(
            onPressed: actions[0].onPressed,
            child: Text(actions[0].label),
          ),
          ElevatedButton(
            onPressed: actions[1].onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: DS.secondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DS.radiusFull),
              ),
            ),
            child: Text(actions[1].label),
          ),
        ],
      );
    }

    // 开启液态玻璃：玻璃托盘（useOwnLayer: true，独立路由无父图层）+
    // 自绘玻璃按钮（官方 GlassDialogAction 样式过素，「确认存入」改用
    // GlassPanelButton 强调胶囊，与全站玻璃按钮语言一致）
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: GlassContainer(
          shape: GlassMaterials.shape(24),
          settings: GlassMaterials.bar(),
          quality: GlassQuality.standard,
          useOwnLayer: true,
          padding: const EdgeInsets.all(DS.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  '${_getWishEmoji(widget.wish.title)} 存入心愿',
                  style: DS.headlineSm.copyWith(
                    fontWeight: FontWeight.w700,
                    color: DS.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: DS.md),
              body,
              const SizedBox(height: DS.md),
              Row(
                children: [
                  Expanded(
                    child: GlassPanelButton(
                      label: '取消',
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: DS.sm),
                  Expanded(
                    child: GlassPanelButton(
                      label: '确认存入',
                      primary: true,
                      onPressed: _addMoney,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getWishEmoji(String title) {
    if (title.contains('衣服') || title.contains('鞋')) return '👗';
    if (title.contains('旅行') || title.contains('旅游')) return '✈️';
    if (title.contains('手机') || title.contains('数码')) return '📱';
    if (title.contains('学习') || title.contains('课程')) return '📚';
    if (title.contains('美食') || title.contains('吃')) return '🍱';
    return '✨';
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}

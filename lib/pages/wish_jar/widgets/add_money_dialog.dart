import 'package:flutter/material.dart';

import '../../../models/models.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/utils.dart';

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
    final remaining = widget.wish.targetAmount - widget.wish.currentAmount;
    
    return AlertDialog(
      title: Row(
        children: [
          Text(_getWishEmoji(widget.wish.title), style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              '💰 存入心愿',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 心愿信息
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppTheme.bgSection,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.wish.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '已存 ¥${FormatUtils.formatAmount(widget.wish.currentAmount)} / 目标 ¥${FormatUtils.formatAmount(widget.wish.targetAmount)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
                if (remaining > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    '还需 ¥${FormatUtils.formatAmount(remaining)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          // 快捷金额
          Text(
            '快捷金额：',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickAmounts.map((amount) {
              return GestureDetector(
                onTap: () => _selectQuickAmount(amount),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(color: AppTheme.primary),
                  ),
                  child: Text(
                    '¥$amount',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          // 自定义金额
          TextField(
            controller: _amountController,
            decoration: const InputDecoration(
              labelText: '存入金额',
              hintText: '输入金额',
              prefixIcon: Icon(Icons.attach_money),
            ),
            keyboardType: TextInputType.number,
            autofocus: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _addMoney,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.success,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
          ),
          child: const Text('确认存入'),
        ),
      ],
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

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart'
    show GlassDialog, GlassDialogAction, GlassQuality;
import 'package:uuid/uuid.dart';

import '../../../models/models.dart';
import '../../../theme/app_design_system.dart';
import '../../../theme/glass_materials.dart';
import '../../../providers/theme_provider.dart';
import '../../../widgets/glass_date_picker.dart';
import '../../../widgets/glass_dialog_shell.dart';
import 'package:provider/provider.dart';

/// 创建心愿对话框
class CreateWishDialog extends StatefulWidget {
  final Function(WishModel) onCreate;

  const CreateWishDialog({super.key, required this.onCreate});

  @override
  State<CreateWishDialog> createState() => _CreateWishDialogState();
}

class _CreateWishDialogState extends State<CreateWishDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime? _deadline;

  static const List<Map<String, dynamic>> _templates = [
    {'name': '买一件喜欢的衣服', 'emoji': '👗', 'amount': '500'},
    {'name': '旅行基金', 'emoji': '✈️', 'amount': '3000'},
    {'name': '买心仪的数码产品', 'emoji': '📱', 'amount': '5000'},
    {'name': '学习课程', 'emoji': '📚', 'amount': '1000'},
    {'name': '美食探店', 'emoji': '🍱', 'amount': '300'},
    {'name': '自定义心愿', 'emoji': '✨', 'amount': '1000'},
  ];

  void _selectTemplate(Map<String, dynamic> template) {
    setState(() {
      _titleController.text = template['name'];
      _amountController.text = template['amount'];
    });
  }

  Future<void> _createWish() async {
    if (!_formKey.currentState!.validate()) return;

    final wish = WishModel(
      id: const Uuid().v4(),
      bookId: '', // 将在 Provider 中设置
      title: _titleController.text,
      description: _descriptionController.text.isEmpty
          ? null
          : _descriptionController.text,
      targetAmount: double.parse(_amountController.text),
      currentAmount: 0.0,
      priority: 1,
      isCompleted: false,
      createdAt: DateTime.now(),
      deadline: _deadline,
    );

    widget.onCreate(wish);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>(); // theme rebuild

    final form = SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 快速模板
            Text(
              '快速选择：',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: DS.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _templates.map((tpl) {
                return GestureDetector(
                  onTap: () => _selectTemplate(tpl),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: shouldUseLiquidGlass(context)
                          ? (DS.isDark
                              ? Colors.white.withOpacity(0.10)
                              : Colors.white.withOpacity(0.50))
                          : DS.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(DS.radiusFull),
                      border: Border.all(color: DS.outlineVariant),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(tpl['emoji'], style: TextStyle(fontSize: 16)),
                        SizedBox(width: 4),
                        Text(
                          tpl['name'],
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            SizedBox(height: DS.gutter),

            // 心愿名称
            TextFormField(
              controller: _titleController,
              decoration: glassDialogInputDecoration(
                context,
                labelText: '心愿名称',
                hintText: '例如：买一台新手机',
                prefixIcon: const Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入心愿名称';
                }
                return null;
              },
            ),

            SizedBox(height: DS.base),

            // 心愿描述（可选）
            TextFormField(
              controller: _descriptionController,
              decoration: glassDialogInputDecoration(
                context,
                labelText: '描述（选填）',
                hintText: '添加一些备注',
                prefixIcon: const Icon(Icons.description),
              ),
              maxLines: 2,
            ),

            SizedBox(height: DS.base),

            // 心愿金额
            TextFormField(
              controller: _amountController,
              decoration: glassDialogInputDecoration(
                context,
                labelText: '心愿金额',
                hintText: '例如：5000',
                prefixIcon: const Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入心愿金额';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return '请输入有效金额';
                }
                return null;
              },
            ),

            SizedBox(height: DS.base),

            // 截止日期
            GestureDetector(
              onTap: () async {
                final picked = await showGlassDatePicker(
                  context: context,
                  initialDate:
                      _deadline ?? DateTime.now().add(const Duration(days: 30)),
                  minimumDate: DateTime.now(),
                  maximumDate: DateTime.now().add(const Duration(days: 365)),
                  title: '截止日期',
                );
                if (picked != null) {
                  setState(() {
                    _deadline = picked;
                  });
                }
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: DS.sm,
                  vertical: DS.base,
                ),
                decoration: BoxDecoration(
                  color: shouldUseLiquidGlass(context)
                      ? (DS.isDark
                          ? Colors.white.withOpacity(0.10)
                          : Colors.white.withOpacity(0.50))
                      : DS.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(DS.radiusSm),
                  border: Border.all(color: DS.outlineVariant),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 18, color: DS.emphasis),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _deadline != null
                            ? '截止：${_deadline!.year}年${_deadline!.month}月${_deadline!.day}日'
                            : '选择截止日期（选填）',
                        style: TextStyle(
                          fontSize: 13,
                          color: _deadline != null
                              ? DS.onSurface
                              : DS.onSurfaceVariant,
                        ),
                      ),
                    ),
                    if (_deadline != null)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _deadline = null;
                          });
                        },
                        child: Icon(Icons.clear, size: 18, color: DS.outline),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    final actions = [
      GlassDialogAction(
        label: '取消',
        onPressed: () => Navigator.pop(context),
      ),
      GlassDialogAction(
        label: '创建',
        isPrimary: true,
        onPressed: _createWish,
      ),
    ];

    if (!shouldUseLiquidGlass(context)) {
      return AlertDialog(
        title: Text('✨ 创建新心愿'),
        content: form,
        actions: [
          TextButton(
            onPressed: actions[0].onPressed,
            child: Text(actions[0].label),
          ),
          ElevatedButton(
            onPressed: actions[1].onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: DS.primary,
              padding: EdgeInsets.symmetric(
                horizontal: DS.md,
                vertical: DS.base,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DS.radiusFull),
              ),
            ),
            child: Text(actions[1].label),
          ),
        ],
      );
    }

    // 开启液态玻璃：官方 GlassDialog（真玻璃材质 + 交互光晕）
    return GlassDialog(
      title: '✨ 创建新心愿',
      content: form,
      maxWidth: 340,
      quality: GlassQuality.standard,
      settings: GlassMaterials.bar(),
      actions: actions,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }
}

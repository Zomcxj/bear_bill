import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../../services/database_service.dart';
import '../../services/storage_service.dart';
import '../../theme/app_design_system.dart';
import '../../theme/app_theme.dart';
import '../../utils/utils.dart';
import '../../providers/theme_provider.dart';

/// 预算设置页 - 月度预算设置、进度监控
class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  final _controller = TextEditingController();
  double _currentBudget = 0.0;
  bool _loading = true;

  static const List<double> _quickAmounts = [1000, 2000, 3000, 5000, 8000, 10000];

  @override
  void initState() {
    super.initState();
    _loadBudget();
  }

  Future<void> _loadBudget() async {
    final appProvider = context.read<AppProvider>();
    final book = await appProvider.getCurrentBook();

    setState(() {
      _currentBudget = book?.budget ?? 0.0;
      _controller.text = _currentBudget > 0 ? _currentBudget.toString() : '';
      _loading = false;
    });
  }

  Future<void> _saveBudget() async {
    final input = _controller.text.trim();
    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入预算金额')),
      );
      return;
    }

    final budget = double.tryParse(input);
    if (budget == null || budget < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效金额')),
      );
      return;
    }

    final appProvider = context.read<AppProvider>();
    final book = await appProvider.getCurrentBook();
    if (!mounted) return;

    if (book == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择账本')),
      );
      return;
    }

    final updatedBook = book.copyWith(budget: budget);
    await DatabaseService.instance.updateBook(updatedBook);

    // 同时保存到 StorageService 供成就检查使用
    StorageService.instance.setString('monthlyBudget', budget.toString());

    setState(() {
      _currentBudget = budget;
    });

    // 检查预算成就
    if (mounted) {
      appProvider.checkBudgetAchievements();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('预算已保存'),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  Future<void> _clearBudget() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('清除预算'),
        content: Text('确定清除当前预算设置吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('清除', style: TextStyle(color: DS.primaryContainer)),
          ),
        ],
      ),
    );
    if (!mounted) return;

    if (confirmed == true) {
      final appProvider = context.read<AppProvider>();
      final book = await appProvider.getCurrentBook();

      if (book != null) {
        final updatedBook = book.copyWith(budget: 0.0);
        await DatabaseService.instance.updateBook(updatedBook);

        setState(() {
          _currentBudget = 0.0;
          _controller.text = '';
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已清除预算')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>(); // theme rebuild
    return Scaffold(
      backgroundColor: DS.background,
      appBar: AppBar(
        title: Text('预算设置'),
        backgroundColor: DS.primary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(DS.base),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 当前预算显示
                  _buildCurrentBudgetCard(),

                  SizedBox(height: DS.gutter),

                  // 快捷金额
                  _buildQuickAmounts(),

                  SizedBox(height: DS.gutter),

                  // 自定义输入
                  _buildCustomInput(),

                  SizedBox(height: DS.md),

                  // 操作按钮
                  _buildActionButtons(),

                  SizedBox(height: DS.gutter),

                  // 温馨提示
                  _buildTips(),
                ],
              ),
            ),
    );
  }

  Widget _buildCurrentBudgetCard() {
    return Container(
      padding: EdgeInsets.all(DS.gutter),
      decoration: BoxDecoration(
        color: DS.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(DS.radiusMd),
        border: Border.all(color: DS.outlineVariant),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.flag, size: 18, color: DS.onSurfaceVariant),
              SizedBox(width: 6),
              Text(
                '当前月度预算',
                style: DS.labelMd.copyWith(color: DS.onSurfaceVariant),
              ),
            ],
          ),
          SizedBox(height: DS.base),
          Text(
            _currentBudget > 0
                ? '¥${FormatUtils.formatAmountWithComma(_currentBudget)}'
                : '未设置',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: _currentBudget > 0
                  ? DS.primaryContainer
                  : DS.outline,
            ),
          ),
          if (_currentBudget > 0) ...[
            SizedBox(height: 8),
            Text(
              '每日可用 ¥${FormatUtils.formatAmount(_currentBudget / 30)}',
              style: DS.labelSm.copyWith(color: DS.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickAmounts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '快捷设置：',
          style: DS.labelMd.copyWith(color: DS.onSurface),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _quickAmounts.map((amount) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  _controller.text = amount.toString();
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: DS.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(DS.radiusFull),
                  border: Border.all(color: DS.primary),
                ),
                child: Text(
                  '¥${amount.toInt()}',
                  style: DS.labelMd.copyWith(color: DS.primaryContainer),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCustomInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '自定义金额：',
          style: DS.labelMd.copyWith(color: DS.onSurface),
        ),
        SizedBox(height: 8),
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: '输入月度预算金额',
            prefixIcon: Icon(Icons.attach_money, color: DS.primary),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, size: 18),
                    onPressed: () {
                      setState(() {
                        _controller.text = '';
                      });
                    },
                  )
                : null,
            filled: true,
            fillColor: DS.surfaceContainerLowest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DS.radiusSm),
              borderSide: BorderSide.none,
            ),
          ),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _clearBudget,
            icon: Icon(Icons.clear),
            label: Text('清除预算'),
            style: OutlinedButton.styleFrom(
              foregroundColor: DS.primaryContainer,
              side: BorderSide(color: DS.primaryContainer),
              padding: EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DS.radiusSm),
              ),
            ),
          ),
        ),
        SizedBox(width: DS.base),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _saveBudget,
            icon: Icon(Icons.save),
            label: Text('保存预算'),
            style: ElevatedButton.styleFrom(
              backgroundColor: DS.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DS.radiusSm),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTips() {
    return Container(
      padding: EdgeInsets.all(DS.gutter),
      decoration: BoxDecoration(
        color: AppTheme.infoLight,
        borderRadius: BorderRadius.circular(DS.radiusSm),
        border: Border.all(color: AppTheme.info.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: AppTheme.info, size: 20),
              SizedBox(width: 8),
              Text(
                '温馨提示',
                style: DS.labelMd.copyWith(color: DS.onSurface),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            '• 建议根据月收入设置合理预算\n'
            '• 一般建议支出不超过收入的 80%\n'
            '• 可在首页查看预算使用进度\n'
            '• 超支时会有提醒哦～',
            style: DS.labelSm.copyWith(
              color: DS.onSurfaceVariant,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

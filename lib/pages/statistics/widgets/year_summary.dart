import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/app_provider.dart';
import '../../../services/database_service.dart';
import '../../../theme/app_design_system.dart';
import '../../../utils/utils.dart';
import '../../../providers/theme_provider.dart';

/// 年度总结组件
class YearSummary extends StatefulWidget {
  const YearSummary({super.key});

  @override
  State<YearSummary> createState() => _YearSummaryState();
}

class _YearSummaryState extends State<YearSummary> {
  int _selectedYear = DateTime.now().year;
  List<Map<String, dynamic>> _monthlyData = [];
  List<Map<String, dynamic>> _expenseCategories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadYearStats();
  }

  Future<void> _loadYearStats() async {
    setState(() => _loading = true);
    final appProvider = context.read<AppProvider>();
    final data = await DatabaseService.instance.getYearStatistics(
      '$_selectedYear',
      bookId: appProvider.currentBookId,
    );

    if (mounted) {
      setState(() {
        _monthlyData = (data['monthlyData'] as List).cast<Map<String, dynamic>>();
        _expenseCategories = (data['categories'] as List)
            .cast<Map<String, dynamic>>()
            .where((c) => c['type'] == 'expense')
            .toList();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>(); // theme rebuild
    return _loading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: DS.sm),
                // 12 月柱状图
                _buildMonthlyChart(),
                SizedBox(height: DS.sm),
                // 年度分类明细
                _buildYearCategoryBreakdown(),
                SizedBox(height: DS.sm),
              ],
            ),
          );
  }

  Widget _buildYearSelector() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              setState(() => _selectedYear--);
              _loadYearStats();
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: DS.background,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.chevron_left, size: 24, color: DS.primaryContainer),
            ),
          ),
          SizedBox(width: 16),
          GestureDetector(
            onTap: _pickYear,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$_selectedYear 年',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: DS.onSurface,
                  ),
                ),
                Icon(Icons.unfold_more, size: 18, color: DS.outline),
              ],
            ),
          ),
          SizedBox(width: 16),
          GestureDetector(
            onTap: _selectedYear < DateTime.now().year
                ? () {
                    setState(() => _selectedYear++);
                    _loadYearStats();
                  }
                : null,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: DS.background,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chevron_right,
                size: 24,
                color: _selectedYear < DateTime.now().year
                    ? DS.primaryContainer
                    : DS.outline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _pickYear() {
    int tempYear = _selectedYear;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.chevron_left),
                  onPressed: () => setState(() => tempYear--),
                ),
                Text(
                  '$tempYear 年',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                IconButton(
                  icon: Icon(Icons.chevron_right),
                  onPressed: tempYear < DateTime.now().year
                      ? () => setState(() => tempYear++)
                      : null,
                ),
              ],
            ),
            content: Text('选择年份查看年度总结', textAlign: TextAlign.center),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  setState(() => _selectedYear = tempYear);
                  Navigator.pop(ctx);
                  _loadYearStats();
                },
                child: Text('确认', style: TextStyle(color: DS.primary)),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 格式化金额为紧凑显示
  String _formatCompact(double amount) {
    if (amount <= 0) return '';
    if (amount >= 10000) return '${(amount / 10000).toStringAsFixed(1)}w';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}k';
    return amount.toStringAsFixed(0);
  }

  Widget _buildMonthlyChart() {
    if (_monthlyData.isEmpty) return const SizedBox.shrink();

    final maxAmount = _monthlyData
        .map((m) => (m['expense'] as double) > (m['income'] as double)
            ? (m['expense'] as double)
            : (m['income'] as double))
        .reduce((a, b) => a > b ? a : b);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: DS.sm),
      padding: EdgeInsets.all(DS.gutter),
      decoration: DS.glassDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart, size: 18, color: DS.primary),
              SizedBox(width: 6),
              Text(
                '月度趋势',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: DS.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(12, (i) {
                final data = _monthlyData[i];
                final expense = data['expense'] as double;
                final income = data['income'] as double;
                final hasData = expense > 0 || income > 0;
                final expenseRatio = maxAmount > 0 ? expense / maxAmount : 0.0;
                final incomeRatio = maxAmount > 0 ? income / maxAmount : 0.0;
                final isCurrentMonth = i + 1 == DateTime.now().month &&
                    _selectedYear == DateTime.now().year;
                final barHeight = hasData ? 120.0 : 2.0;

                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // 金额标签（仅有数据时显示）
                        if (hasData)
                          Text(
                            _formatCompact(expense),
                            style: TextStyle(
                              fontSize: 8,
                              color: DS.primaryContainer,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        if (hasData) SizedBox(height: 2),
                        // 双柱
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              width: 6,
                              height: hasData ? barHeight * expenseRatio : 2,
                              decoration: BoxDecoration(
                                color: hasData
                                    ? DS.primaryContainer
                                    : DS.outlineVariant,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            SizedBox(width: 2),
                            Container(
                              width: 6,
                              height: hasData ? barHeight * incomeRatio : 2,
                              decoration: BoxDecoration(
                                color: hasData
                                    ? DS.secondary
                                    : DS.outlineVariant,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontSize: 10,
                            color: isCurrentMonth
                                ? DS.primary
                                : DS.outline,
                            fontWeight: isCurrentMonth
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 10, height: 10, color: DS.primaryContainer),
              SizedBox(width: 4),
              Text('支出', style: TextStyle(fontSize: 11)),
              SizedBox(width: 16),
              Container(width: 10, height: 10, color: DS.secondary),
              SizedBox(width: 4),
              Text('收入', style: TextStyle(fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildYearCategoryBreakdown() {
    if (_expenseCategories.isEmpty) return const SizedBox.shrink();

    // 计算百分比
    final total = _expenseCategories.fold(0.0, (s, c) => s + (c['amount'] as double));
    final categoriesWithPercent = _expenseCategories.map((c) {
      return {
        ...c,
        'percent': total > 0 ? (c['amount'] as double) / total * 100 : 0.0,
      };
    }).toList();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: DS.sm),
      padding: EdgeInsets.all(DS.gutter),
      decoration: DS.glassDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart, size: 18, color: DS.primary),
              SizedBox(width: 6),
              Text(
                '年度支出分类 Top ${categoriesWithPercent.length > 5 ? 5 : categoriesWithPercent.length}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: DS.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          ...categoriesWithPercent.take(5).map((c) => _buildCategoryItem(c)),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(Map<String, dynamic> category) {
    final amount = category['amount'] as double;
    final percent = category['percent'] as double;
    final count = category['count'] as int? ?? 0;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(category['icon'] ?? '📦', style: TextStyle(fontSize: 18)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              category['name'],
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: DS.onSurface,
              ),
            ),
          ),
          Text(
            '$count笔',
            style: TextStyle(fontSize: 11, color: DS.outline),
          ),
          SizedBox(width: 8),
          Text(
            '¥${FormatUtils.formatAmount(amount)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: DS.onSurface,
            ),
          ),
          SizedBox(width: 4),
          Text(
            '${percent.toStringAsFixed(1)}%',
            style: TextStyle(fontSize: 11, color: DS.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

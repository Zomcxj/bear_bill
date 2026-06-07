import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/database_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_utils.dart';
import '../bill_list/bill_list_page.dart';
import 'widgets/category_breakdown.dart';
import 'widgets/monthly_summary.dart';
import 'widgets/trend_line_chart.dart';
import 'widgets/stat_tabs.dart';
import 'widgets/income_expense_summary.dart';
import 'widgets/year_summary.dart';

/// 统计页 - 甜甜圈图、分类统计、热力日历、小熊助手总结
class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  DateTime _selectedMonth = DateTime.now();
  String _activeTab = 'expense'; // expense | income

  double _totalExpense = 0.0;
  double _totalIncome = 0.0;
  double _balance = 0.0;

  List<Map<String, dynamic>> _expenseCategories = [];
  List<Map<String, dynamic>> _incomeCategories = [];

  bool _loading = true;
  String _viewMode = 'monthly'; // monthly, yearly

  @override
  void initState() {
    super.initState();
    _loadStats();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      appProvider.addListener(_loadStats);
    });
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);

    final monthStr =
        '${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}';
    final appProvider = context.read<AppProvider>();
    final stats = await DatabaseService.instance.getMonthStatistics(
      monthStr,
      bookId: appProvider.currentBookId,
    );

    final expense = stats['expense'] ?? 0.0;
    final income = stats['income'] ?? 0.0;
    final categories = stats['categories'] as List? ?? [];

    // 处理支出分类
    final expCats = categories.where((c) => c['type'] == 'expense').map((c) {
      final percent = expense > 0
          ? FormatUtils.calculatePercentage(c['amount'], expense)
          : 0.0;
      return <String, dynamic>{
        ...c,
        'percent': percent,
      };
    }).toList();

    // 处理收入分类
    final incCats = categories.where((c) => c['type'] == 'income').map((c) {
      final percent = income > 0
          ? FormatUtils.calculatePercentage(c['amount'], income)
          : 0.0;
      return <String, dynamic>{
        ...c,
        'percent': percent,
      };
    }).toList();

    setState(() {
      _totalExpense = expense;
      _totalIncome = income;
      _balance = income - expense;
      _expenseCategories = expCats;
      _incomeCategories = incCats;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>(); // listen to theme changes
    final monthTitle = '${_selectedMonth.year}年${_selectedMonth.month}月';

    return Scaffold(
      backgroundColor: AppTheme.bgPage,
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('📊', style: TextStyle(fontSize: 20)),
            SizedBox(width: 8),
            Text(
              '统计报表',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.primary,
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 月度/年度切换
                _buildViewModeToggle(),

                // 月份/年份选择器
                if (_viewMode == 'monthly')
                  _buildMonthSelector(monthTitle),

                Expanded(
                  child: _viewMode == 'yearly'
                      ? const YearSummary()
                      : SingleChildScrollView(
                          child: Column(
                            children: [
                              // 1. 收支结余卡片
                              IncomeExpenseSummary(
                                expense: _totalExpense,
                                income: _totalIncome,
                                balance: _balance,
                              ),

                              const SizedBox(height: AppSpacing.sm),

                              // 2. 小熊助手报告
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm),
                                child: MonthlySummary(
                                  expense: _totalExpense,
                                  income: _totalIncome,
                                  balance: _balance,
                                  topCategory: _expenseCategories.isNotEmpty
                                      ? _expenseCategories.first
                                      : null,
                                ),
                              ),

                              const SizedBox(height: 10),

                              // 2.5 收支趋势折线图
                              const TrendLineChart(),

                              const SizedBox(height: 10),

                              // 3. 支出/收入切换 + 分类明细
                              Container(
                                margin: const EdgeInsets.all(AppSpacing.sm),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.bgCard,
                                  borderRadius: BorderRadius.circular(AppRadius.lg),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    // 支出/收入切换
                                    StatTabs(
                                      activeTab: _activeTab,
                                      totalExpense: _totalExpense,
                                      totalIncome: _totalIncome,
                                      onTabChanged: (tab) {
                                        setState(() {
                                          _activeTab = tab;
                                        });
                                      },
                                    ),

                                    const SizedBox(height: 12),

                                    // 分类明细（带图标，可点击下钻）
                                    CategoryBreakdown(
                                      categories: _activeTab == 'expense'
                                          ? _expenseCategories
                                          : _incomeCategories,
                                      onCategoryTap: (category) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => BillListPage(
                                              initialCategoryId: category['id'] as String,
                                              initialType: _activeTab,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  /// 构建月份选择器
  Widget _buildMonthSelector(String monthTitle) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 左侧留白 + 上一月按钮
          Row(
            children: [
              const SizedBox(width: 20),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedMonth = DateTime(
                      _selectedMonth.year,
                      _selectedMonth.month - 1,
                    );
                  });
                  _loadStats();
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.bgPage,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chevron_left,
                    size: 24,
                    color: AppTheme.primaryDark,
                  ),
                ),
              ),
            ],
          ),

          // 中间月份显示
          GestureDetector(
            onTap: () => _pickYearMonth(context),
            child: Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      monthTitle,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Icon(Icons.unfold_more, size: 18, color: AppTheme.textHint),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '消费报告',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // 下一月按钮 + 右侧留白
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedMonth = DateTime(
                      _selectedMonth.year,
                      _selectedMonth.month + 1,
                    );
                  });
                  _loadStats();
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.bgPage,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chevron_right,
                    size: 24,
                    color: AppTheme.primaryDark,
                  ),
                ),
              ),
              const SizedBox(width: 20),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildViewModeToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.bgSection,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _viewMode = 'monthly'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _viewMode == 'monthly' ? AppTheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Center(
                  child: Text(
                    '月度报表',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _viewMode == 'monthly' ? Colors.white : AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _viewMode = 'yearly'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _viewMode == 'yearly' ? AppTheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Center(
                  child: Text(
                    '年度总结',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _viewMode == 'yearly' ? Colors.white : AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _pickYearMonth(BuildContext context) {
    int selectedYear = _selectedMonth.year;
    int selectedMonth = _selectedMonth.month;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => setState(() => selectedYear--),
                ),
                Text(
                  '$selectedYear 年',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: selectedYear < DateTime.now().year
                      ? () => setState(() => selectedYear++)
                      : null,
                ),
              ],
            ),
            content: SizedBox(
              width: 280,
              child: GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.4,
                ),
                itemCount: 12,
                itemBuilder: (_, i) {
                  final month = i + 1;
                  final isCurrent = month == selectedMonth;
                  final isFuture = selectedYear == DateTime.now().year &&
                      month > DateTime.now().month;
                  return GestureDetector(
                    onTap: isFuture
                        ? null
                        : () {
                            setState(() {
                              _selectedMonth = DateTime(selectedYear, month);
                            });
                            Navigator.pop(ctx);
                            _loadStats();
                          },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isCurrent ? AppTheme.primary : AppTheme.bgSection,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$month 月',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                          color: isFuture
                              ? AppTheme.textHint
                              : isCurrent
                                  ? Colors.white
                                  : AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      appProvider.removeListener(_loadStats);
    } catch (_) {}
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../../services/database_service.dart';
import '../../theme/app_design_system.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_utils.dart';
import '../bill_list/bill_list_page.dart';
import 'widgets/category_breakdown.dart';
import 'widgets/monthly_summary.dart';
import 'widgets/trend_line_chart.dart';
import 'widgets/stat_tabs.dart';
import 'widgets/income_expense_summary.dart';
import 'widgets/year_summary.dart';

/// 统计页 — Luminous Finance 风格
class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  DateTime _selectedMonth = DateTime.now();
  String _activeTab = 'expense';

  double _totalExpense = 0.0;
  double _totalIncome = 0.0;
  double _balance = 0.0;

  List<Map<String, dynamic>> _expenseCategories = [];
  List<Map<String, dynamic>> _incomeCategories = [];

  bool _loading = true;
  String _viewMode = 'monthly';

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

    final expCats = categories.where((c) => c['type'] == 'expense').map((c) {
      final percent = expense > 0
          ? FormatUtils.calculatePercentage(c['amount'], expense)
          : 0.0;
      return <String, dynamic>{...c, 'percent': percent};
    }).toList();

    final incCats = categories.where((c) => c['type'] == 'income').map((c) {
      final percent = income > 0
          ? FormatUtils.calculatePercentage(c['amount'], income)
          : 0.0;
      return <String, dynamic>{...c, 'percent': percent};
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
    final monthTitle = '${_selectedMonth.year}年${_selectedMonth.month}月';

    return Scaffold(
      backgroundColor: DS.background,
      body: SafeArea(
        top: false,
        bottom: false,
        child: _loading
          ? const Center(child: CircularProgressIndicator(color: DS.secondaryContainer))
          : Column(
              children: [
                // 渐变 Hero 头部
                Container(
                  padding: EdgeInsets.fromLTRB(DS.containerMargin, MediaQuery.of(context).padding.top + DS.gutter, DS.containerMargin, DS.base),
                  decoration: BoxDecoration(
                    gradient: DS.heroGradientBlueCurrent,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(DS.radiusLg),
                      bottomRight: Radius.circular(DS.radiusLg),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.leaderboard, size: 22, color: DS.onSurface),
                          SizedBox(width: DS.sm),
                          Text('统计报表', style: DS.headlineMd),
                        ],
                      ),
                      SizedBox(height: DS.sm),
                      Container(
                        padding: EdgeInsets.symmetric(vertical: DS.gutter),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(DS.radiusMd),
                          border: Border.all(color: Colors.black.withOpacity(0.08)),
                        ),
                        child: IntrinsicHeight(
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    Text('本月支出', style: DS.labelSm),
                                    SizedBox(height: DS.xs),
                                    Text(
                                      '¥${FormatUtils.formatAmount(_totalExpense)}',
                                      style: TextStyle(
                                        fontFamily: DS.fontDisplay,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: DS.error,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(width: 1, color: DS.outlineVariant),
                              Expanded(
                                child: Column(
                                  children: [
                                    Text('本月收入', style: DS.labelSm),
                                    SizedBox(height: DS.xs),
                                    Text(
                                      '¥${FormatUtils.formatAmount(_totalIncome)}',
                                      style: TextStyle(
                                        fontFamily: DS.fontDisplay,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: DS.secondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(width: 1, color: DS.outlineVariant),
                              Expanded(
                                child: Column(
                                  children: [
                                    Text('结余', style: DS.labelSm),
                                    SizedBox(height: DS.xs),
                                    Text(
                                      '¥${FormatUtils.formatAmount(_balance)}',
                                      style: TextStyle(
                                        fontFamily: DS.fontDisplay,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: _balance >= 0 ? DS.secondary : DS.error,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: DS.sm),
                      // 月份/年份切换
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                if (_viewMode == 'monthly') {
                                  _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
                                } else {
                                  _selectedMonth = DateTime(_selectedMonth.year - 1, _selectedMonth.month);
                                }
                              });
                              _loadStats();
                            },
                            child: Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.6),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.chevron_left, size: 18, color: DS.onSurface),
                            ),
                          ),
                          SizedBox(width: DS.xs),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _pickYearMonth(context),
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: DS.sm, vertical: DS.xs + 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(DS.radiusFull),
                                  border: Border.all(color: Colors.black.withOpacity(0.08)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _viewMode == 'monthly' ? monthTitle : '${_selectedMonth.year}年',
                                      style: DS.labelMd.copyWith(color: DS.onSurface),
                                    ),
                                    SizedBox(width: DS.xs),
                                    Icon(Icons.unfold_more, size: 14, color: DS.outline),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: DS.xs),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                if (_viewMode == 'monthly') {
                                  _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
                                } else {
                                  _selectedMonth = DateTime(_selectedMonth.year + 1, _selectedMonth.month);
                                }
                              });
                              _loadStats();
                            },
                            child: Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.6),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.chevron_right, size: 18, color: DS.onSurface),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: DS.sm),
                      // 月度/年度切换
                      Container(
                        padding: EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(DS.radiusFull),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _viewMode = 'monthly'),
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: DS.sm),
                                  decoration: BoxDecoration(
                                    color: _viewMode == 'monthly' ? DS.primary : Colors.transparent,
                                    borderRadius: BorderRadius.circular(DS.radiusFull),
                                  ),
                                  child: Center(
                                    child: Text('月度', style: DS.labelMd.copyWith(
                                      color: _viewMode == 'monthly' ? DS.onPrimary : DS.onSurface,
                                    )),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _viewMode = 'yearly'),
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: DS.sm),
                                  decoration: BoxDecoration(
                                    color: _viewMode == 'yearly' ? DS.primary : Colors.transparent,
                                    borderRadius: BorderRadius.circular(DS.radiusFull),
                                  ),
                                  child: Center(
                                    child: Text('年度', style: DS.labelMd.copyWith(
                                      color: _viewMode == 'yearly' ? DS.onPrimary : DS.onSurface,
                                    )),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: DS.base),
                Expanded(
                  child: _viewMode == 'yearly'
                      ? YearSummary()
                      : SingleChildScrollView(
                          child: Column(
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: DS.sm),
                                child: MonthlySummary(
                                  expense: _totalExpense,
                                  income: _totalIncome,
                                  balance: _balance,
                                  topCategory: _expenseCategories.isNotEmpty
                                      ? _expenseCategories.first
                                      : null,
                                ),
                              ),
                              SizedBox(height: DS.sm),
                              const TrendLineChart(),
                              SizedBox(height: DS.sm),
                              Container(
                                margin: EdgeInsets.symmetric(horizontal: DS.sm),
                                padding: EdgeInsets.all(DS.sm),
                                decoration: BoxDecoration(
                                  color: DS.surfaceContainerLowest,
                                  borderRadius: BorderRadius.circular(DS.radiusMd),
                                  border: Border.all(color: DS.outlineVariant),
                                  boxShadow: DS.shadowSm,
                                ),
                                child: Column(
                                  children: [
                                    StatTabs(
                                      activeTab: _activeTab,
                                      totalExpense: _totalExpense,
                                      totalIncome: _totalIncome,
                                      onTabChanged: (tab) {
                                        setState(() => _activeTab = tab);
                                      },
                                    ),
                                    SizedBox(height: DS.sm),
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
                  icon: Icon(Icons.chevron_left),
                  onPressed: () => setState(() => selectedYear--),
                ),
                Text('$selectedYear 年', style: DS.headlineSm),
                IconButton(
                  icon: Icon(Icons.chevron_right),
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
                  mainAxisSpacing: DS.sm,
                  crossAxisSpacing: DS.sm,
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
                        color: isCurrent ? DS.primary : DS.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(DS.radiusSm),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$month 月',
                        style: DS.labelMd.copyWith(
                          color: isFuture
                              ? DS.outline
                              : isCurrent
                                  ? DS.onPrimary
                                  : DS.onSurface,
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

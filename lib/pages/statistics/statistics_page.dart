import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/database_service.dart';
import '../../theme/app_design_system.dart';
import '../../widgets/glass_dialog_shell.dart';
import '../../theme/glass_materials.dart';
import '../../utils/format_utils.dart';
import '../bill_list/bill_list_page.dart';
import 'widgets/category_breakdown.dart';
import 'widgets/monthly_summary.dart';
import 'widgets/trend_line_chart.dart';
import 'widgets/stat_tabs.dart';
import 'widgets/year_summary.dart';

/// Statistics page — Luminous Finance style
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

    final appProvider = context.read<AppProvider>();
    final yearStr = '${_selectedMonth.year}';

    double expense;
    double income;
    List categories;

    if (_viewMode == 'yearly') {
      // Yearly mode: aggregate the whole year's data (header numbers use the same metric as monthly)
      final stats = await DatabaseService.instance.getYearStatistics(
        yearStr,
        bookId: appProvider.currentBookId,
      );
      expense = (stats['totalExpense'] as num?)?.toDouble() ?? 0.0;
      income = (stats['totalIncome'] as num?)?.toDouble() ?? 0.0;
      categories = stats['categories'] as List? ?? [];
    } else {
      final monthStr =
          '${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}';
      final stats = await DatabaseService.instance.getMonthStatistics(
        monthStr,
        bookId: appProvider.currentBookId,
      );
      expense = (stats['expense'] as num?)?.toDouble() ?? 0.0;
      income = (stats['income'] as num?)?.toDouble() ?? 0.0;
      categories = stats['categories'] as List? ?? [];
    }

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
    context.watch<ThemeProvider>(); // rebuild on theme change
    final monthTitle = '${_selectedMonth.year}年${_selectedMonth.month}月';
    final isYearly = _viewMode == 'yearly';
    final periodLabel = isYearly ? '年' : '本月';

    return Scaffold(
      backgroundColor: DS.background,
      body: SafeArea(
        top: false,
        bottom: false,
        // hero (including the monthly/yearly switcher) stays mounted: loading only replaces
        // the content area below, otherwise the switcher would be destroyed and rebuilt on
        // toggle, losing the sliding animation
        child: Column(
              children: [
                // Glass hero: a single shader glass block (same as the profile page); disabled state uses the original gradient (zero drift)
                GlassSurface(
                  borderRadius: DS.radiusLg,
                  fallbackDecoration: BoxDecoration(
                    gradient: DS.heroGradientBlueCurrent,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(DS.radiusLg),
                      bottomRight: Radius.circular(DS.radiusLg),
                    ),
                  ),
                  padding: EdgeInsets.fromLTRB(DS.containerMargin, MediaQuery.of(context).padding.top + DS.gutter, DS.containerMargin, DS.base),
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
                      GlassSurface(
                        padding: EdgeInsets.symmetric(vertical: DS.gutter),
                        fallbackDecoration: BoxDecoration(
                          color: DS.heroCardBg,
                          borderRadius: BorderRadius.circular(DS.radiusMd),
                          border: Border.all(color: DS.heroCardBorder),
                        ),
                        child: IntrinsicHeight(
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    Text('$periodLabel支出', style: DS.labelSm),
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
                                    Text('$periodLabel收入', style: DS.labelSm),
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
                      // Month/year switcher
                      // Glass state: the whole date bar = the same glass bar as the bottom nav; disabled state as-is
                      GlassBarWrap(
                        child: Row(
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
                                color: shouldUseLiquidGlass(context)
                                    ? Colors.transparent
                                    : DS.heroCardBg,
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
                                  color: shouldUseLiquidGlass(context)
                                      ? Colors.transparent
                                      : DS.heroCardBg,
                                  borderRadius: BorderRadius.circular(DS.radiusFull),
                                  // Glass theme has no border; disabled state as-is
                                  border: shouldUseLiquidGlass(context)
                                      ? null
                                      : Border.all(color: DS.heroCardBorder),
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
                                color: shouldUseLiquidGlass(context)
                                    ? Colors.transparent
                                    : DS.heroCardBg,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.chevron_right, size: 18, color: DS.onSurface),
                            ),
                          ),
                        ],
                      ),
                      ),
                      SizedBox(height: DS.sm),
                      // Monthly/yearly switcher
                      if (!shouldUseLiquidGlass(context))
                        Container(
                          padding: EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: DS.heroCardBg,
                            borderRadius: BorderRadius.circular(DS.radiusFull),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    if (_viewMode == 'monthly') return;
                                    setState(() => _viewMode = 'monthly');
                                    _loadStats();
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(vertical: DS.sm),
                                    decoration: BoxDecoration(
                                      color: _viewMode == 'monthly' ? DS.emphasis : Colors.transparent,
                                      borderRadius: BorderRadius.circular(DS.radiusFull),
                                    ),
                                    child: Center(
                                      child: Text('月度', style: DS.labelMd.copyWith(
                                        color: _viewMode == 'monthly' ? DS.background : DS.onSurface,
                                      )),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    if (_viewMode == 'yearly') return;
                                    setState(() => _viewMode = 'yearly');
                                    _loadStats();
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(vertical: DS.sm),
                                    decoration: BoxDecoration(
                                      color: _viewMode == 'yearly' ? DS.emphasis : Colors.transparent,
                                      borderRadius: BorderRadius.circular(DS.radiusFull),
                                    ),
                                    child: Center(
                                      child: Text('年度', style: DS.labelMd.copyWith(
                                        color: _viewMode == 'yearly' ? DS.background : DS.onSurface,
                                      )),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        GlassSegmented(
                          labels: const ['月度', '年度'],
                          selectedIndex: _viewMode == 'monthly' ? 0 : 1,
                          onSelected: (i) {
                            final mode = i == 0 ? 'monthly' : 'yearly';
                            if (_viewMode == mode) return;
                            setState(() => _viewMode = mode);
                            _loadStats();
                          },
                        ),
                    ],
                  ),
                ),
                SizedBox(height: DS.base),
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: DS.secondaryContainer))
                      : _viewMode == 'yearly'
                          ? YearSummary(year: _selectedMonth.year)
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
                              // Tighten the spacing below the line chart card (the original DS.sm was too wide)
                              SizedBox(height: DS.base),
                              // Glass state: the expense/income + category breakdown block as a whole = glass;
                              // disabled state = the original solid card (zero drift)
                              GlassSurface(
                                borderRadius: DS.radiusMd,
                                margin: EdgeInsets.symmetric(horizontal: DS.sm),
                                padding: EdgeInsets.all(DS.sm),
                                fallbackDecoration: BoxDecoration(
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
                              // Bottom inset in glass mode: keep content from being covered by the floating glass bottom bar
                              SizedBox(height: glassBottomInset(context)),
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
    // Glass year-month picker sheet (shared component for the three date switchers, see glass_dialog_shell)
    showGlassYearMonthPicker(
      context: context,
      currentMonth:
          '${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}',
      onPicked: (m) {
        final p = m.split('-');
        setState(
            () => _selectedMonth = DateTime(int.parse(p[0]), int.parse(p[1])));
        _loadStats();
      },
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

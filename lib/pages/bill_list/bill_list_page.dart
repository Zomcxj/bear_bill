import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/database_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_design_system.dart';
import '../../utils/utils.dart' as utils;
import 'widgets/bill_filter_mixin.dart';
import 'widgets/record_detail_dialog.dart';
import 'widgets/record_group_list.dart';

/// 账单列表页 — Luminous Finance 风格
class BillListPage extends StatefulWidget {
  final String? initialCategoryId;
  final String? initialType;

  const BillListPage({super.key, this.initialCategoryId, this.initialType});

  @override
  State<BillListPage> createState() => _BillListPageState();
}

class _BillListPageState extends State<BillListPage> with BillFilterMixin {
  String _currentMonth = '';
  List<Map<String, dynamic>> _groupedRecords = [];
  double _totalExpense = 0.0;
  double _totalIncome = 0.0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _currentMonth = utils.DateUtils.getCurrentMonth();
    if (widget.initialCategoryId != null) {
      filterCategories.add(widget.initialCategoryId!);
    }
    if (widget.initialType != null) {
      filterType = widget.initialType!;
    }
    _loadRecords();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      appProvider.addListener(_onAppProviderChange);
    });
  }

  void _onAppProviderChange() {
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() => _loading = true);

    final appProvider = context.read<AppProvider>();
    final records = await DatabaseService.instance.getMonthRecords(
      _currentMonth,
      bookId: appProvider.currentBookId,
    );

    final filteredRecords = records.where((r) => matchesFilter(r)).toList();
    final grouped = _groupByDate(filteredRecords);

    setState(() {
      _groupedRecords = grouped;
      _loading = false;
    });
  }

  List<Map<String, dynamic>> _groupByDate(List<RecordModel> records) {
    final Map<String, Map<String, dynamic>> dateMap = {};
    double totalExpense = 0.0;
    double totalIncome = 0.0;

    final today = utils.DateUtils.getToday();
    final yesterday = utils.DateUtils.getYesterday();

    for (final record in records) {
      if (!dateMap.containsKey(record.date)) {
        String label;
        if (record.date == today) {
          label = '今天';
        } else if (record.date == yesterday) {
          label = '昨天';
        } else {
          label = utils.DateUtils.formatDayCN(record.date);
        }

        dateMap[record.date] = {
          'date': record.date,
          'label': label,
          'weekday': utils.DateUtils.getWeekday(DateTime.parse(record.date)),
          'dayExpense': 0.0,
          'dayIncome': 0.0,
          'records': <RecordModel>[],
        };
      }

      dateMap[record.date]!['records'].add(record);

      if (record.type == 'expense') {
        dateMap[record.date]!['dayExpense'] += record.amount;
        totalExpense += record.amount;
      } else {
        dateMap[record.date]!['dayIncome'] += record.amount;
        totalIncome += record.amount;
      }
    }

    final grouped = dateMap.values.toList();
    grouped.sort((a, b) => b['date'].compareTo(a['date']));

    _totalExpense = totalExpense;
    _totalIncome = totalIncome;

    return grouped;
  }

  void _prevMonth() {
    final parts = _currentMonth.split('-');
    int year = int.parse(parts[0]);
    int month = int.parse(parts[1]);
    month--;
    if (month < 1) { month = 12; year--; }
    setState(() => _currentMonth = '$year-${month.toString().padLeft(2, '0')}');
    _loadRecords();
  }

  void _nextMonth() {
    final parts = _currentMonth.split('-');
    int year = int.parse(parts[0]);
    int month = int.parse(parts[1]);
    month++;
    if (month > 12) { month = 1; year++; }
    setState(() => _currentMonth = '$year-${month.toString().padLeft(2, '0')}');
    _loadRecords();
  }

  List<Map<String, dynamic>> _getAllCategories() {
    final allCategories = <Map<String, dynamic>>[];
    for (final cat in expenseCategories) {
      allCategories.add({'id': cat.id, 'name': cat.name, 'emoji': cat.icon});
    }
    for (final cat in incomeCategories) {
      allCategories.add({'id': cat.id, 'name': cat.name, 'emoji': cat.icon});
    }
    return allCategories;
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return Scaffold(
      backgroundColor: DS.background,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
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
                      Icon(Icons.receipt_long, size: 22, color: DS.onSurface),
                      SizedBox(width: DS.sm),
                      Text('我的账单', style: DS.headlineMd),
                    ],
                  ),
                  SizedBox(height: DS.sm),
                  Container(
                    padding: EdgeInsets.symmetric(vertical: DS.gutter),
                    decoration: BoxDecoration(
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
                                Text('本月支出', style: DS.labelSm),
                                SizedBox(height: DS.xs),
                                Text(
                                  '¥${utils.FormatUtils.formatAmount(_totalExpense)}',
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
                                  '¥${utils.FormatUtils.formatAmount(_totalIncome)}',
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
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: DS.sm),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _prevMonth,
                        child: Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: DS.heroCardBg,
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
                              color: DS.heroCardBg,
                              borderRadius: BorderRadius.circular(DS.radiusFull),
                              border: Border.all(color: DS.heroCardBorder),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  utils.DateUtils.formatMonthCN(_currentMonth),
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
                        onTap: _nextMonth,
                        child: Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: DS.heroCardBg,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.chevron_right, size: 18, color: DS.onSurface),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: DS.sm),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: DS.sm),
                    decoration: BoxDecoration(
                      color: DS.heroCardBg,
                      borderRadius: BorderRadius.circular(DS.radiusFull),
                      border: Border.all(color: DS.heroCardBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, size: 18, color: DS.outline),
                        SizedBox(width: DS.sm),
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              hintText: '搜索分类、备注...',
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 10),
                            ),
                            style: DS.labelMd,
                            onChanged: (value) {
                              setState(() => keyword = value);
                              _loadRecords();
                            },
                          ),
                        ),
                        GestureDetector(
                          onTap: () => showFilterDialog(
                            getAllCategories: _getAllCategories,
                            onApply: _loadRecords,
                          ),
                          child: Icon(Icons.tune, size: 18, color: DS.onSurface),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          SizedBox(height: DS.base),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: DS.secondaryContainer))
                : _groupedRecords.isEmpty
                    ? _buildEmptyState()
                    : RecordGroupList(
                        groupedRecords: _groupedRecords,
                        onDelete: _deleteRecord,
                        onRecordTap: _showRecordDetail,
                      ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: DS.outlineVariant),
          SizedBox(height: DS.md),
          Text('本月还没有账单', style: DS.bodyMd.copyWith(color: DS.onSurfaceVariant)),
          SizedBox(height: DS.sm),
          Text('快去记第一笔吧', style: DS.labelSm.copyWith(color: DS.outline)),
        ],
      ),
    );
  }

  void _pickYearMonth(BuildContext context) {
    final parts = _currentMonth.split('-');
    int selectedYear = int.parse(parts[0]);
    int selectedMonth = int.parse(parts[1]);

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
                            final m = month.toString().padLeft(2, '0');
                            setState(() => _currentMonth = '$selectedYear-$m');
                            Navigator.pop(ctx);
                            _loadRecords();
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
                                  ? Colors.white
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

  Future<void> _deleteRecord(String recordId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.delete_outline, size: 20, color: DS.error),
            SizedBox(width: DS.xs),
            Text('确认删除'),
          ],
        ),
        content: Text('确定要删除这条账单吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: DS.error),
            child: Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseService.instance.deleteRecord(recordId);
      if (!mounted) return;
      context.read<AppProvider>().onRecordDeleted();
      NotificationService.instance.refreshTodaySummary();
      _loadRecords();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已删除'), duration: Duration(seconds: 1)),
        );
      }
    }
  }

  void _showRecordDetail(RecordModel record) {
    showDialog(
      context: context,
      builder: (context) => RecordDetailDialog(record: record),
    );
  }

  @override
  void dispose() {
    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      appProvider.removeListener(_onAppProviderChange);
    } catch (_) {}
    super.dispose();
  }
}

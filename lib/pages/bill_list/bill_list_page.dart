import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../services/database_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_design_system.dart';
import '../../utils/utils.dart' as utils;
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

class _BillListPageState extends State<BillListPage> {
  String _currentMonth = '';
  List<Map<String, dynamic>> _groupedRecords = [];
  double _totalExpense = 0.0;
  double _totalIncome = 0.0;
  bool _loading = true;

  String _keyword = '';
  String _filterType = 'all';
  final List<String> _filterCategories = [];
  double? _minAmount;
  double? _maxAmount;
  String _filterLocation = '';

  @override
  void initState() {
    super.initState();
    _currentMonth = utils.DateUtils.getCurrentMonth();
    if (widget.initialCategoryId != null) {
      _filterCategories.add(widget.initialCategoryId!);
    }
    if (widget.initialType != null) {
      _filterType = widget.initialType!;
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

    final filteredRecords = _applyFilter(records);
    final grouped = _groupByDate(filteredRecords);

    setState(() {
      _groupedRecords = grouped;
      _loading = false;
    });
  }

  List<RecordModel> _applyFilter(List<RecordModel> records) {
    return records.where((record) {
      if (_keyword.isNotEmpty) {
        final keywordLower = _keyword.toLowerCase();
        final matchCategory =
            record.categoryName.toLowerCase().contains(keywordLower);
        final matchNote =
            (record.remark ?? '').toLowerCase().contains(keywordLower);
        final matchAmount = record.amount.toString().contains(_keyword);
        if (!matchCategory && !matchNote && !matchAmount) return false;
      }
      if (_filterType != 'all' && record.type != _filterType) return false;
      if (_filterCategories.isNotEmpty &&
          !_filterCategories.contains(record.categoryId)) return false;
      if (_minAmount != null && record.amount < _minAmount!) return false;
      if (_maxAmount != null && record.amount > _maxAmount!) return false;
      if (_filterLocation.isNotEmpty) {
        final location = record.location ?? '';
        if (!location.toLowerCase().contains(_filterLocation.toLowerCase())) {
          return false;
        }
      }
      return true;
    }).toList();
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

  void _showFilterDialog() {
    final minController = TextEditingController(
        text: _minAmount != null ? _minAmount.toString() : '');
    final maxController = TextEditingController(
        text: _maxAmount != null ? _maxAmount.toString() : '');
    final locationController = TextEditingController(text: _filterLocation);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.tune, size: 20),
                SizedBox(width: DS.xs),
                Text('筛选条件'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('收支类型', style: DS.labelMd),
                  SizedBox(height: DS.sm),
                  Wrap(
                    spacing: DS.sm,
                    children: [
                      _buildFilterChip(label: '全部', selected: _filterType == 'all', onTap: () => setDialogState(() => _filterType = 'all')),
                      _buildFilterChip(label: '支出', selected: _filterType == 'expense', onTap: () => setDialogState(() => _filterType = 'expense')),
                      _buildFilterChip(label: '收入', selected: _filterType == 'income', onTap: () => setDialogState(() => _filterType = 'income')),
                    ],
                  ),
                  SizedBox(height: DS.gutter),
                  Text('分类', style: DS.labelMd),
                  SizedBox(height: DS.sm),
                  Wrap(
                    spacing: DS.sm,
                    runSpacing: DS.sm,
                    children: [
                      _buildFilterChip(label: '清除分类', selected: false, onTap: () => setDialogState(() => _filterCategories.clear())),
                      ..._getAllCategories().map((category) {
                        final isSelected = _filterCategories.contains(category['id']);
                        return _buildFilterChip(
                          label: '${category['emoji']} ${category['name']}',
                          selected: isSelected,
                          onTap: () => setDialogState(() {
                            if (isSelected) {
                              _filterCategories.remove(category['id']);
                            } else {
                              _filterCategories.add(category['id']);
                            }
                          }),
                        );
                      }),
                    ],
                  ),
                  SizedBox(height: DS.gutter),
                  Text('金额范围', style: DS.labelMd),
                  SizedBox(height: DS.sm),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: minController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(hintText: '最低金额', isDense: true),
                          style: DS.bodyMd,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: DS.sm),
                        child: Text('~', style: DS.bodyMd),
                      ),
                      Expanded(
                        child: TextField(
                          controller: maxController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(hintText: '最高金额', isDense: true),
                          style: DS.bodyMd,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: DS.gutter),
                  Text('位置', style: DS.labelMd),
                  SizedBox(height: DS.sm),
                  TextField(
                    controller: locationController,
                    decoration: const InputDecoration(
                      hintText: '按位置关键词筛选',
                      isDense: true,
                      prefixIcon: Icon(Icons.place, size: 18),
                    ),
                    style: DS.bodyMd,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _filterType = 'all';
                    _filterCategories.clear();
                    _minAmount = null;
                    _maxAmount = null;
                    _filterLocation = '';
                  });
                  Navigator.pop(context);
                  _loadRecords();
                },
                child: Text('清除'),
              ),
              ElevatedButton(
                onPressed: () {
                  final min = double.tryParse(minController.text.trim());
                  final max = double.tryParse(maxController.text.trim());
                  setState(() {
                    _minAmount = min;
                    _maxAmount = max;
                    _filterLocation = locationController.text.trim();
                  });
                  Navigator.pop(context);
                  _loadRecords();
                },
                child: Text('确定'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: DS.sm, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? DS.primary : DS.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(DS.radiusFull),
          border: Border.all(
            color: selected ? DS.primary : DS.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: DS.fontLabel,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? DS.onPrimary : DS.onSurface,
          ),
        ),
      ),
    );
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
    return Scaffold(
      backgroundColor: DS.background,
      body: SafeArea(
        top: false,
        child: Column(
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
                      Icon(Icons.receipt_long, size: 22, color: DS.onSurface),
                      SizedBox(width: DS.sm),
                      Text('我的账单', style: DS.headlineMd),
                    ],
                  ),
                  SizedBox(height: DS.sm),
                  // 收支汇总卡片
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
                  // 月份切换 + 搜索筛选
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _prevMonth,
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
                            color: Colors.white.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.chevron_right, size: 18, color: DS.onSurface),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: DS.sm),
                  // 搜索栏
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: DS.sm),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(DS.radiusFull),
                      border: Border.all(color: Colors.black.withOpacity(0.08)),
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
                              setState(() => _keyword = value);
                              _loadRecords();
                            },
                          ),
                        ),
                        GestureDetector(
                          onTap: _showFilterDialog,
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

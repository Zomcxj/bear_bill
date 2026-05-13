import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/database_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/utils.dart' as utils;
import 'widgets/bill_search_bar.dart';
import 'widgets/month_selector.dart';
import 'widgets/record_detail_dialog.dart';
import 'widgets/record_group_list.dart';

/// 账单列表页 - 搜索、筛选、分组展示、左滑删除
class BillListPage extends StatefulWidget {
  const BillListPage({super.key});

  @override
  State<BillListPage> createState() => _BillListPageState();
}

class _BillListPageState extends State<BillListPage> {
  String _currentMonth = '';
  List<Map<String, dynamic>> _groupedRecords = [];
  double _totalExpense = 0.0;
  double _totalIncome = 0.0;
  bool _loading = true;

  // 搜索和筛选状态
  String _keyword = '';
  String _filterType = 'all'; // all, expense, income
  final List<String> _filterCategories = [];
  final bool _showFilter = false;

  @override
  void initState() {
    super.initState();
    _currentMonth = utils.DateUtils.getCurrentMonth();
    _loadRecords();
    // 监听全局 Provider 变化，自动刷新列表（如新增/删除记录、切换账本）
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

    // 应用筛选
    final filteredRecords = _applyFilter(records);

    // 按日期分组
    final grouped = _groupByDate(filteredRecords);

    setState(() {
      _groupedRecords = grouped;
      _loading = false;
    });
  }

  List<RecordModel> _applyFilter(List<RecordModel> records) {
    return records.where((record) {
      // 关键词筛选
      if (_keyword.isNotEmpty) {
        final keywordLower = _keyword.toLowerCase();
        final matchCategory =
            record.categoryName.toLowerCase().contains(keywordLower);
        final matchNote =
            (record.remark ?? '').toLowerCase().contains(keywordLower);
        final matchAmount = record.amount.toString().contains(_keyword);
        if (!matchCategory && !matchNote && !matchAmount) {
          return false;
        }
      }

      // 类型筛选
      if (_filterType != 'all' && record.type != _filterType) {
        return false;
      }

      // 分类筛选
      if (_filterCategories.isNotEmpty &&
          !_filterCategories.contains(record.categoryId)) {
        return false;
      }

      return true;
    }).toList();
  }

  List<Map<String, dynamic>> _groupByDate(List<RecordModel> records) {
    final Map<String, Map<String, dynamic>> dateMap = {};
    double totalExpense = 0.0;
    double totalIncome = 0.0;

    // 获取今天和昨天的日期
    final today = utils.DateUtils.getToday();
    final yesterday = utils.DateUtils.getYesterday();

    for (final record in records) {
      if (!dateMap.containsKey(record.date)) {
        // 判断是否为今天或昨天
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

    // 转换为列表并按日期降序排序
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
    if (month < 1) {
      month = 12;
      year--;
    }

    setState(() {
      _currentMonth = '$year-${month.toString().padLeft(2, '0')}';
    });
    _loadRecords();
  }

  void _nextMonth() {
    final parts = _currentMonth.split('-');
    int year = int.parse(parts[0]);
    int month = int.parse(parts[1]);

    month++;
    if (month > 12) {
      month = 1;
      year++;
    }

    setState(() {
      _currentMonth = '$year-${month.toString().padLeft(2, '0')}';
    });
    _loadRecords();
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('筛选条件'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 类型筛选
                  const Text(
                    '收支类型',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildFilterChip(
                        label: '全部',
                        selected: _filterType == 'all',
                        onTap: () {
                          setDialogState(() {
                            _filterType = 'all';
                          });
                        },
                      ),
                      _buildFilterChip(
                        label: '支出',
                        selected: _filterType == 'expense',
                        onTap: () {
                          setDialogState(() {
                            _filterType = 'expense';
                          });
                        },
                      ),
                      _buildFilterChip(
                        label: '收入',
                        selected: _filterType == 'income',
                        onTap: () {
                          setDialogState(() {
                            _filterType = 'income';
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 分类筛选
                  const Text(
                    '分类',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFilterChip(
                        label: '清除分类',
                        selected: false,
                        onTap: () {
                          setDialogState(() {
                            _filterCategories.clear();
                          });
                        },
                      ),
                      ..._getAllCategories().map((category) {
                        final isSelected =
                            _filterCategories.contains(category['id']);
                        return _buildFilterChip(
                          label: '${category['emoji']} ${category['name']}',
                          selected: isSelected,
                          onTap: () {
                            setDialogState(() {
                              if (isSelected) {
                                _filterCategories.remove(category['id']);
                              } else {
                                _filterCategories.add(category['id']);
                              }
                            });
                          },
                        );
                      }),
                    ],
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
                  });
                  Navigator.pop(context);
                  _loadRecords();
                },
                child: const Text('清除'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _loadRecords();
                },
                child: const Text(
                  '确定',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: selected ? Colors.white : AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getAllCategories() {
    // 获取所有分类（支出 + 收入）
    final allCategories = <Map<String, dynamic>>[];

    // 支出分类
    for (final cat in expenseCategories) {
      allCategories.add({
        'id': cat.id,
        'name': cat.name,
        'emoji': cat.icon,
      });
    }

    // 收入分类
    for (final cat in incomeCategories) {
      allCategories.add({
        'id': cat.id,
        'name': cat.name,
        'emoji': cat.icon,
      });
    }

    return allCategories;
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>(); // listen to theme changes
    return Scaffold(
      backgroundColor: AppTheme.bgPage,
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('📔', style: TextStyle(fontSize: 20)),
            SizedBox(width: 8),
            Text(
              '我的账单',
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
      body: Column(
        children: [
          // 月份切换条
          MonthSelector(
            currentMonth: _currentMonth,
            totalExpense: _totalExpense,
            totalIncome: _totalIncome,
            onPrevMonth: _prevMonth,
            onNextMonth: _nextMonth,
            onMonthPicked: (month) {
              setState(() => _currentMonth = month);
              _loadRecords();
            },
          ),

          // 搜索筛选栏
          BillSearchBar(
            keyword: _keyword,
            filterType: _filterType,
            filterCategories: _filterCategories,
            onKeywordChanged: (value) {
              setState(() {
                _keyword = value;
              });
              _loadRecords();
            },
            onFilterTap: _showFilterDialog,
          ),

          // 账单列表
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
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
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🔍', style: TextStyle(fontSize: 64)),
          SizedBox(height: AppSpacing.md),
          Text(
            '本月还没有账单',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '快去记第一笔吧 🐻',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textHint,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteRecord(String recordId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这条账单吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                Text('删除', style: TextStyle(color: AppTheme.primaryDark)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseService.instance.deleteRecord(recordId);
      context.read<AppProvider>().onRecordDeleted();
      NotificationService.instance.refreshTodaySummary();
      _loadRecords();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已删除'),
            duration: Duration(seconds: 1),
          ),
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

import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart'
    show GlassButton, GlassButtonStyle, LiquidRoundedSuperellipse;
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/category_order_service.dart';
import '../../services/database_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_design_system.dart';
import '../../theme/glass_materials.dart';
import '../../utils/utils.dart' as utils;
import '../../widgets/glass_dialog_shell.dart';
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
    // 支出分类跟随用户自定义顺序
    for (final cat in CategoryOrderService.instance.expense) {
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
                      Icon(Icons.receipt_long, size: 22, color: DS.onSurface),
                      SizedBox(width: DS.sm),
                      Text('我的账单', style: DS.headlineMd),
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
                  // 玻璃态：整条日期栏 = 底部导航栏同款玻璃条（与统计页统一）；
                  // 关闭态原样（零漂移）
                  GlassBarWrap(
                    child: Row(
                      children: [
                        _monthArrow(context, icon: Icons.chevron_left, onTap: _prevMonth),
                        SizedBox(width: DS.xs),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _pickYearMonth(context),
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: DS.sm, vertical: DS.xs + 2),
                              decoration: BoxDecoration(
                                // 玻璃条本身是玻璃面，胶囊不再填充
                                color: shouldUseLiquidGlass(context)
                                    ? Colors.transparent
                                    : DS.heroCardBg,
                                borderRadius: BorderRadius.circular(DS.radiusFull),
                                // 玻璃主题无边框；关闭态原样
                                border: shouldUseLiquidGlass(context)
                                    ? null
                                    : Border.all(color: DS.heroCardBorder),
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
                        _monthArrow(context, icon: Icons.chevron_right, onTap: _nextMonth),
                      ],
                    ),
                  ),
                  SizedBox(height: DS.sm),
                  GlassSurface(
                    padding: EdgeInsets.symmetric(horizontal: DS.sm),
                    fallbackDecoration: BoxDecoration(
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
                            decoration: InputDecoration(
                              // 主题全局 filled + 实色 fillColor(surfaceContainerLow)
                              // 会把整个玻璃框填黑 —— 玻璃态必须置透明，玻璃才透出来
                              filled: true,
                              fillColor: shouldUseLiquidGlass(context)
                                  ? Colors.transparent
                                  : null,
                              hintText: '搜索分类、备注...',
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 10),
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

          // 与每日分组间距一致（组间也是 DS.sm），避免首组贴顶
          SizedBox(height: DS.sm),
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

  /// 玻璃态：透明玻璃圆钮（玻璃条本身已是玻璃，不套玻璃）；
  /// 关闭态：原填充圆钮（零漂移）
  Widget _monthArrow(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
  }) {
    if (shouldUseLiquidGlass(context)) {
      return GlassButton.custom(
        style: GlassButtonStyle.transparent,
        onTap: onTap,
        interactionScale: 1.12,
        stretch: 0.2,
        shape: const LiquidRoundedSuperellipse(borderRadius: 999),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(icon, size: 18, color: DS.onSurface),
        ),
      );
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: DS.heroCardBg,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: DS.onSurface),
      ),
    );
  }

  void _pickYearMonth(BuildContext context) {
    // 玻璃年月选择小窗（三处日期切换统一组件，见 glass_dialog_shell）
    showGlassYearMonthPicker(
      context: context,
      currentMonth: _currentMonth,
      onPicked: (m) {
        setState(() => _currentMonth = m);
        _loadRecords();
      },
    );
  }

  Future<void> _deleteRecord(String recordId) async {
    // 开启液态玻璃时走玻璃弹窗（真玻璃材质），关闭时回退标准 AlertDialog
    final confirmed = await showGlassConfirmDialog(
      context: context,
      title: '确认删除',
      message: '确定要删除这条账单吗？',
      confirmText: '删除',
      destructive: true,
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
    // 玻璃态走居中小窗壳（showDialog 的紧约束会把玻璃壳撑成全屏）
    showGlassContentDialog(
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

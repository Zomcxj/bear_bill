import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/app_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../services/database_service.dart';
import '../../../theme/app_design_system.dart';
import '../../../utils/utils.dart' as utils;
import '../../../widgets/glass_card.dart';
import '../../multi_book/multi_book_page.dart';
import '../../statistics/statistics_page.dart';

/// Hero 问候卡片 — Luminous Finance 渐变风格
class GreetingCard extends StatefulWidget {
  const GreetingCard({super.key});

  @override
  State<GreetingCard> createState() => _GreetingCardState();
}

class _GreetingCardState extends State<GreetingCard>
    with SingleTickerProviderStateMixin {
  String _greeting = '';
  String _bearMood = '';
  String _bearEmoji = '🐻';

  double _totalExpense = 0.0;
  double _totalIncome = 0.0;
  double _balance = 0.0;

  String _monthLabel = '';
  String _currentBookName = '小熊账本';
  String _currentBookIcon = '🐻';
  double _monthlyBudget = 0.0;

  int _checkInDays = 0;
  bool _todayChecked = false;

  late final AnimationController _floatController;
  late final Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _loadData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      appProvider.addListener(_loadData);
    });

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -3, end: 3).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      appProvider.removeListener(_loadData);
    } catch (_) {}
    super.dispose();
  }

  Future<void> _loadData() async {
    final appProvider = context.read<AppProvider>();

    setState(() {
      _greeting = utils.DateUtils.getGreeting();
      _checkInDays = appProvider.checkInDays;
      _todayChecked = appProvider.todayChecked;
    });

    final currentMonth = utils.DateUtils.getCurrentMonth();
    final stats = await DatabaseService.instance.getMonthStatistics(
      currentMonth,
      bookId: appProvider.currentBookId,
    );

    final expense = stats['expense'] ?? 0.0;
    final income = stats['income'] ?? 0.0;
    final balance = income - expense;

    String mood;
    String emoji;
    if (balance > 2000) {
      emoji = '🥳';
      mood = '超级开心！结余好多呢';
    } else if (balance > 500) {
      emoji = '😊';
      mood = '不错哦，继续加油！';
    } else if (balance > 0) {
      emoji = '😌';
      mood = '基本平衡，小熊放心了';
    } else if (balance > -500) {
      emoji = '😅';
      mood = '稍微超支了，要注意哦';
    } else {
      emoji = '😢';
      mood = '超支啦！下次省着点吧';
    }

    final book = await appProvider.getCurrentBook();

    if (mounted) {
      setState(() {
        _totalExpense = expense;
        _totalIncome = income;
        _balance = balance;
        _bearMood = mood;
        _bearEmoji = emoji;
        _monthLabel = utils.DateUtils.formatMonthCN(currentMonth);
        _currentBookName = book?.name ?? '小熊账本';
        _currentBookIcon = book?.icon ?? '🐻';
        _monthlyBudget = book?.budget ?? 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>(); // 主题变更时触发重建
    return Container(
      decoration: BoxDecoration(
        gradient: DS.heroGradientBlueCurrent,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(DS.radiusLg),
          bottomRight: Radius.circular(DS.radiusLg),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        DS.containerMargin,
        MediaQuery.of(context).padding.top + DS.gutter,
        DS.containerMargin,
        DS.base,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 问候行
          Row(
            children: [
              AnimatedBuilder(
                animation: _floatAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _floatAnimation.value),
                    child: child,
                  );
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black.withOpacity(0.08)),
                  ),
                  child: Center(
                    child: Text(_bearEmoji, style: TextStyle(fontSize: 28)),
                  ),
                ),
              ),
              SizedBox(width: DS.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greeting,
                      style: DS.headlineSm.copyWith(color: DS.onSurface),
                    ),
                    SizedBox(height: 2),
                    Text(
                      _bearMood,
                      style: DS.labelSm.copyWith(color: DS.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _todayChecked ? null : _handleCheckIn,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(DS.radiusSm),
                    border: Border.all(color: Colors.black.withOpacity(0.08)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _todayChecked ? Icons.check_circle : Icons.local_fire_department,
                        size: 16,
                        color: _todayChecked ? DS.secondary : DS.error,
                      ),
                      SizedBox(height: 1),
                      Text(
                        '$_checkInDays天',
                        style: TextStyle(
                          fontFamily: DS.fontLabel,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: DS.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: DS.sm),

          // 月份 + 账本
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$_monthLabel 概览',
                style: DS.labelMd.copyWith(color: DS.onSurfaceVariant),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MultiBookPage()),
                  );
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: DS.sm,
                    vertical: DS.xs + 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(DS.radiusSm),
                    border: Border.all(color: Colors.black.withOpacity(0.08)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_currentBookIcon, style: TextStyle(fontSize: 14)),
                      SizedBox(width: DS.xs),
                      Text(
                        _currentBookName,
                        style: DS.labelSm.copyWith(color: DS.onSurface),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.chevron_right, size: 14, color: DS.outline),
                    ],
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: DS.sm),

          // 三项汇总 — 毛玻璃卡片
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StatisticsPage()),
              );
            },
            child: GlassCard(
              padding: EdgeInsets.symmetric(vertical: DS.gutter),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    _buildSummaryCell(
                      '¥${utils.FormatUtils.formatAmount(_totalExpense)}',
                      '本月支出',
                      DS.error,
                    ),
                    _buildDivider(),
                    _buildSummaryCell(
                      '¥${utils.FormatUtils.formatAmount(_totalIncome)}',
                      '本月收入',
                      DS.secondary,
                    ),
                    _buildDivider(),
                    _buildSummaryCell(
                      '¥${utils.FormatUtils.formatAmount(_balance.abs())}',
                      '结余',
                      _balance >= 0 ? DS.secondary : DS.error,
                    ),
                  ],
                ),
              ),
            ),
          ),

          SizedBox(height: DS.sm),

          // 预算进度
          if (_monthlyBudget > 0)
            GestureDetector(
              onTap: _showBudgetSettings,
              child: GlassCard(
                padding: EdgeInsets.all(DS.gutter),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.pie_chart_outline, size: 16, color: DS.onSurface),
                            SizedBox(width: DS.xs),
                            Text('本月预算', style: DS.labelMd),
                          ],
                        ),
                        Text(
                          '¥${utils.FormatUtils.formatAmount(_totalExpense)} / ¥${utils.FormatUtils.formatAmount(_monthlyBudget)}',
                          style: DS.labelSm.copyWith(color: DS.onSurfaceVariant),
                        ),
                      ],
                    ),
                    SizedBox(height: DS.sm),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(DS.radiusFull),
                      child: LinearProgressIndicator(
                        value: (_totalExpense / _monthlyBudget).clamp(0, 1),
                        backgroundColor: DS.surfaceContainerHigh,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _totalExpense > _monthlyBudget
                              ? DS.error
                              : _totalExpense > _monthlyBudget * 0.8
                                  ? DS.secondaryContainer
                                  : DS.secondary,
                        ),
                        minHeight: 8,
                      ),
                    ),
                    SizedBox(height: DS.xs),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${((_totalExpense / _monthlyBudget) * 100).toStringAsFixed(1)}% 已使用',
                          style: DS.labelSm.copyWith(
                            color: _totalExpense > _monthlyBudget
                                ? DS.error
                                : DS.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          _totalExpense > _monthlyBudget
                              ? '已超支 ¥${utils.FormatUtils.formatAmount(_totalExpense - _monthlyBudget)}'
                              : '剩余 ¥${utils.FormatUtils.formatAmount(_monthlyBudget - _totalExpense)}',
                          style: DS.labelSm.copyWith(
                            color: _totalExpense > _monthlyBudget
                                ? DS.error
                                : DS.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCell(String value, String label, Color valueColor) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: DS.fontDisplay,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: valueColor,
              height: 1.2,
              letterSpacing: -0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: DS.xs),
          Text(
            label,
            style: DS.labelSm.copyWith(color: DS.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      color: DS.outlineVariant,
      margin: EdgeInsets.symmetric(vertical: 4),
    );
  }

  Future<void> _handleCheckIn() async {
    final appProvider = context.read<AppProvider>();
    final achievements = await appProvider.recordCheckIn();

    setState(() {
      _checkInDays = appProvider.checkInDays;
      _todayChecked = appProvider.todayChecked;
    });

    if (achievements.isNotEmpty) {
      _showAchievementToast(achievements);
    }
  }

  void _showAchievementToast(List<dynamic> achievements) {
    final first = achievements.first;
    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: GlassCard(
          padding: EdgeInsets.symmetric(horizontal: DS.md, vertical: DS.gutter),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.emoji_events, size: 40, color: DS.secondaryContainer),
              SizedBox(width: DS.gutter),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('成就解锁！', style: DS.labelSm.copyWith(color: DS.outline)),
                  SizedBox(height: 2),
                  Text(
                    first.title ?? '新成就',
                    style: DS.headlineSm.copyWith(color: DS.onSurface),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      if (!mounted) return;
      context.read<AppProvider>().clearNewAchievements();
    });
  }

  void _showBudgetSettings() {
    final controller = TextEditingController(
      text: _monthlyBudget > 0 ? _monthlyBudget.toStringAsFixed(0) : '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.savings_outlined, size: 20),
            SizedBox(width: DS.xs),
            Text('设置月度预算'),
          ],
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '预算金额',
            prefixText: '¥ ',
            hintText: '请输入月度预算',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              final input = controller.text.trim();
              if (input.isEmpty) {
                Navigator.pop(context);
                return;
              }

              final budget = double.tryParse(input);
              if (budget == null || budget < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请输入有效的预算金额')),
                );
                return;
              }

              final appProvider = context.read<AppProvider>();
              final book = await appProvider.getCurrentBook();
              if (book != null) {
                final updatedBook = book.copyWith(budget: budget);
                await DatabaseService.instance.updateBook(updatedBook);
                if (!mounted) return;

                _loadData();

                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('预算已更新'),
                    backgroundColor: DS.secondary,
                  ),
                );
              }
            },
            child: Text('保存'),
          ),
        ],
      ),
    );
  }
}

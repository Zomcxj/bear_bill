import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/app_provider.dart';
import '../../../services/database_service.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/utils.dart' as utils;
import '../../../widgets/app_card.dart';
import '../../multi_book/multi_book_page.dart';
import '../../statistics/statistics_page.dart';

/// 小熊问候卡片 - Hero 区域（对齐小程序版）
/// 包含装饰气泡、白色文字、毛玻璃 summary 三栏、悬浮动画
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
  double _monthlyBudget = 0.0; // 月度预算

  int _checkInDays = 0;
  bool _todayChecked = false;

  // 悬浮动画控制器
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

    // 悬浮动画：上下缓慢浮动
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
        _monthlyBudget = book?.budget ?? 0.0; // 加载预算
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppRadius.xl),
          bottomRight: Radius.circular(AppRadius.xl),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        MediaQuery.of(context).padding.top + AppSpacing.lg, // 状态栏高度
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Stack(
        children: [
          // ── 装饰气泡 ──
          Positioned(
            top: -15,
            right: 30,
            child: _buildBubble(60),
          ),
          Positioned(
            top: 30,
            right: -10,
            child: _buildBubble(40),
          ),
          Positioned(
            bottom: -30,
            left: -20,
            child: _buildBubble(80),
          ),

          // ── 主内容 ──
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 问候行
              Row(
                children: [
                  // 小熊 Emoji（悬浮动画）
                  AnimatedBuilder(
                    animation: _floatAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _floatAnimation.value),
                        child: child,
                      );
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          _bearEmoji,
                          style: const TextStyle(fontSize: 26),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: AppSpacing.sm),

                  // 问候语文本（白色）
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _greeting,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.heroTextMain,
                            shadows: [
                              Shadow(
                                color: Color(0x26000000),
                                offset: Offset(0, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _bearMood,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.heroTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 打卡徽章（半透明白底）
                  GestureDetector(
                    onTap: _todayChecked ? null : _handleCheckIn,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.35),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _todayChecked ? '✅' : '🔥',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            '$_checkInDays天',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.heroTextMain,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // 月份标签 + 账本切换
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$_monthLabel 概览',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.heroTextMain,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const MultiBookPage()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_currentBookIcon,
                              style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 4),
                          Text(
                            _currentBookName,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.heroTextMain,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '›',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.7),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // 三项汇总（毛玻璃背景）
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const StatisticsPage()),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        _buildSummaryCell(
                          '¥${utils.FormatUtils.formatAmount(_totalExpense)}',
                          '本月支出',
                          AppTheme.heroExpense,
                        ),
                        _buildDivider(),
                        _buildSummaryCell(
                          '¥${utils.FormatUtils.formatAmount(_totalIncome)}',
                          '本月收入',
                          AppTheme.heroIncome,
                        ),
                        _buildDivider(),
                        _buildSummaryCell(
                          '¥${utils.FormatUtils.formatAmount(_balance.abs())}',
                          '结余',
                          _balance >= 0
                              ? AppTheme.heroBalancePos
                              : AppTheme.heroBalanceNeg,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // 月度预算进度条
              _monthlyBudget > 0
                  ? GestureDetector(
                      onTap: _showBudgetSettings,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  '📊 本月预算',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.heroTextMain,
                                  ),
                                ),
                                Text(
                                  '¥${utils.FormatUtils.formatAmount(_totalExpense)} / ¥${utils.FormatUtils.formatAmount(_monthlyBudget)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.heroTextSub,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.full),
                              child: LinearProgressIndicator(
                                value: _totalExpense / _monthlyBudget,
                                backgroundColor: Colors.white.withOpacity(0.25),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _totalExpense > _monthlyBudget
                                      ? AppTheme.heroBalanceNeg
                                      : _totalExpense > _monthlyBudget * 0.8
                                          ? const Color(0xFFFFA726)
                                          : AppTheme.heroIncome,
                                ),
                                minHeight: 8,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${((_totalExpense / _monthlyBudget) * 100).toStringAsFixed(1)}% 已使用',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _totalExpense > _monthlyBudget
                                        ? AppTheme.heroBalanceNeg
                                        : AppTheme.heroTextSub,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  _totalExpense > _monthlyBudget
                                      ? '已超支 ¥${utils.FormatUtils.formatAmount(_totalExpense - _monthlyBudget)}'
                                      : '剩余 ¥${utils.FormatUtils.formatAmount(_monthlyBudget - _totalExpense)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _totalExpense > _monthlyBudget
                                        ? AppTheme.heroBalanceNeg
                                        : AppTheme.heroIncome,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ],
          ),
        ],
      ),
    );
  }

  /// 装饰气泡
  Widget _buildBubble(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.12),
      ),
    );
  }

  /// 汇总单元格
  Widget _buildSummaryCell(String value, String label, Color valueColor) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: valueColor,
              height: 1.2,
              letterSpacing: -0.5,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.heroTextMain,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  /// 分隔线
  Widget _buildDivider() {
    return Container(
      width: 1,
      color: Colors.white.withOpacity(0.25),
      margin: const EdgeInsets.symmetric(vertical: 4),
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

  /// 成就解锁弹窗（对齐小程序的 achievement-toast）
  void _showAchievementToast(List<dynamic> achievements) {
    final first = achievements.first;
    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: AppCard(
          margin: const EdgeInsets.only(top: 60),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          showShadow: true,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                first.emoji ?? '🏆',
                style: const TextStyle(fontSize: 40),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '成就解锁！',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textHint,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    first.title ?? '新成就',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      context.read<AppProvider>().clearNewAchievements();
    });
  }

  /// 显示预算设置对话框
  void _showBudgetSettings() {
    final controller = TextEditingController(
      text: _monthlyBudget > 0 ? _monthlyBudget.toStringAsFixed(0) : '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('💰 设置月度预算'),
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
            child: const Text('取消'),
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

              // 更新当前账本的预算
              final appProvider = context.read<AppProvider>();
              final book = await appProvider.getCurrentBook();
              if (book != null) {
                final updatedBook = book.copyWith(budget: budget);
                await DatabaseService.instance.updateBook(updatedBook);

                // 刷新数据
                _loadData();

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('预算已更新'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}

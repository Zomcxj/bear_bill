import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/database_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/utils.dart';
import 'widgets/add_money_dialog.dart';
import 'widgets/create_wish_dialog.dart';
import 'widgets/wish_jar_card.dart';

/// 心愿罐页 - 创建心愿、存钱进度、完成庆祝
class WishJarPage extends StatefulWidget {
  const WishJarPage({super.key});

  @override
  State<WishJarPage> createState() => _WishJarPageState();
}

class _WishJarPageState extends State<WishJarPage>
    with SingleTickerProviderStateMixin {
  List<WishModel> _wishes = [];
  double _totalSaved = 0.0;
  double _totalTarget = 0.0;
  int _completedCount = 0;
  bool _loading = true;
  String _currentTab = 'ongoing'; // ongoing, completed
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTab = _tabController.index == 0 ? 'ongoing' : 'completed';
      });
    });
    _loadWishes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadWishes() async {
    setState(() => _loading = true);

    final wishes = await DatabaseService.instance.getAllWishes();

    // 计算统计数据
    double totalSaved = 0.0;
    double totalTarget = 0.0;
    int completedCount = 0;

    for (final wish in wishes) {
      totalSaved += wish.currentAmount;
      totalTarget += wish.targetAmount;
      if (wish.isCompleted) {
        completedCount++;
      }
    }

    setState(() {
      _wishes = wishes;
      _totalSaved = totalSaved;
      _totalTarget = totalTarget;
      _completedCount = completedCount;
      _loading = false;
    });
  }

  Future<void> _createWish(WishModel wish) async {
    await DatabaseService.instance.insertWish(wish);
    _loadWishes();

    // 检查心愿成就
    if (mounted) {
      context.read<AppProvider>().checkWishAchievements();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('心愿创建成功！🎉'),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  Future<void> _addMoney(String wishId, double amount) async {
    final wish = _wishes.firstWhere((w) => w.id == wishId);
    final newAmount = wish.currentAmount + amount;
    final isCompleted = newAmount >= wish.targetAmount;

    final updatedWish = wish.copyWith(
      currentAmount: newAmount,
      isCompleted: isCompleted,
      completedAt: isCompleted ? DateTime.now() : null,
    );

    await DatabaseService.instance.updateWish(updatedWish);
    _loadWishes();

    // 检查心愿成就（完成心愿时）
    if (isCompleted && mounted) {
      context.read<AppProvider>().checkWishAchievements();
    }

    if (mounted) {
      if (isCompleted) {
        _showCompletionCelebration(updatedWish);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已存入 ¥${FormatUtils.formatAmount(amount)} 💰'),
            backgroundColor: AppTheme.success,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }

  Future<void> _deleteWish(String wishId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个心愿吗？'),
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
      await DatabaseService.instance.deleteWish(wishId);
      _loadWishes();

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

  void _showCompletionCelebration(WishModel wish) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 0.5 + (value * 0.5),
                    child: const Text('🎉', style: TextStyle(fontSize: 80)),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                '恭喜达成心愿！',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                wish.title,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                ),
                child: const Text('太棒了！'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>(); // listen to theme changes
    final ongoingWishes = _wishes.where((w) => !w.isCompleted).toList();
    final completedWishes = _wishes.where((w) => w.isCompleted).toList();

    return Scaffold(
      backgroundColor: AppTheme.bgPage,
      appBar: AppBar(
        title: const Text('心愿储蓄罐'),
        backgroundColor: AppTheme.primary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ongoingWishes.isEmpty && completedWishes.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    // 顶部统计横幅
                    _buildHeroBanner(),

                    // Tab切换
                    Container(
                      color: Colors.white,
                      child: TabBar(
                        controller: _tabController,
                        indicatorColor: AppTheme.primary,
                        labelColor: AppTheme.primary,
                        unselectedLabelColor: AppTheme.textSecondary,
                        labelStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                        ),
                        tabs: const [
                          Tab(text: '进行中'),
                          Tab(text: '已实现'),
                        ],
                      ),
                    ),

                    // 心愿列表
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildWishList(
                            ongoingWishes,
                            emptyText: '暂无进行中的心愿',
                          ),
                          _buildWishList(
                            completedWishes,
                            emptyText: '暂无已实现的心愿',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
      // 悬浮按钮：创建心愿
      floatingActionButton: SizedBox(
        width: 100,
        child: FloatingActionButton.extended(
          onPressed: _showCreateDialog,
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          icon: const Text('✨', style: TextStyle(fontSize: 20)),
          label: const Text(
            '创建心愿',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
        ),
      ),
    );
  }

  Widget _buildWishList(List<WishModel> wishes, {required String emptyText}) {
    if (wishes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 64)),
            const SizedBox(height: AppSpacing.md),
            Text(
              emptyText,
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.sm),
      itemCount: wishes.length,
      itemBuilder: (context, index) {
        final wish = wishes[index];
        return WishJarCard(
          wish: wish,
          onAddMoney: () => _showAddMoneyDialog(wish),
          onDelete: () => _deleteWish(wish.id),
        );
      },
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
      ),
      child: Column(
        children: [
          Row(
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(seconds: 2),
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, -5 * value),
                    child: const Text('🫙', style: TextStyle(fontSize: 48)),
                  );
                },
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '心愿储蓄罐',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '把梦想装进罐子，一点点填满它',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // 统计数据
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                  '¥${FormatUtils.formatAmount(_totalSaved)}', '已存入'),
              Container(height: 30, width: 1, color: AppTheme.border),
              _buildStatItem('$_completedCount', '已实现'),
              Container(height: 30, width: 1, color: AppTheme.border),
              _buildStatItem('${_wishes.length}', '总心愿'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(seconds: 2),
            builder: (context, value, child) {
              return Transform.scale(
                scale: 1.0 + (value * 0.1),
                child: const Text('🫙', style: TextStyle(fontSize: 80)),
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            '还没有心愿罐',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '许下你的第一个心愿吧！',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton.icon(
            onPressed: () => _showCreateDialog(),
            icon: const Icon(Icons.add),
            label: const Text('创建第一个心愿'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateWishDialog(onCreate: _createWish),
    );
  }

  void _showAddMoneyDialog(WishModel wish) {
    showDialog(
      context: context,
      builder: (context) => AddMoneyDialog(
        wish: wish,
        onAdd: (amount) {
          Navigator.pop(context);
          _addMoney(wish.id, amount);
        },
      ),
    );
  }
}

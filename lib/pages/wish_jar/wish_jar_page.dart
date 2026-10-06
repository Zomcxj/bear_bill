import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart'
    show GlassContainer, GlassQuality, GlassSegment, GlassSegmentedControl,
        LiquidRoundedSuperellipse;
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/database_service.dart';
import '../../theme/app_design_system.dart';
import '../../theme/glass_materials.dart';
import '../../utils/utils.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/glass_dialog_shell.dart';
import 'widgets/add_money_dialog.dart';
import 'widgets/create_wish_dialog.dart';
import 'widgets/wish_jar_card.dart';

/// 心愿罐页 — Luminous Finance 渐变风格
class WishJarPage extends StatefulWidget {
  const WishJarPage({super.key});

  @override
  State<WishJarPage> createState() => _WishJarPageState();
}

class _WishJarPageState extends State<WishJarPage>
    with SingleTickerProviderStateMixin {
  List<WishModel> _wishes = [];
  double _totalSaved = 0.0;
  int _completedCount = 0;
  bool _loading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
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

    double totalSaved = 0.0;
    int completedCount = 0;
    for (final wish in wishes) {
      totalSaved += wish.currentAmount;
      if (wish.isCompleted) completedCount++;
    }

    setState(() {
      _wishes = wishes;
      _totalSaved = totalSaved;
      _completedCount = completedCount;
      _loading = false;
    });
  }

  Future<void> _createWish(WishModel wish) async {
    await DatabaseService.instance.insertWish(wish);
    _loadWishes();
    if (mounted) {
      context.read<AppProvider>().checkWishAchievements();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('心愿创建成功！'), backgroundColor: DS.secondary),
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

    if (isCompleted && mounted) {
      context.read<AppProvider>().checkWishAchievements();
    }

    if (mounted) {
      if (isCompleted) {
        _showCompletionCelebration(updatedWish);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已存入 ¥${FormatUtils.formatAmount(amount)}'),
            backgroundColor: DS.secondary,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }

  Future<void> _deleteWish(String wishId) async {
    // 开启液态玻璃时走玻璃弹窗，关闭时回退标准 AlertDialog
    final confirmed = await showGlassConfirmDialog(
      context: context,
      title: '确认删除',
      message: '确定要删除这个心愿吗？',
      confirmText: '删除',
      destructive: true,
    );

    if (confirmed == true) {
      await DatabaseService.instance.deleteWish(wishId);
      _loadWishes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已删除'), duration: Duration(seconds: 1)),
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
        child: GlassCard(
          padding: EdgeInsets.all(DS.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 0.5 + (value * 0.5),
                    child: Icon(Icons.celebration, size: 80, color: DS.secondaryContainer),
                  );
                },
              ),
              SizedBox(height: DS.md),
              Text('恭喜达成心愿！', style: DS.headlineMd),
              SizedBox(height: DS.sm),
              Text(wish.title, style: DS.bodyMd.copyWith(color: DS.onSurfaceVariant)),
              SizedBox(height: DS.md),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('太棒了！'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>(); // 主题变更时触发重建
    final ongoingWishes = _wishes.where((w) => !w.isCompleted).toList();
    final completedWishes = _wishes.where((w) => w.isCompleted).toList();

    return Scaffold(
      backgroundColor: DS.background,
      body: SafeArea(
        top: false,
        bottom: false,
        child: _loading
          ? const Center(child: CircularProgressIndicator(color: DS.secondaryContainer))
          : ongoingWishes.isEmpty && completedWishes.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    _buildHeroBanner(),
                    SizedBox(height: DS.base),
                    Expanded(
                      child: _tabController.index == 0
                          ? _buildWishList(ongoingWishes, emptyText: '暂无进行中的心愿')
                          : _buildWishList(completedWishes, emptyText: '暂无已实现的心愿'),
                    ),
                  ],
                ),
        ),
      // 玻璃态下 GlassScaffold 沉浸式布局，FAB 需上抬让位（与首页"记一笔"一致）
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          bottom: shouldUseLiquidGlass(context) ? 96 : 0,
        ),
        child: shouldUseLiquidGlass(context)
            ? _buildGlassCreateButton()
            : FloatingActionButton.extended(
                onPressed: _showCreateDialog,
                backgroundColor: DS.secondaryContainer,
                foregroundColor: DS.primary,
                icon: Icon(Icons.auto_awesome, size: 20),
                label: Text('创建心愿', style: DS.labelMd),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DS.radiusFull),
                ),
              ),
      ),
    );
  }

  /// 「创建心愿」玻璃药丸：与首页「记一笔」同款材质/尺寸（高 56）
  Widget _buildGlassCreateButton() {
    return GlassContainer(
      height: 56,
      shape: const LiquidRoundedSuperellipse(borderRadius: DS.radiusFull),
      settings: GlassMaterials.bar(),
      quality: GlassQuality.standard,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: _showCreateDialog,
        behavior: HitTestBehavior.opaque,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 20, color: DS.onSurface),
            const SizedBox(width: 8),
            Text(
              '创建心愿',
              style: TextStyle(
                fontFamily: DS.fontLabel,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: DS.onSurface,
              ),
            ),
          ],
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
            Icon(Icons.savings_outlined, size: 64, color: DS.outlineVariant),
            SizedBox(height: DS.md),
            Text(emptyText, style: DS.bodyMd.copyWith(color: DS.onSurfaceVariant)),
          ],
        ),
      );
    }

    return ListView.builder(
      // 玻璃模式底部留白：避免最后一张卡被浮动玻璃底栏盖住
      padding: EdgeInsets.only(
        left: DS.sm,
        right: DS.sm,
        bottom: DS.sm + glassBottomInset(context),
      ),
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
              Icon(Icons.savings, size: 22, color: DS.onSurface),
              SizedBox(width: DS.sm),
              Text('心愿储蓄罐', style: DS.headlineMd),
            ],
          ),
          SizedBox(height: DS.sm),
          GlassCard(
            padding: EdgeInsets.symmetric(vertical: DS.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('¥${FormatUtils.formatAmount(_totalSaved)}', '已存入'),
                Container(height: 30, width: 1, color: DS.outlineVariant),
                _buildStatItem('$_completedCount', '已实现'),
                Container(height: 30, width: 1, color: DS.outlineVariant),
                _buildStatItem('${_wishes.length}', '总心愿'),
              ],
            ),
          ),
          SizedBox(height: DS.sm),
          // Tab 切换
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
                      onTap: () => _tabController.animateTo(0),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: DS.sm),
                        decoration: BoxDecoration(
                          color: _tabController.index == 0 ? DS.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(DS.radiusFull),
                        ),
                        child: Center(
                          child: Text('进行中', style: DS.labelMd.copyWith(
                            color: _tabController.index == 0 ? DS.onPrimary : DS.onSurface,
                          )),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _tabController.animateTo(1),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: DS.sm),
                        decoration: BoxDecoration(
                          color: _tabController.index == 1 ? DS.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(DS.radiusFull),
                        ),
                        child: Center(
                          child: Text('已实现', style: DS.labelMd.copyWith(
                            color: _tabController.index == 1 ? DS.onPrimary : DS.onSurface,
                          )),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            GlassSegmentedControl(
              segments: const [
                GlassSegment(label: '进行中'),
                GlassSegment(label: '已实现'),
              ],
              selectedIndex: _tabController.index,
              onSegmentSelected: (i) => _tabController.animateTo(i),
              height: 34,
              selectedTextStyle: DS.labelMd.copyWith(
                fontWeight: FontWeight.w600,
                color: DS.onSurface,
              ),
              unselectedTextStyle:
                  DS.labelMd.copyWith(color: DS.onSurfaceVariant),
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: DS.headlineSm.copyWith(color: DS.onSurface)),
        SizedBox(height: DS.xs),
        Text(label, style: DS.labelSm.copyWith(color: DS.onSurfaceVariant)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.savings_outlined, size: 80, color: DS.outlineVariant),
          SizedBox(height: DS.md),
          Text('还没有心愿罐', style: DS.headlineSm),
          SizedBox(height: DS.sm),
          Text('许下你的第一个心愿吧！', style: DS.bodyMd.copyWith(color: DS.onSurfaceVariant)),
          SizedBox(height: DS.lg),
          ElevatedButton.icon(
            onPressed: () => _showCreateDialog(),
            icon: Icon(Icons.add),
            label: Text('创建第一个心愿'),
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

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:provider/provider.dart';

import 'pages/bill_list/bill_list_page.dart';
import 'pages/home/home_page.dart';
import 'pages/profile/profile_page.dart';
import 'pages/statistics/statistics_page.dart';
import 'pages/wish_jar/wish_jar_page.dart';
import 'providers/app_provider.dart';
import 'providers/theme_provider.dart';
import 'services/auto_record_service.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'theme/app_design_system.dart';
import 'theme/app_theme.dart';
import 'theme/glass_materials.dart';
import 'widgets/glass_top_strip.dart';
import 'widgets/tab_swipe.dart';

// 全局路由观察者（用于页面返回时刷新数据）
final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

// 字号变更通知器
class FontSizeNotifier extends ChangeNotifier {
  static final FontSizeNotifier _instance = FontSizeNotifier._();
  static FontSizeNotifier get instance => _instance;
  FontSizeNotifier._();

  void notifyFontSizeChanged() {
    notifyListeners();
  }
}

Future<void> _checkMonthlySummary() async {
  final now = DateTime.now();
  if (now.day != 1) return; // 只在每月1日触发
  final monthKey = 'monthlySummary_${now.year}_${now.month.toString().padLeft(2, '0')}';
  final sent = await StorageService.instance.getStringAsync(monthKey);
  if (sent == '1') return; // 本月已发送
  StorageService.instance.setString(monthKey, '1');
  await NotificationService.instance.showMonthlySummary();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化数据库
  await DatabaseService.instance.database;

  // 加载本地缓存（如打卡/账本记忆、字号设置）
  await StorageService.instance.load();

  // 初始化主题（从缓存加载用户选择的颜色）
  final themeProvider = ThemeProvider();

  // 初始化通知服务
  await NotificationService.instance.init();

  // 初始化自动记账服务（恢复轮询状态）
  await AutoRecordService.instance.init();

  // 月度财务简报：每月1日自动推送
  await _checkMonthlySummary();

  // 预热液态玻璃 shader（异步 I/O，不阻塞首帧；失败会自动降级雾面路线）
  await LiquidGlassWidgets.initialize(enablePerformanceMonitor: false);

  runApp(
    LiquidGlassWidgets.wrap(
      brightnessResolver: Theme.maybeBrightnessOf,
      adaptiveQuality: true,
      child: BearBillApp(themeProvider: themeProvider),
    ),
  );
}

class BearBillApp extends StatefulWidget {
  final ThemeProvider themeProvider;
  const BearBillApp({super.key, required this.themeProvider});

  @override
  State<BearBillApp> createState() => _BearBillAppState();
}

class _BearBillAppState extends State<BearBillApp> {
  double _textScaleFactor = 1.0;

  @override
  void initState() {
    super.initState();
    _loadFontSize();
    // 监听字号变更通知
    FontSizeNotifier.instance.addListener(_loadFontSize);
    // 监听主题变更，触发重建
    widget.themeProvider.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    FontSizeNotifier.instance.removeListener(_loadFontSize);
    widget.themeProvider.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadFontSize() async {
    final storage = StorageService.instance;
    final fontSize = storage.getString('fontSize') ?? '标准';
    final sizeMap = {
      '小': 0.7,
      '标准': 0.8,
      '大': 0.9,
    };

    if (mounted) {
      setState(() {
        _textScaleFactor = sizeMap[fontSize] ?? 1.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.themeProvider),
        ChangeNotifierProvider(create: (_) => AppProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => MaterialApp(
        title: '🐻 小熊记账本',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.currentTheme,
        builder: (context, child) {
          // 玻璃控件（GlassDialog/GlassTabBar 等）是纯自绘、无 Material 祖先，
          // 会继承 MaterialApp 的 _errorTextStyle 兜底样式（黄色双下划线），
          // 根上清掉 decoration；深层 Material 各自的 DefaultTextStyle 不受影响。
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(_textScaleFactor),
            ),
            child: DefaultTextStyle(
              style: const TextStyle(decoration: TextDecoration.none),
              child: child!,
            ),
          );
        },
        navigatorObservers: [routeObserver], // 注册全局路由观察者
        home: MainTabPage(onFontSizeChanged: _loadFontSize),
      ),
      ),
    );
  }
}

/// 主 Tab 页面
/// 全局 Tab 切换通知器（从子页面切换底部 Tab）
final ValueNotifier<int> tabSwitchNotifier = ValueNotifier<int>(0);

class MainTabPage extends StatefulWidget {
  final VoidCallback? onFontSizeChanged;

  const MainTabPage({super.key, this.onFontSizeChanged});

  @override
  State<MainTabPage> createState() => _MainTabPageState();
}

class _MainTabPageState extends State<MainTabPage> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    tabSwitchNotifier.addListener(_onTabSwitch);
  }

  @override
  void dispose() {
    tabSwitchNotifier.removeListener(_onTabSwitch);
    super.dispose();
  }

  void _onTabSwitch() {
    final index = tabSwitchNotifier.value;
    if (index >= 0 && index < _pages.length) {
      setState(() => _currentIndex = index);
    }
  }

  /// 统一的 Tab 切换入口：点按、滑动都走这里，
  /// 由 tabSwitchNotifier 作为单一真源触发 _onTabSwitch 更新状态。
  void _goToTab(int index) {
    if (index == _currentIndex) return;
    tabSwitchNotifier.value = index;
  }

  final List<Widget> _pages = [
    const HomePage(),
    const BillListPage(),
    const StatisticsPage(),
    const WishJarPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    // 双树分叉：开启液态玻璃走官方骨架（导航层玻璃 + 沉浸式滚动），
    // 关闭时保留原树（贴底满宽白栏 + 自研拖动），老用户体验零变化。
    if (shouldUseLiquidGlass(context)) {
      return _buildGlassTree();
    }
    return _buildLegacyTree();
  }

  /// 开启态：官方 GlassScaffold + GlassTabBar.bottom
  ///
  /// GlassScaffold 自带：内容穿到底栏下的沉浸式滚动、滚动边缘渐隐、
  /// 状态栏图标自适应、安全区处理、bar 隔离。
  /// 官方 GlassTabBar.bottom 原生支持按住拖动切换（jelly 物理 + magic lens）。
  Widget _buildGlassTree() {
    return GlassScaffold(
      bottomBar: GlassTabBar.bottom(
        tabs: const [
          GlassTab(icon: Icon(Icons.home_rounded), label: '首页'),
          GlassTab(icon: Icon(Icons.receipt_long_rounded), label: '账单'),
          GlassTab(icon: Icon(Icons.leaderboard_rounded), label: '统计'),
          GlassTab(icon: Icon(Icons.track_changes_rounded), label: '心愿'),
          GlassTab(icon: Icon(Icons.person_rounded), label: '我的'),
        ],
        selectedIndex: _currentIndex,
        onTabSelected: _goToTab,
        // 官方底栏专用材质（iOS 26 Apple News/Safari 调校），
        // 自调的 surface() 会覆盖它导致药丸过透明、文字发虚
        settings: GlassMaterials.bar(),
        // 官方底栏默认 quality 就是 premium（静态 footer 适用场景）：
        // 真折射 + 色散 + jelly 物理。此前误用 standard（轻量 shader、无折射）
        // 导致"不够液态"。
        quality: GlassQuality.premium,
        showIndicator: true,
        barHeight: 64,
        // 选中图标放大倍率（官方默认 1.15，调大增强"液态"动感）
        magnification: 1.25,
        // 真胶囊哨兵值：jelly 膨胀期间 shader 仍钳制为胶囊，
        // 有限半径（如 32）在膨胀时会显方。参考案例站导航也全用胶囊（999）。
        barBorderRadius: GlassDefaults.capsuleRadius,
      ),
      body: NotificationListener<ScrollNotification>(
        // 统一在 tab 骨架层监听滚动，驱动顶栏玻璃条淡入淡出，
        // 5 个页面无需各自持有 ScrollController。
        onNotification: (n) {
          _updateStripOpacity(n.metrics.pixels);
          return false;
        },
        child: Stack(
          children: [
            IndexedStack(
              index: _currentIndex,
              children: _pages,
            ),
            // 顶栏玻璃悬浮条：滚动淡入、回顶淡出（iOS 26 行为）
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: GlassTopStrip(
                title: _tabTitles[_currentIndex],
                opacity: _stripOpacity,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const List<String> _tabTitles = ['首页', '账单', '统计', '心愿', '我的'];

  double _stripOpacity = 0;

  void _updateStripOpacity(double offset) {
    final next = glassStripOpacityFor(offset);
    if (next != _stripOpacity && mounted) {
      setState(() => _stripOpacity = next);
    }
  }

  /// 关闭态：原有树完全保留（贴底满宽白栏 + 自研按住拖动）
  Widget _buildLegacyTree() {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBottomBar() {
    final items = Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildNavItem(0, Icons.home_rounded, '首页'),
        _buildNavItem(1, Icons.receipt_long_rounded, '账单'),
        _buildNavItem(2, Icons.leaderboard_rounded, '统计'),
        _buildNavItem(3, Icons.track_changes_rounded, '心愿'),
        _buildNavItem(4, Icons.person_rounded, '我的'),
      ],
    );

    // 关闭态底栏：原样保留（贴底满宽 + BackdropFilter 模糊 + 顶部细边框）
    final bar = ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(DS.radiusMd)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: DS.surfaceContainerLowest.withOpacity(0.85),
            border: Border(
              top: BorderSide(color: DS.outlineVariant, width: 0.5),
            ),
          ),
          padding: EdgeInsets.only(bottom: 8, top: 4),
          child: items,
        ),
      ),
    );

    // 按住底栏水平滑动，实时切换到手指经过的 Tab（开启态由官方 tab bar 接管）。
    // 与各 item 的点击手势共存（不移动 = tap；移动超阈值 = 拖动切换）。
    return Builder(
      builder: (barContext) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragUpdate: (d) {
            final box = barContext.findRenderObject();
            if (box is! RenderBox || !box.hasSize) return;
            final idx = barTabFromX(d.localPosition.dx, box.size.width,
                _pages.length);
            if (idx != _currentIndex) _goToTab(idx);
          },
          child: bar,
        );
      },
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => _goToTab(index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: isActive
            ? Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: DS.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: DS.onPrimary, size: 24),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: DS.outline, size: 24),
                  SizedBox(height: 2),
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: DS.fontLabel,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: DS.outline,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

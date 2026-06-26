import 'dart:ui';
import 'package:flutter/material.dart';
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

void _checkMonthlySummary() {
  final now = DateTime.now();
  if (now.day != 1) return; // 只在每月1日触发
  final monthKey = 'monthlySummary_${now.year}_${now.month.toString().padLeft(2, '0')}';
  final sent = StorageService.instance.getString(monthKey);
  if (sent == '1') return; // 本月已发送
  StorageService.instance.setString(monthKey, '1');
  NotificationService.instance.showMonthlySummary();
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
  _checkMonthlySummary();

  runApp(BearBillApp(themeProvider: themeProvider));
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
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(_textScaleFactor),
            ),
            child: child!,
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
    if (index >= 0 && index < 5) {
      setState(() => _currentIndex = index);
    }
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
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: ClipRRect(
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, '首页'),
                _buildNavItem(1, Icons.receipt_long_rounded, '账单'),
                _buildNavItem(2, Icons.leaderboard_rounded, '统计'),
                _buildNavItem(3, Icons.track_changes_rounded, '心愿'),
                _buildNavItem(4, Icons.person_rounded, '我的'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
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

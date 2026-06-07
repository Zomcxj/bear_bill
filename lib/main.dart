import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'pages/bill_list/bill_list_page.dart';
import 'pages/home/home_page.dart';
import 'pages/profile/profile_page.dart';
import 'pages/statistics/statistics_page.dart';
import 'pages/wish_jar/wish_jar_page.dart';
import 'providers/app_provider.dart';
import 'providers/theme_provider.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

// 全局路由观察者（用于页面返回时刷新数据）
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

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
  AppTheme.themeProvider = themeProvider;

  // 初始化通知服务
  await NotificationService.instance.init();

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
      child: MaterialApp(
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
    HomePage(),
    BillListPage(),
    StatisticsPage(),
    WishJarPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          boxShadow: AppShadow.navbar,
          border: Border(
            top: BorderSide(color: AppTheme.border, width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppTheme.primary,
          unselectedItemColor: AppTheme.textHint,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded, size: 22), label: '首页'),
            BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_rounded, size: 22), label: '账单'),
            BottomNavigationBarItem(
                icon: Icon(Icons.pie_chart_rounded, size: 22), label: '统计'),
            BottomNavigationBarItem(
                icon: Icon(Icons.auto_awesome_rounded, size: 22), label: '心愿'),
            BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded, size: 22), label: '我的'),
          ],
        ),
      ),
    );
  }
}

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
import 'services/category_order_service.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'theme/app_design_system.dart';
import 'theme/app_theme.dart';
import 'theme/glass_materials.dart';
import 'widgets/glass_top_strip.dart';
import 'widgets/tab_swipe.dart';

// Global route observer (refreshes data when returning to a page)
final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

// Font size change notifier
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
  if (now.day != 1) return; // Trigger only on the 1st of each month
  final monthKey = 'monthlySummary_${now.year}_${now.month.toString().padLeft(2, '0')}';
  final sent = await StorageService.instance.getStringAsync(monthKey);
  if (sent == '1') return; // Already sent this month
  StorageService.instance.setString(monthKey, '1');
  await NotificationService.instance.showMonthlySummary();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the database
  await DatabaseService.instance.database;

  // Load local cache (e.g. check-in/ledger memory, font size settings)
  await StorageService.instance.load();

  // Category ordering (user-defined expense category order; default = constant table order)
  await CategoryOrderService.instance.load();

  // Initialize theme (load the user-selected color from cache)
  final themeProvider = ThemeProvider();

  // Initialize the notification service
  await NotificationService.instance.init();

  // Initialize the auto-record service (restore polling state)
  await AutoRecordService.instance.init();

  // Monthly finance summary: pushed automatically on the 1st of each month
  await _checkMonthlySummary();

  // Warm up the liquid glass shader (async I/O, does not block the first frame; falls back to frosted mode on failure)
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
    // Listen for font size change notifications
    FontSizeNotifier.instance.addListener(_loadFontSize);
    // Listen for theme changes and trigger a rebuild
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
          // Glass widgets (GlassDialog/GlassTabBar, etc.) are pure custom-painted with no Material ancestor,
          // so they inherit MaterialApp's fallback _errorTextStyle (yellow double underline);
          // clear decoration at the root; nested Material DefaultTextStyles are unaffected.
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
        navigatorObservers: [routeObserver], // Register the global route observer
        home: MainTabPage(onFontSizeChanged: _loadFontSize),
      ),
      ),
    );
  }
}

/// Main tab page
/// Global tab switch notifier (switch the bottom tab from a child page)
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

  /// Unified tab switch entry point: both taps and swipes go through here,
  /// with tabSwitchNotifier as the single source of truth triggering _onTabSwitch to update state.
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
    // Dual-tree split: with liquid glass enabled, use the official skeleton (nav-layer glass + immersive scrolling);
    // when disabled, keep the original tree (flush-bottom full-width white bar + custom drag), with zero change for existing users.
    if (shouldUseLiquidGlass(context)) {
      return _buildGlassTree();
    }
    return _buildLegacyTree();
  }

  /// Enabled state: official GlassScaffold + GlassTabBar.bottom
  ///
  /// GlassScaffold provides: immersive scrolling with content passing under the
  /// bottom bar, scroll-edge fade, automatic status bar icon adaptation, safe area
  /// handling, and bar isolation.
  /// The official GlassTabBar.bottom natively supports press-and-drag switching (jelly physics + magic lens).
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
        // Material dedicated to the official bottom bar (tuned for iOS 26 Apple News/Safari);
        // a custom surface() would override it, making the pill too transparent and the text blurry
        settings: GlassMaterials.navBar(),
        // The official bottom bar's default quality is premium (suited for static footers):
        // true refraction + dispersion + jelly physics. Using standard by mistake
        // (lightweight shader, no refraction) made it "not liquid enough".
        quality: GlassQuality.premium,
        showIndicator: true,
        barHeight: 64,
        // Selected icon magnification (official default 1.15; larger enhances the "liquid" feel)
        magnification: 1.25,
        // True capsule sentinel value: during jelly expansion the shader still clamps to a capsule;
        // a finite radius (e.g. 32) appears square while expanding. The reference site's navigation also uses capsules (999).
        barBorderRadius: GlassDefaults.capsuleRadius,
      ),
      body: NotificationListener<ScrollNotification>(
        // Listen for scroll centrally at the tab skeleton level to drive the top glass strip's
        // fade in/out, so the 5 pages don't each need their own ScrollController.
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
            // Top glass floating strip: fades in on scroll, fades out on return to top (iOS 26 behavior)
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

  /// Disabled state: the original tree is fully preserved (flush-bottom full-width white bar + custom press-and-drag)
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

    // Disabled-state bottom bar: kept as-is (flush-bottom full width + BackdropFilter blur + thin top border)
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

    // Press the bottom bar and slide horizontally to switch to the tab under the finger in real time (the official tab bar takes over in the enabled state).
    // Coexists with each item's tap gesture (no movement = tap; movement past threshold = drag switch).
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
                  color: DS.emphasis,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                    icon,
                    color: DS.isDark ? DS.background : Colors.white,
                    size: 24),
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

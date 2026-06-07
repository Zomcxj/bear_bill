import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../main.dart'; // 导入全局 routeObserver
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../add_record/add_record_page.dart';
import 'widgets/greeting_card.dart';
import 'widgets/quick_entries.dart';
import 'widgets/today_records.dart';
import 'widgets/week_trend_chart.dart';

/// 首页 - 沉浸式 Hero 卡片布局（对齐小程序版）
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with WidgetsBindingObserver, RouteAware {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() {
    _loadData();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadData();
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadData() async {
    // 数据由 Provider 自动管理
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>(); // listen to theme changes
    return Scaffold(
      backgroundColor: AppTheme.bgPage,
      body: SafeArea(
        top: false, // 允许 Hero 卡片延伸到状态栏
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppTheme.primary,
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Hero 问候卡片（沉浸式，延伸到状态栏，含预算进度）
                GreetingCard(),

                SizedBox(height: AppSpacing.md),

                // 2. 本周趋势图
                WeekTrendChart(),

                SizedBox(height: AppSpacing.md),

                // 4. 快捷记账入口
                QuickEntries(),

                SizedBox(height: AppSpacing.md),

                // 5. 今日账单
                TodayRecords(),

                // 底部留白（给 FAB 和导航栏让空间）
                SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
      // 悬浮按钮：记一笔
      floatingActionButton: SizedBox(
        width: 100,
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddRecordPage(),
              ),
            );
          },
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          icon: const Text('✏️', style: TextStyle(fontSize: 20)),
          label: const Text(
            '记一笔',
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
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../main.dart';
import '../../providers/app_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/database_service.dart';
import '../../theme/app_theme.dart';
import 'widgets/achievement_grid.dart';
import 'widgets/settings_list.dart';
import 'widgets/user_profile_card.dart';

/// 个人中心页 - 等级系统、连续打卡、成就徽章、账本管理
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _totalBooks = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final books = await DatabaseService.instance.getAllBooks();

    setState(() {
      _totalBooks = books.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>(); // listen to theme changes
    return Scaffold(
      backgroundColor: AppTheme.bgPage,
      appBar: AppBar(
        title: const Text('我的'),
        backgroundColor: AppTheme.primary,
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        color: AppTheme.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // 1. 用户信息卡片
              Consumer<AppProvider>(
                builder: (context, appProvider, child) {
                  return UserProfileCard(
                    totalRecords: appProvider.user?.totalRecords ?? 0,
                    totalBooks: _totalBooks,
                    onRecordTap: () {
                      tabSwitchNotifier.value = -1;
                      tabSwitchNotifier.value = 1;
                    },
                  );
                },
              ),

              const SizedBox(height: AppSpacing.sm),

              // 2. 成就徽章
              const AchievementGrid(),

              const SizedBox(height: AppSpacing.sm),

              // 3. 设置列表
              SettingsList(onClearData: _clearAllData),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ 警告'),
        content: const Text('确定要清空所有账单数据吗？此操作不可恢复！'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('确认清空',
                style: TextStyle(color: AppTheme.primaryDark)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final appProvider = context.read<AppProvider>();

      // 清空当前账本的记录
      await DatabaseService.instance
          .clearRecordsByBook(appProvider.currentBookId);

      // 重新计算所有账本的总记录数
      final allBooks = await DatabaseService.instance.getAllBooks();
      int totalRecords = 0;
      for (final book in allBooks) {
        final count = await DatabaseService.instance.getTotalRecordsCount(
          bookId: book.id,
        );
        totalRecords += count;
      }

      // 更新用户统计数据
      if (appProvider.user != null) {
        final updatedUser = appProvider.user!.copyWith(
          totalRecords: totalRecords,
        );
        await appProvider.updateUserStats(updatedUser);
      }

      _loadStats();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已清空当前账本的账单数据'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    }
  }
}

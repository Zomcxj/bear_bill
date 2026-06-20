import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../main.dart';
import '../../providers/app_provider.dart';
import '../../services/database_service.dart';
import '../../theme/app_design_system.dart';
import '../../theme/app_theme.dart';
import 'widgets/achievement_grid.dart';
import 'widgets/settings_list.dart';
import 'widgets/user_profile_card.dart';

/// 个人中心页 — Luminous Finance 风格
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
    setState(() => _totalBooks = books.length);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DS.background,
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
        onRefresh: _loadStats,
        color: DS.secondaryContainer,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
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
              SizedBox(height: DS.base),
              const AchievementGrid(),
              SizedBox(height: DS.base),
              SettingsList(onClearData: _clearAllData),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber, size: 20, color: DS.error),
            SizedBox(width: DS.xs),
            Text('警告'),
          ],
        ),
        content: Text('确定要清空所有账单数据吗？此操作不可恢复！'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: DS.error),
            child: Text('确认清空'),
          ),
        ],
      ),
    );
    if (!mounted) return;

    if (confirmed == true) {
      final appProvider = context.read<AppProvider>();

      await DatabaseService.instance
          .clearRecordsByBook(appProvider.currentBookId);

      final allBooks = await DatabaseService.instance.getAllBooks();
      int totalRecords = 0;
      for (final book in allBooks) {
        final count = await DatabaseService.instance.getTotalRecordsCount(
          bookId: book.id,
        );
        totalRecords += count;
      }

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
            backgroundColor: DS.secondary,
          ),
        );
      }
    }
  }
}

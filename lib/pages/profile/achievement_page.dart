import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/achievement_model.dart';
import '../../providers/app_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/storage_service.dart';
import '../../services/database_service.dart';
import '../../theme/app_theme.dart';

class AchievementPage extends StatefulWidget {
  const AchievementPage({super.key});

  @override
  State<AchievementPage> createState() => _AchievementPageState();
}

class _AchievementPageState extends State<AchievementPage> {
  int _completedWishes = 0;
  int _totalImages = 0;
  int _locationCount = 0;
  int _moodCount = 0;
  int _uniqueCategories = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = DatabaseService.instance;
    final wishes = await db.getAllWishes();
    final totalImages = await db.getTotalImagesCount();
    final locationCount = await db.getRecordsWithLocationCount();
    final moodCount = await db.getRecordsWithMoodCount();
    final uniqueCategories = await db.getUniqueCategoriesCount();
    setState(() {
      _completedWishes = wishes.where((w) => w.isCompleted).length;
      _totalImages = totalImages;
      _locationCount = locationCount;
      _moodCount = moodCount;
      _uniqueCategories = uniqueCategories;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        final unlockedIds = appProvider.unlockedAchievements;
        final user = appProvider.user;
        final checkInDays = appProvider.checkInDays;
        final totalRecords = user?.totalRecords ?? 0;

        final budgetStr =
            StorageService.instance.getString('monthlyBudget');
        final hasBudget = budgetStr != null &&
            budgetStr.isNotEmpty &&
            double.tryParse(budgetStr) != null &&
            double.parse(budgetStr) > 0;

        return Scaffold(
          backgroundColor: AppTheme.bgPage,
          appBar: AppBar(
            title: Text(
              '成就徽章  ${unlockedIds.length}/${AchievementDefinitions.all.length}',
            ),
            backgroundColor: AppTheme.bgCard,
            foregroundColor: AppTheme.textPrimary,
            elevation: 0,
          ),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : GridView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: AppSpacing.sm,
                    mainAxisSpacing: AppSpacing.sm,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: AchievementDefinitions.all.length,
                  itemBuilder: (context, index) {
                    final achievement = AchievementDefinitions.all[index];
                    final isUnlocked =
                        unlockedIds.contains(achievement.id);
                    final progress = _calcProgress(
                      achievement: achievement,
                      isUnlocked: isUnlocked,
                      checkInDays: checkInDays,
                      totalRecords: totalRecords,
                      hasBudget: hasBudget,
                      completedWishes: _completedWishes,
                    );

                    return _AchievementCard(
                      achievement: achievement,
                      isUnlocked: isUnlocked,
                      progress: progress,
                    );
                  },
                ),
        );
      },
    );
  }

  double _calcProgress({
    required AchievementModel achievement,
    required bool isUnlocked,
    required int checkInDays,
    required int totalRecords,
    required bool hasBudget,
    required int completedWishes,
  }) {
    if (isUnlocked) return 1.0;

    switch (achievement.id) {
      // 打卡
      case 'checkin_3':
      case 'checkin_7':
      case 'checkin_14':
      case 'checkin_30':
      case 'checkin_60':
      case 'checkin_100':
      case 'checkin_365':
        return (checkInDays / achievement.threshold).clamp(0.0, 1.0);
      // 记账次数
      case 'records_10':
      case 'records_50':
      case 'records_100':
      case 'records_500':
        return (totalRecords / achievement.threshold).clamp(0.0, 1.0);
      // 预算
      case 'budget_1':
        return hasBudget ? 1.0 : 0.0;
      case 'budget_save':
        return 0.0;
      // 心愿
      case 'wish_1':
        return 0.0;
      case 'wish_complete':
        return completedWishes >= 1 ? 1.0 : 0.0;
      case 'wish_5':
        return (completedWishes / 5).clamp(0.0, 1.0);
      // 图片
      case 'images_10':
      case 'images_50':
        return (_totalImages / achievement.threshold).clamp(0.0, 1.0);
      // 位置
      case 'location_10':
      case 'location_50':
        return (_locationCount / achievement.threshold).clamp(0.0, 1.0);
      // 心情
      case 'mood_10':
      case 'mood_50':
        return (_moodCount / achievement.threshold).clamp(0.0, 1.0);
      // 分类
      case 'category_10':
      case 'category_50':
        return (_uniqueCategories / achievement.threshold).clamp(0.0, 1.0);
      default:
        return 0.0;
    }
  }
}

class _AchievementCard extends StatelessWidget {
  final AchievementModel achievement;
  final bool isUnlocked;
  final double progress;

  const _AchievementCard({
    required this.achievement,
    required this.isUnlocked,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).toInt();
    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isUnlocked ? AppTheme.primary : AppTheme.border,
            width: isUnlocked ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isUnlocked
                    ? AppTheme.primaryLight
                    : AppTheme.bgSection,
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(
                  color:
                      isUnlocked ? AppTheme.primary : AppTheme.border,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  achievement.emoji,
                  style: TextStyle(
                    fontSize: 18,
                    color: isUnlocked
                        ? Colors.black
                        : Colors.grey.shade400,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              achievement.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isUnlocked
                    ? AppTheme.textPrimary
                    : AppTheme.textHint,
              ),
            ),
            const SizedBox(height: 2),
            // 进度条
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.full),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: AppTheme.bgSection,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isUnlocked ? AppTheme.success : AppTheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              isUnlocked ? '已完成' : '$percent%',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: isUnlocked
                    ? AppTheme.success
                    : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    final percent = (progress * 100).toInt();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(achievement.emoji,
                style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    achievement.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    isUnlocked ? '✅ 已解锁' : '🔒 未解锁 ($percent%)',
                    style: TextStyle(
                      fontSize: 13,
                      color: isUnlocked
                          ? AppTheme.success
                          : AppTheme.textHint,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '达成条件：',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              achievement.description,
              style: const TextStyle(fontSize: 14),
            ),
            if (!isUnlocked) ...[
              const SizedBox(height: 16),
              const Text(
                '当前进度：',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.full),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: AppTheme.bgSection,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppTheme.primary),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$percent%',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
            if (isUnlocked && achievement.unlockedAt != null) ...[
              const SizedBox(height: 16),
              const Text(
                '解锁时间：',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${achievement.unlockedAt!.year}年${achievement.unlockedAt!.month}月${achievement.unlockedAt!.day}日',
                style: TextStyle(
                    fontSize: 14, color: AppTheme.textSecondary),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }
}

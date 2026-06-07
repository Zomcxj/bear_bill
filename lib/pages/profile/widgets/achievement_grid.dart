import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/achievement_model.dart';
import '../../../providers/app_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../theme/app_theme.dart';
import '../achievement_page.dart';

/// 成就徽章网格
class AchievementGrid extends StatelessWidget {
  const AchievementGrid({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>(); // listen to theme changes
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        final unlockedIds = appProvider.unlockedAchievements;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '🏆 成就徽章',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AchievementPage(),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Text(
                          '${unlockedIds.length}/${AchievementDefinitions.all.length}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: AppTheme.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 64,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: AchievementDefinitions.all.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final achievement = AchievementDefinitions.all[index];
                    final isUnlocked = unlockedIds.contains(achievement.id);

                    return SizedBox(
                      width: 42,
                      child: _AchievementBadge(
                        achievement: achievement,
                        isUnlocked: isUnlocked,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AchievementBadge extends StatelessWidget {
  final AchievementModel achievement;
  final bool isUnlocked;

  const _AchievementBadge({
    required this.achievement,
    required this.isUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showAchievementDetail(context),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isUnlocked ? AppTheme.primaryLight : AppTheme.bgSection,
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(
                color: isUnlocked ? AppTheme.primary : AppTheme.border,
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                achievement.emoji,
                style: TextStyle(
                  fontSize: 14,
                  color: isUnlocked ? AppTheme.textPrimary : Colors.grey.shade400,
                ),
              ),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            achievement.title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 7.5,
              color: isUnlocked ? AppTheme.textPrimary : AppTheme.textHint,
              fontWeight: isUnlocked ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  void _showAchievementDetail(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(achievement.emoji, style: const TextStyle(fontSize: 28)),
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
                    isUnlocked ? '✅ 已解锁' : '🔒 未解锁',
                    style: TextStyle(
                      fontSize: 13,
                      color: isUnlocked ? AppTheme.success : AppTheme.textHint,
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/achievement_model.dart';
import '../../../providers/app_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../theme/app_design_system.dart';
import '../../../theme/app_theme.dart';
import '../achievement_page.dart';

/// 成就徽章网格
class AchievementGrid extends StatelessWidget {
  const AchievementGrid({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>(); // 主题变更时触发重建
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        final unlockedIds = appProvider.unlockedAchievements;

        return Container(
          margin: EdgeInsets.symmetric(horizontal: DS.sm),
          padding: EdgeInsets.all(DS.gutter),
          decoration: DS.glassDecorationLight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.emoji_events, size: 18, color: DS.onSurface),
                      SizedBox(width: 6),
                      Text(
                        '成就徽章',
                        style: DS.labelMd.copyWith(color: DS.onSurface),
                      ),
                    ],
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
                          style: DS.labelSm.copyWith(color: DS.onSurfaceVariant),
                        ),
                        SizedBox(width: 2),
                        Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: DS.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              SizedBox(
                height: 76,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: AchievementDefinitions.all.length,
                  separatorBuilder: (context, index) =>
                      SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final achievement = AchievementDefinitions.all[index];
                    final isUnlocked = unlockedIds.contains(achievement.id);

                    return SizedBox(
                      width: 52,
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
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isUnlocked ? DS.surfaceContainerHigh : DS.surfaceContainerLow,
              borderRadius: BorderRadius.circular(DS.radiusFull),
              border: Border.all(
                color: isUnlocked ? DS.primary : DS.outlineVariant,
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                achievement.emoji,
                style: TextStyle(
                  fontSize: 18,
                  color: isUnlocked ? DS.onSurface : Colors.grey.shade400,
                ),
              ),
            ),
          ),
          SizedBox(height: 2),
          Text(
            achievement.title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              color: isUnlocked ? DS.onSurface : DS.outline,
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
            Text(achievement.emoji, style: TextStyle(fontSize: 28)),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    achievement.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    isUnlocked ? '✅ 已解锁' : '🔒 未解锁',
                    style: TextStyle(
                      fontSize: 13,
                      color: isUnlocked ? AppTheme.success : DS.outline,
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
            Text(
              '达成条件：',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              achievement.description,
              style: TextStyle(fontSize: 14),
            ),
            if (isUnlocked && achievement.unlockedAt != null) ...[
              SizedBox(height: 16),
              Text(
                '解锁时间：',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '${achievement.unlockedAt!.year}年${achievement.unlockedAt!.month}月${achievement.unlockedAt!.day}日',
                style: DS.labelMd.copyWith(color: DS.onSurfaceVariant),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('知道了'),
          ),
        ],
      ),
    );
  }
}

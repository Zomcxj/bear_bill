import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/app_provider.dart';
import '../../../theme/app_theme.dart';
import '../../multi_book/multi_book_page.dart';

/// 用户信息卡片 - 等级、经验、打卡（对齐小程序渐变 Hero 风格）
class UserProfileCard extends StatelessWidget {
  final int totalRecords;
  final int totalBooks;
  final VoidCallback? onRecordTap;

  const UserProfileCard({
    super.key,
    required this.totalRecords,
    required this.totalBooks,
    this.onRecordTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        final user = appProvider.user;
        if (user == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final levelInfo = _getLevelInfo(user.level);
        final nextLevelExp = user.expForNextLevel;

        return Container(
          margin: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: AppShadow.card,
          ),
          child: Stack(
            children: [
              Positioned(
                top: -20,
                right: -10,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.12),
                  ),
                ),
              ),
              Positioned(
                bottom: -25,
                left: -15,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => _pickAvatar(context),
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.4),
                                width: 2,
                              ),
                              image: user.avatar.isNotEmpty
                                  ? DecorationImage(
                                      image: FileImage(File(user.avatar)),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: user.avatar.isNotEmpty
                                ? null
                                : Center(
                                    child: Text(
                                      levelInfo['emoji'],
                                      style: const TextStyle(fontSize: 26),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.nickname,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.heroTextMain,
                                  shadows: [
                                    Shadow(
                                      color: Color(0x26000000),
                                      offset: Offset(0, 1),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.25),
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.full),
                                    ),
                                    child: Text(
                                      'Lv.${user.level} ${levelInfo['name']}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.heroTextMain,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '经验值',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.heroTextSub,
                              ),
                            ),
                            Text(
                              '${user.exp} / $nextLevelExp',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.heroTextMain,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          child: LinearProgressIndicator(
                            value: user.expProgress,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem('📝', '$totalRecords', '记账次数',
                              onTap: onRecordTap),
                          _buildStatItem('🔥', '${appProvider.checkInDays}', '连续打卡',
                              onTap: () => _showCheckInInfo(context, appProvider)),
                          _buildStatItem('📒', '$totalBooks', '账本数',
                              onTap: () => _showBookManagement(context)),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (!appProvider.todayChecked)
                      GestureDetector(
                        onTap: () async {
                          final achievements =
                              await appProvider.recordCheckIn();
                          if (achievements.isNotEmpty && context.mounted) {
                            _showAchievementDialog(context, achievements);
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(AppRadius.full),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.4),
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              '🔥 今日打卡',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.heroTextMain,
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: const Center(
                          child: Text(
                            '✅ 今日已打卡',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.heroTextMain,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String emoji, String value, String label,
      {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.heroTextMain,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.heroTextSub,
            ),
          ),
        ],
      ),
    );
  }

  /// 显示打卡信息
  void _showCheckInInfo(BuildContext context, AppProvider appProvider) {
    final lastCheckIn = appProvider.user?.lastCheckIn ?? '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('🔥 打卡记录'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('连续打卡：${appProvider.checkInDays} 天'),
            const SizedBox(height: 8),
            if (lastCheckIn.isNotEmpty)
              Text('上次打卡：$lastCheckIn')
            else
              const Text('暂无打卡记录'),
            const SizedBox(height: 12),
            const Text(
              '每天记账即自动打卡，断签会重置连续天数。',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  /// 显示账本管理
  void _showBookManagement(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MultiBookPage()),
    );
  }

  Map<String, dynamic> _getLevelInfo(int level) {
    final levels = [
      {'level': 1, 'name': '存钱小熊', 'emoji': '🐻'},
      {'level': 2, 'name': '记账小熊', 'emoji': '📝'},
      {'level': 3, 'name': '省钱达人', 'emoji': '💰'},
      {'level': 4, 'name': '理财小能手', 'emoji': '📊'},
      {'level': 5, 'name': '财务小神', 'emoji': '🏦'},
      {'level': 6, 'name': '记账大师', 'emoji': '👑'},
    ];

    final index = (level - 1).clamp(0, levels.length - 1);
    return levels[index];
  }

  Future<void> _pickAvatar(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: '选择头像图片',
      type: FileType.image,
      allowMultiple: false,
    );

    final path = result?.files.single.path;
    if (path == null || !context.mounted) return;

    await context.read<AppProvider>().updateUserProfile(avatar: path);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('头像已更新'),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  void _showAchievementDialog(
      BuildContext context, List<dynamic> achievements) {
    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          margin: const EdgeInsets.only(top: 60),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: AppShadow.deep,
            border: Border.all(color: AppTheme.border, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                achievements.first.emoji ?? '🏆',
                style: const TextStyle(fontSize: 40),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '成就解锁！',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textHint,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    achievements.first.title ?? '新成就',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      context.read<AppProvider>().clearNewAchievements();
    });
  }
}

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart'
    show GlassButton, LiquidRoundedSuperellipse;
import 'package:provider/provider.dart';

import '../../../providers/app_provider.dart';
import '../../../theme/app_design_system.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/glass_materials.dart';
import '../../../widgets/glass_dialog_shell.dart';
import '../../multi_book/multi_book_page.dart';
import '../../../providers/theme_provider.dart';

/// User info card - level, experience, check-in (Luminous Finance style)
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
    context.watch<ThemeProvider>(); // theme rebuild
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        final user = appProvider.user;
        if (user == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final levelInfo = _getLevelInfo(user.level);
        final nextLevelExp = user.expForNextLevel;

        // Glass mode: the whole user card is shader glass (text uses the dynamic
        // DS.onSurface color, readable in both modes); disabled = the original blue gradient hero (zero drift)
        return GlassSurface(
          borderRadius: DS.radiusLg,
          fallbackDecoration: BoxDecoration(
            gradient: DS.heroGradientBlueCurrent,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(DS.radiusLg),
              bottomRight: Radius.circular(DS.radiusLg),
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            DS.containerMargin,
            MediaQuery.of(context).padding.top + DS.gutter,
            DS.containerMargin,
            DS.base,
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
              Column(
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
                            // No border in glass theme; unchanged when disabled
                            border: shouldUseLiquidGlass(context)
                                ? null
                                : Border.all(
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
                                    style: TextStyle(fontSize: 26),
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(width: DS.base),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.nickname,
                              style: TextStyle(
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
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.25),
                                    borderRadius:
                                        BorderRadius.circular(DS.radiusFull),
                                  ),
                                  child: Text(
                                    'Lv.${user.level} ${levelInfo['name']}',
                                    style: TextStyle(
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
                  SizedBox(height: DS.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '经验值',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.heroTextSub,
                            ),
                          ),
                          Text(
                            '${user.exp} / $nextLevelExp',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.heroTextMain,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(DS.radiusFull),
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
                  SizedBox(height: DS.sm),
                  // Single glass strip: the three stats merged into one bar (glass mode = one glass
                  // strip; disabled = the original fallback fill box, zero drift)
                  GlassSurface(
                    borderRadius: DS.radiusSm,
                    fallbackDecoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(DS.radiusSm),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(Icons.edit_note, '$totalRecords',
                            '记账次数', onTap: onRecordTap),
                        _buildStatItem(Icons.local_fire_department,
                            '${appProvider.checkInDays}', '连续打卡',
                            onTap: () =>
                                _showCheckInInfo(context, appProvider)),
                        _buildStatItem(Icons.book, '$totalBooks', '账本数',
                            onTap: () => _showBookManagement(context)),
                      ],
                    ),
                  ),
                  SizedBox(height: DS.base),
                  if (!appProvider.todayChecked)
                    shouldUseLiquidGlass(context)
                        ? GlassButton.custom(
                            // Glass mode: default filled = glass shell + press physics + glow
                            // (same as the budget dialog button; glass button on a glass hero verified visually)
                            onTap: () async {
                              final achievements = await appProvider.recordCheckIn();
                              if (achievements.isNotEmpty && context.mounted) {
                                _showAchievementDialog(context, achievements);
                              }
                            },
                            interactionScale: 1.03,
                            stretch: 0.1,
                            shape: const LiquidRoundedSuperellipse(borderRadius: 999),
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.local_fire_department,
                                      size: 18, color: AppTheme.heroTextMain),
                                  SizedBox(width: 6),
                                  Text(
                                    '今日打卡',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.heroTextMain,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : GestureDetector(
                            onTap: () async {
                              final achievements = await appProvider.recordCheckIn();
                              if (achievements.isNotEmpty && context.mounted) {
                                _showAchievementDialog(context, achievements);
                              }
                            },
                            child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(DS.radiusFull),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.4),
                              ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.local_fire_department,
                                size: 18, color: AppTheme.heroTextMain),
                            SizedBox(width: 6),
                            Text(
                              '今日打卡',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.heroTextMain,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    shouldUseLiquidGlass(context)
                        ? GlassButton.custom(
                            onTap: () {},
                            interactionScale: 1.0,
                            stretch: 0.0,
                            shape: const LiquidRoundedSuperellipse(
                                borderRadius: 999),
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle,
                                      size: 18, color: AppTheme.heroTextMain),
                                ],
                              ),
                            ),
                          )
                        : Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(DS.radiusFull),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle,
                              size: 18, color: AppTheme.heroTextMain),
                          SizedBox(width: 6),
                          Text(
                            '今日已打卡',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.heroTextMain,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label,
      {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppTheme.heroTextMain),
          SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.heroTextMain,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.heroTextSub,
            ),
          ),
        ],
      ),
    );
  }

  /// Show check-in info
  void _showCheckInInfo(BuildContext context, AppProvider appProvider) {
    final lastCheckIn = appProvider.user?.lastCheckIn ?? '';
    showGlassDialog(
      context: context,
      title: '打卡记录',
      maxWidth: 320,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('连续打卡：${appProvider.checkInDays} 天',
              style: DS.bodyMd.copyWith(color: DS.onSurface)),
          const SizedBox(height: 8),
          Text(
            lastCheckIn.isNotEmpty ? '上次打卡：$lastCheckIn' : '暂无打卡记录',
            style: DS.bodyMd.copyWith(color: DS.onSurface),
          ),
          const SizedBox(height: 12),
          Text(
            '每天记账即自动打卡，断签会重置连续天数。',
            style: DS.labelSm.copyWith(color: DS.onSurfaceVariant),
          ),
        ],
      ),
      buildActions: (ctx) => [
        GlassDialogButton(
          label: '知道了',
          isPrimary: true,
          onPressed: () => Navigator.pop(ctx),
        ),
      ],
    );
  }

  /// Show book management
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
    final file = await FilePicker.pickFile(
      dialogTitle: '选择头像图片',
      type: FileType.image,
    );

    final path = file?.path;
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
    final glass = shouldUseLiquidGlass(context);
    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          margin: EdgeInsets.only(top: 60),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: glass
                ? (DS.isDark
                    ? Colors.white.withOpacity(0.16)
                    : Colors.white.withOpacity(0.80))
                : DS.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(DS.radiusMd),
            boxShadow: DS.shadowMd,
            // No border in glass theme; unchanged when disabled
            border: glass
                ? null
                : Border.all(
                    color: DS.outlineVariant,
                    width: 1.5,
                  ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                achievements.first.emoji ?? '🏆',
                style: TextStyle(fontSize: 40),
              ),
              SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '成就解锁！',
                    style: DS.labelSm.copyWith(color: DS.onSurfaceVariant),
                  ),
                  SizedBox(height: 2),
                  Text(
                    achievements.first.title ?? '新成就',
                    style: DS.headlineSm.copyWith(
                      color: DS.onSurface,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      if (!context.mounted) return;
      context.read<AppProvider>().clearNewAchievements();
    });
  }
}

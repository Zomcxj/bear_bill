import 'package:flutter/material.dart';

import '../../../models/models.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/utils.dart';

/// 心愿罐卡片
class WishJarCard extends StatelessWidget {
  final WishModel wish;
  final VoidCallback onAddMoney;
  final VoidCallback onDelete;

  const WishJarCard({
    super.key,
    required this.wish,
    required this.onAddMoney,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final progress = wish.progress * 100;
    final themeColor = _getThemeColor(wish.id);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: themeColor.withOpacity(0.18),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: themeColor.withOpacity(0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头部：图标、名称、删除按钮
          Row(
            children: [
              // 心愿图标
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.28),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Center(
                  child: Text(
                    _getWishEmoji(wish.title),
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),

              const SizedBox(width: AppSpacing.sm),

              // 心愿信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wish.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    // 截止日期
                    if (wish.deadline != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 12, color: AppTheme.textHint),
                          const SizedBox(width: 4),
                          Text(
                            '${wish.deadline!.year}-${wish.deadline!.month.toString().padLeft(2, '0')}-${wish.deadline!.day.toString().padLeft(2, '0')} 截止',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (wish.description?.isNotEmpty == true) ...[
                      const SizedBox(height: 2),
                      Text(
                        wish.description!,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // 删除按钮
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Icon(Icons.close,
                      size: 14, color: AppTheme.textHint),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // 进度信息
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '¥${FormatUtils.formatAmount(wish.currentAmount)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: themeColor,
                      ),
                    ),
                    TextSpan(
                      text:
                          ' / ¥${FormatUtils.formatAmount(wish.targetAmount)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${progress.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: themeColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // 进度条
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: LinearProgressIndicator(
              value: wish.progress,
              backgroundColor: AppTheme.bgCard,
              valueColor: AlwaysStoppedAnimation<Color>(themeColor),
              minHeight: 8,
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // 存钱按钮或完成标签
          if (wish.isCompleted)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.success,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: const Center(
                child: Text(
                  '🎉 已实现',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          else
            GestureDetector(
              onTap: onAddMoney,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: themeColor,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: const Center(
                  child: Text(
                    '💰 存入',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getThemeColor(String id) {
    // 6 个固定颜色，不随主题变化
    const colors = [
      Color(0xFFFF8FAB), // 蜜桃粉
      Color(0xFF74C0FC), // 天空蓝
      Color(0xFF6BCB77), // 薄荷绿
      Color(0xFFFFA94D), // 活力橙
      Color(0xFF9B59B6), // 紫罗兰
      Color(0xFFFF6B6B), // 珊瑚红
    ];
    return colors[id.hashCode.abs() % colors.length];
  }

  String _getWishEmoji(String title) {
    if (title.contains('衣服') || title.contains('鞋')) return '👗';
    if (title.contains('旅行') || title.contains('旅游')) return '✈️';
    if (title.contains('手机') || title.contains('数码')) return '📱';
    if (title.contains('学习') || title.contains('课程')) return '📚';
    if (title.contains('美食') || title.contains('吃')) return '🍱';
    return '✨';
  }
}

import 'package:flutter/material.dart';

import '../../../models/models.dart';
import '../../../theme/app_design_system.dart';
import '../../../utils/utils.dart';
import '../../../widgets/glass_card.dart';

/// 心愿罐卡片 — 玻璃风格 + Material Icons
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
    final icon = _getWishIcon(wish.title);

    return GlassCard(
      margin: EdgeInsets.only(bottom: DS.base),
      padding: EdgeInsets.all(DS.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: themeColor.withOpacity(0.3)),
                ),
                child: Icon(icon, size: 22, color: themeColor),
              ),
              SizedBox(width: DS.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wish.title,
                      style: DS.bodyMd.copyWith(
                        fontWeight: FontWeight.w600,
                        color: DS.onSurface,
                      ),
                    ),
                    if (wish.deadline != null) ...[
                      SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.event, size: 12, color: DS.outline),
                          SizedBox(width: 4),
                          Text(
                            '${wish.deadline!.year}-${wish.deadline!.month.toString().padLeft(2, '0')}-${wish.deadline!.day.toString().padLeft(2, '0')} 截止',
                            style: DS.labelSm.copyWith(color: DS.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ],
                    if (wish.description?.isNotEmpty == true) ...[
                      SizedBox(height: 2),
                      Text(
                        wish.description!,
                        style: DS.labelSm.copyWith(color: DS.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: DS.surfaceContainerLow,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close, size: 14, color: DS.outline),
                ),
              ),
            ],
          ),

          SizedBox(height: DS.sm),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '¥${FormatUtils.formatAmount(wish.currentAmount)}',
                      style: TextStyle(
                        fontFamily: DS.fontDisplay,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: themeColor,
                      ),
                    ),
                    TextSpan(
                      text: ' / ¥${FormatUtils.formatAmount(wish.targetAmount)}',
                      style: TextStyle(
                        fontFamily: DS.fontLabel,
                        fontSize: 13,
                        color: DS.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${progress.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontFamily: DS.fontLabel,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: themeColor,
                ),
              ),
            ],
          ),

          SizedBox(height: DS.sm),

          ClipRRect(
            borderRadius: BorderRadius.circular(DS.radiusFull),
            child: LinearProgressIndicator(
              value: wish.progress,
              backgroundColor: DS.surfaceContainerHigh,
              valueColor: AlwaysStoppedAnimation<Color>(themeColor),
              minHeight: 8,
            ),
          ),

          SizedBox(height: DS.sm),

          if (wish.isCompleted)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: DS.sm),
              decoration: BoxDecoration(
                color: DS.secondary,
                borderRadius: BorderRadius.circular(DS.radiusFull),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 16, color: DS.onPrimary),
                  SizedBox(width: DS.xs),
                  Text('已实现', style: DS.labelMd),
                ],
              ),
            )
          else
            GestureDetector(
              onTap: onAddMoney,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: DS.sm),
                decoration: BoxDecoration(
                  color: DS.primary,
                  borderRadius: BorderRadius.circular(DS.radiusFull),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.savings, size: 16, color: DS.onPrimary),
                    SizedBox(width: DS.xs),
                    Text(
                      '存入',
                      style: TextStyle(
                        fontFamily: DS.fontLabel,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: DS.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getThemeColor(String id) {
    const colors = [
      Color(0xFF40C2FD), // 天蓝
      Color(0xFFD3579A), // 粉色
      Color(0xFF00668A), // 深蓝
      Color(0xFFFFA726), // 橙色
      Color(0xFF7E57C2), // 紫色
      Color(0xFF66BB6A), // 绿色
    ];
    return colors[id.hashCode.abs() % colors.length];
  }

  IconData _getWishIcon(String title) {
    if (title.contains('衣服') || title.contains('鞋')) return Icons.checkroom;
    if (title.contains('旅行') || title.contains('旅游')) return Icons.flight_takeoff;
    if (title.contains('手机') || title.contains('数码')) return Icons.devices;
    if (title.contains('学习') || title.contains('课程')) return Icons.school;
    if (title.contains('美食') || title.contains('吃')) return Icons.restaurant;
    if (title.contains('车')) return Icons.directions_car;
    if (title.contains('房') || title.contains('家')) return Icons.home;
    return Icons.auto_awesome;
  }
}

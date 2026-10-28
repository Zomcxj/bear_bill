import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart'
    show GlassButton, GlassButtonStyle, LiquidRoundedSuperellipse;

import '../../../models/models.dart';
import '../../../theme/app_design_system.dart';
import '../../../theme/glass_materials.dart';
import '../../../utils/utils.dart';
import '../../../widgets/glass_card.dart';
import '../../../providers/theme_provider.dart';
import 'package:provider/provider.dart';

/// Wish jar card — glass style + Material Icons
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
    context.watch<ThemeProvider>(); // theme rebuild
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
                  // No border in the glass theme; unchanged when disabled
                  border: shouldUseLiquidGlass(context)
                      ? null
                      : Border.all(color: themeColor.withOpacity(0.3)),
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
            // Press physics = official GlassButton transparent style (spring
            // scale + drag follow + touch highlight), with no glass shell
            // painted — the card itself is already glass and glass is never
            // nested in glass; the key face still uses the same glass tint
            // layer as the Done key on the record keypad
            GlassButton.custom(
              style: GlassButtonStyle.transparent,
              onTap: onAddMoney,
              interactionScale: 1.05,
              stretch: 0.25,
              shape: const LiquidRoundedSuperellipse(borderRadius: 999),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: DS.sm),
                // Glass mode: same glass sheet style as the Done key on the
                // record keypad (highlight gradient + dark/light border + soft
                // shadow), with no refraction layer — the card itself is
                // already glass and glass is never nested in glass; when
                // disabled, keep the solid accent pill
                decoration: BoxDecoration(
                  gradient: shouldUseLiquidGlass(context)
                      ? LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: DS.isDark
                              ? [
                                  Colors.white.withOpacity(0.36),
                                  Colors.white.withOpacity(0.12),
                                ]
                              : [
                                  Colors.white.withOpacity(0.69),
                                  Colors.white.withOpacity(0.45),
                                ],
                        )
                      : null,
                  color: !shouldUseLiquidGlass(context) ? DS.emphasis : null,
                  borderRadius: BorderRadius.circular(DS.radiusFull),
                  border: shouldUseLiquidGlass(context)
                      ? Border.all(
                          color: DS.isDark
                              ? Colors.white.withOpacity(0.16)
                              : Colors.black.withOpacity(0.10),
                        )
                      : null,
                  boxShadow: shouldUseLiquidGlass(context)
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(
                              DS.isDark ? 0.20 : 0.06,
                            ),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.savings,
                      size: 16,
                      color: shouldUseLiquidGlass(context)
                          ? DS.onSurface
                          : (DS.isDark ? DS.background : Colors.white),
                    ),
                    SizedBox(width: DS.xs),
                    Text(
                      '存入',
                      style: TextStyle(
                        fontFamily: DS.fontLabel,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: shouldUseLiquidGlass(context)
                            ? DS.onSurface
                            : (DS.isDark ? DS.background : Colors.white),
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
      Color(0xFF40C2FD), // sky blue
      Color(0xFFD3579A), // pink
      Color(0xFF00668A), // deep blue
      Color(0xFFFFA726), // orange
      Color(0xFF7E57C2), // purple
      Color(0xFF66BB6A), // green
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

import 'package:flutter/material.dart';
import '../theme/app_design_system.dart';
import '../theme/glass_materials.dart';

/// 通用卡片容器 - 毛玻璃风格
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? color;
  final bool showBorder;
  final bool showShadow;
  final VoidCallback? onTap;

  AppCard({
    super.key,
    required this.child,
    this.margin,
    EdgeInsetsGeometry? padding,
    this.borderRadius = DS.radiusMd,
    this.color,
    this.showBorder = true,
    this.showShadow = true,
    this.onTap,
  }) : padding = padding ?? const EdgeInsets.all(16);

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? DS.heroCardBg,
        borderRadius: BorderRadius.circular(borderRadius),
        // 共享卡片：玻璃主题无边框；关闭态原样（零漂移）
        border: showBorder
            ? (shouldUseLiquidGlass(context)
                ? null
                : Border.all(color: DS.heroCardBorder))
            : null,
        boxShadow: showShadow ? DS.shadowSm : null,
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: card);
    }
    return card;
  }
}

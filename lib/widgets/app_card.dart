import 'package:flutter/material.dart';
import '../theme/app_design_system.dart';

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
        color: color ?? Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(borderRadius),
        border: showBorder
            ? Border.all(color: Colors.black.withOpacity(0.08))
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

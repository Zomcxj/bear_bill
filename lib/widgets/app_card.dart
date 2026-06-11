import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 通用卡片容器 - 统一圆角、边框、阴影样式
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? color;
  final bool showBorder;
  final bool showShadow;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.margin,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.borderRadius = AppRadius.lg,
    this.color,
    this.showBorder = true,
    this.showShadow = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppTheme.bgCard,
        borderRadius: BorderRadius.circular(borderRadius),
        border: showBorder ? Border.all(color: AppTheme.border, width: 1) : null,
        boxShadow: showShadow ? AppShadow.card : null,
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: card);
    }
    return card;
  }
}

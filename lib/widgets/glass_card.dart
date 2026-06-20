import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_design_system.dart';

/// 毛玻璃卡片组件
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final double opacity;
  final VoidCallback? onTap;

  GlassCard({
    super.key,
    required this.child,
    this.margin,
    EdgeInsetsGeometry? padding,
    this.borderRadius = DS.radiusMd,
    this.opacity = 0.7,
    this.onTap,
  }) : padding = padding ?? const EdgeInsets.all(16);

  @override
  Widget build(BuildContext context) {
    final card = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          margin: margin,
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(opacity),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: Colors.black.withOpacity(0.08)),
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: card);
    }
    return card;
  }
}

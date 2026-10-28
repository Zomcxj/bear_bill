import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart'
    show GlassContainer, GlassQuality;

import '../theme/app_design_system.dart';
import '../theme/glass_materials.dart';

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
    final Widget card;
    if (shouldUseLiquidGlass(context)) {
      // 玻璃态：真实液态玻璃（与底栏/弹窗同源材质）
      final glassCard = GlassContainer(
        shape: GlassMaterials.shape(borderRadius),
        // 卡片材质与底栏/日期条统一（bar），保持全 App 玻璃观感一致
        settings: GlassMaterials.bar(),
        quality: GlassQuality.standard,
        // 页面树里没有父玻璃图层，自建图层
        useOwnLayer: true,
        padding: padding,
        child: child,
      );
      if (!GlassMaterials.hasOuterFrame) {
        // 轻薄档：与改造前逐像素一致
        card = Padding(
          padding: margin ?? EdgeInsets.zero,
          child: glassCard,
        );
      } else {
        // 厚/实心档：外挂 1px 描边 + 外层阴影
        card = Padding(
          padding: margin ?? EdgeInsets.zero,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: GlassMaterials.outerBorderColor),
              boxShadow: GlassMaterials.outerShadows,
            ),
            child: glassCard,
          ),
        );
      }
    } else {
      // 关闭态：原毛玻璃卡片（零漂移）
      card = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            margin: margin,
            padding: padding,
            decoration: BoxDecoration(
              color: DS.isDark
                  ? Colors.white.withOpacity((opacity * 0.12).clamp(0.0, 1.0))
                  : Colors.white.withOpacity(opacity),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: DS.heroCardBorder),
            ),
            child: child,
          ),
        ),
      );
    }

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: card);
    }
    return card;
  }
}

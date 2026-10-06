import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart'
    show GlassContainer, GlassQuality, LiquidRoundedSuperellipse;

import '../theme/app_design_system.dart';
import '../theme/glass_materials.dart';

/// 顶部玻璃悬浮条：滚动时淡入、回到顶部淡出（iOS 26 行为）
///
/// 现有页面头部（问候卡/月份选择等）完全不动，本组件只叠在上层，
/// 用于在滚动时给出"内容已离开顶部"的玻璃状态条。
///
/// 纯展示组件：[opacity] 由外部驱动（见 [glassStripOpacityFor]），
/// 滚动监听放在 [MainTabPage] 层，避免给 5 个页面各塞一个 ScrollController。
class GlassTopStrip extends StatelessWidget {
  const GlassTopStrip({
    super.key,
    required this.title,
    required this.opacity,
  });

  final String title;

  /// 0 = 完全隐藏（在顶部），1 = 完全显示（已滚动）
  final double opacity;

  @override
  Widget build(BuildContext context) {
    if (!shouldUseLiquidGlass(context)) return const SizedBox.shrink();

    return IgnorePointer(
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: GlassContainer(
          margin: EdgeInsets.only(
            top: MediaQuery.paddingOf(context).top + DS.xs,
            left: DS.sm,
            right: DS.sm,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: DS.base,
            vertical: DS.sm,
          ),
          shape: const LiquidRoundedSuperellipse(borderRadius: DS.radiusFull),
          settings: GlassMaterials.bar(),
          quality: GlassQuality.premium,
          child: Row(
            children: [
              Text(
                title,
                style: DS.headlineSm.copyWith(color: DS.onSurface),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 由滚动偏移量换算玻璃条的显示不透明度（纯函数，便于单测）
double glassStripOpacityFor(double scrollOffset, {double fadeDistance = 60}) {
  if (scrollOffset <= 0) return 0;
  return (scrollOffset / fadeDistance).clamp(0.0, 1.0);
}

import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart'
    show GlassContainer, GlassQuality, LiquidRoundedSuperellipse;

import '../theme/app_design_system.dart';
import '../theme/glass_materials.dart';

/// Top glass floating strip: fades in on scroll, fades out back at the top (iOS 26 behavior)
///
/// Existing page headers (greeting card/month selector, etc.) stay untouched; this component only overlays them
/// to show a glass status bar that signals "content has left the top" while scrolling.
///
/// Presentational only: [opacity] is driven externally (see [glassStripOpacityFor]),
/// and the scroll listener lives in [MainTabPage], so the 5 pages do not each need a ScrollController.
class GlassTopStrip extends StatelessWidget {
  const GlassTopStrip({
    super.key,
    required this.title,
    required this.opacity,
  });

  final String title;

  /// 0 = fully hidden (at the top), 1 = fully visible (scrolled)
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
          settings: GlassMaterials.navBar(),
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

/// Map a scroll offset to the strip's opacity (pure function, easy to unit test)
double glassStripOpacityFor(double scrollOffset, {double fadeDistance = 60}) {
  if (scrollOffset <= 0) return 0;
  return (scrollOffset / fadeDistance).clamp(0.0, 1.0);
}

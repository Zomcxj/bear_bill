import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart'
    show GlassContainer, GlassQuality;

import '../theme/app_design_system.dart';
import '../theme/glass_materials.dart';

/// Frosted glass card widget
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
      // Glass mode: real liquid glass (same source material as the bottom bar/dialogs)
      final glassCard = GlassContainer(
        shape: GlassMaterials.shape(borderRadius),
        // Card material matches the bottom bar/date strip (bar), keeping the app-wide glass look consistent
        settings: GlassMaterials.bar(),
        quality: GlassQuality.standard,
        // There is no parent glass layer in the page tree, so create our own layer
        useOwnLayer: true,
        padding: padding,
        child: child,
      );
      if (!GlassMaterials.hasOuterFrame) {
        // Thin style: pixel-identical to before the rework
        card = Padding(
          padding: margin ?? EdgeInsets.zero,
          child: glassCard,
        );
      } else {
        // Thick/solid style: external 1px border + outer shadow
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
      // Off: the original frosted glass card (zero drift)
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

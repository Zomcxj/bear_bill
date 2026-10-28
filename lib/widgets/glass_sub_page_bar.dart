import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart'
    show GlassContainer, GlassQuality, LiquidRoundedSuperellipse;

import '../theme/app_design_system.dart';
import '../theme/glass_materials.dart';

/// Glass top bar for sub pages (navigation layer)
///
/// Official design philosophy: glass is only used for navigation/control
/// layers, and the top bar belongs to the navigation layer. When glass is
/// enabled, render the back button + title + actions with real glass
/// material; when disabled, fall back to the standard [AppBar] with zero
/// visual drift.
///
/// Uses [standard] rather than [GlassQuality.premium]: the top bar floats
/// above scrolling content, so — as with the FAB — premium's texture capture
/// is unavailable in this context.
class GlassSubPageBar extends StatelessWidget implements PreferredSizeWidget {
  const GlassSubPageBar({
    super.key,
    required this.title,
    this.actions,
    this.fallbackBackground,
    this.fallbackForeground,
    this.leading,
  });

  final String title;
  final List<Widget>? actions;

  /// AppBar background color when disabled (null → follow the theme, which
  /// fixes the constant-black issue in dark mode)
  final Color? fallbackBackground;

  /// AppBar foreground color when disabled (null → follow the theme)
  final Color? fallbackForeground;

  /// Custom back area (null → default back button)
  final Widget? leading;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    if (!shouldUseLiquidGlass(context)) {
      return AppBar(
        title: Text(title),
        actions: actions,
        leading: leading,
        backgroundColor: fallbackBackground,
        foregroundColor: fallbackForeground,
      );
    }

    final topInset = MediaQuery.paddingOf(context).top;
    return SizedBox(
      height: kToolbarHeight + topInset,
      child: Padding(
        padding: EdgeInsets.only(
          top: topInset + DS.xs,
          left: DS.sm,
          right: DS.sm,
        ),
        child: GlassContainer(
          shape: const LiquidRoundedSuperellipse(borderRadius: DS.radiusFull),
          settings: GlassMaterials.navBar(),
          quality: GlassQuality.standard,
          padding: const EdgeInsets.symmetric(horizontal: DS.xs),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Truly centered title: it does not shift with the width of the
              // buttons on either side
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 56),
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: DS.headlineSm.copyWith(
                    fontSize: 18,
                    color: DS.onSurface,
                  ),
                ),
              ),
              Row(
                children: [
                  leading ??
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios_new,
                          size: 18,
                          color: DS.onSurface,
                        ),
                        onPressed: () => Navigator.maybePop(context),
                      ),
                  const Spacer(),
                  ...?actions,
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

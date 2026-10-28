import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'app_design_system.dart';

/// Liquid glass material parameters (values "hard-coded" per the
/// liquid-glass-flutter prompt document)
///
/// Mapping to the document's clauses:
/// - background blur blur(20px)      -> [blur] = 20
/// - saturate(180%)           -> [saturation] = 1.8
/// - brightness(1.05)         -> [whitenStrength] = 0.05 (the package has no
///                               standalone brightness parameter, so the official
///                               "blend toward white" knob approximates the lift;
///                               applies uniformly across all tiers)
/// - base tint light rgba(255,255,255,0.12) / dark rgba(0,0,0,0.15) -> [tintLight] / [tintDark]
/// - top 1px highlight rim    -> [rimLight] + [lightAngle] (light comes from above)
/// - bottom inner shadow      -> [shadow] (elevation + contact layers)
/// - edge refraction 2~3px    -> [thickness] = 24 + [refractiveIndex] = 1.2
/// - dispersion via RGB channel offset -> [chromaticAberration] = 0.01
/// - 3% noise overlay to remove banding -> **the package exposes no noise/dither
///                               parameter**, so this item is not implemented;
///                               banding removal relies on blur/frost itself, and
///                               any banding on real devices needs another fix
///
/// Refraction and dispersion belong to the Premium (Shader) path and only work
/// on Impeller; on Skia/Web/test environments the code automatically falls back
/// to the frosted BackdropFilter path, and the remaining parameters still apply.
/// Three glass style tiers: classic solid / thin glass / dark solid
///
/// - [classic]: glass disabled, each page uses its off state (zero drift)
/// - [thin]: the existing thin glass (bar() matches the pre-refactor values)
/// - [solid]: dark solid (near-black solid card + 1px border + bright pills)
enum AppGlassStyle { classic, thin, solid }

abstract final class GlassMaterials {
  /// Shared material base values the document requires to be "hard-coded, no improvisation"
  static const double blur = 20;
  static const double saturation = 1.8;
  static const double brightness = 1.05;
  static const double edgeRefractionPx = 24;
  static const double refractiveIndex = 1.2;
  static const double chromaticAberration = 0.01;
  static const double noisePercent = 3; // Not implemented, see the class doc comment

  /// Top highlight rim strength (light mode)
  static const double rimLight = 0.35;

  /// Light source from above (-pi/2): puts the highlight on the top edge
  static const double lightAngleTop = -1.5707963267948966;

  static const Color tintLight = Color(0x1FFFFFFF); // rgba(255,255,255,0.12)
  static const Color tintDark = Color(0x26000000); // rgba(0,0,0,0.15)

  /// Current glass style (three tiers), controlled by the settings page
  static AppGlassStyle _style = AppGlassStyle.classic;
  static AppGlassStyle get style => _style;
  static void setStyle(AppGlassStyle value) => _style = value;

  /// Whether the "dark solid" tier is active (near-black solid card + thin border + bright pills)
  static bool get isSolid => _style == AppGlassStyle.solid;

  /// Whether an outer 1px border + outer shadow is needed (dark solid tier only)
  static bool get hasOuterFrame => isSolid;

  /// Outer border color
  static Color get outerBorderColor => solidBorderColor;

  /// Outer shadows
  static List<BoxShadow> get outerShadows => solidShadows;

  // ── "Dark solid" tier ───────────────────────────────────
  /// Solid card surface: near-black (dark #161A23) / near-white (light)
  static Color get solidCardColor =>
      DS.isDark ? const Color(0xFF161A23) : const Color(0xFFFFFFFF);

  /// Solid card 1px hairline border (8% white in dark / 8% black in light)
  static Color get solidBorderColor =>
      DS.isDark ? const Color(0x14FFFFFF) : const Color(0x14000000);

  /// Outer shadow of the solid tier
  static List<BoxShadow> get solidShadows => [
        BoxShadow(
          color: Colors.black.withOpacity(DS.isDark ? 0.35 : 0.08),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ];

  /// Accent blue (selected pill / indicator)
  static const Color solidAccent = Color(0xFF2D7EF6);

  /// Text/icon color on pills
  static const Color solidOnAccent = Color(0xFFFFFFFF);

  /// Solid tier track (segmented control container background, one step darker than the card)
  static Color get solidTrackColor =>
      DS.isDark ? const Color(0xFF0B0D12) : const Color(0xFFEDEFF2);

  /// Glass floating action button border: in light mode the glass blends into the
  /// light background, so a hairline border + shadow is what lifts it
  static Color get fabBorderColor =>
      DS.isDark ? const Color(0x1FFFFFFF) : const Color(0x1A000000);

  /// Glass floating action button shadow (heavier in light mode to separate it from the background)
  static List<BoxShadow> get fabShadows => [
        BoxShadow(
          color: Colors.black.withOpacity(DS.isDark ? 0.30 : 0.14),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  /// Whether the glass layer is enabled (kept for legacy call sites): classic means "glass off"
  static bool get enabled => _style != AppGlassStyle.classic;
  static void setEnabled(bool value) => _style =
      value ? AppGlassStyle.thin : AppGlassStyle.classic;

  /// Whether the runtime rendering backend supports shader refraction (false on
  /// Skia/test environments, which fall back to the frosted path)
  static bool get supportsRefraction =>
      ImageFilter.isShaderFilterSupported;

  static Color get tint => DS.isDark ? tintDark : tintLight;

  /// Primary glass material: cards, panels, bottom bars
  static LiquidGlassSettings surface() {
    final brightnessLift = (brightness - 1.0).clamp(0.0, 1.0);
    return LiquidGlassSettings(
      glassColor: tint,
      blur: blur,
      saturation: saturation,
      thickness: edgeRefractionPx,
      refractiveIndex: refractiveIndex,
      chromaticAberration: chromaticAberration,
      lightAngle: lightAngleTop,
      rimLight: rimLight,
      whitenStrength: brightnessLift,
      shadowElevation: 1.0,
    );
  }

  /// Secondary glass: list items, small widgets (lighter blur to avoid large blurry areas)
  static LiquidGlassSettings subtle() {
    final brightnessLift = (brightness - 1.0).clamp(0.0, 1.0);
    return LiquidGlassSettings(
      glassColor: tint,
      blur: blur * 0.6,
      saturation: saturation,
      thickness: edgeRefractionPx * 0.6,
      refractiveIndex: refractiveIndex,
      chromaticAberration: chromaticAberration,
      lightAngle: lightAngleTop,
      rimLight: rimLight * 0.8,
      whitenStrength: brightnessLift,
      shadowElevation: 0.5,
    );
  }

  /// Material for bottom/top bars: the official [kBottomBarGlassDefaults] iOS 26 tuning
  ///
  /// The official bottom bar defaults (thickness 30 / refractive index 1.59 /
  /// 135° light source / 24% white base) are measured values from the Apple News /
  /// Safari bottom bar and are "thicker" than [surface]. Overriding them with
  /// [surface] previously made pills too transparent and text look fuzzy.
  /// Only the top highlight rim ([rimLight]) required by the project design spec
  /// is kept on top.
  static LiquidGlassSettings bar() {
    // "Dark solid" tier: fully opaque fill + zero blur/highlight — a solid-card look
    // (glassColor is fully opaque, so the shader outputs exactly that color = pure solid)
    if (isSolid) {
      return LiquidGlassSettings(
        glassColor: solidCardColor,
        blur: 0,
        saturation: 1,
        thickness: 10,
        refractiveIndex: 1,
        chromaticAberration: 0,
        lightAngle: lightAngleTop,
        lightIntensity: 0,
        ambientStrength: 0,
        rimLight: 0,
        whitenStrength: 0,
        shadowElevation: 0,
      );
    }
    // Thin tier: matches the pre-refactor values (do not "tidy up" in passing,
    // this is the regression baseline)
    return LiquidGlassSettings(
      glassColor: tintBar,
      blur: 3,
      saturation: 0.7,
      thickness: 30,
      refractiveIndex: 1.59,
      chromaticAberration: 0.3,
      lightAngle: 0.75 * math.pi,
      lightIntensity: 0.6,
      ambientStrength: 1,
      rimLight: rimLight,
      shadowElevation: 1.0,
    );
  }

  /// Glass material for floating navigation/action bars (bottom nav, top bar, floating buttons)
  ///
  /// In the "dark solid" tier cards are opaque, but floating chrome such as bottom
  /// bars / top bars / floating buttons must keep the liquid glass look — they
  /// cannot share [bar] with cards (in the solid tier that is a purely opaque fill
  /// and would paint the glass as a solid slab).
  /// Non-solid tiers return [bar] directly, keeping the existing look with zero drift.
  static LiquidGlassSettings navBar() {
    if (!isSolid) return bar();
    return LiquidGlassSettings(
      glassColor: tintBar,
      blur: 16,
      saturation: 1.5,
      thickness: 30,
      refractiveIndex: 1.59,
      chromaticAberration: 0.3,
      lightAngle: 0.75 * math.pi,
      lightIntensity: 0.6,
      ambientStrength: 1,
      rimLight: 0.5,
      shadowElevation: 2.0,
    );
  }

  /// Bottom bar base tint: the official 24% white
  static Color get tintBar =>
      DS.isDark ? const Color(0x26FFFFFF) : const Color(0x3DFFFFFF);

  /// Concentric corner radius: inner radius = outer radius - padding (the document's "shape rule")
  static BorderRadius concentricRadius(
    double outerRadius,
    double padding,
  ) =>
      BorderRadius.circular((outerRadius - padding).clamp(0.0, outerRadius));

  /// Glass shape: continuous superellipse (the iOS 26 squircle look)
  static LiquidRoundedSuperellipse shape(double radius) =>
      LiquidRoundedSuperellipse(borderRadius: radius);
}

/// Whether liquid glass should be rendered: switch on + not suppressed by the
/// system's "reduce transparency"
///
/// The official library approximates iOS's "increase contrast" signal with
/// `MediaQuery.highContrastOf`; when that signal is on, the glass shader is
/// bypassed (official accessibility behavior). The same rule is kept here so the
/// UI layer's dual-tree branch matches the official rendering behavior.
bool shouldUseLiquidGlass(BuildContext context) {
  if (!GlassMaterials.enabled) return false;
  final mq = MediaQuery.maybeOf(context);
  if (mq != null && mq.highContrast) return false;
  return true;
}

/// Bottom padding for scrolling content in glass mode
///
/// GlassScaffold uses an immersive layout (content runs under the bottom bar), so
/// a floating glass bottom bar covers the last list item and scroll containers
/// must reserve this space themselves; returns 0 when glass is off (zero drift).
double glassBottomInset(BuildContext context) =>
    shouldUseLiquidGlass(context) ? 80 : 0;

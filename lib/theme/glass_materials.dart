import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'app_design_system.dart';

/// 液态玻璃材质参数（按 liquid-glass-flutter 提示词文档"写死"的数值）
///
/// 与文档条款的对应关系：
/// - 背景模糊 blur(20px)      -> [blur] = 20
/// - saturate(180%)           -> [saturation] = 1.8
/// - brightness(1.05)         -> [whitenStrength] = 0.05（包内无独立亮度参数，
///                               用官方"向白混合"旋钮近似提亮，全档位一致生效）
/// - 底色 浅色 rgba(255,255,255,0.12) / 深色 rgba(0,0,0,0.15) -> [tintLight] / [tintDark]
/// - 顶部 1px 高光描边        -> [rimLight] + [lightAngle]（光来自上方）
/// - 底部内阴影               -> [shadow]（elevation + contact 双层）
/// - 边缘折射 2~3px           -> [thickness] = 24 + [refractiveIndex] = 1.2
/// - RGB 通道错位模拟色散     -> [chromaticAberration] = 0.01
/// - 叠 3% 噪声去色带         -> **包未提供噪声/抖动参数**，此项未实现，
///                               去色带依赖 blur/frost 自身，真机若出现色带需另解
///
/// 折射与色散属于 Premium(Shader) 路线，只在 Impeller 生效；
/// Skia/Web/测试环境自动落到雾面 BackdropFilter 路线，其余参数照常生效。
abstract final class GlassMaterials {
  /// 文档要求"写死，不要自由发挥"的公共材质基值
  static const double blur = 20;
  static const double saturation = 1.8;
  static const double brightness = 1.05;
  static const double edgeRefractionPx = 24;
  static const double refractiveIndex = 1.2;
  static const double chromaticAberration = 0.01;
  static const double noisePercent = 3; // 未实现，见类注释

  /// 顶部高光描边强度（浅色模式）
  static const double rimLight = 0.35;

  /// 光源自上方（-pi/2）：让高光落在顶部边缘
  static const double lightAngleTop = -1.5707963267948966;

  static const Color tintLight = Color(0x1FFFFFFF); // rgba(255,255,255,0.12)
  static const Color tintDark = Color(0x26000000); // rgba(0,0,0,0.15)

  /// 玻璃层是否可用：受设置页开关控制
  static bool _enabled = false;
  static bool get enabled => _enabled;
  static void setEnabled(bool value) => _enabled = value;

  /// 运行时渲染后端是否支持 Shader 折射（Skia/测试环境为 false，自动走雾面）
  static bool get supportsRefraction =>
      ImageFilter.isShaderFilterSupported;

  static Color get tint => DS.isDark ? tintDark : tintLight;

  /// 主玻璃材质：卡片、面板、底栏
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

  /// 次级玻璃：列表项、小组件（模糊更轻，避免大面积糊）
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

  /// 底栏/顶栏专用材质：官方 [kBottomBarGlassDefaults] 的 iOS 26 调校值
  ///
  /// 官方底栏默认值（thickness 30 / 折射率 1.59 / 135° 光源 / 24% 白底）
  /// 是 Apple News / Safari 底栏的实测参数，比 [surface] 更"厚实"。
  /// 之前用 [surface] 覆盖它导致药丸过透明、文字发虚。
  /// 仅额外保留项目设计规范要求的顶部高光描边（[rimLight]）。
  static LiquidGlassSettings bar() {
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

  /// 底栏底色：官方 24% 白；深色模式压暗避免发白
  static Color get tintBar =>
      DS.isDark ? const Color(0x26FFFFFF) : const Color(0x3DFFFFFF);

  /// 同心圆角：内圆角 = 外圆角 - padding（文档"形状规则"）
  static BorderRadius concentricRadius(
    double outerRadius,
    double padding,
  ) =>
      BorderRadius.circular((outerRadius - padding).clamp(0.0, outerRadius));

  /// 玻璃形状：连续超椭圆（iOS 26 的 squircle 观感）
  static LiquidRoundedSuperellipse shape(double radius) =>
      LiquidRoundedSuperellipse(borderRadius: radius);
}

/// 是否应渲染液态玻璃：开关开启 + 未被系统"减弱透明度"抑制
///
/// 官方库用 `MediaQuery.highContrastOf` 近似 iOS 的"增强对比度"信号，
/// 该信号开启时玻璃 shader 会被绕过（官方无障碍行为），这里保持同口径，
/// 让 UI 层的双树分叉与官方渲染行为一致。
bool shouldUseLiquidGlass(BuildContext context) {
  if (!GlassMaterials.enabled) return false;
  final mq = MediaQuery.maybeOf(context);
  if (mq != null && mq.highContrast) return false;
  return true;
}

/// 玻璃模式下的滚动内容底部留白
///
/// GlassScaffold 是沉浸式布局（内容穿到底栏下），浮动玻璃底栏会盖住
/// 列表最后一项，滚动容器需自行留出这段空间；关闭态返回 0，零漂移。
double glassBottomInset(BuildContext context) =>
    shouldUseLiquidGlass(context) ? 80 : 0;

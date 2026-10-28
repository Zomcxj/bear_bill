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
/// 玻璃风格三档：经典实色 / 轻薄玻璃 / 深色实心
///
/// - [classic]：不启用玻璃，走各页面的关闭态（零漂移）
/// - [thin]：现有轻薄玻璃（bar() 逐值等于改造前）
/// - [solid]：深色实心（近黑实心卡 + 1px 描边 + 亮色药丸）
enum AppGlassStyle { classic, thin, solid }

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

  /// 当前玻璃风格（三档），由设置页控制
  static AppGlassStyle _style = AppGlassStyle.classic;
  static AppGlassStyle get style => _style;
  static void setStyle(AppGlassStyle value) => _style = value;

  /// 是否「深色实心」档（近黑实心卡 + 细描边 + 亮色药丸）
  static bool get isSolid => _style == AppGlassStyle.solid;

  /// 是否需要外层 1px 描边 + 外层阴影（仅深色实心档）
  static bool get hasOuterFrame => isSolid;

  /// 外描边色
  static Color get outerBorderColor => solidBorderColor;

  /// 外层阴影
  static List<BoxShadow> get outerShadows => solidShadows;

  // ── 「深色实心」档 ──────────────────────────────────────
  /// 实心卡面：近黑（深色 #161A23）/ 近白（浅色）
  static Color get solidCardColor =>
      DS.isDark ? const Color(0xFF161A23) : const Color(0xFFFFFFFF);

  /// 实心卡 1px 细描边（深色 8% 白 / 浅色 8% 黑）
  static Color get solidBorderColor =>
      DS.isDark ? const Color(0x14FFFFFF) : const Color(0x14000000);

  /// 实心档外层阴影
  static List<BoxShadow> get solidShadows => [
        BoxShadow(
          color: Colors.black.withOpacity(DS.isDark ? 0.35 : 0.08),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ];

  /// 强调蓝（选中药丸/指示器）
  static const Color solidAccent = Color(0xFF2D7EF6);

  /// 药丸上的文字/图标色
  static const Color solidOnAccent = Color(0xFFFFFFFF);

  /// 实心档底槽（分段控件容器底色，比卡面暗一档）
  static Color get solidTrackColor =>
      DS.isDark ? const Color(0xFF0B0D12) : const Color(0xFFEDEFF2);

  /// 玻璃悬浮按钮外描边：浅色下玻璃与浅底不分家，靠细边 + 阴影立起来
  static Color get fabBorderColor =>
      DS.isDark ? const Color(0x1FFFFFFF) : const Color(0x1A000000);

  /// 玻璃悬浮按钮阴影（浅色更重，拉开与背景的层级）
  static List<BoxShadow> get fabShadows => [
        BoxShadow(
          color: Colors.black.withOpacity(DS.isDark ? 0.30 : 0.14),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  /// 玻璃层是否可用（兼容旧调用点）：classic 即"玻璃未开启"
  static bool get enabled => _style != AppGlassStyle.classic;
  static void setEnabled(bool value) => _style =
      value ? AppGlassStyle.thin : AppGlassStyle.classic;

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
    // 第 4 档「深色实心」：全不透明填充 + 零模糊/零高光 —— 实心卡观感
    // （glassColor 取全不透明，shader 输出即该色，等于纯实心）
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
    // 轻薄档：逐值等于改造前（勿"顺手优化"，此为回归基线）
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

  /// 浮动导航/操作条专用玻璃材质（底部导航、顶栏、悬浮按钮）
  ///
  /// 「深色实心」档下卡片是实心不透明的，但底栏/顶栏/悬浮按钮这类**浮动
  /// chrome** 仍需保留液态玻璃观感 —— 它们不能和卡片共用 [bar]（那份在
  /// 实心档是纯不透明填充，会把玻璃刷成一块实心板）。
  /// 非实心档直接返回 [bar]，保证既有观感零漂移。
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

  /// 底栏底色：官方 24% 白
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

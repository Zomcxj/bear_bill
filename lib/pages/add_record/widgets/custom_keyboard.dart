import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart'
    show GlassContainer, GlassQuality;

import '../../../theme/app_design_system.dart';
import '../../../providers/theme_provider.dart';
import '../../../theme/glass_materials.dart';
import 'package:provider/provider.dart';

/// 自定义数字键盘 — Luminous Finance 风格
///
/// 玻璃哲学：整块键盘是贴底控制层 = 玻璃"托盘"（与底栏同场景）；
/// 按键只是托盘上的半透明着色层，各自不再建折射图层（玻璃不套玻璃）。
/// 关闭态完全保留原白底样式，零视觉漂移。
class CustomKeyboard extends StatelessWidget {
  final Function(String) onKeyTap;

  const CustomKeyboard({super.key, required this.onKeyTap});

  static const List<List<String>> _keys = [
    ['7', '8', '9', '⌫'],
    ['4', '5', '6', '备注'],
    ['1', '2', '3', '.'],
    ['00', '0', '完成'],
  ];

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>(); // theme rebuild
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    if (!shouldUseLiquidGlass(context)) {
      return _buildLegacy(context, bottomPadding);
    }

    // 开启态：悬浮玻璃托盘。记一笔是独立整页路由，
    // 没有父 LiquidGlassLayer，grouped 模式会忽略 per-widget settings，
    // 必须自建图层（useOwnLayer: true）。
    return Padding(
      padding: EdgeInsets.fromLTRB(DS.sm, 0, DS.sm, bottomPadding + DS.sm),
      child: GlassContainer(
        shape: GlassMaterials.shape(28),
        settings: GlassMaterials.bar(),
        // 贴底静态控制条 = footer 场景，官方调校的 premium 真折射
        quality: GlassQuality.premium,
        useOwnLayer: true,
        width: double.infinity,
        padding: const EdgeInsets.all(DS.xs + 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _keys.map((row) {
            return Padding(
              padding: EdgeInsets.only(bottom: 3),
              child: Row(
                children: row.map((key) {
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: DS.xs / 2),
                      child: _KeyButton(
                        label: key,
                        onTap: () => onKeyTap(key),
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// 关闭态：原样保留（贴底满宽白底 + 顶部细边框）
  Widget _buildLegacy(BuildContext context, double bottomPadding) {
    return Container(
      padding: EdgeInsets.fromLTRB(DS.xs, DS.xs, DS.xs, bottomPadding + DS.xs),
      decoration: BoxDecoration(
        color: DS.surfaceContainerLow.withOpacity(0.95),
        border: Border(
          top: BorderSide(color: DS.outlineVariant, width: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: _keys.map((row) {
          return Padding(
            padding: EdgeInsets.only(bottom: 3),
            child: Row(
              children: row.map((key) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: DS.xs / 2),
                    child: _KeyButton(
                      label: key,
                      onTap: () => onKeyTap(key),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _KeyButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _KeyButton({
    required this.label,
    required this.onTap,
  });

  @override
  State<_KeyButton> createState() => _KeyButtonState();
}

class _KeyButtonState extends State<_KeyButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>(); // theme rebuild
    final label = widget.label;
    final isBackspace = label == '⌫';
    final isNote = label == '备注';
    final isComplete = label == '完成';
    final isAction = isBackspace || isNote;
    final glass = shouldUseLiquidGlass(context);

    // 玻璃态键面：托盘上的"玻璃片"——半透明白 + 顶部高光渐变 + 细白边，
    // 数字键 / 动作键 / 完成键三档层次（light/dark 两套），
    // 完成键 = 强调胶囊（与 GlassPanelButton.primary 同语言）
    final double base = glass
        ? (isComplete
            ? (DS.isDark ? 0.22 : 0.55)
            : isAction
                ? (DS.isDark ? 0.05 : 0.18)
                : (DS.isDark ? 0.12 : 0.38))
        : 0;
    final double lit = _pressed ? base + 0.18 : base;
    final Color keyColor = glass
        ? Colors.white.withOpacity(lit.clamp(0.0, 1.0))
        : (isComplete
            ? DS.primary
            : isAction
                ? DS.surfaceContainerHigh
                : DS.surfaceContainerLowest);

    final Color contentColor = glass
        ? (isBackspace
            ? const Color(0xFFFF6B6B)
            : isNote
                ? DS.secondary
                : DS.onSurface)
        : (isBackspace
            ? DS.error
            : isNote
                ? DS.secondary
                : DS.onSurface);

    final key = AnimatedScale(
      scale: _pressed ? 0.94 : 1.0,
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        height: 44,
        decoration: glass
            ? BoxDecoration(
                color: keyColor,
                // 顶部高光渐变：模拟玻璃片上缘受光，底部透出托盘
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white
                        .withOpacity((lit + 0.14).clamp(0.0, 1.0)),
                    Colors.white
                        .withOpacity((lit - 0.10).clamp(0.0, 1.0)),
                  ],
                ),
                borderRadius: BorderRadius.circular(
                  isComplete ? DS.radiusFull : DS.radiusMd,
                ),
                border: Border.all(
                  // 亮色下深色细边才能显形（纯白边在亮玻璃上隐形）
                  color: DS.isDark
                      ? Colors.white.withOpacity(0.16)
                      : Colors.black.withOpacity(0.10),
                ),
                // 轻浮起：玻璃片与托盘之间的一点投影层次
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(
                      DS.isDark ? 0.20 : 0.06,
                    ),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              )
            : BoxDecoration(
                color: keyColor,
                borderRadius: BorderRadius.circular(
                  isComplete ? DS.radiusFull : DS.radiusSm,
                ),
                border: isComplete
                    ? null
                    : Border.all(color: DS.outlineVariant, width: 0.5),
                boxShadow: isComplete ? DS.shadowSm : null,
              ),
        child: Center(
          child: isComplete
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check, size: 18, color: contentColor),
                    SizedBox(width: DS.xs),
                    Text(
                      '完成',
                      style: TextStyle(
                        fontFamily: DS.fontLabel,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: contentColor,
                      ),
                    ),
                  ],
                )
              : Text(
                  label,
                  style: TextStyle(
                    fontFamily: isAction ? DS.fontLabel : DS.fontDisplay,
                    fontSize: isAction ? 14 : 22,
                    fontWeight: isAction ? FontWeight.w600 : FontWeight.w500,
                    color: contentColor,
                  ),
                ),
        ),
      ),
    );

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: key,
    );
  }
}

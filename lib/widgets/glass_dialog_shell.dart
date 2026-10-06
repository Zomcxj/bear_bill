import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart'
    show GlassContainer, GlassDialog, GlassDialogAction, GlassQuality;

import '../theme/app_design_system.dart';
import '../theme/glass_materials.dart';

/// 玻璃弹窗按钮（与官方 `GlassDialogAction` 字段对齐）
///
/// 关闭态转成 `TextButton`，开启态转成 `GlassDialogAction`。
class GlassDialogButton {
  const GlassDialogButton({
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
    this.isDestructive = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;
  final bool isDestructive;
}

/// 统一玻璃弹窗（任意内容 + 1~3 个按钮）
///
/// 开启液态玻璃时走官方 [GlassDialog]（真玻璃材质 + 交互光晕），
/// 关闭时回退标准 [AlertDialog]（零视觉漂移）。
///
/// [buildActions] 接收**弹窗自身的 BuildContext**，按钮里的
/// `Navigator.pop(ctx, value)` 必须用它，避免嵌套 Navigator 时 pop 错路由。
/// [content] 用于表单/选择器等自定义内容；[title]/[message] 为纯文本快捷方式。
Future<T?> showGlassDialog<T>({
  required BuildContext context,
  String? title,
  String? message,
  Widget? content,
  required List<GlassDialogButton> Function(BuildContext dialogContext)
      buildActions,
  double maxWidth = 280,
  bool barrierDismissible = false,
}) {
  if (!shouldUseLiquidGlass(context)) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (ctx) {
        final actions = buildActions(ctx);
        assert(actions.length > 0 && actions.length <= 3,
            'showGlassDialog 需要 1~3 个按钮');
        return AlertDialog(
          title: title != null ? Text(title) : null,
          content: content ?? (message != null ? Text(message) : null),
          actions: actions
              .map(
                (a) => TextButton(
                  onPressed: a.onPressed,
                  child: Text(
                    a.label,
                    style: a.isDestructive
                        ? TextStyle(color: Colors.red.shade400)
                        : null,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (ctx) {
      final actions = buildActions(ctx);
      assert(actions.length > 0 && actions.length <= 3,
          'showGlassDialog 需要 1~3 个按钮');
      return GlassDialog(
        title: title,
        message: message,
        content: content,
        quality: GlassQuality.standard,
        maxWidth: maxWidth,
        actions: actions
            .map(
              (a) => GlassDialogAction(
                label: a.label,
                onPressed: a.onPressed,
                isPrimary: a.isPrimary,
                isDestructive: a.isDestructive,
              ),
            )
            .toList(),
      );
    },
  );
}

/// 统一玻璃确认弹窗（`showGlassDialog` 的确认场景快捷方式）
///
/// 返回 true 表示用户点了确认，false/null 表示取消。
Future<bool?> showGlassConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmText = '确认',
  String cancelText = '取消',
  bool destructive = false,
}) {
  return showGlassDialog<bool>(
    context: context,
    title: title,
    message: message,
    buildActions: (ctx) => [
      GlassDialogButton(
        label: cancelText,
        onPressed: () => Navigator.pop(ctx, false),
      ),
      GlassDialogButton(
        label: confirmText,
        onPressed: () => Navigator.pop(ctx, true),
        isPrimary: !destructive,
        isDestructive: destructive,
      ),
    ],
  );
}

/// 玻璃面板弹窗（自定义内容 + 自定义按钮区，按钮数量不受 1~3 限制）
///
/// 官方 [GlassDialog] 限制 1~3 个 action（iOS 规范）；账本管理、成就详情等
/// 需要更多按钮或自定义布局的弹窗走这个壳：外壳是官方 [GlassContainer]，
/// 按钮由调用方自绘（推荐 [GlassPanelButton]）。
///
/// 开启态用真玻璃材质；关闭态回退 [AlertDialog]（[fallbackTitle] 必填）。
Future<T?> showGlassPanel<T>({
  required BuildContext context,
  required String fallbackTitle,
  required Widget child,
  String? title,
  double maxWidth = 340,
  EdgeInsetsGeometry padding = const EdgeInsets.all(DS.md),
  bool barrierDismissible = false,
  bool scrollable = false,
}) {
  if (!shouldUseLiquidGlass(context)) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (ctx) => AlertDialog(
        title: Text(fallbackTitle),
        content: scrollable ? SingleChildScrollView(child: child) : child,
      ),
    );
  }

  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (ctx) => Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: GlassContainer(
          shape: GlassMaterials.shape(24),
          settings: GlassMaterials.bar(),
          quality: GlassQuality.standard,
          // 弹窗在独立路由里，没有父 LiquidGlassLayer：
          // grouped 模式会忽略 per-widget settings，必须自建图层
          useOwnLayer: true,
          padding: padding,
          child: scrollable ? SingleChildScrollView(child: child) : child,
        ),
      ),
    ),
  );
}

/// 玻璃面板弹窗内的按钮（胶囊；[primary] 为强调填充，[destructive] 为红色文字）
class GlassPanelButton extends StatelessWidget {
  const GlassPanelButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.primary = false,
    this.destructive = false,
    this.icon,
  });

  final String label;
  final VoidCallback onPressed;
  final bool primary;
  final bool destructive;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final glass = shouldUseLiquidGlass(context);
    if (!glass) {
      return TextButton(
        onPressed: onPressed,
        child: Text(
          label,
          style: destructive ? TextStyle(color: Colors.red.shade400) : null,
        ),
      );
    }

    final Color fg = destructive ? const Color(0xFFFF6B6B) : DS.onSurface;

    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: primary
              ? (DS.isDark
                  ? Colors.white.withOpacity(0.22)
                  : Colors.white.withOpacity(0.75))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(DS.radiusFull),
          border: Border.all(
            color: primary
                ? Colors.transparent
                : (DS.isDark
                    ? Colors.white.withOpacity(0.20)
                    : Colors.black.withOpacity(0.12)),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: primary ? FontWeight.bold : FontWeight.w600,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 玻璃弹窗内的文本输入框（统一玻璃态样式）
///
/// 弹窗内容是自定义 widget，默认 TextField 在深色玻璃上对比度不足，
/// 这里统一处理边框/填充/文字色。
class GlassDialogField extends StatelessWidget {
  const GlassDialogField({
    super.key,
    required this.controller,
    this.hintText,
    this.keyboardType,
    this.maxLines = 1,
    this.autofocus = false,
    this.prefixText,
  });

  final TextEditingController controller;
  final String? hintText;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool autofocus;
  final String? prefixText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      autofocus: autofocus,
      style: DS.bodyMd.copyWith(color: DS.onSurface),
      decoration: glassDialogInputDecoration(
        context,
        hintText: hintText,
        prefixText: prefixText,
      ),
    );
  }
}

/// 玻璃弹窗内输入框的统一装饰（TextField / TextFormField 共用）
InputDecoration glassDialogInputDecoration(
  BuildContext context, {
  String? hintText,
  String? labelText,
  String? prefixText,
  Widget? prefixIcon,
}) {
  final glass = shouldUseLiquidGlass(context);
  return InputDecoration(
    hintText: hintText,
    labelText: labelText,
    prefixText: prefixText,
    prefixIcon: prefixIcon,
    hintStyle: DS.bodyMd.copyWith(color: DS.outline),
    labelStyle: DS.bodyMd.copyWith(color: DS.onSurfaceVariant),
    filled: true,
    fillColor: glass
        ? (DS.isDark
            ? Colors.white.withOpacity(0.10)
            : Colors.white.withOpacity(0.55))
        : DS.surfaceContainerLow,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: DS.sm,
      vertical: DS.sm,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(DS.radiusSm),
      borderSide: BorderSide(color: DS.outlineVariant),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(DS.radiusSm),
      borderSide: BorderSide(color: DS.outlineVariant),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(DS.radiusSm),
      borderSide: BorderSide(color: DS.secondary, width: 1.5),
    ),
  );
}

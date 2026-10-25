import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart'
    show
        GlassButton,
        GlassButtonStyle,
        GlassContainer,
        GlassDefaults,
        GlassDialog,
        GlassDialogAction,
        GlassMaterializeTransition,
        GlassQuality,
        LiquidRoundedSuperellipse;

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
    print('[详情壳] 非玻璃分支'); // TODO: 定位后移除
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

  return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: '对话框',
      pageBuilder: (ctx, _, __) {
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
      // 进场 = iOS 26 materialize 编排（玻璃先成形、内容后清晰），
      // 出场反向（内容先走、玻璃后溶解）；这是驱动 shader 可见性的
      // 唯一正确玻璃淡入方式，普通 FadeTransition 会让玻璃整帧跳变。
      transitionBuilder: (_, animation, __, child) =>
          GlassMaterializeTransition(animation: animation, child: child),
      transitionDuration: GlassDefaults.materializeDuration,
      // showGeneralDialog 无 reverseTransitionDuration：
      // 出场以同长反放，GlassMaterializeTransition 依 status 自动切换为
      // 「内容先走、玻璃后溶解」的出场编排
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

  return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: '面板',
      pageBuilder: (ctx, _, __) => Center(
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
      // 与 showGlassDialog 同款 materialize 进出编排
      transitionBuilder: (_, animation, __, child) =>
          GlassMaterializeTransition(animation: animation, child: child),
      transitionDuration: GlassDefaults.materializeDuration,
  );
}

/// 玻璃详情窗口（内容由调用方全权绘制，居中小窗 + materialize 编排）
///
/// 玻璃态直接用官方 [GlassDialog] 本体（真机验证可用的唯一玻璃弹窗路线，
/// 见设置月度预算弹窗）：它自带 GlassCard + AdaptiveLiquidGlassLayer 图层
/// 管线；裸 GlassContainer/GlassCard 自拼结构在弹窗路由里整窗不可见。
/// [builder] 返回纯内容 Column，操作按钮由内容自绘（actions 传空）。
/// 关闭态不做 AlertDialog 回退：[builder] 内部按 shouldUseLiquidGlass 自行分支。
Future<T?> showGlassContentDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  double maxWidth = 360,
  bool barrierDismissible = true,
}) {
  if (!shouldUseLiquidGlass(context)) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: builder,
    );
  }

  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: '详情',
    pageBuilder: (ctx, _, __) => GlassDialog(
      quality: GlassQuality.standard,
      maxWidth: maxWidth,
      actions: const [],
      content: builder(ctx),
    ),
    // 与 showGlassDialog / showGlassPanel 同款 materialize 进出编排
    transitionBuilder: (_, animation, __, child) =>
        GlassMaterializeTransition(animation: animation, child: child),
    transitionDuration: GlassDefaults.materializeDuration,
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

    // 按压物理 = 官方 GlassButton 透明样式（弹簧膨胀 + 拖拽跟随 + 触点光晕），
    // transparent 不画玻璃壳，键面仍是托盘上的着色层——玻璃不套玻璃
    return GlassButton.custom(
      style: GlassButtonStyle.transparent,
      onTap: onPressed,
      interactionScale: 1.05,
      stretch: 0.25,
      shape: const LiquidRoundedSuperellipse(borderRadius: 999),
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
          // 玻璃主题无边框（老大要求）：描边取消，仅靠填充区分
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

/// 玻璃圆形图标按钮（月份切换、步进器等小圆钮统一用这套）
///
/// 玻璃态 = 官方 [GlassButton] 默认样式（真玻璃壳 + 按压弹簧 + 触点光晕）；
/// 关闭态 = 原 [GestureDetector]+填充圆钮（零漂移，由调用方决定是否回退）。
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 36,
    this.iconSize = 22,
    this.iconColor,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final double iconSize;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final glass = shouldUseLiquidGlass(context);
    if (!glass) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: DS.surfaceContainerLow,
            borderRadius: BorderRadius.circular(DS.radiusFull),
          ),
          child: Icon(icon, size: iconSize, color: iconColor ?? DS.onSurfaceVariant),
        ),
      );
    }

    return GlassButton.custom(
      onTap: onTap,
      interactionScale: 1.06,
      stretch: 0.2,
      shape: const LiquidRoundedSuperellipse(borderRadius: 999),
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        child: Icon(icon, size: iconSize, color: iconColor ?? DS.onSurface),
      ),
    );
  }
}

/// 底部导航栏同款玻璃条包装
///
/// 玻璃态：child 整体包进一条 shader 玻璃（GlassContainer 胶囊条，
/// 材质与 GlassTabBar.bottom 同源）；关闭态原样返回 child（零漂移）。
/// 条上的按钮请用 GlassButton.custom(style: transparent)——条本身
/// 已是玻璃，按钮只取按压物理（玻璃不套玻璃）。
class GlassBarWrap extends StatelessWidget {
  const GlassBarWrap({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!shouldUseLiquidGlass(context)) return child;
    return Padding(
      padding: EdgeInsets.fromLTRB(DS.base, 4, DS.base, 4),
      child: GlassContainer(
        shape: GlassMaterials.shape(DS.radiusFull),
        settings: GlassMaterials.bar(),
        quality: GlassQuality.standard,
        // 页面树里没有父玻璃图层，自建图层
        useOwnLayer: true,
        padding: EdgeInsets.symmetric(horizontal: DS.base, vertical: 8),
        child: child,
      ),
    );
  }
}

/// 玻璃分段切换器（月度/年度、进行中/已实现等两段切换统一走这套）
///
/// 官方 [GlassSegmentedControl] 在本项目的页面树里渲染为灰底板、
/// 无玻璃观感，故用自研模式：每段一枚玻璃壳钮（按压弹簧+光晕），
/// 选中段强调填充。关闭态调用方自行回退（本组件仅在玻璃态使用）。
class GlassSegmented extends StatefulWidget {
  const GlassSegmented({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
    this.height = 40,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final double height;

  @override
  State<GlassSegmented> createState() => _GlassSegmentedState();
}

class _GlassSegmentedState extends State<GlassSegmented> {
  final _barKey = GlobalKey();
  int? _pressed;

  /// 按住拖动换段（底栏"按住滑动"同款换算）+ 按压段放大
  void _onPointer(PointerEvent event) {
    final box = _barKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final idx = ((event.localPosition.dx) / (box.size.width / widget.labels.length))
        .floor()
        .clamp(0, widget.labels.length - 1);
    if (_pressed != idx) setState(() => _pressed = idx);
    if (idx != widget.selectedIndex) widget.onSelected(idx);
  }

  void _pressEnd() {
    if (_pressed != null) setState(() => _pressed = null);
  }

  @override
  Widget build(BuildContext context) {
    // 一体玻璃条（底栏模板）：整条 shader 玻璃 + 选中段白色滑块 + 按住拖动
    return GlassContainer(
      shape: GlassMaterials.shape(DS.radiusFull),
      settings: GlassMaterials.bar(),
      quality: GlassQuality.standard,
      useOwnLayer: true,
      padding: const EdgeInsets.all(4),
      child: Listener(
        key: _barKey,
        behavior: HitTestBehavior.translucent,
        onPointerDown: _onPointer,
        onPointerMove: _onPointer,
        onPointerUp: (_) => _pressEnd(),
        onPointerCancel: (_) => _pressEnd(),
        child: Stack(
          children: [
            // 高光滑块：AnimatedAlign 平滑滑动（底栏 jelly 观感的简化版）
            AnimatedAlign(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment(
                  widget.labels.length < 2
                      ? 0
                      : -1 +
                          2 *
                              widget.selectedIndex /
                              (widget.labels.length - 1),
                  0),
              child: FractionallySizedBox(
                widthFactor: 1 / widget.labels.length,
                child: Container(
                  height: widget.height - 8,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: DS.isDark
                        ? Colors.white.withOpacity(0.22)
                        : Colors.white.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(DS.radiusFull),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                for (int i = 0; i < widget.labels.length; i++)
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => widget.onSelected(i),
                      child: AnimatedScale(
                        scale: _pressed == i ? 1.06 : 1.0,
                        duration: const Duration(milliseconds: 120),
                        curve: Curves.easeOut,
                        child: Container(
                          height: widget.height - 8,
                          alignment: Alignment.center,
                          child: Text(
                            widget.labels[i],
                            style: DS.labelMd.copyWith(
                              fontWeight: FontWeight.w600,
                              color: i == widget.selectedIndex
                                  ? DS.onSurface
                                  : DS.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 玻璃表面容器：卡片级液态玻璃
///
/// 玻璃态 = shader 玻璃卡（GlassContainer + subtle 材质，自建图层）；
/// 关闭态 = [fallbackDecoration] 原装饰原样渲染（零漂移）。
/// 用于概览收支卡、预算卡、账单/统计汇总卡这类大面积表面。
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.borderRadius = DS.radiusMd,
    this.fallbackDecoration,
    this.padding = EdgeInsets.zero,
    this.margin,
    this.width,
  });

  final Widget child;
  final double? width;
  final double borderRadius;

  /// 关闭态的装饰（调用方把原 Container 的 decoration 原样搬进来）
  final BoxDecoration? fallbackDecoration;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    if (!shouldUseLiquidGlass(context)) {
      return Container(
        margin: margin,
        padding: padding,
        decoration: fallbackDecoration,
        width: width,
        child: child,
      );
    }
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: SizedBox(
        width: width,
        child: GlassContainer(
          shape: GlassMaterials.shape(borderRadius),
        // 卡片材质与底栏/日期条统一（bar），避免 subtle 在浅色下
        // 透明到和底图融成一片（老大实测反馈）
          settings: GlassMaterials.bar(),
          quality: GlassQuality.standard,
          // 页面树里没有父玻璃图层，自建图层
          useOwnLayer: true,
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

/// 玻璃年月选择小窗（账单/统计/月份条三处统一走这套）
///
/// 玻璃态 = 官方 [GlassDialog] 壳 + 玻璃化内容：年份透明玻璃步进
/// （壳本身是玻璃，按钮只取按压物理）、月份玻璃格（选中 = 强调填充）。
/// 关闭态 = [showGlassDialog] 自动回退标准 AlertDialog，内容用经典配色。
Future<void> showGlassYearMonthPicker({
  required BuildContext context,
  required String currentMonth,
  required ValueChanged<String> onPicked,
}) {
  final parts = currentMonth.split('-');
  int selectedYear = int.parse(parts[0]);
  int selectedMonth = int.parse(parts[1]);
  final now = DateTime.now();

  return showGlassDialog<void>(
    context: context,
    maxWidth: 320,
    content: StatefulBuilder(
      builder: (ctx, setState) {
        final glass = shouldUseLiquidGlass(ctx);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _pickerStepper(
                    ctx, Icons.chevron_left, () => setState(() => selectedYear--)),
                const SizedBox(width: DS.sm),
                Text('$selectedYear 年',
                    style: DS.headlineSm.copyWith(color: DS.onSurface)),
                const SizedBox(width: DS.sm),
                _pickerStepper(
                    ctx,
                    Icons.chevron_right,
                    selectedYear < now.year
                        ? () => setState(() => selectedYear++)
                        : null),
              ],
            ),
            const SizedBox(height: DS.sm),
            SizedBox(
              width: 280,
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: DS.sm,
                  crossAxisSpacing: DS.sm,
                  childAspectRatio: 1.4,
                ),
                itemCount: 12,
                itemBuilder: (_, i) {
                  final month = i + 1;
                  final isCurrent = month == selectedMonth;
                  final isFuture =
                      selectedYear == now.year && month > now.month;
                  return GestureDetector(
                    onTap: isFuture
                        ? null
                        : () {
                            final m = month.toString().padLeft(2, '0');
                            Navigator.pop(ctx);
                            onPicked('$selectedYear-$m');
                          },
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? DS.emphasis
                            : (glass
                                ? (DS.isDark
                                    ? Colors.white.withOpacity(0.08)
                                    : Colors.white.withOpacity(0.5))
                                : DS.surfaceContainerLow),
                        borderRadius: BorderRadius.circular(DS.radiusSm),
                      ),
                      child: Text(
                        '$month 月',
                        style: DS.labelMd.copyWith(
                          color: isFuture
                              ? DS.outline
                              : isCurrent
                                  ? (DS.isDark ? DS.background : Colors.white)
                                  : DS.onSurface,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    ),
    buildActions: (ctx) => [
      GlassDialogButton(
        label: '取消',
        onPressed: () => Navigator.pop(ctx),
      ),
    ],
  );
}

/// 年份步进按钮：玻璃态透明玻璃钮（弹窗壳本身已是玻璃，不套玻璃）；
/// 关闭态原 IconButton（零漂移）
Widget _pickerStepper(BuildContext context, IconData icon, VoidCallback? onTap) {
  if (shouldUseLiquidGlass(context)) {
    return GlassButton.custom(
      style: GlassButtonStyle.transparent,
      onTap: onTap ?? () {},
      interactionScale: 1.1,
      stretch: 0.2,
      shape: const LiquidRoundedSuperellipse(borderRadius: 999),
      child: SizedBox(
        width: 40,
        height: 40,
        child: Icon(icon, size: 20, color: DS.onSurface),
      ),
    );
  }
  return IconButton(icon: Icon(icon), onPressed: onTap);
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
    // 玻璃主题无边框：靠填充色区分输入区；关闭态保留描边（零漂移）
    border: glass
        ? InputBorder.none
        : OutlineInputBorder(
            borderRadius: BorderRadius.circular(DS.radiusSm),
            borderSide: BorderSide(color: DS.outlineVariant),
          ),
    enabledBorder: glass
        ? InputBorder.none
        : OutlineInputBorder(
            borderRadius: BorderRadius.circular(DS.radiusSm),
            borderSide: BorderSide(color: DS.outlineVariant),
          ),
    focusedBorder: glass
        ? InputBorder.none
        : OutlineInputBorder(
            borderRadius: BorderRadius.circular(DS.radiusSm),
            borderSide: BorderSide(color: DS.secondary, width: 1.5),
          ),
  );
}

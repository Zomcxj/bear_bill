
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

/// Glass dialog button (fields aligned with the official `GlassDialogAction`)
///
/// Renders as a `TextButton` when disabled and as a `GlassDialogAction` when
/// enabled.
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

/// Unified glass dialog (arbitrary content + 1~3 buttons)
///
/// When liquid glass is enabled it uses the official [GlassDialog] (real glass
/// material + interaction glow); when disabled it falls back to the standard
/// [AlertDialog] (zero visual drift).
///
/// [buildActions] receives **the dialog's own BuildContext**; the
/// `Navigator.pop(ctx, value)` inside the buttons must use it to avoid popping
/// the wrong route with nested Navigators. [content] is for custom content such
/// as forms/pickers; [title]/[message] are plain-text shortcuts.
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
          // The official GlassDialog goes through showGeneralDialog, so the
          // dialog route tree has no Material ancestor. Components with
          // built-in ink such as ListTile / InkWell call Material.of(context)
          // during build, which throws an assertion in debug and an exception
          // in release that gets replaced by an ErrorWidget (showing as a
          // blank grey box with the rest of the content pushed off screen).
          // Add a transparent Material ancestor for custom content here: it
          // paints nothing and intercepts no taps.
          content: content == null
              ? null
              : Material(
                  type: MaterialType.transparency,
                  // The dialog route may carry a dark text style of its own;
                  // force the correct foreground color for the current mode,
                  // otherwise uncolored text turns white and becomes
                  // invisible in light mode
                  child: DefaultTextStyle(
                    style: DefaultTextStyle.of(context)
                        .style
                        .copyWith(color: DS.onSurface),
                    child: content,
                  ),
                ),
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
      // Entrance = iOS 26 materialize choreography (glass forms first, then
      // content sharpens); exit is the reverse (content leaves first, glass
      // dissolves after). This is the only correct way to fade glass in while
      // driving shader visibility — a plain FadeTransition makes the glass
      // jump for a whole frame.
      transitionBuilder: (_, animation, __, child) =>
          GlassMaterializeTransition(animation: animation, child: child),
      transitionDuration: GlassDefaults.materializeDuration,
      // showGeneralDialog has no reverseTransitionDuration: the exit replays
      // over the same duration, and GlassMaterializeTransition switches
      // automatically based on status to the 'content leaves first, glass
      // dissolves after' exit choreography
  );
}

/// Unified glass confirmation dialog (shortcut for the confirm case of
/// `showGlassDialog`)
///
/// Returns true when the user confirms, false/null when cancelled.
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

/// Glass panel dialog (custom content + custom button area, with no 1~3
/// button limit)
///
/// The official [GlassDialog] allows only 1~3 actions (per the iOS spec);
/// dialogs that need more buttons or a custom layout — book management,
/// achievement details, and so on — use this shell: the shell is the official
/// [GlassContainer] and the buttons are drawn by the caller
/// ([GlassPanelButton] is recommended).
///
/// Enabled uses real glass material; disabled falls back to [AlertDialog]
/// ([fallbackTitle] is required).
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
            // The dialog lives in a standalone route with no parent
            // LiquidGlassLayer: grouped mode ignores per-widget settings, so
            // the layer must be created here
            useOwnLayer: true,
            padding: padding,
            child: scrollable ? SingleChildScrollView(child: child) : child,
          ),
        ),
      ),
      // Same materialize entrance/exit choreography as showGlassDialog
      transitionBuilder: (_, animation, __, child) =>
          GlassMaterializeTransition(animation: animation, child: child),
      transitionDuration: GlassDefaults.materializeDuration,
  );
}

/// Glass detail window (the caller draws all content; centered small window +
/// materialize choreography)
///
/// Glass mode uses the official [GlassDialog] itself (the only glass dialog
/// route verified to work on device — see the monthly budget dialog): it comes
/// with the GlassCard + AdaptiveLiquidGlassLayer pipeline; hand-assembled
/// structures of bare GlassContainer/GlassCard are entirely invisible inside a
/// dialog route. [builder] returns a content-only Column and the action
/// buttons are drawn by the content (actions is passed empty). Disabled mode
/// does not fall back to AlertDialog: [builder] branches on
/// shouldUseLiquidGlass internally.
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
    // Same materialize entrance/exit choreography as showGlassDialog /
    // showGlassPanel
    transitionBuilder: (_, animation, __, child) =>
        GlassMaterializeTransition(animation: animation, child: child),
    transitionDuration: GlassDefaults.materializeDuration,
  );
}

/// Button inside the glass panel dialog (pill; [primary] is an accent fill,
/// [destructive] is red text)
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

    final Color fg = destructive
        ? const Color(0xFFFF6B6B)
        : DS.onSurface;

    // Press physics = official GlassButton transparent style (spring scale +
    // drag follow + touch highlight); transparent paints no glass shell, and
    // the key face stays a tint layer on the tray — glass is never nested in
    // glass
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
          // No border in the glass theme (per the project owner): the outline
          // is dropped and states are distinguished by fill alone
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

/// Glass round icon button (the shared set for small round buttons such as
/// month switchers and steppers)
///
/// Glass mode = the official [GlassButton] default style (real glass shell +
/// press spring + touch highlight); disabled mode = the original
/// [GestureDetector] + filled round button (zero drift; the caller decides
/// whether to fall back).
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

/// Same glass bar wrapper as the bottom navigation bar
///
/// Glass mode: the whole child is wrapped in a single strip of shader glass
/// (a GlassContainer pill bar whose material comes from the same source as
/// GlassTabBar.bottom); disabled mode returns the child unchanged (zero
/// drift). For buttons on the bar use GlassButton.custom(style: transparent)
/// — the bar itself is already glass, so the buttons only take the press
/// physics (glass is never nested in glass).
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
        // No parent glass layer in the page tree, so create the layer here
        useOwnLayer: true,
        padding: EdgeInsets.symmetric(horizontal: DS.base, vertical: 8),
        child: child,
      ),
    );
  }
}

/// Glass segmented control (shared by two-segment switches such as
/// monthly/yearly and in-progress/completed)
///
/// The official [GlassSegmentedControl] renders as a grey base plate with no
/// glass look in this project's page tree, so a custom approach is used: one
/// glass shell button per segment (press spring + glow) with the selected
/// segment in an accent fill. The caller handles the disabled fallback (this
/// component is only used in glass mode).
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

  /// Pressed segment
  int? _pressed;

  /// Hold and drag to switch segments (same math as the bottom bar's
  /// "hold and slide") plus scaling of the pressed segment
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

  /// Alignment value for the target segment
  Alignment _alignmentFor(int index) => Alignment(
        widget.labels.length < 2
            ? 0
            : -1 + 2 * index / (widget.labels.length - 1),
        0,
      );

  /// The thumb itself
  ///
  /// - Light tier: translucent white block, height = widget.height - 8
  ///   (pixel-identical to before the rework)
  /// - Dark solid tier: solid accent-colored block at full height
  Widget _pill() {
    final solid = GlassMaterials.isSolid;
    return FractionallySizedBox(
        widthFactor: 1 / widget.labels.length,
        child: Container(
          height: solid ? null : widget.height - 8,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: solid
                ? GlassMaterials.solidAccent
                : (DS.isDark
                    ? Colors.white.withOpacity(0.22)
                    : Colors.white.withOpacity(0.65)),
            borderRadius: BorderRadius.circular(DS.radiusFull),
          ),
        ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // One-piece glass bar: a whole strip of shader glass + a solid thumb +
    // hold-and-drag
    // Animation: 300ms easeOutCubic, bulging vertically while sliding
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
        child: SizedBox(
          height: widget.height,
          child: Stack(
            // The pill must be visible beyond the Stack bounds while sliding
            clipBehavior: Clip.none,
            children: [
              // Main thumb: AnimatedAlign for a true slide (same look as the
              // bottom bar indicator)
              AnimatedAlign(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                alignment: _alignmentFor(widget.selectedIndex),
                child: _pill(),
              ),
              Row(
                children: [
                  for (int i = 0; i < widget.labels.length; i++)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => widget.onSelected(i),
                        // Press: linear 1.06 (regression baseline)
                        child: AnimatedScale(
                          scale: _pressed == i ? 1.06 : 1.0,
                          duration: const Duration(milliseconds: 120),
                          curve: Curves.easeOut,
                          child: Container(
                            alignment: Alignment.center,
                            child: Text(
                              widget.labels[i],
                              style: DS.labelMd.copyWith(
                                fontWeight: FontWeight.w600,
                                // Selected segment: on the dark solid tier it
                                // sits on a solid accent block -> white text;
                                // on the light tier it sits on a white block
                                // -> surface color (unchanged from before)
                                color: i == widget.selectedIndex
                                    ? (GlassMaterials.isSolid
                                        ? GlassMaterials.solidOnAccent
                                        : DS.onSurface)
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
      ),
    );
  }
}

/// Glass surface container: card-level liquid glass
///
/// Glass mode = shader glass card (GlassContainer + subtle material, with its
/// own layer); disabled mode = the original [fallbackDecoration] rendered
/// as-is (zero drift). Used for large surfaces such as the overview
/// income/expense card, the budget card, and the bill/statistics summary
/// cards.
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

  /// Decoration used when disabled (the caller moves the original Container's
  /// decoration in unchanged)
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
    final glassCard = GlassContainer(
      shape: GlassMaterials.shape(borderRadius),
      // Card material matches the bottom bar/date bar (bar) so that subtle
      // does not become so transparent in light mode that it blends into the
      // background (feedback from the project owner's on-device testing)
      settings: GlassMaterials.bar(),
      quality: GlassQuality.standard,
      // No parent glass layer in the page tree, so create the layer here
      useOwnLayer: true,
      padding: padding,
      child: child,
    );
    // Light tier: pixel-identical to before the rework (no outer decoration)
    if (!GlassMaterials.hasOuterFrame) {
      return Padding(
        padding: margin ?? EdgeInsets.zero,
        child: SizedBox(width: width, child: glassCard),
      );
    }
    // Thick/solid tier: an extra 1px outline + outer shadow
    // (LiquidGlassSettings only handles refraction/blur/inner highlight; the
    // outer outline is provided here)
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: SizedBox(
        width: width,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: GlassMaterials.outerBorderColor),
            boxShadow: GlassMaterials.outerShadows,
          ),
          child: glassCard,
        ),
      ),
    );
  }
}

/// Glass year/month picker window (shared by the bill, statistics, and month
/// bar screens)
///
/// Glass mode = the official [GlassDialog] shell + glassified content: a
/// transparent glass stepper for the year (the shell is already glass, so the
/// buttons only take the press physics) and glass cells for the months
/// (selected = accent fill). Disabled mode = [showGlassDialog] automatically
/// falls back to a standard AlertDialog with classic colors.
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

/// Year stepper button: a transparent glass button in glass mode (the dialog
/// shell is already glass, so glass is not nested); the original IconButton
/// when disabled (zero drift)
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

/// Text input inside a glass dialog (unified glass styling)
///
/// Dialog content is a custom widget and the default TextField has
/// insufficient contrast on dark glass, so the border/fill/text color are
/// handled uniformly here.
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

/// Shared decoration for inputs inside glass dialogs (used by both TextField
/// and TextFormField)
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
    // No border in the glass theme: the input area is distinguished by fill
    // color; the outline is kept when disabled (zero drift)
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

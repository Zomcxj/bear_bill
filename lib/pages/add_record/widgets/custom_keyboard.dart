import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart'
    show
        GlassButton,
        GlassButtonStyle,
        GlassContainer,
        GlassQuality,
        LiquidRoundedSuperellipse;

import '../../../theme/app_design_system.dart';
import '../../../providers/theme_provider.dart';
import '../../../theme/glass_materials.dart';
import 'package:provider/provider.dart';

/// Custom numeric keyboard — Luminous Finance style
///
/// Glass philosophy: the whole keyboard is a bottom-docked control layer = a glass "tray"
/// (same scene as the bottom bar); the keys are only translucent tinted layers on the tray
/// and no longer build their own refraction layers (no glass on glass).
/// When disabled it keeps the original white background exactly, with zero visual drift.
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

    // Enabled state: floating glass tray. "Add record" is a standalone full-page route
    // with no parent LiquidGlassLayer, and grouped mode ignores per-widget settings,
    // so the layer must be created here (useOwnLayer: true).
    return Padding(
      padding: EdgeInsets.fromLTRB(DS.sm, 0, DS.sm, bottomPadding + DS.sm),
      child: GlassContainer(
        shape: GlassMaterials.shape(28),
        settings: GlassMaterials.bar(),
        // Bottom-docked static control bar = footer scene, officially tuned premium real refraction
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

  /// Disabled state: kept as-is (bottom-docked full-width white background + thin top border)
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

    if (glass) {
      // Enabled state: press physics = the official GlassButton transparent style (spring
      // scale + slight drag follow + touch-point glow). transparent draws no glass shell—
      // the keyboard tray is already glass, no glass on glass; the key face stays a static
      // tinted layer, and the press highlight is driven by the official ambient light.
      final double base = isComplete
          ? (DS.isDark ? 0.22 : 0.55)
          : isAction
              ? (DS.isDark ? 0.05 : 0.18)
              : (DS.isDark ? 0.12 : 0.38);
      return GlassButton.custom(
        style: GlassButtonStyle.transparent,
        onTap: widget.onTap,
        interactionScale: 1.06,
        // Holding a key slides across neighbors, so drag stretch is tuned down to the light tier
        stretch: 0.15,
        shape: LiquidRoundedSuperellipse(
          borderRadius: isComplete ? 999 : DS.radiusMd,
        ),
        child: _GlassKeyFace(
          label: label,
          base: base,
          isComplete: isComplete,
          isAction: isAction,
        ),
      );
    }

    // Disabled state: kept as-is (custom 0.94 press-down feedback), zero visual drift
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: _LegacyKeyFace(
          label: label,
          isComplete: isComplete,
          isAction: isAction,
          isBackspace: isBackspace,
        ),
      ),
    );
  }
}

/// Enabled key face: a static "glass chip" tinted layer (translucent white + top highlight
/// gradient + thin border + soft shadow), with three tiers for number / action / confirm keys
/// (separate light/dark sets); the confirm key = emphasis pill (same language as
/// GlassPanelButton.primary)
class _GlassKeyFace extends StatelessWidget {
  final String label;
  final double base;
  final bool isComplete;
  final bool isAction;

  const _GlassKeyFace({
    required this.label,
    required this.base,
    required this.isComplete,
    required this.isAction,
  });

  @override
  Widget build(BuildContext context) {
    final isBackspace = label == '⌫';
    final isNote = label == '备注';
    final lit = base;
    final Color contentColor = isBackspace
        ? const Color(0xFFFF6B6B)
        : isNote
            ? DS.secondary
            : DS.onSurface;

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(lit.clamp(0.0, 1.0)),
        // Top highlight gradient: simulates light hitting the top edge of the glass chip, with the tray showing through at the bottom
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withOpacity((lit + 0.14).clamp(0.0, 1.0)),
            Colors.white.withOpacity((lit - 0.10).clamp(0.0, 1.0)),
          ],
        ),
        borderRadius: BorderRadius.circular(
          isComplete ? DS.radiusFull : DS.radiusMd,
        ),
        border: Border.all(
          // In light mode a dark thin border is needed to render (a pure white border disappears on light glass)
          color: DS.isDark
              ? Colors.white.withOpacity(0.16)
              : Colors.black.withOpacity(0.10),
        ),
        // Slight lift: a hint of shadow layering between the glass chip and the tray
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              DS.isDark ? 0.20 : 0.06,
            ),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
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
    );
  }
}

/// Disabled key face: as-is (solid color + thin border), zero visual drift
class _LegacyKeyFace extends StatelessWidget {
  final String label;
  final bool isComplete;
  final bool isAction;
  final bool isBackspace;

  const _LegacyKeyFace({
    required this.label,
    required this.isComplete,
    required this.isAction,
    required this.isBackspace,
  });

  @override
  Widget build(BuildContext context) {
    final isNote = label == '备注';
    final Color keyColor = isComplete
        ? DS.primary
        : isAction
            ? DS.surfaceContainerHigh
            : DS.surfaceContainerLowest;
    final Color contentColor = isBackspace
        ? DS.error
        : isNote
            ? DS.secondary
            : DS.onSurface;

    return Container(
      height: 44,
      decoration: BoxDecoration(
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
    );
  }
}

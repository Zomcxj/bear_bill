import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart'
    show GlassContainer, GlassQuality;

import '../theme/app_design_system.dart';
import '../theme/glass_materials.dart';

/// Unified glass date picker bottom tray
///
/// Glass philosophy: the glass sliding up from the bottom is the "tray" and the wheel picker
/// is the content on it—the tray uses the real glass material while the content stays the
/// native CupertinoDatePicker without glass treatment, so there is no glass nested in glass.
///
/// Liquid glass enabled: `showModalBottomSheet` + the official [GlassContainer]
/// (a standalone route requires `useOwnLayer: true`; grouped mode ignores per-widget settings).
/// Disabled state: fully reproduces the original white background (320 height + cancel/confirm
/// + wheel), zero visual drift.
Future<DateTime?> showGlassDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime minimumDate,
  required DateTime maximumDate,
  String title = '选择日期',
}) {
  DateTime tempDate = initialDate;

  if (!shouldUseLiquidGlass(context)) {
    return showCupertinoModalPopup<DateTime>(
      context: context,
      builder: (context) => Container(
        height: 320,
        color: DS.surfaceContainerLowest,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  child: Text('取消'),
                  onPressed: () => Navigator.pop(context),
                ),
                CupertinoButton(
                  child: Text('确定', style: TextStyle(fontWeight: FontWeight.w600)),
                  onPressed: () => Navigator.pop(context, tempDate),
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: initialDate,
                minimumDate: minimumDate,
                maximumDate: maximumDate,
                onDateTimeChanged: (date) => tempDate = date,
              ),
            ),
          ],
        ),
      ),
    );
  }

  return showModalBottomSheet<DateTime>(
    context: context,
    backgroundColor: Colors.transparent,
    elevation: 0,
    // The sheet lives in a standalone route with no parent LiquidGlassLayer, so GlassContainer creates its own layer
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(DS.sm),
        child: GlassContainer(
          shape: GlassMaterials.shape(24),
          settings: GlassMaterials.bar(),
          // Bottom static tray = footer scene, using the official premium real refraction
          quality: GlassQuality.premium,
          useOwnLayer: true,
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(DS.md, DS.sm, DS.md, DS.xs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _GlassDatePickerAction(
                    label: '取消',
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    title,
                    style: DS.labelMd.copyWith(
                      fontWeight: FontWeight.w600,
                      color: DS.onSurfaceVariant,
                    ),
                  ),
                  _GlassDatePickerAction(
                    label: '确定',
                    highlighted: true,
                    onPressed: () => Navigator.pop(context, tempDate),
                  ),
                ],
              ),
              SizedBox(
                height: 220,
                // The wheel text is fixed black by default and unreadable on dark glass, so tint it with the theme color
                child: CupertinoTheme(
                  data: const CupertinoThemeData().copyWith(
                    textTheme: const CupertinoTextThemeData().copyWith(
                      dateTimePickerTextStyle: TextStyle(
                        fontSize: 22,
                        color: DS.onSurface,
                      ),
                    ),
                  ),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: initialDate,
                    minimumDate: minimumDate,
                    maximumDate: maximumDate,
                    onDateTimeChanged: (date) => tempDate = date,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Text button at the top of the glass date tray
class _GlassDatePickerAction extends StatelessWidget {
  const _GlassDatePickerAction({
    required this.label,
    required this.onPressed,
    this.highlighted = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: DS.xs, vertical: DS.sm),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: highlighted ? FontWeight.bold : FontWeight.w500,
            color: DS.onSurface,
          ),
        ),
      ),
    );
  }
}

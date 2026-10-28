import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart'
    show GlassButton, LiquidRoundedSuperellipse;

import '../../../theme/app_design_system.dart';
import '../../../theme/glass_materials.dart';

/// Check-in badge on the home hero (consecutive check-ins)
///
/// Glass state: official GlassButton with a real glass shell (press spring + drag follow +
/// touch-point glow); disabled state / already checked in: the original [GestureDetector] +
/// filled pill (zero drift, including the disabled state).
class CheckInBadge extends StatelessWidget {
  const CheckInBadge({
    super.key,
    required this.checked,
    required this.days,
    required this.onTap,
  });

  final bool checked;
  final int days;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (checked || !shouldUseLiquidGlass(context)) {
      return GestureDetector(
        onTap: checked ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: DS.heroCardBg,
            borderRadius: BorderRadius.circular(DS.radiusSm),
            border: Border.all(color: DS.heroCardBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                checked ? Icons.check_circle : Icons.local_fire_department,
                size: 16,
                color: checked ? DS.secondary : DS.error,
              ),
              const SizedBox(height: 1),
              Text(
                '$days天',
                style: TextStyle(
                  fontFamily: DS.fontLabel,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: DS.onSurface,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GlassButton.custom(
      onTap: onTap,
      interactionScale: 1.08,
      stretch: 0.15,
      shape: const LiquidRoundedSuperellipse(borderRadius: 999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_fire_department, size: 16, color: DS.error),
            const SizedBox(height: 1),
            Text(
              '$days天',
              style: TextStyle(
                fontFamily: DS.fontLabel,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: DS.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Book switch pill on the home hero
///
/// Glass state: real glass shell button (tap to switch books); disabled state: the original filled pill.
class BookSwitchChip extends StatelessWidget {
  const BookSwitchChip({
    super.key,
    required this.icon,
    required this.name,
    required this.onTap,
  });

  final String icon;
  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 14)),
        SizedBox(width: DS.xs),
        Text(name, style: DS.labelSm.copyWith(color: DS.onSurface)),
        const SizedBox(width: 2),
        Icon(Icons.chevron_right, size: 14, color: DS.outline),
      ],
    );

    if (!shouldUseLiquidGlass(context)) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: DS.sm, vertical: DS.xs + 2),
          decoration: BoxDecoration(
            color: DS.heroCardBg,
            borderRadius: BorderRadius.circular(DS.radiusSm),
            border: Border.all(color: DS.heroCardBorder),
          ),
          child: row,
        ),
      );
    }

    return GlassButton.custom(
      onTap: onTap,
      interactionScale: 1.05,
      stretch: 0.15,
      shape: const LiquidRoundedSuperellipse(borderRadius: 999),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: DS.sm, vertical: 6),
        child: row,
      ),
    );
  }
}

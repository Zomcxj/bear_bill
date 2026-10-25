import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart'
    show GlassButton, LiquidRoundedSuperellipse;

import '../../../theme/app_design_system.dart';
import '../../../theme/glass_materials.dart';

/// 首页 hero 上的打卡徽章（连续签到）
///
/// 玻璃态：官方 GlassButton 真玻璃壳（按压弹簧 + 拖拽跟随 + 触点光晕）；
/// 关闭态 / 已打卡：原 [GestureDetector]+填充胶囊（零漂移，含禁用态）。
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

/// 首页 hero 上的账本切换胶囊
///
/// 玻璃态：真玻璃壳按钮（点进去换账本）；关闭态：原填充胶囊。
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

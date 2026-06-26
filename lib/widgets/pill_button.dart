import 'package:flutter/material.dart';
import '../theme/app_design_system.dart';

/// 胶囊按钮组件
class PillButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool filled;
  final bool expanded;

  const PillButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.filled = true,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? DS.primary;
    final fgColor = foregroundColor ?? DS.onPrimary;

    final button = TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: filled ? bgColor : Colors.transparent,
        foregroundColor: filled ? fgColor : bgColor,
        padding: EdgeInsets.symmetric(
          horizontal: DS.md,
          vertical: DS.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DS.radiusFull),
          side: filled
              ? BorderSide.none
              : BorderSide(color: bgColor.withOpacity(0.3)),
        ),
      ),
      child: Row(
        mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18),
            SizedBox(width: DS.xs),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: DS.fontLabel,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}

import 'package:flutter/material.dart';

import '../../../theme/app_design_system.dart';

/// 自定义数字键盘 — Luminous Finance 风格
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
    final bottomPadding = MediaQuery.of(context).padding.bottom;
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

class _KeyButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _KeyButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isBackspace = label == '⌫';
    final isNote = label == '备注';
    final isComplete = label == '完成';
    final isAction = isBackspace || isNote;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: isComplete
              ? DS.primary
              : isAction
                  ? DS.surfaceContainerHigh
                  : DS.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(isComplete ? DS.radiusFull : DS.radiusSm),
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
                    Icon(Icons.check, size: 18, color: DS.onPrimary),
                    SizedBox(width: DS.xs),
                    Text(
                      '完成',
                      style: TextStyle(
                        fontFamily: DS.fontLabel,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: DS.onPrimary,
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
                    color: isBackspace ? DS.error : isNote ? DS.secondary : DS.onSurface,
                  ),
                ),
        ),
      ),
    );
  }
}

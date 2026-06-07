import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

/// 自定义数字键盘
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
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: _keys.map((row) {
          return Row(
            children: row.map((key) {
              return Expanded(
                child: _KeyButton(
                  label: key,
                  onTap: () => onKeyTap(key),
                ),
              );
            }).toList(),
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
    final isAction = label == '⌫' || label == '备注' || label == '完成';
    final isComplete = label == '完成';
    
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 60,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isComplete 
              ? AppTheme.primary 
              : isAction 
                  ? AppTheme.bgSection 
                  : AppTheme.bgCard,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: AppTheme.border,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isAction ? 16 : 22,
              fontWeight: FontWeight.w600,
              color: isComplete 
                  ? Colors.white 
                  : isAction 
                      ? AppTheme.textSecondary 
                      : AppTheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

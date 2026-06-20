import 'package:flutter/material.dart';

import '../../../theme/app_design_system.dart';

/// 支出/收入类型切换器
class TypeSwitcher extends StatelessWidget {
  final String type;
  final ValueChanged<String> onTypeChanged;

  const TypeSwitcher({
    super.key,
    required this.type,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(DS.base),
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: DS.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(DS.radiusFull),
        border: Border.all(color: DS.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onTypeChanged('expense'),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: type == 'expense'
                      ? DS.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(DS.radiusFull),
                ),
                child: Center(
                  child: Text(
                    '💸 支出',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: type == 'expense'
                          ? Colors.white
                          : DS.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => onTypeChanged('income'),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color:
                      type == 'income' ? DS.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(DS.radiusFull),
                ),
                child: Center(
                  child: Text(
                    '💰 收入',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: type == 'income'
                          ? Colors.white
                          : DS.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

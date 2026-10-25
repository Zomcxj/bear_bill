import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_design_system.dart';
import '../../../theme/glass_materials.dart';
import '../../../widgets/glass_dialog_shell.dart';
import '../../../providers/theme_provider.dart';

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
    context.watch<ThemeProvider>(); // theme rebuild
    final glass = shouldUseLiquidGlass(context);
    if (!glass) {
      // 关闭态：原填充胶囊（零漂移）
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
                    color: type == 'expense' ? DS.primary : Colors.transparent,
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
                  color: type == 'income' ? DS.primary : Colors.transparent,
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

    // 玻璃态：一体玻璃条 + 白滑块动画 + 按住拖动（底栏同款）
    return Padding(
      padding: EdgeInsets.all(DS.base),
      child: GlassSegmented(
        labels: const ['💸 支出', '💰 收入'],
        selectedIndex: type == 'expense' ? 0 : 1,
        onSelected: (i) => onTypeChanged(i == 0 ? 'expense' : 'income'),
        height: 40,
      ),
    );
  }
}

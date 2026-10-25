import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_design_system.dart';
import '../../../theme/glass_materials.dart';
import '../../../widgets/glass_dialog_shell.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/utils.dart' as utils;
import '../../../providers/theme_provider.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart'
    show GlassButton, GlassButtonStyle, LiquidRoundedSuperellipse;

/// 月份选择器 - 顶部切换条
class MonthSelector extends StatelessWidget {
  final String currentMonth;
  final double totalExpense;
  final double totalIncome;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<String>? onMonthPicked;

  const MonthSelector({
    super.key,
    required this.currentMonth,
    required this.totalExpense,
    required this.totalIncome,
    required this.onPrevMonth,
    required this.onNextMonth,
    this.onMonthPicked,
  });

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>(); // theme rebuild
    final glass = shouldUseLiquidGlass(context);
    final row = Row(
      children: [
        // 上一月按钮
        _arrow(context, icon: Icons.chevron_left, onTap: onPrevMonth),

        SizedBox(width: DS.base),

        // 月份和统计信息
        Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: onMonthPicked != null
                      ? () => _pickYearMonth(context)
                      : null,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        utils.DateUtils.formatMonthCN(currentMonth),
                        style: DS.bodyMd.copyWith(
                          fontWeight: FontWeight.w600,
                          color: DS.onSurface,
                        ),
                      ),
                      if (onMonthPicked != null)
                        Icon(Icons.unfold_more, size: 18, color: DS.outline),
                    ],
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '支 ¥${utils.FormatUtils.formatAmount(totalExpense)}',
                      style: DS.labelSm.copyWith(
                        // 动态支出色（常量 primaryContainer 深色下不可见）
                        color: DS.chartExpense,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('|', style: TextStyle(color: DS.outline)),
                    ),
                    Text(
                      '收 ¥${utils.FormatUtils.formatAmount(totalIncome)}',
                      style: DS.labelSm.copyWith(
                        color: AppTheme.success,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(width: DS.base),

        // 下一月按钮
        _arrow(context, icon: Icons.chevron_right, onTap: onNextMonth),
      ],
    );

    if (!glass) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: DS.base, vertical: 12),
        decoration: BoxDecoration(
          color: DS.surfaceContainerLowest,
          border: Border(bottom: BorderSide(color: DS.outlineVariant)),
        ),
        child: row,
      );
    }

    // 玻璃态：整条日期栏 = 底部导航栏同款玻璃条
    return GlassBarWrap(child: row);
  }

  /// 玻璃态：透明玻璃按钮（条本身已是玻璃，只取按压物理）；
  /// 关闭态：原填充圆钮（零漂移）
  Widget _arrow(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
  }) {
    if (shouldUseLiquidGlass(context)) {
      return GlassButton.custom(
        style: GlassButtonStyle.transparent,
        onTap: onTap,
        interactionScale: 1.12,
        stretch: 0.2,
        shape: const LiquidRoundedSuperellipse(borderRadius: 999),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: 22, color: DS.onSurface),
        ),
      );
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: DS.surfaceContainerLow,
          borderRadius: BorderRadius.circular(DS.radiusFull),
        ),
        child: Icon(icon, color: DS.onSurfaceVariant),
      ),
    );
  }

  void _pickYearMonth(BuildContext context) {
    // 玻璃年月选择小窗（三处日期切换统一组件，见 glass_dialog_shell）
    showGlassYearMonthPicker(
      context: context,
      currentMonth: currentMonth,
      onPicked: onMonthPicked!,
    );
  }
}

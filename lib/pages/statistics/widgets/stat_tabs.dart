import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:liquid_glass_widgets/liquid_glass_widgets.dart'
    show GlassContainer, GlassQuality;

import '../../../theme/app_design_system.dart';
import '../../../theme/glass_materials.dart';
import '../../../utils/utils.dart';
import '../../../providers/theme_provider.dart';
import 'package:provider/provider.dart';

/// 统计页 Tab 切换器
class StatTabs extends StatelessWidget {
  final String activeTab;
  final double totalExpense;
  final double totalIncome;
  final Function(String) onTabChanged;

  StatTabs({
    super.key,
    required this.activeTab,
    required this.totalExpense,
    required this.totalIncome,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>(); // theme rebuild
    final glass = shouldUseLiquidGlass(context);
    return Container(
      padding: EdgeInsets.all(DS.base),
      decoration: BoxDecoration(
        // 玻璃主题：无底色无边框（页面玻璃底直接透出）；关闭态原样
        color: glass ? Colors.transparent : DS.surfaceContainerLowest,
        border: glass
            ? null
            : Border(bottom: BorderSide(color: DS.outlineVariant)),
      ),
      // 按住拖动切换：指针压在左半区=支出、右半区=收入，
      // 拖过中线即切（与底栏"按住滑动"同款自研交互）
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (e) => _onPointer(context, e),
        onPointerMove: (e) => _onPointer(context, e),
        onPointerUp: (_) => _pressEnd(),
        onPointerCancel: (_) => _pressEnd(),
        child: glass
            ? GlassContainer(
                shape: GlassMaterials.shape(DS.radiusFull),
                settings: GlassMaterials.bar(),
                quality: GlassQuality.standard,
                useOwnLayer: true,
                padding: const EdgeInsets.all(4),
                child: ValueListenableBuilder<int?>(
                  valueListenable: _pressed,
                  builder: (_, pressed, __) => Stack(
                    children: [
                      // 白滑块：AnimatedAlign 平滑滑动（与记一笔切换器同款）
                    AnimatedAlign(
                      // 厚档 300ms（对齐参考实测）；轻薄档 220ms（现状）
                      duration: Duration(
                        milliseconds: GlassMaterials.isThick ? 300 : 220,
                      ),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment(activeTab == 'expense' ? -1 : 1, 0),
                      child: FractionallySizedBox(
                        widthFactor: 0.5,
                        // 厚档：滑动中纵向鼓起（sin 峰），落定回 1.0
                        child: TweenAnimationBuilder<double>(
                          key: ValueKey(activeTab),
                          tween: Tween<double>(begin: 0, end: 1),
                          duration: Duration(
                            milliseconds: GlassMaterials.isThick ? 300 : 0,
                          ),
                          builder: (_, v, child) => Transform.scale(
                            scaleY: GlassMaterials.isThick
                                ? 1.0 + 0.22 * math.sin(v * math.pi)
                                : 1.0,
                            child: child,
                          ),
                          child: Container(
                            height: 56,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: GlassMaterials.isThick
                                  ? null
                                  : (DS.isDark
                                      ? Colors.white.withOpacity(0.22)
                                      : Colors.white.withOpacity(0.65)),
                              gradient: GlassMaterials.isThick
                                  ? LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [
                                        DS.secondaryContainer.withOpacity(0.88),
                                        DS.secondaryContainer,
                                      ],
                                    )
                                  : null,
                              borderRadius:
                                  BorderRadius.circular(DS.radiusFull),
                              boxShadow: GlassMaterials.isThick
                                  ? [
                                      BoxShadow(
                                        color: DS.secondaryContainer
                                            .withOpacity(0.36),
                                        blurRadius: 12,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => onTabChanged('expense'),
                            child: AnimatedScale(
                              scale: pressed == 0 ? 1.06 : 1.0,
                              duration: const Duration(milliseconds: 120),
                              curve: Curves.easeOut,
                              child: Container(
                                height: 56,
                                alignment: Alignment.center,
                                child: _tabContent(
                                  active: activeTab == 'expense',
                                  icon: Icons.trending_down,
                                  label: '支出',
                                  amount: totalExpense,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => onTabChanged('income'),
                            child: AnimatedScale(
                              scale: pressed == 1 ? 1.06 : 1.0,
                              duration: const Duration(milliseconds: 120),
                              curve: Curves.easeOut,
                              child: Container(
                                height: 56,
                                alignment: Alignment.center,
                                child: _tabContent(
                                  active: activeTab == 'income',
                                  icon: Icons.trending_up,
                                  label: '收入',
                                  amount: totalIncome,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
            : Row(
                children: [
                  Expanded(
                    child: _classicTab(
                      active: activeTab == 'expense',
                      icon: Icons.trending_down,
                      label: '支出',
                      amount: totalExpense,
                      onTap: () => onTabChanged('expense'),
                    ),
                  ),
                  SizedBox(width: DS.base),
                  Expanded(
                    child: _classicTab(
                      active: activeTab == 'income',
                      icon: Icons.trending_up,
                      label: '收入',
                      amount: totalIncome,
                      onTap: () => onTabChanged('income'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }


  final ValueNotifier<int?> _pressed = ValueNotifier<int?>(null);

  void _onPointer(BuildContext context, PointerEvent event) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final left = box.localToGlobal(Offset.zero).dx;
    final tab =
        (event.position.dx - left) * 2 < box.size.width ? 'expense' : 'income';
    final idx = tab == 'expense' ? 0 : 1;
    _pressed.value = idx;
    if (tab != activeTab) {
      onTabChanged(tab);
    }
  }

  void _pressEnd() {
    _pressed.value = null;
  }


  /// 关闭态 Tab（零漂移：与改版前逐像素一致）
  Widget _classicTab({
    required bool active,
    required IconData icon,
    required String label,
    required double amount,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? DS.surfaceContainerHigh : Colors.transparent,
          borderRadius: BorderRadius.circular(DS.radiusMd),
          border: Border.all(
            color: active ? DS.emphasis : Colors.transparent,
            width: 2,
          ),
        ),
        child: _tabContent(
          active: active,
          icon: icon,
          label: label,
          amount: amount,
        ),
      ),
    );
  }

  Widget _tabContent({
    required bool active,
    required IconData icon,
    required String label,
    required double amount,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              // 厚档选中段压主题色实心药丸 -> 白；轻薄档维持强调色（现状）
              color: active
                  ? (GlassMaterials.isThick
                      ? DS.onSecondaryContainer
                      : DS.emphasis)
                  : DS.onSurfaceVariant,
            ),
            SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: active
                    ? (GlassMaterials.isThick
                        ? DS.onSecondaryContainer
                        : DS.emphasis)
                    : DS.onSurfaceVariant,
              ),
            ),
          ],
        ),
        SizedBox(height: 4),
        Text(
          '¥${FormatUtils.formatAmount(amount)}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: active
                ? (GlassMaterials.isThick
                    ? DS.onSecondaryContainer
                    : DS.emphasis)
                : DS.onSurface,
          ),
        ),
      ],
    );
  }
}

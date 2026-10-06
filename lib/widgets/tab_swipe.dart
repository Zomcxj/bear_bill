import 'package:flutter/material.dart';

/// 底部导航栏"按住滑动"：把指针的 x 坐标换算成应选中的 Tab 索引。
///
/// 底栏视为 [tabCount] 等分，指针落在第几等分就选第几个 Tab。
/// 用于关闭液态玻璃时的自研底栏（开启时由官方 GlassTabBar.bottom 原生接管，
/// 官方实现还带 magic-lens 指示器与 jelly 物理动画）。
int barTabFromX(double dx, double barWidth, int tabCount) {
  if (barWidth <= 0 || tabCount <= 1) return 0;
  final idx = (dx / (barWidth / tabCount)).floor();
  return idx.clamp(0, tabCount - 1);
}

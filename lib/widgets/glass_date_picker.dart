import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart'
    show GlassContainer, GlassQuality;

import '../theme/app_design_system.dart';
import '../theme/glass_materials.dart';

/// 统一玻璃日期选择底部托盘
///
/// 玻璃哲学：底部弹起的玻璃是"托盘"，滚轮选择器是托盘上的内容——
/// 托盘用真玻璃材质，内容保持原生 CupertinoDatePicker 不做玻璃化，
/// 不存在玻璃嵌套玻璃。
///
/// 开启液态玻璃：`showModalBottomSheet` + 官方 [GlassContainer]
/// （独立路由必须 `useOwnLayer: true`，grouped 模式会忽略 per-widget settings）。
/// 关闭态：完全复刻原白底样式（320 高 + 取消/确定 + 滚轮），零视觉漂移。
Future<DateTime?> showGlassDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime minimumDate,
  required DateTime maximumDate,
  String title = '选择日期',
}) {
  DateTime tempDate = initialDate;

  if (!shouldUseLiquidGlass(context)) {
    return showCupertinoModalPopup<DateTime>(
      context: context,
      builder: (context) => Container(
        height: 320,
        color: DS.surfaceContainerLowest,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  child: Text('取消'),
                  onPressed: () => Navigator.pop(context),
                ),
                CupertinoButton(
                  child: Text('确定', style: TextStyle(fontWeight: FontWeight.w600)),
                  onPressed: () => Navigator.pop(context, tempDate),
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: initialDate,
                minimumDate: minimumDate,
                maximumDate: maximumDate,
                onDateTimeChanged: (date) => tempDate = date,
              ),
            ),
          ],
        ),
      ),
    );
  }

  return showModalBottomSheet<DateTime>(
    context: context,
    backgroundColor: Colors.transparent,
    elevation: 0,
    // 弹窗在独立路由里，没有父 LiquidGlassLayer，GlassContainer 自建图层
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(DS.sm),
        child: GlassContainer(
          shape: GlassMaterials.shape(24),
          settings: GlassMaterials.bar(),
          // 底部静态托盘 = footer 场景，用官方调校的 premium 真折射
          quality: GlassQuality.premium,
          useOwnLayer: true,
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(DS.md, DS.sm, DS.md, DS.xs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _GlassDatePickerAction(
                    label: '取消',
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    title,
                    style: DS.labelMd.copyWith(
                      fontWeight: FontWeight.w600,
                      color: DS.onSurfaceVariant,
                    ),
                  ),
                  _GlassDatePickerAction(
                    label: '确定',
                    highlighted: true,
                    onPressed: () => Navigator.pop(context, tempDate),
                  ),
                ],
              ),
              SizedBox(
                height: 220,
                // 滚轮文字默认固定黑色，深色玻璃上看不清，统一染成主题色
                child: CupertinoTheme(
                  data: const CupertinoThemeData().copyWith(
                    textTheme: const CupertinoTextThemeData().copyWith(
                      dateTimePickerTextStyle: TextStyle(
                        fontSize: 22,
                        color: DS.onSurface,
                      ),
                    ),
                  ),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: initialDate,
                    minimumDate: minimumDate,
                    maximumDate: maximumDate,
                    onDateTimeChanged: (date) => tempDate = date,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// 玻璃日期托盘顶部的文字按钮
class _GlassDatePickerAction extends StatelessWidget {
  const _GlassDatePickerAction({
    required this.label,
    required this.onPressed,
    this.highlighted = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: DS.xs, vertical: DS.sm),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: highlighted ? FontWeight.bold : FontWeight.w500,
            color: DS.onSurface,
          ),
        ),
      ),
    );
  }
}

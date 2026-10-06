import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart'
    show GlassContainer, GlassQuality;

import '../../../services/notification_service.dart';
import '../../../services/storage_service.dart';
import '../../../theme/app_design_system.dart';
import '../../../theme/glass_materials.dart';

/// 显示提醒设置对话框（滚动选择器）
///
/// 玻璃哲学：底部弹起的玻璃是"托盘"，时间滚轮是托盘上的内容——
/// 托盘用真玻璃材质（独立路由无父图层，`useOwnLayer: true`），
/// 滚轮保持原生不玻璃化。关闭态保留原白底样式，零视觉漂移。
Future<void> showReminderDialog(BuildContext context) async {
  final storage = StorageService.instance;
  int selectedHour =
      int.tryParse(storage.getString('reminderHour') ?? '') ?? 20;
  int selectedMinute =
      int.tryParse(storage.getString('reminderMinute') ?? '') ?? 0;
  selectedMinute = (selectedMinute ~/ 5) * 5;

  final hourController = FixedExtentScrollController(initialItem: selectedHour);
  final minuteController =
      FixedExtentScrollController(initialItem: selectedMinute ~/ 5);

  await showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    elevation: 0,
    isScrollControlled: true,
    builder: (context) {
      if (!shouldUseLiquidGlass(context)) {
        // 关闭态：原样保留（白底 + 顶部圆角）
        return Container(
          height: 360,
          decoration: BoxDecoration(
            color: DS.surfaceContainerLowest,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(DS.radiusMd)),
          ),
          child: _buildContent(
              context,
              storage,
              hourController,
              minuteController,
              () => selectedHour,
              (v) => selectedHour = v,
              () => selectedMinute,
              (v) => selectedMinute = v,
              false),
        );
      }

      // 开启态：悬浮玻璃托盘
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(DS.sm),
          child: GlassContainer(
            shape: GlassMaterials.shape(24),
            settings: GlassMaterials.bar(),
            quality: GlassQuality.premium,
            useOwnLayer: true,
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(DS.md, DS.sm, DS.md, DS.xs),
            child: SizedBox(
              height: 360,
              child: _buildContent(
                  context,
                  storage,
                  hourController,
                  minuteController,
                  () => selectedHour,
                  (v) => selectedHour = v,
                  () => selectedMinute,
                  (v) => selectedMinute = v,
                  true),
            ),
          ),
        ),
      );
    },
  );
}

Widget _buildContent(
  BuildContext context,
  StorageService storage,
  FixedExtentScrollController hourController,
  FixedExtentScrollController minuteController,
  int Function() getHour,
  ValueChanged<int> setHour,
  int Function() getMinute,
  ValueChanged<int> setMinute,
  bool glass,
) {
  final Color separator = glass
      ? (DS.isDark
          ? Colors.white.withOpacity(0.12)
          : Colors.black.withOpacity(0.08))
      : DS.outlineVariant;

  final TextStyle wheelStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: glass ? DS.onSurface : DS.onSurface,
  );

  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Padding(
        padding: EdgeInsets.symmetric(horizontal: DS.sm, vertical: DS.sm),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _TopAction(
              label: '关闭提醒',
              color: glass ? const Color(0xFFFF6B6B) : DS.error,
              onTap: () async {
                try {
                  await NotificationService.instance.cancelDailyReminder();
                  storage.setString('reminderHour', '');
                  storage.setString('reminderMinute', '');
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('已关闭记账提醒'),
                          backgroundColor: DS.secondary),
                    );
                  }
                } catch (_) {}
              },
            ),
            Text(
              '设置提醒时间',
              style: glass
                  ? DS.headlineSm.copyWith(color: DS.onSurface)
                  : DS.headlineSm,
            ),
            _TopAction(
              label: '确定',
              highlighted: true,
              color: glass ? DS.onSurface : DS.onSurface,
              onTap: () async {
                try {
                  await NotificationService.instance.scheduleDailyReminder(
                    hour: getHour(),
                    minute: getMinute(),
                  );
                  storage.setString('reminderHour', getHour().toString());
                  storage.setString('reminderMinute', getMinute().toString());
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            '已设置每日 ${getHour().toString().padLeft(2, '0')}:${getMinute().toString().padLeft(2, '0')} 提醒'),
                        backgroundColor: DS.secondary,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('设置失败：$e'), backgroundColor: DS.error),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
      Divider(height: 1, color: separator),
      Expanded(
        child: Row(
          children: [
            Expanded(
              child: ListWheelScrollView.useDelegate(
                controller: hourController,
                itemExtent: 44,
                physics: const FixedExtentScrollPhysics(),
                onSelectedItemChanged: (i) => setHour(i),
                childDelegate: ListWheelChildBuilderDelegate(
                  builder: (context, index) {
                    if (index < 0 || index > 23) return null;
                    return Center(
                      child: Text(
                        '${index.toString().padLeft(2, '0')} 时',
                        style: wheelStyle,
                      ),
                    );
                  },
                ),
              ),
            ),
            Text(
              ':',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: glass ? DS.onSurface : DS.onSurface,
              ),
            ),
            Expanded(
              child: ListWheelScrollView.useDelegate(
                controller: minuteController,
                itemExtent: 44,
                physics: const FixedExtentScrollPhysics(),
                onSelectedItemChanged: (i) => setMinute(i * 5),
                childDelegate: ListWheelChildBuilderDelegate(
                  builder: (context, index) {
                    if (index < 0 || index > 11) return null;
                    return Center(
                      child: Text(
                        '${(index * 5).toString().padLeft(2, '0')} 分',
                        style: wheelStyle,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      Padding(
        padding: EdgeInsets.all(DS.sm),
        child: GestureDetector(
          onTap: () async {
            try {
              const channel = MethodChannel('bear_bill/alarm');
              await channel.invokeMethod('openBatterySettings');
            } catch (_) {}
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.battery_alert,
                size: 14,
                color: glass ? DS.onSurfaceVariant : DS.primaryContainer,
              ),
              SizedBox(width: DS.xs),
              Text(
                '提醒不生效？点击关闭电池优化',
                style: DS.labelSm.copyWith(
                  color: glass ? DS.onSurfaceVariant : DS.primaryContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

/// 玻璃托盘顶部的文字按钮（关闭提醒 / 确定）
class _TopAction extends StatelessWidget {
  const _TopAction({
    required this.label,
    required this.onTap,
    this.highlighted = false,
    this.color,
  });

  final String label;
  final VoidCallback onTap;
  final bool highlighted;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: DS.xs, vertical: DS.sm),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: highlighted ? FontWeight.bold : FontWeight.w500,
            color: color ?? DS.onSurface,
          ),
        ),
      ),
    );
  }
}

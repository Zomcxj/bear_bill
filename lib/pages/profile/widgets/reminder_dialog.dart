import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../services/notification_service.dart';
import '../../../services/storage_service.dart';
import '../../../theme/app_design_system.dart';

/// 显示提醒设置对话框（滚动选择器）
Future<void> showReminderDialog(BuildContext context) async {
  final storage = StorageService.instance;
  int selectedHour = int.tryParse(storage.getString('reminderHour') ?? '') ?? 20;
  int selectedMinute = int.tryParse(storage.getString('reminderMinute') ?? '') ?? 0;
  selectedMinute = (selectedMinute ~/ 5) * 5;

  final hourController = FixedExtentScrollController(initialItem: selectedHour);
  final minuteController = FixedExtentScrollController(initialItem: selectedMinute ~/ 5);

  await showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => Container(
      height: 360,
      decoration: BoxDecoration(
        color: DS.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(DS.radiusMd)),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: DS.sm, vertical: DS.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () async {
                    try {
                      await NotificationService.instance.cancelDailyReminder();
                      storage.setString('reminderHour', '');
                      storage.setString('reminderMinute', '');
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('已关闭记账提醒'), backgroundColor: DS.secondary),
                        );
                      }
                    } catch (_) {}
                  },
                  child: Text('关闭提醒', style: TextStyle(color: DS.error)),
                ),
                Text('设置提醒时间', style: DS.headlineSm),
                TextButton(
                  onPressed: () async {
                    try {
                      await NotificationService.instance.scheduleDailyReminder(
                        hour: selectedHour,
                        minute: selectedMinute,
                      );
                      storage.setString('reminderHour', selectedHour.toString());
                      storage.setString('reminderMinute', selectedMinute.toString());
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('已设置每日 ${selectedHour.toString().padLeft(2, '0')}:${selectedMinute.toString().padLeft(2, '0')} 提醒'),
                            backgroundColor: DS.secondary,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('设置失败：$e'), backgroundColor: DS.error),
                        );
                      }
                    }
                  },
                  child: Text('确定'),
                ),
              ],
            ),
          ),
          Divider(height: 1),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: ListWheelScrollView.useDelegate(
                    controller: hourController,
                    itemExtent: 44,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (i) => selectedHour = i,
                    childDelegate: ListWheelChildBuilderDelegate(
                      builder: (context, index) {
                        if (index < 0 || index > 23) return null;
                        return Center(
                          child: Text(
                            '${index.toString().padLeft(2, '0')} 时',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Text(':', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Expanded(
                  child: ListWheelScrollView.useDelegate(
                    controller: minuteController,
                    itemExtent: 44,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (i) => selectedMinute = i * 5,
                    childDelegate: ListWheelChildBuilderDelegate(
                      builder: (context, index) {
                        if (index < 0 || index > 11) return null;
                        return Center(
                          child: Text(
                            '${(index * 5).toString().padLeft(2, '0')} 分',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
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
                  Icon(Icons.battery_alert, size: 14, color: DS.primaryContainer),
                  SizedBox(width: DS.xs),
                  Text('提醒不生效？点击关闭电池优化', style: DS.labelSm.copyWith(color: DS.primaryContainer)),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'database_service.dart';

/// 本地通知服务 - 记账提醒
/// 调度使用原生 Android AlarmManager（兼容 vivo 等国产 ROM）
/// 显示使用 flutter_local_notifications
class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static const MethodChannel _alarmChannel = MethodChannel('bear_bill/alarm');
  bool _isInitialized = false;

  /// 初始化通知服务
  Future<void> init() async {
    if (_isInitialized) return;

    // 初始化时区数据
    tz.initializeTimeZones();

    // 设置本地时区
    try {
      final offset = DateTime.now().timeZoneOffset.inHours;
      final tzMap = {
        8: 'Asia/Shanghai',
        9: 'Asia/Tokyo',
        7: 'Asia/Bangkok',
        0: 'UTC',
      };
      final tzName = tzMap[offset] ?? 'Asia/Shanghai';
      tz.setLocalLocation(tz.getLocation(tzName));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));
    }

    // Android 初始化配置
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initSettings);

    // 预创建通知渠道
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'daily_reminder',
          '每日记账提醒',
          description: '提醒你每天记录账单',
          importance: Importance.high,
          enableVibration: true,
          enableLights: true,
        ),
      );
    }

    _isInitialized = true;
  }

  /// 请求通知权限（Android 13+）
  Future<bool> requestPermission() async {
    try {
      final status = await Permission.notification.request();
      return status.isGranted;
    } catch (_) {
      return false;
    }
  }

  /// 设置每日记账提醒（通过原生 AlarmManager 调度）
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    await init();

    // 检查通知权限
    final hasPermission = await requestPermission();
    if (!hasPermission) {
      throw Exception('通知权限被拒绝，请在系统设置中允许通知');
    }

    // 请求精确闹钟权限（Android 12+）
    try {
      await Permission.scheduleExactAlarm.request();
    } catch (_) {}

    try {
      // 通过原生 AlarmManager 调度（兼容 vivo 等国产 ROM）
      await _alarmChannel.invokeMethod('scheduleAlarm', {
        'hour': hour,
        'minute': minute,
      });
    } catch (e) {
      throw Exception('设置提醒失败: $e');
    }
  }

  /// 取消每日提醒
  Future<void> cancelDailyReminder() async {
    await init();
    try {
      await _alarmChannel.invokeMethod('cancelAlarm');
    } catch (_) {}
    try {
      await _notifications.cancel(0);
    } catch (_) {}
    try {
      await _notifications.cancelAll();
    } catch (_) {}
  }

  /// 检查是否已设置提醒
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    await init();
    return await _notifications.pendingNotificationRequests();
  }

  /// 更新今日记账摘要（闹钟触发时显示总结）
  Future<void> updateTodaySummary({
    required int count,
    required double expense,
    required double income,
  }) async {
    try {
      await _alarmChannel.invokeMethod('updateTodaySummary', {
        'count': count,
        'expense': expense,
        'income': income,
      });
    } catch (_) {}
  }

  /// 自动计算今日记录并更新摘要（记账/删账后调用）
  Future<void> refreshTodaySummary() async {
    try {
      final records = await DatabaseService.instance.getTodayRecords();
      double expense = 0;
      double income = 0;
      for (final r in records) {
        if (r.type == 'expense') {
          expense += r.amount;
        } else {
          income += r.amount;
        }
      }
      await updateTodaySummary(
        count: records.length,
        expense: expense,
        income: income,
      );
    } catch (_) {}
  }

  /// 立即发送测试通知（显示真实今日内容）
  Future<void> showTestNotification() async {
    await init();

    // 获取今日数据
    final records = await DatabaseService.instance.getTodayRecords();
    double expense = 0;
    double income = 0;
    for (final r in records) {
      if (r.type == 'expense') {
        expense += r.amount;
      } else {
        income += r.amount;
      }
    }

    final String title;
    final String content;
    if (records.isNotEmpty) {
      title = '🐼 今日记账总结';
      final parts = <String>[];
      parts.add('${records.length}笔记录');
      if (expense > 0) parts.add('支出¥${expense.toStringAsFixed(0)}');
      if (income > 0) parts.add('收入¥${income.toStringAsFixed(0)}');
      final suffix = expense >= 5000
          ? '简直壕气！💰'
          : expense >= 1000
              ? '太有实力了！💪'
              : expense >= 500
                  ? '花得不少呢～😅'
                  : expense > 0
                      ? '继续保持～'
                      : '今天没有支出，攒钱达人！🌟';
      content = '${parts.join('，')}。$suffix';
    } else {
      title = '🐼 记账提醒';
      content = '今天还没记账哦，快来记录一笔吧～';
    }

    const androidDetails = AndroidNotificationDetails(
      'test_channel',
      '测试通知',
      channelDescription: '用于测试通知功能',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_notification',
      color: Color(0xFFFF8FAB),
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _notifications.show(
      999,
      title,
      content,
      notificationDetails,
    );
  }
}

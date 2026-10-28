import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import 'database_service.dart';

/// Local notification service - record reminders
/// Uses the native Android AlarmManager for scheduling and flutter_local_notifications for display
class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  static const MethodChannel _alarmChannel = MethodChannel('bear_bill/alarm');

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  /// Initialize the notification service
  Future<void> init() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _notifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

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

  /// Request notification permission (Android 13+)
  Future<bool> requestPermission() async {
    try {
      final status = await Permission.notification.request();
      return status.isGranted;
    } catch (_) {
      return false;
    }
  }

  /// Schedule the daily record reminder (dispatched through the native AlarmManager)
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    await init();

    final hasPermission = await requestPermission();
    if (!hasPermission) {
      throw Exception('通知权限被拒绝，请在系统设置中允许通知');
    }

    try {
      await Permission.scheduleExactAlarm.request();
    } catch (_) {}

    try {
      await _alarmChannel.invokeMethod('scheduleAlarm', {
        'hour': hour,
        'minute': minute,
      });
    } catch (e) {
      throw Exception('设置提醒失败: $e');
    }
  }

  /// Cancel the daily reminder
  Future<void> cancelDailyReminder() async {
    await init();
    await _alarmChannel.invokeMethod('cancelAlarm');
  }

  /// Check whether a reminder is already scheduled
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    await init();
    return await _notifications.pendingNotificationRequests();
  }

  /// Update today's record summary (shown when the alarm fires)
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

  /// Compute today's records and update the summary (called after adding or deleting a record)
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

  /// Send a test notification immediately
  Future<void> showTestNotification() async {
    await init();

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
      if (expense > 0) parts.add('支出¥${expense.toStringAsFixed(2)}');
      if (income > 0) parts.add('收入¥${income.toStringAsFixed(2)}');
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

    await _notifications.show(
      999,
      title,
      content,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'test_channel',
          '测试通知',
          channelDescription: '用于测试通知功能',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_notification',
          color: Color(0xFFFF8FAB),
          visibility: NotificationVisibility.secret,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  /// Show the monthly financial summary notification
  Future<void> showMonthlySummary() async {
    await init();

    // Get last month's month string
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1);
    final monthStr =
        '${lastMonth.year}-${lastMonth.month.toString().padLeft(2, '0')}';
    final monthLabel = '${lastMonth.month}月';

    final stats = await DatabaseService.instance.getMonthStatistics(monthStr);
    final expense = stats['expense'] as double? ?? 0.0;
    final income = stats['income'] as double? ?? 0.0;
    final balance = income - expense;
    final categories = stats['categories'] as List? ?? [];
    final records = stats['records'] as List? ?? [];

    if (records.isEmpty) return; // No records last month, so skip the notification

    // Get the top category
    String topCatText = '';
    if (categories.isNotEmpty) {
      final top = categories.first;
      final amount = top['amount'] as double;
      final percent = expense > 0 ? (amount / expense * 100).toStringAsFixed(0) : '0';
      topCatText = '，${top['icon']}${top['name']}占比$percent%';
    }

    // Build the summary content
    final parts = <String>[];
    parts.add('支出¥${expense.toStringAsFixed(0)}');
    parts.add('收入¥${income.toStringAsFixed(0)}');
    if (balance >= 0) {
      parts.add('结余¥${balance.toStringAsFixed(0)}');
    } else {
      parts.add('超支¥${(-balance).toStringAsFixed(0)}');
    }

    final suffix = balance > 0
        ? '攒钱达人！'
        : balance == 0
            ? '收支平衡～'
            : '下月加油～';

    final content = '$monthLabel${parts.join('，')}$topCatText$suffix';

    await _notifications.show(
      888,
      '📊 $monthLabel财务简报',
      content,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'monthly_summary',
          '月度财务简报',
          channelDescription: '每月1日推送上月财务摘要',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_notification',
          color: Color(0xFFFF8FAB),
          visibility: NotificationVisibility.secret,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}

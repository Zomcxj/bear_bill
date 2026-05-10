import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

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

  /// 标记今日已记账（闹钟触发时会跳过提醒）
  Future<void> markRecordedToday() async {
    try {
      await _alarmChannel.invokeMethod('markRecordedToday');
    } catch (_) {}
  }

  /// 立即发送测试通知（使用 flutter_local_notifications，已验证可用）
  Future<void> showTestNotification() async {
    await init();

    const androidDetails = AndroidNotificationDetails(
      'test_channel',
      '测试通知',
      channelDescription: '用于测试通知功能',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_notification',
      color: Color(0xFFFF8FAB), // 硬编码：通知颜色不随主题变化（系统通知栏无法实时更新）
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _notifications.show(
      999,
      '🐻 测试通知',
      '通知功能正常工作！',
      notificationDetails,
    );
  }
}

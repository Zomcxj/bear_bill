import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/models.dart';
import 'database_service.dart';
import 'glm_service.dart';
import 'notification_service.dart';

/// 自动记账服务 - 处理微信/支付宝支付通知
class AutoRecordService {
  static final AutoRecordService instance = AutoRecordService._();
  AutoRecordService._();

  static const MethodChannel _channel = MethodChannel('bear_bill/auto_record');
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _handlerSet = false;

  /// 初始化自动记账服务（App 启动时调用）
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // 创建通知渠道
    await _notifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );

    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'auto_record',
          '自动记账',
          description: '自动记账确认通知',
          importance: Importance.high,
        ),
      );
    }

    // 注册 MethodChannel 回调，接收原生 NotificationListenerService 推送
    _setupMethodCallHandler();
  }

  /// 注册 MethodChannel 回调（只注册一次）
  void _setupMethodCallHandler() {
    if (_handlerSet) return;
    _handlerSet = true;

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onPaymentNotification') {
        // 检查自动记账开关（原生端因跨进程无法读取，由 Flutter 端判断）
        final enabled = await isAutoRecordEnabled();
        if (!enabled) {
          if (kDebugMode) print('自动记账: 开关未开启，忽略通知');
          return;
        }

        final data = Map<String, dynamic>.from(call.arguments);
        final title = data['title'] as String? ?? '';
        final text = data['text'] as String? ?? '';
        final source = data['source'] as String? ?? '';

        if (kDebugMode) print('自动记账: 收到推送通知 [$title] $text');
        await _processPaymentNotification(title, text, source);
      }
    });

    if (kDebugMode) print('自动记账: MethodChannel 回调已注册');
  }

  /// 检查自动记账是否已启用（通过 MethodChannel 读取原生 SharedPreferences）
  Future<bool> isAutoRecordEnabled() async {
    try {
      final result = await _channel.invokeMethod<bool>('getAutoRecordEnabled');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// 设置自动记账开关（通过 MethodChannel 写入原生 SharedPreferences）
  Future<void> setAutoRecordEnabled(bool enabled) async {
    try {
      await _channel.invokeMethod('setAutoRecordEnabled', {'enabled': enabled});
    } catch (_) {}
  }

  /// 处理支付通知
  Future<void> _processPaymentNotification(
    String title,
    String text,
    String source,
  ) async {
    if (kDebugMode) print('处理支付通知: [$title] $text (来源: $source)');

    // 使用 GLM 或本地解析
    final input = '$title $text';
    final result = await GlmService.instance.parseUserInput(input);

    if (!result.isRecord) {
      if (kDebugMode) print('通知解析失败，无法识别为记账');
      return;
    }

    // 创建记录
    final category = getCategoryById(
      result.categoryId!,
      isExpense: result.type == 'expense',
    );

    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final record = RecordModel(
      id: '${now.millisecondsSinceEpoch}_auto',
      bookId: 'default',
      type: result.type ?? 'expense',
      amount: result.amount!,
      categoryId: result.categoryId!,
      categoryName: category?.name ?? '其他',
      categoryIcon: category?.icon ?? '📦',
      categoryColor: category?.color,
      remark: result.remark ?? '自动记账',
      date: dateStr,
      month: dateStr.substring(0, 7),
      dateTs: now.millisecondsSinceEpoch,
      createdAt: now,
    );

    await DatabaseService.instance.insertRecord(record);
    NotificationService.instance.refreshTodaySummary();

    // 发送确认通知
    await _showAutoRecordNotification(record, source);

    if (kDebugMode) print('自动记账成功: ${record.categoryName} ¥${record.amount}');
  }

  /// 显示自动记账确认通知
  Future<void> _showAutoRecordNotification(
    RecordModel record,
    String source,
  ) async {
    final sourceLabel = source == 'wechat' ? '微信' : source == 'alipay' ? '支付宝' : '银行';
    final sign = record.type == 'expense' ? '-' : '+';

    await _notifications.show(
      777,
      '🐻 自动记账',
      '$sourceLabel ${record.categoryName} $sign¥${record.amount.toStringAsFixed(2)}',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'auto_record',
          '自动记账',
          channelDescription: '自动记账确认通知',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_notification',
          color: Color(0xFFFF8FAB),
        ),
      ),
    );
  }

  /// 检查通知监听权限是否已授予
  Future<bool> isNotificationListenerEnabled() async {
    try {
      final result = await _channel.invokeMethod<bool>('isListenerEnabled');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// 打开通知监听设置页面
  Future<void> openNotificationListenerSettings() async {
    try {
      await _channel.invokeMethod('openListenerSettings');
    } catch (_) {
      // ignore
    }
  }

  /// 检查无障碍服务是否已授予
  Future<bool> isAccessibilityEnabled() async {
    try {
      final result = await _channel.invokeMethod<bool>('isAccessibilityEnabled');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// 打开无障碍设置页面
  Future<void> openAccessibilitySettings() async {
    try {
      await _channel.invokeMethod('openAccessibilitySettings');
    } catch (_) {
      // ignore
    }
  }
}

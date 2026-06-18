import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  bool _isPolling = false;
  Timer? _pollTimer;

  /// 初始化自动记账服务
  Future<void> init() async {
    // 监听来自原生的广播
    _channel.setMethodCallHandler(_handleMethodCall);

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
  }

  /// 开始轮询通知
  void startPolling() {
    if (_isPolling) return;
    _isPolling = true;
    _pollTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _checkPendingNotification(),
    );
  }

  /// 停止轮询
  void stopPolling() {
    _isPolling = false;
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    if (call.method == 'onNotificationReceived') {
      final title = call.arguments['title'] as String? ?? '';
      final text = call.arguments['text'] as String? ?? '';
      final source = call.arguments['source'] as String? ?? '';
      await _processPaymentNotification(title, text, source);
    }
  }

  /// 检查 SharedPreferences 中的待处理通知
  Future<void> _checkPendingNotification() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('pending_notification');
      if (jsonStr == null) return;

      // 清除已读通知
      await prefs.remove('pending_notification');

      final data = jsonDecode(jsonStr);
      final title = data['title'] as String? ?? '';
      final text = data['text'] as String? ?? '';
      final source = data['source'] as String? ?? '';
      final timestamp = data['timestamp'] as int? ?? 0;

      // 忽略超过 30 秒的通知
      if (DateTime.now().millisecondsSinceEpoch - timestamp > 30000) return;

      await _processPaymentNotification(title, text, source);
    } catch (e) {
      if (kDebugMode) print('检查通知失败: $e');
    }
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
    final sourceLabel = source == 'wechat' ? '微信' : '支付宝';
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
}

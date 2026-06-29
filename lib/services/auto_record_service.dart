import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/models.dart';
import 'database_service.dart';
import 'glm_service.dart';
import 'notification_service.dart';

/// 自动记账检测结果（用于弹窗确认）
class AutoRecordCandidate {
  final RecordModel record;
  final String source;
  final String rawText;

  AutoRecordCandidate({
    required this.record,
    required this.source,
    required this.rawText,
  });
}

/// 自动记账服务 - 处理微信/支付宝支付通知
class AutoRecordService {
  static final AutoRecordService instance = AutoRecordService._();
  AutoRecordService._();

  static const MethodChannel _channel = MethodChannel('bear_bill/auto_record');
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _handlerSet = false;
  String? _lastProcessedFingerprint;
  DateTime? _lastProcessedAt;

  /// 待确认的候选记录（检测到支付后暂存）
  AutoRecordCandidate? _pendingCandidate;
  AutoRecordCandidate? get pendingCandidate => _pendingCandidate;

  /// 检测到支付后，通过 stream 通知 UI 弹窗确认
  final StreamController<AutoRecordCandidate> _candidateController =
      StreamController<AutoRecordCandidate>.broadcast();
  Stream<AutoRecordCandidate> get onCandidateDetected =>
      _candidateController.stream;

  /// 初始化自动记账服务（App 启动时调用）
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // 创建通知渠道
    await _notifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (details) {
        // 用户点击了自动记账确认通知 → 弹出确认弹窗
        if (_pendingCandidate != null) {
          _candidateController.add(_pendingCandidate!);
        }
      },
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

    // 检查是否有暂存的支付数据（app 在后台时原生端存的）
    _checkPendingPayment();
  }

  /// 检查暂存的支付数据（公开方法，app 回前台时调用）
  Future<void> checkPendingPayment() async {
    await _checkPendingPayment();
  }

  /// 检查暂存的支付数据
  Future<void> _checkPendingPayment() async {
    try {
      final result = await _channel.invokeMethod<Map>('getPendingPayment');
      if (result != null && result.isNotEmpty) {
        final title = result['title'] as String? ?? '';
        final text = result['text'] as String? ?? '';
        final source = result['source'] as String? ?? '';
        if (title.isNotEmpty || text.isNotEmpty) {
          final enabled = await isAutoRecordEnabled();
          if (!enabled) {
            if (kDebugMode) print('自动记账: 开关未开启，忽略暂存支付数据');
            return;
          }
          if (kDebugMode) print('自动记账: 发现暂存支付数据 [$title] $text');
          await _processPaymentNotification(title, text, source);
        }
      }
    } catch (e) {
      if (kDebugMode) print('自动记账: 检查暂存数据失败: $e');
    }
  }

  /// 打开编辑页面的回调（用于通知点击跳转）
  Function(String title, String text, String source)? onOpenEditPage;

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
      } else if (call.method == 'openEditPage') {
        // 通知点击跳转编辑页面
        final data = Map<String, dynamic>.from(call.arguments);
        final title = data['title'] as String? ?? '';
        final text = data['text'] as String? ?? '';
        final source = data['source'] as String? ?? '';

        if (kDebugMode) print('自动记账: 跳转编辑页面 [$title] $text');
        onOpenEditPage?.call(title, text, source);
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

  /// 处理支付通知：解析为候选记录，由用户确认后在记账页保存
  Future<void> _processPaymentNotification(
    String title,
    String text,
    String source,
  ) async {
    if (kDebugMode) print('处理支付通知: [$title] $text (来源: $source)');

    final fingerprint = '$source|$title|$text';
    final now = DateTime.now();
    if (_lastProcessedFingerprint == fingerprint &&
        _lastProcessedAt != null &&
        now.difference(_lastProcessedAt!).inSeconds < 30) {
      if (kDebugMode) print('自动记账: 重复通知，已忽略');
      return;
    }
    _lastProcessedFingerprint = fingerprint;
    _lastProcessedAt = now;

    // 支付通知优先使用本地解析，避免自动记账依赖网络和 API 配额
    final input = '$title $text';
    var result = _parsePaymentLocally(title, text);
    result ??= await GlmService.instance.parseUserInput(input);

    if (!result.isRecord) {
      if (kDebugMode) print('通知解析失败，无法识别为记账');
      await _showDetectionFailedNotification(input);
      return;
    }

    // 获取当前账本 ID
    final books = await DatabaseService.instance.getAllBooks();
    final bookId = books.isNotEmpty ? books.first.id : 'default';

    final type = result.type ?? 'expense';

    // 创建候选记录。这里只预填，不直接入库，避免误识别生成脏账单。
    final category = getCategoryById(
      result.categoryId ?? (type == 'income' ? 'other_in' : 'other'),
      isExpense: type == 'expense',
    );

    final recordDate = result.resolvedDate;
    final dateStr =
        '${recordDate.year}-${recordDate.month.toString().padLeft(2, '0')}-${recordDate.day.toString().padLeft(2, '0')}';

    final record = RecordModel(
      id: '${now.millisecondsSinceEpoch}_auto',
      bookId: bookId,
      type: type,
      amount: result.amount!,
      categoryId: category?.id ?? (type == 'income' ? 'other_in' : 'other'),
      categoryName: category?.name ?? '其他',
      categoryIcon: category?.icon ?? (type == 'income' ? '💰' : '📦'),
      categoryColor: category?.color,
      remark: result.remark ?? '自动记账',
      date: dateStr,
      month: dateStr.substring(0, 7),
      dateTs: recordDate.millisecondsSinceEpoch,
      createdAt: now,
    );

    _pendingCandidate = AutoRecordCandidate(
      record: record,
      source: source,
      rawText: input,
    );
    _candidateController.add(_pendingCandidate!);

    if (kDebugMode) {
      print('自动记账候选: ${record.categoryName} ¥${record.amount}');
    }
  }

  AiParseResult? _parsePaymentLocally(
    String title,
    String text,
  ) {
    final input = '$title $text'.trim();
    final amount = _extractAmount(input);
    if (amount == null || amount <= 0) return null;

    final type = _detectPaymentType(input);
    final categoryId = _detectPaymentCategory(input, type);
    final remark = _extractPaymentRemark(title, text);

    return AiParseResult(
      intent: 'record',
      type: type,
      amount: amount,
      categoryId: categoryId,
      remark: remark,
    );
  }

  double? _extractAmount(String input) {
    final patterns = [
      RegExp(r'[¥￥]\s*(\d+(?:\.\d{1,2})?)'),
      RegExp(r'(?:支出|消费|付款|支付|扣款|收入|到账|转入|收款)\s*[¥￥]?\s*(\d+(?:\.\d{1,2})?)'),
      RegExp(r'(\d+(?:\.\d{1,2})?)\s*元'),
      RegExp(r'金额\s*[¥￥]?\s*(\d+(?:\.\d{1,2})?)'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(input);
      if (match == null) continue;
      final amount = double.tryParse(match.group(1) ?? '');
      if (amount != null && amount > 0 && amount < 1000000) {
        return amount;
      }
    }
    return null;
  }

  String _detectPaymentType(String input) {
    final incomeKeywords = ['收入', '到账', '转入', '收款', '存入', '退款', '退回'];
    if (incomeKeywords.any(input.contains)) return 'income';
    return 'expense';
  }

  String _detectPaymentCategory(String input, String type) {
    if (type == 'income') {
      if (input.contains('工资') || input.contains('薪')) return 'salary';
      if (input.contains('奖金') || input.contains('年终')) return 'bonus';
      if (input.contains('理财') || input.contains('利息')) return 'invest';
      if (input.contains('红包')) return 'red_packet';
      if (input.contains('转入') || input.contains('转账')) return 'transfer';
      return 'other_in';
    }

    final keywordMap = <String, List<String>>{
      'food': ['餐', '饭', '外卖', '食堂', '火锅', '烧烤', '餐厅', '美团', '饿了么'],
      'milk_tea': ['奶茶', '咖啡', '星巴克', '瑞幸', '饮料'],
      'transport': ['打车', '地铁', '公交', '高铁', '火车', '机票', '加油', '停车', '滴滴'],
      'shopping': ['超市', '商场', '淘宝', '京东', '拼多多', '购物'],
      'housing': ['水费', '电费', '燃气', '物业', '房租', '宽带'],
      'health': ['医院', '药', '挂号', '体检'],
      'entertainment': ['电影', '游戏', '会员', '娱乐'],
      'red_packet': ['红包'],
      'transfer': ['转账', '转出'],
    };

    for (final entry in keywordMap.entries) {
      if (entry.value.any(input.contains)) return entry.key;
    }
    return 'other';
  }

  String? _extractPaymentRemark(String title, String text) {
    final raw = '$title $text'
        .replaceAll(RegExp(r'[¥￥]?\d+(?:\.\d{1,2})?\s*元?'), '')
        .replaceAll(
            RegExp(r'(支付成功|付款成功|交易成功|消费|支出|收入|到账|扣款|你有一笔|点击查看详情|通知)'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (raw.isEmpty) return '自动记账';
    return raw.length > 24 ? raw.substring(0, 24) : raw;
  }

  /// 用户确认后写入数据库
  Future<void> confirmRecord(RecordModel record) async {
    try {
      await DatabaseService.instance.insertRecord(record);
      NotificationService.instance.refreshTodaySummary();
      _pendingCandidate = null;
      if (kDebugMode) print('自动记账确认: ${record.categoryName} ¥${record.amount}');
    } catch (e) {
      if (kDebugMode) print('自动记账写入失败: $e');
      rethrow;
    }
  }

  /// 用户取消
  void dismissRecord() {
    _pendingCandidate = null;
    if (kDebugMode) print('自动记账: 用户取消');
  }

  /// 模拟支付通知（测试用）
  Future<void> simulatePayment({
    String title = '微信支付',
    String text = '支付成功 ¥25.00 瑞幸咖啡',
    String source = 'wechat',
  }) async {
    if (kDebugMode) print('自动记账: 模拟支付 [$title] $text');
    await _processPaymentNotification(title, text, source);
  }

  /// 显示检测失败通知
  Future<void> _showDetectionFailedNotification(String rawText) async {
    await _notifications.show(
      778,
      '🐻 检测到支付但无法识别',
      '原始内容: ${rawText.length > 50 ? rawText.substring(0, 50) : rawText}...',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'auto_record',
          '自动记账',
          channelDescription: '自动记账确认通知',
          importance: Importance.low,
          priority: Priority.low,
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

  /// 检查通知监听服务是否在运行
  Future<bool> isNotificationListenerRunning() async {
    try {
      final result = await _channel.invokeMethod<bool>('isListenerRunning');
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
      final result =
          await _channel.invokeMethod<bool>('isAccessibilityEnabled');
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

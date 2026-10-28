import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import 'database_service.dart';
import 'glm_service.dart';
import 'notification_service.dart';

/// Auto-record detection result (used for the confirmation dialog)
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

/// Auto-record service - handles WeChat/Alipay payment notifications
class AutoRecordService {
  static final AutoRecordService instance = AutoRecordService._();
  AutoRecordService._();

  static const MethodChannel _channel = MethodChannel('bear_bill/auto_record');
  static const _lastFingerprintKey = 'auto_record_last_fingerprint';
  static const _lastProcessedAtKey = 'auto_record_last_processed_at';
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _handlerSet = false;
  String? _lastProcessedFingerprint;
  DateTime? _lastProcessedAt;

  /// Candidate record awaiting confirmation (held after a payment is detected)
  AutoRecordCandidate? _pendingCandidate;
  DateTime? _pendingCandidateAt;
  Timer? _alipayEmitTimer;
  AutoRecordCandidate? get pendingCandidate => _pendingCandidate;

  /// Notifies the UI through a stream after a payment is detected, so it can show the confirmation dialog
  final StreamController<AutoRecordCandidate> _candidateController =
      StreamController<AutoRecordCandidate>.broadcast();
  Stream<AutoRecordCandidate> get onCandidateDetected =>
      _candidateController.stream;

  /// Initialize the auto-record service (called on app start)
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Create the notification channel
    await _notifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (details) {
        // The user tapped the auto-record confirmation notification → show the confirmation dialog
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

    // Register the MethodChannel callback that receives pushes from the native NotificationListenerService
    _setupMethodCallHandler();

    // Check for a pending payment payload (stored natively while the app was in the background)
    _checkPendingPayment();
  }

  /// Check for a pending payment payload (public method, called when the app returns to the foreground)
  Future<void> checkPendingPayment() async {
    await _checkPendingPayment();
  }

  /// Check for a pending payment payload
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

  /// Register the MethodChannel callback (registered only once)
  void _setupMethodCallHandler() {
    if (_handlerSet) return;
    _handlerSet = true;

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onPaymentNotification') {
        // Check the auto-record switch (the native side cannot read it across processes, so Flutter decides)
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
        // Legacy native entry points all route back to auto-record parsing, so tapping a notification cannot produce a wrong record through coarse parsing.
        final data = Map<String, dynamic>.from(call.arguments);
        final title = data['title'] as String? ?? '';
        final text = data['text'] as String? ?? '';
        final source = data['source'] as String? ?? '';

        if (kDebugMode) print('自动记账: 点击通知 [$title] $text');
        await _processPaymentNotification(title, text, source);
      }
    });

    if (kDebugMode) print('自动记账: MethodChannel 回调已注册');
  }

  /// Check whether auto-record is enabled (reads the native SharedPreferences through MethodChannel)
  Future<bool> isAutoRecordEnabled() async {
    try {
      final result = await _channel.invokeMethod<bool>('getAutoRecordEnabled');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Set the auto-record switch (writes the native SharedPreferences through MethodChannel)
  Future<void> setAutoRecordEnabled(bool enabled) async {
    try {
      await _channel.invokeMethod('setAutoRecordEnabled', {'enabled': enabled});
    } catch (_) {}
  }

  /// Handle a payment notification: parse it into a candidate record, saved on the add-record page once the user confirms
  Future<void> _processPaymentNotification(
    String title,
    String text,
    String source,
  ) async {
    if (kDebugMode) print('处理支付通知: [$title] $text (来源: $source)');

    final fingerprint = '$source|$title|$text';
    final now = DateTime.now();
    if (await _isDuplicate(fingerprint, now)) {
      if (kDebugMode) print('自动记账: 重复通知，已忽略');
      return;
    }

    // Parse payment notifications locally first, so auto-record does not depend on the network or API quota
    final input = '$title $text';
    var result = _parsePaymentLocally(title, text);
    result ??= await GlmService.instance.parseUserInput(input);

    if (!result.isRecord) {
      if (kDebugMode) print('通知解析失败，无法识别为记账');
      await _showDetectionFailedNotification(input);
      return;
    }

    if (_shouldIgnoreDuplicateSource(
      existingSource: _pendingCandidate?.source,
      existingAmount: _pendingCandidate?.record.amount,
      existingAt: _pendingCandidateAt,
      newSource: source,
      newAmount: result.amount!,
      now: now,
    )) {
      if (kDebugMode) print('自动记账: 1秒内已有银行卡候选，忽略支付宝通知');
      return;
    }

    await _markProcessed(fingerprint, now);

    // Get the current book ID
    final books = await DatabaseService.instance.getAllBooks();
    final bookId = books.isNotEmpty ? books.first.id : 'default';

    final type = result.type ?? 'expense';

    // Build the candidate record. Only prefill here, never write to the database, to avoid dirty records from mis-detection.
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

    final candidate = AutoRecordCandidate(
      record: record,
      source: source,
      rawText: input,
    );
    _publishCandidate(candidate, now);
    await _clearPendingPayment();

    if (kDebugMode) {
      print('自动记账候选: ${record.categoryName} ¥${record.amount}');
    }
  }

  AiParseResult? _parsePaymentLocally(
    String title,
    String text,
  ) {
    final input = '$title $text'.trim();
    if (RegExp(r'(余额|可用额度|剩余额度)').hasMatch(input) &&
        !RegExp(r'(支出|消费|付款|支付|扣款|收入|到账|转入|收款)').hasMatch(input)) {
      return null;
    }
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

  Future<bool> _isDuplicate(String fingerprint, DateTime now) async {
    if (_lastProcessedFingerprint == fingerprint &&
        _lastProcessedAt != null &&
        now.difference(_lastProcessedAt!).inSeconds < 30) {
      return true;
    }

    final prefs = await SharedPreferences.getInstance();
    final savedFingerprint = prefs.getString(_lastFingerprintKey);
    final savedAt = prefs.getInt(_lastProcessedAtKey);
    return savedFingerprint == fingerprint &&
        savedAt != null &&
        now.difference(DateTime.fromMillisecondsSinceEpoch(savedAt)).inMinutes <
            5;
  }

  Future<void> _markProcessed(String fingerprint, DateTime now) async {
    _lastProcessedFingerprint = fingerprint;
    _lastProcessedAt = now;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastFingerprintKey, fingerprint);
    await prefs.setInt(_lastProcessedAtKey, now.millisecondsSinceEpoch);
  }

  Future<void> _clearPendingPayment() async {
    try {
      await _channel.invokeMethod('clearPendingPayment');
    } catch (_) {
      // Keep the in-memory candidate when the native cleanup fails, so the user can still confirm the current record.
    }
  }

  void _publishCandidate(AutoRecordCandidate candidate, DateTime now) {
    _pendingCandidate = candidate;
    _pendingCandidateAt = now;

    _alipayEmitTimer?.cancel();
    if (candidate.source == 'alipay') {
      // When the Alipay wallet pays through a bank card, the bank debit notification usually arrives within 1 second; wait before deciding the source.
      _alipayEmitTimer = Timer(const Duration(seconds: 1), () {
        if (_pendingCandidate == candidate) {
          _candidateController.add(candidate);
        }
      });
      return;
    }

    _candidateController.add(candidate);
  }

  @visibleForTesting
  static AiParseResult? parsePaymentForTest(String title, String text) {
    return AutoRecordService.instance._parsePaymentLocally(title, text);
  }

  bool _shouldIgnoreDuplicateSource({
    required String? existingSource,
    required double? existingAmount,
    required DateTime? existingAt,
    required String newSource,
    required double newAmount,
    required DateTime now,
  }) {
    return shouldIgnoreDuplicateSourceForTest(
      existingSource: existingSource,
      existingAmount: existingAmount,
      existingAt: existingAt,
      newSource: newSource,
      newAmount: newAmount,
      now: now,
    );
  }

  @visibleForTesting
  static bool shouldIgnoreDuplicateSourceForTest({
    required String? existingSource,
    required double? existingAmount,
    required DateTime? existingAt,
    required String newSource,
    required double newAmount,
    required DateTime now,
  }) {
    if (existingAmount == null || existingAt == null) return false;
    final samePayment = (existingAmount - newAmount).abs() < 0.01 &&
        now.difference(existingAt).inMilliseconds.abs() <= 1000;
    if (!samePayment) return false;
    return existingSource == 'bank' && newSource == 'alipay';
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

  /// Write to the database after the user confirms
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

  /// User cancelled
  void dismissRecord() {
    _alipayEmitTimer?.cancel();
    _pendingCandidate = null;
    _pendingCandidateAt = null;
    if (kDebugMode) print('自动记账: 用户取消');
  }

  /// Simulate a payment notification (for testing)
  Future<void> simulatePayment({
    String title = '微信支付',
    String text = '支付成功 ¥25.00 瑞幸咖啡',
    String source = 'wechat',
  }) async {
    if (kDebugMode) print('自动记账: 模拟支付 [$title] $text');
    await _processPaymentNotification(title, text, source);
  }

  /// Show the detection-failed notification
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

  /// Check whether notification-listener permission is granted
  Future<bool> isNotificationListenerEnabled() async {
    try {
      final result = await _channel.invokeMethod<bool>('isListenerEnabled');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Check whether the notification listener service is running
  Future<bool> isNotificationListenerRunning() async {
    try {
      final result = await _channel.invokeMethod<bool>('isListenerRunning');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Open the notification listener settings page
  Future<void> openNotificationListenerSettings() async {
    try {
      await _channel.invokeMethod('openListenerSettings');
    } catch (_) {
      // ignore
    }
  }
}

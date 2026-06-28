import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../main.dart';
import '../../providers/theme_provider.dart';
import '../../services/baidu_speech_service.dart';
import '../../services/api_quota_service.dart';
import '../../services/auto_record_confirm_mixin.dart';
import '../../theme/app_design_system.dart';
import '../add_record/add_record_page.dart';
import '../ai_chat/ai_chat_page.dart';
import 'widgets/greeting_card.dart';
import 'widgets/quick_entries.dart';
import 'widgets/today_records.dart';
import 'widgets/week_trend_chart.dart';

/// 首页 — Luminous Finance 风格
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with WidgetsBindingObserver, RouteAware, AutoRecordConfirmMixin {
  bool _isRecording = false;
  bool _isRecognizing = false;
  bool _isCancelled = false;
  Timer? _pollTimer;
  double _dragStartY = 0;

  @override
  void initState() {
    super.initState();
    // WidgetsBindingObserver 由 AutoRecordConfirmMixin 注册，无需重复添加
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() {}

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {}

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    // WidgetsBindingObserver 由 AutoRecordConfirmMixin 移除，无需重复操作
    _pollTimer?.cancel();
    super.dispose();
  }

  // ---- 语音录制 ----

  Future<void> _onVoicePanStart(DragStartDetails details) async {
    if (_isRecognizing) return;
    _dragStartY = details.globalPosition.dy;
    _isCancelled = false;

    // 检查语音配额
    final quota = await ApiQuotaService.instance.checkVoiceQuota();
    if (!quota.allowed) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(quota.message ?? '语音次数已用完')),
        );
      }
      return;
    }

    try {
      await BaiduSpeechService.instance.startRecording();
      if (!mounted) return;
      setState(() => _isRecording = true);

      _pollTimer = Timer.periodic(
          const Duration(milliseconds: 300), (timer) async {
        try {
          final recording = await BaiduSpeechService.instance.isRecording();
          if (!recording && mounted) {
            timer.cancel();
            _pollTimer = null;
            _finishRecording();
          }
        } catch (_) {}
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('录音启动失败：$e')),
      );
    }
  }

  void _onVoicePanUpdate(DragUpdateDetails details) {
    if (!_isRecording) return;
    final dy = _dragStartY - details.globalPosition.dy;
    final cancelled = dy > 80;
    if (cancelled != _isCancelled) {
      setState(() => _isCancelled = cancelled);
    }
  }

  Future<void> _onVoicePanEnd(DragEndDetails details) async {
    if (!_isRecording) return;
    _pollTimer?.cancel();
    _pollTimer = null;

    if (_isCancelled) {
      await BaiduSpeechService.instance.cancelRecording();
      if (mounted) setState(() => _isRecording = false);
    } else {
      _finishRecording();
    }
  }

  Future<void> _finishRecording() async {
    if (!_isRecording && !_isRecognizing) return;
    setState(() {
      _isRecording = false;
      _isRecognizing = true;
    });

    try {
      final result = await BaiduSpeechService.instance.stopAndRecognize();
      if (!mounted) return;
      setState(() => _isRecognizing = false);

      final text = (result['text'] as String).trim();
      if (text.isNotEmpty) {
        // 记录语音使用次数
        await ApiQuotaService.instance.recordVoiceUsage();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AiChatPage(initialText: text),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('没有识别到内容')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isRecognizing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('识别失败，请重试')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>(); // 主题变更时触发重建
    return Scaffold(
      backgroundColor: DS.background,
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: () async {},
              color: DS.secondaryContainer,
              child: const SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GreetingCard(),
                    SizedBox(height: DS.base),
                    WeekTrendChart(),
                    SizedBox(height: DS.base),
                    QuickEntries(),
                    SizedBox(height: DS.base),
                    TodayRecords(),
                    SizedBox(height: 100),
                  ],
                ),
              ),
            ),
            // 录音中全屏遮罩
            if (_isRecording)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.45),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: _isCancelled
                                ? Colors.grey.withOpacity(0.3)
                                : DS.error.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isCancelled ? Icons.cancel : Icons.mic,
                            size: 40,
                            color: _isCancelled ? Colors.white : DS.error,
                          ),
                        ),
                        SizedBox(height: 20),
                        Text(
                          _isCancelled ? '松开取消' : '松开发送，上滑取消',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          _isCancelled ? '' : '静音 2 秒自动停止',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            // 识别中遮罩
            if (_isRecognizing)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.45),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 20),
                        Text(
                          '正在识别...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      // 悬浮按钮：话筒 + 记一笔
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          GestureDetector(
            onPanStart: _onVoicePanStart,
            onPanUpdate: _onVoicePanUpdate,
            onPanEnd: _onVoicePanEnd,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _isRecording ? DS.error : DS.surfaceContainerLowest,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _isRecording
                      ? DS.error
                      : DS.outlineVariant,
                ),
                boxShadow: DS.shadowSm,
              ),
              child: Center(
                child: _isRecognizing
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: DS.onSurface,
                        ),
                      )
                    : Icon(
                        _isRecording ? Icons.mic : Icons.mic_none,
                        color: _isRecording ? Colors.white : DS.onSurface,
                        size: 24,
                      ),
              ),
            ),
          ),
          SizedBox(width: 12),
          SizedBox(
            height: 56,
            child: FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddRecordPage(),
                  ),
                );
              },
              backgroundColor: DS.onSurface,
              foregroundColor: DS.background,
              icon: Icon(Icons.edit, size: 20),
              label: Text(
                '记一笔',
                style: TextStyle(
                  fontFamily: DS.fontLabel,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DS.radiusFull),
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

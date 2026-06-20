import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../main.dart';
import '../../providers/theme_provider.dart';
import '../../services/baidu_speech_service.dart';
import '../../theme/app_theme.dart';
import '../add_record/add_record_page.dart';
import '../ai_chat/ai_chat_page.dart';
import 'widgets/greeting_card.dart';
import 'widgets/quick_entries.dart';
import 'widgets/today_records.dart';
import 'widgets/week_trend_chart.dart';

/// 首页 - 沉浸式 Hero 卡片布局（对齐小程序版）
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with WidgetsBindingObserver, RouteAware {
  bool _isRecording = false;
  bool _isRecognizing = false;
  bool _isCancelled = false;
  Timer? _pollTimer;
  double _dragStartY = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
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
  void didPopNext() {
    _loadData();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadData();
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {}

  // ---- 语音录制 ----

  Future<void> _onVoicePanStart(DragStartDetails details) async {
    if (_isRecognizing) return;
    _dragStartY = details.globalPosition.dy;
    _isCancelled = false;

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
        SnackBar(content: Text('识别失败：$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return Scaffold(
      backgroundColor: AppTheme.bgPage,
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: _loadData,
              color: AppTheme.primary,
              child: const SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GreetingCard(),
                    SizedBox(height: AppSpacing.md),
                    WeekTrendChart(),
                    SizedBox(height: AppSpacing.md),
                    QuickEntries(),
                    SizedBox(height: AppSpacing.md),
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
                                : Colors.red.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isCancelled ? Icons.cancel : Icons.mic,
                            size: 40,
                            color: _isCancelled ? Colors.white : Colors.red,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _isCancelled ? '松开取消' : '松开发送，上滑取消',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
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
                  child: Center(
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
                        const SizedBox(height: 20),
                        const Text(
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
      // 悬浮按钮：话筒 + 记一笔（同一行）
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 话筒按钮（按住说话）
          GestureDetector(
            onPanStart: _onVoicePanStart,
            onPanUpdate: _onVoicePanUpdate,
            onPanEnd: _onVoicePanEnd,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _isRecording ? Colors.red : AppTheme.bgCard,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _isRecording
                      ? Colors.red
                      : AppTheme.primary.withOpacity(0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: _isRecognizing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        _isRecording ? Icons.mic : Icons.mic_none,
                        color: _isRecording
                            ? Colors.white
                            : AppTheme.primary,
                        size: 24,
                      ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 记一笔按钮
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
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              icon: const Text('✏️', style: TextStyle(fontSize: 20)),
              label: const Text(
                '记一笔',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart'
    show GlassContainer, GlassQuality, LiquidRoundedSuperellipse;
import 'package:provider/provider.dart';

import '../../main.dart';
import '../../providers/theme_provider.dart';
import '../../services/baidu_speech_service.dart';
import '../../services/api_quota_service.dart';
import '../../services/auto_record_confirm_mixin.dart';
import '../../theme/app_design_system.dart';
import '../../theme/glass_materials.dart';
import '../add_record/add_record_page.dart';
import '../ai_chat/ai_chat_page.dart';
import 'widgets/greeting_card.dart';
import 'widgets/quick_entries.dart';
import 'widgets/today_records.dart';
import 'widgets/week_trend_chart.dart';

/// Home page — Luminous Finance style
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
    // WidgetsBindingObserver is registered by AutoRecordConfirmMixin; no need to add it again
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
  void dispose() {
    routeObserver.unsubscribe(this);
    // WidgetsBindingObserver is removed by AutoRecordConfirmMixin; no need to handle it again
    _pollTimer?.cancel();
    super.dispose();
  }

  // ---- Voice recording ----

  Future<void> _onVoicePanStart(DragStartDetails details) async {
    if (_isRecognizing) return;
    _dragStartY = details.globalPosition.dy;
    _isCancelled = false;

    // Check the voice quota
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

      _pollTimer =
          Timer.periodic(const Duration(milliseconds: 300), (timer) async {
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
        // Record voice usage count
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
    context.watch<ThemeProvider>(); // Rebuild on theme change
    return Scaffold(
      backgroundColor: DS.background,
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: () async {},
              color: DS.secondaryContainer,
              child: SingleChildScrollView(
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
                    SizedBox(height: 100 + glassBottomInset(context)),
                  ],
                ),
              ),
            ),
            // Full-screen overlay while recording
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
            // Overlay while recognizing
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
      // Floating buttons: microphone + Add record
      // In glass mode, GlassScaffold uses an immersive layout (extendBody) with the
      // glass bottom bar floating above the page, so the FAB must be raised to make room or it would be covered.
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          bottom: shouldUseLiquidGlass(context) ? 96 : 0,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildVoiceButton(context),
            SizedBox(width: 12),
            _buildRecordButton(context),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  /// Microphone button: uses a glass circle when liquid glass is enabled, otherwise unchanged.
  /// The recording gestures (onPanStart/Update/End) are identical in both modes.
  Widget _buildVoiceButton(BuildContext context) {
    final inner = Center(
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
    );

    final Widget circle;
    if (shouldUseLiquidGlass(context)) {
      // On light backgrounds the glass blends into the light base: add a thin outline + shadow to lift it
      circle = DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: GlassMaterials.fabBorderColor),
          boxShadow: GlassMaterials.fabShadows,
        ),
        child: GlassContainer(
          width: 56,
          height: 56,
          shape: const LiquidRoundedSuperellipse(borderRadius: 28),
          settings: GlassMaterials.navBar(),
          // The FAB floats over scrolling content: premium's texture capture fails to render in this context;
          // the official recommendation is to use standard for interactive widgets
          quality: GlassQuality.standard,
          child: inner,
        ),
      );
    } else {
      circle = Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: _isRecording ? DS.error : DS.surfaceContainerLowest,
          shape: BoxShape.circle,
          border: Border.all(
            color: _isRecording ? DS.error : DS.outlineVariant,
          ),
          boxShadow: DS.shadowSm,
        ),
        child: inner,
      );
    }

    return GestureDetector(
      onPanStart: _onVoicePanStart,
      onPanUpdate: _onVoicePanUpdate,
      onPanEnd: _onVoicePanEnd,
      child: circle,
    );
  }

  /// "Add record" button: uses a glass pill when liquid glass is enabled, otherwise the original FAB.
  Widget _buildRecordButton(BuildContext context) {
    void openAddRecord() {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AddRecordPage()),
      );
    }

    if (shouldUseLiquidGlass(context)) {
      // Height locked to 56 to match the microphone circle (the Row is centered within the Padding)
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DS.radiusFull),
          border: Border.all(color: GlassMaterials.fabBorderColor),
          boxShadow: GlassMaterials.fabShadows,
        ),
        child: GlassContainer(
          height: 56,
          shape: const LiquidRoundedSuperellipse(borderRadius: DS.radiusFull),
          settings: GlassMaterials.navBar(),
          // The FAB floats over scrolling content: premium fails to render, so use standard
          quality: GlassQuality.standard,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GestureDetector(
            onTap: openAddRecord,
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit, size: 20, color: DS.onSurface),
                const SizedBox(width: 8),
                Text(
                  '记一笔',
                  style: TextStyle(
                    fontFamily: DS.fontLabel,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: DS.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 56,
      child: FloatingActionButton.extended(
        onPressed: openAddRecord,
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
    );
  }
}

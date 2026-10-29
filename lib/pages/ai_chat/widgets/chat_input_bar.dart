import 'dart:async';

import 'package:flutter/material.dart';

import '../../../services/baidu_speech_service.dart';
import '../../../theme/app_design_system.dart';
import '../../../theme/glass_materials.dart';
import '../../../providers/theme_provider.dart';
import 'package:provider/provider.dart';

/// Chat input bar (supports Baidu speech input; WeChat-style: press and hold to talk, swipe up to cancel, release to send, auto-stop on silence)
class ChatInputBar extends StatefulWidget {
  final Function(String) onSend;

  const ChatInputBar({super.key, required this.onSend});

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _isRecording = false;
  bool _isRecognizing = false;
  bool _isCancelled = false; // Swipe-up cancel flag
  Timer? _pollTimer;
  double _dragStartY = 0;

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _controller.clear();
  }

  Future<void> _onPanStart(DragStartDetails details) async {
    if (_isRecognizing) return;
    _focusNode.unfocus();
    _dragStartY = details.globalPosition.dy;
    _isCancelled = false;

    try {
      await BaiduSpeechService.instance.startRecording();
      if (!mounted) return;
      setState(() => _isRecording = true);

      // Poll the recording state; trigger recognition after auto-stop on silence
      _pollTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) async {
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
        SnackBar(
          content: Text('录音启动失败：$e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isRecording) return;
    final dy = _dragStartY - details.globalPosition.dy;
    final cancelled = dy > 80; // Swiping up more than 80px counts as cancel
    if (cancelled != _isCancelled) {
      setState(() => _isCancelled = cancelled);
    }
  }

  Future<void> _onPanEnd(DragEndDetails details) async {
    if (!_isRecording) return;
    _pollTimer?.cancel();
    _pollTimer = null;

    if (_isCancelled) {
      // Cancel recording
      await BaiduSpeechService.instance.cancelRecording();
      if (mounted) setState(() => _isRecording = false);
    } else {
      _finishRecording();
    }
  }

  Future<void> _finishRecording() async {
    if (!_isRecording) return;
    setState(() {
      _isRecording = false;
      _isRecognizing = true;
    });

    try {
      final result = await BaiduSpeechService.instance.stopAndRecognize();
      if (!mounted) return;
      setState(() => _isRecognizing = false);

      final recognized = result['text'] as String;
      // Fill the input box instead of sending directly, so the user can fix
      // any recognition error before submitting
      if (recognized.trim().isNotEmpty) {
        _controller.text = recognized.trim();
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length),
        );
        _focusNode.requestFocus();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isRecognizing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('识别失败：$e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>(); // theme rebuild
    return Stack(
      children: [
        Container(
          padding: EdgeInsets.only(
            left: 12,
            right: 8,
            top: 8,
            bottom: MediaQuery.of(context).padding.bottom + 8,
          ),
          decoration: BoxDecoration(
            color: DS.surfaceContainerLowest,
            // No border in glass theme; kept as-is when disabled
            border: shouldUseLiquidGlass(context)
                ? null
                : Border(top: BorderSide(color: DS.outlineVariant)),
          ),
          child: Row(
            children: [
              // Microphone button (press and hold to talk)
              GestureDetector(
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _isRecording ? Colors.red : DS.background,
                    borderRadius: BorderRadius.circular(20),
                    // No border in glass theme; kept as-is when disabled
                    border: shouldUseLiquidGlass(context)
                        ? null
                        : Border.all(
                            color: _isRecording ? Colors.red : DS.outlineVariant,
                          ),
                  ),
                  child: _isRecognizing
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          _isRecording ? Icons.mic : Icons.mic_none,
                          color: _isRecording ? Colors.white : DS.onSurfaceVariant,
                          size: 20,
                        ),
                ),
              ),
              SizedBox(width: 8),
              // Text field
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: DS.background,
                    borderRadius: BorderRadius.circular(DS.radiusFull),
                    // No border in glass theme; kept as-is when disabled
                    border: shouldUseLiquidGlass(context)
                        ? null
                        : Border.all(color: DS.outlineVariant),
                  ),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    maxLines: 3,
                    minLines: 1,
                    textInputAction: TextInputAction.send,
                    decoration: InputDecoration(
                      hintText: _isRecognizing
                          ? '正在识别...'
                          : '按住说话，上滑取消',
                      hintStyle: TextStyle(
                        color: _isRecognizing
                            ? DS.emphasis
                            : DS.outline,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    style: TextStyle(fontSize: 15),
                    onSubmitted: (_) => _handleSend(),
                  ),
                ),
              ),
              SizedBox(width: 8),
              // Send button
              GestureDetector(
                onTap: _handleSend,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: DS.emphasis,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.send,
                    color: DS.isDark ? DS.background : Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Full-screen overlay while recording
        if (_isRecording)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isCancelled ? Icons.cancel : Icons.mic,
                      size: 64,
                      color: _isCancelled ? Colors.white : Colors.red,
                    ),
                    SizedBox(height: 16),
                    Text(
                      _isCancelled ? '松开取消' : '松开发送，上滑取消',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _isCancelled ? '' : '静音 2 秒自动停止',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

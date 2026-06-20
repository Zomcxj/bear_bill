import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../config/api_keys.dart';

/// 百度语音识别服务（通过 Android 原生 AudioRecord 录音，支持静音自动停止）
class BaiduSpeechService {
  BaiduSpeechService._();
  static final instance = BaiduSpeechService._();

  static const _channel = MethodChannel('bear_bill/speech');
  String? _accessToken;
  DateTime? _tokenExpiry;

  /// 获取百度 API access_token（自动缓存，过期自动刷新）
  Future<String> _getAccessToken() async {
    if (_accessToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) {
      return _accessToken!;
    }

    final url = Uri.parse(
      'https://aip.baidubce.com/oauth/2.0/token'
      '?grant_type=client_credentials'
      '&client_id=$baiduSpeechApiKey'
      '&client_secret=$baiduSpeechSecretKey',
    );

    final response = await http.post(url);
    if (response.statusCode != 200) {
      throw Exception('获取百度 token 失败: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    _accessToken = data['access_token'] as String;
    final expiresIn = data['expires_in'] as int;
    _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn - 60));
    return _accessToken!;
  }

  /// 开始录音（Android 原生 AudioRecord，PCM 16kHz 16bit Mono）
  Future<void> startRecording() async {
    await _channel.invokeMethod('startRecording');
  }

  /// 是否正在录音
  Future<bool> isRecording() async {
    final result = await _channel.invokeMethod<bool>('isRecording');
    return result ?? false;
  }

  /// 停止录音并返回识别结果
  /// 返回 Map: { 'text': String, 'autoStopped': bool }
  Future<Map<String, dynamic>> stopAndRecognize() async {
    final response = await _channel.invokeMethod('stopRecording');
    final path = response['path'] as String?;
    final autoStopped = response['autoStopped'] as bool? ?? false;

    if (path == null) throw Exception('录音失败');

    final file = File(path);
    if (!await file.exists()) throw Exception('录音文件不存在');

    final audioBytes = await file.readAsBytes();
    await file.delete();

    if (audioBytes.isEmpty) throw Exception('录音数据为空');

    final text = await _recognize(audioBytes);
    return {'text': text, 'autoStopped': autoStopped};
  }

  /// 取消录音
  Future<void> cancelRecording() async {
    await _channel.invokeMethod('cancelRecording');
  }

  /// 调用百度语音识别 API
  Future<String> _recognize(List<int> audioData) async {
    final token = await _getAccessToken();

    final url = Uri.parse('https://vop.baidu.com/server_api');

    final body = jsonEncode({
      'format': 'pcm',
      'rate': 16000,
      'channel': 1,
      'cuid': 'bear_bill_app',
      'token': token,
      'speech': base64Encode(audioData),
      'len': audioData.length,
    });

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception('语音识别请求失败: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    final errNo = data['err_no'] as int;

    if (errNo != 0) {
      final errMsg = data['err_msg'] as String? ?? '未知错误';
      throw Exception('语音识别错误($errNo): $errMsg');
    }

    final results = data['result'] as List<dynamic>?;
    if (results == null || results.isEmpty) {
      throw Exception('未识别到语音内容');
    }

    return results.first as String;
  }
}

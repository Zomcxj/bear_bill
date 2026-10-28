import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

import '../config/api_keys.dart';

/// Baidu speech recognition service (records via Android native AudioRecord, auto-stops on silence)
class BaiduSpeechService {
  BaiduSpeechService._();
  static final instance = BaiduSpeechService._();

  static const _channel = MethodChannel('bear_bill/speech');
  String? _accessToken;
  DateTime? _tokenExpiry;

  /// Get the Baidu API access_token (cached, auto-refreshed on expiry)
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

  /// Start recording (Android native AudioRecord, PCM 16kHz 16bit Mono)
  Future<void> startRecording() async {
    final permission = await Permission.microphone.request();
    if (!permission.isGranted) {
      throw Exception('麦克风权限未开启');
    }
    await _channel.invokeMethod('startRecording');
  }

  /// Whether recording is in progress
  Future<bool> isRecording() async {
    final result = await _channel.invokeMethod<bool>('isRecording');
    return result ?? false;
  }

  /// Stop recording and return the recognition result
  /// Returns a Map: { 'text': String, 'autoStopped': bool }
  Future<Map<String, dynamic>> stopAndRecognize() async {
    final response = await _channel.invokeMethod('stopRecording');
    final path = response['path'] as String?;
    final autoStopped = response['autoStopped'] as bool? ?? false;

    if (path == null) throw Exception('录音失败');

    final file = File(path);
    if (!await file.exists()) throw Exception('录音文件不存在');

    final audioBytes = await file.readAsBytes();
    await file.delete();

    if (audioBytes.isEmpty) throw Exception('识别失败');

    final text = await _recognize(audioBytes);
    return {'text': text, 'autoStopped': autoStopped};
  }

  /// Cancel recording
  Future<void> cancelRecording() async {
    await _channel.invokeMethod('cancelRecording');
  }

  /// Call the Baidu speech recognition API
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
      throw Exception('识别失败');
    }

    final results = data['result'] as List<dynamic>?;
    if (results == null || results.isEmpty) {
      throw Exception('识别失败');
    }

    return results.first as String;
  }
}

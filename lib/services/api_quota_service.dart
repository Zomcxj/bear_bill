import 'package:shared_preferences/shared_preferences.dart';

/// API 配额管理服务
class ApiQuotaService {
  static final ApiQuotaService instance = ApiQuotaService._();
  ApiQuotaService._();

  // 限额配置
  static const int voiceDailyLimit = 20;
  static const int voiceTotalLimit = 49960;
  static const int amapDailyLimit = 100;

  /// 检查语音识别是否可用
  Future<QuotaResult> checkVoiceQuota() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getToday();

    final dailyKey = 'voice_daily_$today';
    final totalKey = 'voice_total';

    final dailyCount = prefs.getInt(dailyKey) ?? 0;
    final totalCount = prefs.getInt(totalKey) ?? 0;

    if (dailyCount >= voiceDailyLimit) {
      return QuotaResult(
        allowed: false,
        message: '今日语音次数已用完（${voiceDailyLimit}次/天）',
        dailyUsed: dailyCount,
        dailyLimit: voiceDailyLimit,
        totalUsed: totalCount,
        totalLimit: voiceTotalLimit,
      );
    }

    if (totalCount >= voiceTotalLimit) {
      return QuotaResult(
        allowed: false,
        message: '语音次数已用完（共${voiceTotalLimit}次）',
        dailyUsed: dailyCount,
        dailyLimit: voiceDailyLimit,
        totalUsed: totalCount,
        totalLimit: voiceTotalLimit,
      );
    }

    return QuotaResult(
      allowed: true,
      dailyUsed: dailyCount,
      dailyLimit: voiceDailyLimit,
      totalUsed: totalCount,
      totalLimit: voiceTotalLimit,
    );
  }

  /// 记录语音识别使用
  Future<void> recordVoiceUsage() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getToday();

    final dailyKey = 'voice_daily_$today';
    final totalKey = 'voice_total';

    await prefs.setInt(dailyKey, (prefs.getInt(dailyKey) ?? 0) + 1);
    await prefs.setInt(totalKey, (prefs.getInt(totalKey) ?? 0) + 1);
  }

  /// 检查高德地图是否可用
  Future<QuotaResult> checkAmapQuota() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getToday();

    final dailyKey = 'amap_daily_$today';
    final dailyCount = prefs.getInt(dailyKey) ?? 0;

    if (dailyCount >= amapDailyLimit) {
      return QuotaResult(
        allowed: false,
        message: '今日地图次数已用完（${amapDailyLimit}次/天）',
        dailyUsed: dailyCount,
        dailyLimit: amapDailyLimit,
      );
    }

    return QuotaResult(
      allowed: true,
      dailyUsed: dailyCount,
      dailyLimit: amapDailyLimit,
    );
  }

  /// 记录高德地图使用
  Future<void> recordAmapUsage() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getToday();

    final dailyKey = 'amap_daily_$today';
    await prefs.setInt(dailyKey, (prefs.getInt(dailyKey) ?? 0) + 1);
  }

  /// 获取今日统计
  Future<QuotaStats> getTodayStats() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getToday();

    return QuotaStats(
      voiceDaily: prefs.getInt('voice_daily_$today') ?? 0,
      voiceDailyLimit: voiceDailyLimit,
      voiceTotal: prefs.getInt('voice_total') ?? 0,
      voiceTotalLimit: voiceTotalLimit,
      amapDaily: prefs.getInt('amap_daily_$today') ?? 0,
      amapDailyLimit: amapDailyLimit,
    );
  }

  String _getToday() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String _getMonth() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }
}

/// 配额检查结果
class QuotaResult {
  final bool allowed;
  final String? message;
  final int dailyUsed;
  final int dailyLimit;
  final int? totalUsed;
  final int? totalLimit;

  QuotaResult({
    required this.allowed,
    this.message,
    required this.dailyUsed,
    required this.dailyLimit,
    this.totalUsed,
    this.totalLimit,
  });
}

/// 配额统计
class QuotaStats {
  final int voiceDaily;
  final int voiceDailyLimit;
  final int voiceTotal;
  final int voiceTotalLimit;
  final int amapDaily;
  final int amapDailyLimit;

  QuotaStats({
    required this.voiceDaily,
    required this.voiceDailyLimit,
    required this.voiceTotal,
    required this.voiceTotalLimit,
    required this.amapDaily,
    required this.amapDailyLimit,
  });
}

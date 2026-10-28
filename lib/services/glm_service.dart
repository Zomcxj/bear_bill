import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_keys.dart';
import 'category_order_service.dart';
import '../models/models.dart';

/// AI record parsing result
class AiParseResult {
  final String intent; // 'record' | 'query' | 'unknown'
  final String? type; // 'expense' | 'income'
  final double? amount;
  final String? categoryId;
  final String? remark;
  final String? date; // 'YYYY-MM-DD', defaults to today when empty
  final String? queryPeriod; // 'today' | 'week' | 'month' | 'year'
  // Query filter conditions
  final String? queryCategoryId; // Query by category
  final String? queryMood; // Query by mood
  final String? queryLocation; // Query by location keyword
  final String? queryStartDate; // Custom start date
  final String? queryEndDate; // Custom end date

  const AiParseResult({
    required this.intent,
    this.type,
    this.amount,
    this.categoryId,
    this.remark,
    this.date,
    this.queryPeriod,
    this.queryCategoryId,
    this.queryMood,
    this.queryLocation,
    this.queryStartDate,
    this.queryEndDate,
  });

  bool get isRecord => intent == 'record' && amount != null && amount! > 0;
  bool get isQuery => intent == 'query';

  /// Get the resolved date, defaults to today
  DateTime get resolvedDate {
    if (date != null && date!.length == 10) {
      try {
        return DateTime.parse(date!);
      } catch (_) {}
    }
    return DateTime.now();
  }
}

/// GLM AI service - the core of conversational recording
class GlmService {
  static final GlmService instance = GlmService._();
  GlmService._();

  bool get isConfigured => aiApiKey.isNotEmpty;

  /// Parse user input (API first, local fallback)
  Future<AiParseResult> parseUserInput(String input) async {
    if (isConfigured) {
      try {
        final result = await _callGlmApi(input);
        if (result != null) return result;
      } catch (e) {
        if (kDebugMode) print('GLM API 异常，降级本地解析: $e');
      }
    }
    return _localParse(input);
  }

  /// Call the GLM-4-Flash API
  Future<AiParseResult?> _callGlmApi(String input) async {
    final expenseList = expenseCategories
        .map((c) => '${c.id}:${c.name}(${c.icon})')
        .join(', ');
    final incomeList = incomeCategories
        .map((c) => '${c.id}:${c.name}(${c.icon})')
        .join(', ');

    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final moodList = moods.map((m) => '${m.id}:${m.emoji}${m.label}').join(', ');

    final systemPrompt = '''你是一个记账助手。分析用户输入，返回 JSON 格式结果。
今天的日期是 $todayStr。

分类列表：
- 支出: $expenseList
- 收入: $incomeList
心情列表: $moodList

规则：
1. 只要用户提到了具体的消费/收入行为或分类（如"交通"、"午餐"、"打车"、"买衣服"），即使没有金额，intent 也为 "record"，并尽可能识别 type/categoryId/remark/date，amount 缺失时填 null
2. 只有当用户明确想查看/统计账单时（如"这个月花了多少"、"今天消费"、"查一下账单"、"收入汇总"），intent 才为 "query"
3. 只返回 JSON，不要其他文字
4. 金额必须是数字，不带单位
5. date 字段为 YYYY-MM-DD 格式。如果用户说"昨天"则为昨天日期，"前天"则为前天日期，"大前天"则为3天前，没有提到日期则为今天
6. 用户只说分类名（如"交通"、"餐饮"、"购物"），也要识别为 record，categoryId 填对应分类，amount 填 null
7. 不确定分类时默认 categoryId 为 "other"

查询规则：
- queryPeriod: today/week/month/year，默认 month
- queryCategoryId: 用户提到的分类ID（如"餐饮花了多少"→queryCategoryId:"food"）
- queryMood: 用户提到的心情ID（如"开心时候的消费"→queryMood:"happy"）
- queryLocation: 用户提到的位置关键词（如"在星巴克的消费"→queryLocation:"星巴克"）
- queryStartDate/queryEndDate: 自定义日期范围（如"6月1号到6月10号"→queryStartDate:"2026-06-01",queryEndDate:"2026-06-10"）
- 支持组合查询（如"这个月在餐厅的餐饮支出"→queryPeriod:"month",queryCategoryId:"food",queryLocation:"餐厅"）

JSON 格式:
{"intent":"record","type":"expense","amount":25.5,"categoryId":"food","remark":"午餐","date":"$todayStr"}
或
{"intent":"record","type":"expense","amount":null,"categoryId":"transport","remark":null,"date":"$todayStr"}
或
{"intent":"query","queryPeriod":"month"}
或
{"intent":"query","queryPeriod":"month","queryCategoryId":"food"}
或
{"intent":"query","queryMood":"happy","queryPeriod":"month"}
或
{"intent":"query","queryLocation":"星巴克","queryPeriod":"month"}
或
{"intent":"query","queryStartDate":"2026-06-01","queryEndDate":"2026-06-10"}
或
{"intent":"unknown"}''';

    final response = await http.post(
      Uri.parse(aiBaseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $aiApiKey',
      },
      body: jsonEncode({
        'model': aiModel,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': input},
        ],
        'temperature': 0.1,
      }),
    );

    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body);
    final content = data['choices']?[0]?['message']?['content'] as String?;
    if (content == null) return null;

    // Extract the JSON part
    final jsonMatch = RegExp(r'\{[^}]+\}').firstMatch(content);
    if (jsonMatch == null) return null;

    final parsed = jsonDecode(jsonMatch.group(0)!);
    return AiParseResult(
      intent: parsed['intent'] ?? 'unknown',
      type: parsed['type'],
      amount: parsed['amount'] != null
          ? (parsed['amount'] as num).toDouble()
          : null,
      categoryId: parsed['categoryId'],
      remark: parsed['remark'],
      date: parsed['date'] as String?,
      queryPeriod: parsed['queryPeriod'],
      queryCategoryId: parsed['queryCategoryId'],
      queryMood: parsed['queryMood'],
      queryLocation: parsed['queryLocation'],
      queryStartDate: parsed['queryStartDate'],
      queryEndDate: parsed['queryEndDate'],
    );
  }

  /// Local keyword fallback parsing (used only when the API is unavailable, kept conservative)
  AiParseResult _localParse(String input) {
    final text = input.trim();

    // Detect whether an amount is present
    final amountMatch = RegExp(r'(\d+\.?\d*)').firstMatch(text);
    if (amountMatch == null) {
      // No amount → possibly a query
      if (_isQueryIntent(text)) {
        return AiParseResult(
          intent: 'query',
          queryPeriod: _detectQueryPeriod(text),
        );
      }
      // No amount and no query keyword → try to interpret it as a category follow-up
      final type = _detectType(text);
      final categoryId = _detectCategory(text, type);
      if (categoryId != 'other') {
        return AiParseResult(
          intent: 'record',
          type: type,
          categoryId: categoryId,
          date: _detectDate(text),
        );
      }
      return const AiParseResult(intent: 'unknown');
    }

    final amount = double.parse(amountMatch.group(1)!);
    if (amount <= 0) return const AiParseResult(intent: 'unknown');

    // Amount present → require an explicit record intent word or category word to treat it as a record
    final hasRecordIntent = RegExp(r'(花|消费|支出|记|买了|付|充值|转|收入|赚|工资|奖金)')
        .hasMatch(text);
    final type = _detectType(text);
    final categoryId = _detectCategory(text, type);
    final hasCategory = categoryId != 'other';

    if (!hasRecordIntent && !hasCategory) {
      // Has a number but does not look like a record → possibly a query
      if (_isQueryIntent(text)) {
        return AiParseResult(
          intent: 'query',
          queryPeriod: _detectQueryPeriod(text),
        );
      }
      return const AiParseResult(intent: 'unknown');
    }

    final remark = _extractRemark(text, amount);
    final date = _detectDate(text);

    return AiParseResult(
      intent: 'record',
      type: type,
      amount: amount,
      categoryId: categoryId,
      remark: remark,
      date: date,
    );
  }

  bool _isQueryIntent(String text) {
    final keywords = ['花了多少', '消费', '收入', '支出', '账单', '汇总', '统计', '查询', '多少', '多少钱', '总共', '一共', '合计', '总计', '查看', '看看'];
    return keywords.any((k) => text.contains(k));
  }

  String _detectQueryPeriod(String text) {
    if (text.contains('今天') || text.contains('今日')) return 'today';
    if (text.contains('本周') || text.contains('这周')) return 'week';
    if (text.contains('今年')) return 'year';
    return 'month'; // Default to this month
  }

  String _detectType(String text) {
    final incomeKeywords = ['工资', '收入', '奖金', '理财', '兼职', '租金', '转入', '赚了'];
    if (incomeKeywords.any((k) => text.contains(k))) return 'income';
    return 'expense';
  }

  String _detectCategory(String text, String type) {
    final categories =
        type == 'expense'
            ? CategoryOrderService.instance.expense
            : incomeCategories;

    // Keyword mapping
    final Map<String, List<String>> keywords = {
      'food': ['吃饭', '餐', '饭', '外卖', '食堂', '午餐', '晚餐', '早餐', '火锅', '烧烤', '餐厅'],
      'milk_tea': ['奶茶', '咖啡', '星巴克', '饮料', '果汁', '茶'],
      'snack': ['零食', '薯片', '巧克力', '蛋糕', '甜品'],
      'transport': ['打车', '出租', '地铁', '公交', '高铁', '火车', '飞机', '油费', '加油', '停车'],
      'shopping': ['买', '购物', '超市', '淘宝', '京东', '拼多多', '日用'],
      'entertainment': ['电影', '游戏', 'KTV', '娱乐', '演出', '门票'],
      'health': ['医院', '药', '看病', '体检', '挂号'],
      'housing': ['房租', '水费', '电费', '物业', '燃气', '宽带'],
      'education': ['书', '课程', '培训', '学费', '考试'],
      'digital': ['手机', '电脑', '耳机', '充电', '数码'],
      'clothing': ['衣服', '鞋', '裤子', '外套', '裙子'],
      'pet': ['猫粮', '狗粮', '宠物', '猫砂'],
      'sport': ['健身', '运动', '球', '游泳', '瑜伽'],
      'travel': ['旅游', '酒店', '景点', '机票', '旅行'],
      'social': ['聚餐', '请客', '礼物', '社交'],
      'transfer': ['转账', '转入', '转出'],
      'red_packet': ['红包', '发红包', '收红包'],
      'salary': ['工资', '薪水', '月薪'],
      'bonus': ['奖金', '年终', '提成'],
      'invest': ['理财', '利息', '分红', '股票', '基金'],
      'part_time': ['兼职', '副业', '外快'],
      'rent': ['租金', '出租', '收租'],
    };

    for (final entry in keywords.entries) {
      if (entry.value.any((k) => text.contains(k))) {
        // Make sure the category exists
        if (categories.any((c) => c.id == entry.key)) {
          return entry.key;
        }
      }
    }

    return type == 'expense' ? 'other' : 'other_in';
  }

  String? _extractRemark(String text, double amount) {
    // Remove the amount digits and keep the meaningful text
    var remark = text.replaceAll(RegExp(r'\d+\.?\d*元?'), '').trim();
    // Remove common meaningless words
    remark = remark
        .replaceAll(RegExp(r'(记|记一笔|花了|消费|支出|收入|赚了)'), '')
        .trim();
    if (remark.isEmpty) return null;
    return remark.length > 20 ? remark.substring(0, 20) : remark;
  }

  /// Detect the date (today/yesterday/the day before/the day 3 days ago/X last week)
  String? _detectDate(String text) {
    final now = DateTime.now();

    if (text.contains('大前天')) {
      final d = now.subtract(const Duration(days: 3));
      return _formatDate(d);
    }
    if (text.contains('前天')) {
      final d = now.subtract(const Duration(days: 2));
      return _formatDate(d);
    }
    if (text.contains('昨天')) {
      final d = now.subtract(const Duration(days: 1));
      return _formatDate(d);
    }
    if (text.contains('今天') || text.contains('今日')) {
      return _formatDate(now);
    }

    // X last week
    final weekdayMatch = RegExp(r'上周([一二三四五六日天])').firstMatch(text);
    if (weekdayMatch != null) {
      final weekdayMap = {'一': 1, '二': 2, '三': 3, '四': 4, '五': 5, '六': 6, '日': 7, '天': 7};
      final targetDay = weekdayMap[weekdayMatch.group(1)]!;
      final currentWeekday = now.weekday;
      // Last Monday = current date - current weekday - 6
      final daysAgo = currentWeekday + 7 - targetDay;
      final d = now.subtract(Duration(days: daysAgo));
      return _formatDate(d);
    }

    // X days ago
    final daysAgoMatch = RegExp(r'(\d+)天前').firstMatch(text);
    if (daysAgoMatch != null) {
      final days = int.tryParse(daysAgoMatch.group(1)!) ?? 0;
      if (days > 0 && days <= 30) {
        final d = now.subtract(Duration(days: days));
        return _formatDate(d);
      }
    }

    // No date info; return null (defaults to today)
    return null;
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}

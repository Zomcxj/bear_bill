import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_keys.dart';
import '../models/models.dart';

/// AI 记账解析结果
class AiParseResult {
  final String intent; // 'record' | 'query' | 'unknown'
  final String? type; // 'expense' | 'income'
  final double? amount;
  final String? categoryId;
  final String? remark;
  final String? queryPeriod; // 'today' | 'week' | 'month' | 'year'

  const AiParseResult({
    required this.intent,
    this.type,
    this.amount,
    this.categoryId,
    this.remark,
    this.queryPeriod,
  });

  bool get isRecord => intent == 'record' && amount != null && amount! > 0;
  bool get isQuery => intent == 'query';
}

/// GLM AI 服务 - 对话式记账核心
class GlmService {
  static final GlmService instance = GlmService._();
  GlmService._();

  bool get isConfigured => glmApiKey.isNotEmpty;

  /// 解析用户输入（优先 API，降级本地）
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

  /// 调用 GLM-4-Flash API
  Future<AiParseResult?> _callGlmApi(String input) async {
    final expenseList = expenseCategories
        .map((c) => '${c.id}:${c.name}(${c.icon})')
        .join(', ');
    final incomeList = incomeCategories
        .map((c) => '${c.id}:${c.name}(${c.icon})')
        .join(', ');

    final systemPrompt = '''你是一个记账助手。分析用户输入，返回 JSON 格式结果。

分类列表：
- 支出: $expenseList
- 收入: $incomeList

规则：
1. 如果包含金额数字，intent 为 "record"，并识别 type/amount/categoryId/remark
2. 如果是查询（如"这个月花了多少"、"今天消费"），intent 为 "query"，queryPeriod 为 today/week/month/year
3. 无法识别时 intent 为 "unknown"
4. 金额必须是数字，不带单位
5. 只返回 JSON，不要其他文字

JSON 格式:
{"intent":"record","type":"expense","amount":25.5,"categoryId":"food","remark":"午餐"}
或
{"intent":"query","queryPeriod":"month"}
或
{"intent":"unknown"}''';

    final response = await http.post(
      Uri.parse('https://open.bigmodel.cn/api/paas/v4/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $glmApiKey',
      },
      body: jsonEncode({
        'model': 'GLM-4-Flash',
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

    // 提取 JSON 部分
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
      queryPeriod: parsed['queryPeriod'],
    );
  }

  /// 本地关键词降级解析
  AiParseResult _localParse(String input) {
    final text = input.trim();

    // 检测是否有金额
    final amountMatch = RegExp(r'(\d+\.?\d*)').firstMatch(text);
    if (amountMatch == null) {
      // 无金额 → 可能是查询
      if (_isQueryIntent(text)) {
        return AiParseResult(
          intent: 'query',
          queryPeriod: _detectQueryPeriod(text),
        );
      }
      return const AiParseResult(intent: 'unknown');
    }

    final amount = double.parse(amountMatch.group(1)!);
    if (amount <= 0) return const AiParseResult(intent: 'unknown');

    // 有金额 → 记账
    final type = _detectType(text);
    final categoryId = _detectCategory(text, type);
    final remark = _extractRemark(text, amount);

    return AiParseResult(
      intent: 'record',
      type: type,
      amount: amount,
      categoryId: categoryId,
      remark: remark,
    );
  }

  bool _isQueryIntent(String text) {
    final keywords = ['花了多少', '消费', '收入', '支出', '账单', '汇总', '统计', '查询', '多少'];
    return keywords.any((k) => text.contains(k));
  }

  String _detectQueryPeriod(String text) {
    if (text.contains('今天') || text.contains('今日')) return 'today';
    if (text.contains('本周') || text.contains('这周')) return 'week';
    if (text.contains('今年')) return 'year';
    return 'month'; // 默认本月
  }

  String _detectType(String text) {
    final incomeKeywords = ['工资', '收入', '奖金', '理财', '兼职', '租金', '转入', '赚了'];
    if (incomeKeywords.any((k) => text.contains(k))) return 'income';
    return 'expense';
  }

  String _detectCategory(String text, String type) {
    final categories =
        type == 'expense' ? expenseCategories : incomeCategories;

    // 关键词映射
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
      'social': ['聚餐', '请客', '红包', '礼物', '社交'],
      'salary': ['工资', '薪水', '月薪'],
      'bonus': ['奖金', '年终', '提成'],
      'invest': ['理财', '利息', '分红', '股票', '基金'],
      'part_time': ['兼职', '副业', '外快'],
      'rent': ['租金', '出租', '收租'],
      'transfer': ['转账', '转入'],
    };

    for (final entry in keywords.entries) {
      if (entry.value.any((k) => text.contains(k))) {
        // 确保该分类存在
        if (categories.any((c) => c.id == entry.key)) {
          return entry.key;
        }
      }
    }

    return type == 'expense' ? 'other' : 'other_in';
  }

  String? _extractRemark(String text, double amount) {
    // 移除金额数字，保留有意义的文字
    var remark = text.replaceAll(RegExp(r'\d+\.?\d*元?'), '').trim();
    // 移除常见无意义词
    remark = remark
        .replaceAll(RegExp(r'(记|记一笔|花了|消费|支出|收入|赚了)'), '')
        .trim();
    if (remark.isEmpty) return null;
    return remark.length > 20 ? remark.substring(0, 20) : remark;
  }
}

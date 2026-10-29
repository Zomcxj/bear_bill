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
  /// Only records that carry coordinates (used by "有定位的消费")
  final bool queryRequireLocation;
  // Multiple records parsed from one sentence (empty for a single-record result)
  final List<AiParseResult> items;

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
    this.queryRequireLocation = false,
    this.items = const [],
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

  /// Exposed for unit tests: run only the offline keyword parser.
  @visibleForTesting
  AiParseResult parseLocalForTest(String input) => _localParse(input);

  /// Convert a Chinese numeral string ("二十五", "一百二") to an int.
  /// Used by the amount follow-up in the AI chat page.
  int parseChineseNumber(String s) => _chineseToInt(s);

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
4. 金额必须是数字，不带单位；中文数字要转成阿拉伯数字（"二十五"→25，"一百二"→120）
5. date 字段为 YYYY-MM-DD 格式。如果用户说"昨天"则为昨天，"前天"为前天，"大前天"为3天前，"上周X"为上周对应日期，"X天前"为X天前，"上个月"为上月同日；没有提到日期则为今天
6. 用户只说分类名（如"交通"、"餐饮"、"购物"），也要识别为 record，categoryId 填对应分类，amount 填 null
7. 不确定分类时默认 categoryId 为 "other"
8. amount 是"这笔账的真实金额"，不要取数量/人数/日期里的数字（"买2个苹果花10"→10，"3个人吃饭150"→150，"25号吃饭18"→18）
9. 一句话里有多笔独立消费（如"早餐10块午餐25"）时，用 items 数组一次返回多笔，每笔含 type/amount/categoryId/remark/date；只有一笔时仍用单对象格式
10. 退款/报销/返现/收红包/收到转账 → type 为 "income"；发红包/还信用卡/转账给别人/买东西 → "expense"
11. 用户要求"修改/删除"已有账单时（如"把午餐改成30"、"删掉刚才那笔"），intent 返回 "unknown"，不要当作新账记录
12. 地点与分类冲突时（如"星巴克"也是奶茶分类的关键词）：用户只是提到消费场景时优先填 categoryId，不要同时填 queryLocation；只有明确说"在<地点>"且该地点不是分类词时才填 queryLocation
13. 句子只是在描述"想看的筛选条件"、本身没有要记一笔的意思时，intent 为 "query"，不要返回 record：
    - "有定位的消费"、"在星巴克的消费"、"开心的消费"、"带定位的账单" → query（分别对应 queryLocation / queryMood / 只需带定位的查询）
    - 判断标准：该句若当作记账，说不清"买了什么东西、花了多少"，就应判为 query
14. 用户想按"有定位/带定位"筛选时，返回 queryRequireLocation: true，**不要**把"有定位"填进 queryLocation

查询规则：
- queryPeriod: today/week/month/year，默认 month
- queryCategoryId: 用户提到的分类ID（如"餐饮花了多少"→queryCategoryId:"food"）
- queryMood: 用户提到的心情ID（如"开心时候的消费"→queryMood:"happy"）
- queryLocation: 用户提到的位置关键词（如"在公司楼下的消费"→queryLocation:"公司楼下"）
- queryStartDate/queryEndDate: 自定义日期范围（如"6月1号到6月10号"→queryStartDate:"${today.year}-06-01",queryEndDate:"${today.year}-06-10"）
- 支持组合查询（如"这个月在餐厅的餐饮支出"→queryPeriod:"month",queryCategoryId:"food",queryLocation:"餐厅"）

JSON 格式:
{"intent":"record","type":"expense","amount":25.5,"categoryId":"food","remark":"午餐","date":"$todayStr"}
或
{"intent":"record","type":"expense","amount":null,"categoryId":"transport","remark":null,"date":"$todayStr"}
或
{"intent":"record","items":[{"type":"expense","amount":10,"categoryId":"food","remark":"早餐","date":"$todayStr"},{"type":"expense","amount":25,"categoryId":"food","remark":"午餐","date":"$todayStr"}]}
或
{"intent":"query","queryPeriod":"month"}
或
{"intent":"query","queryPeriod":"month","queryCategoryId":"food"}
或
{"intent":"query","queryMood":"happy","queryPeriod":"month"}
或
{"intent":"query","queryLocation":"公司楼下","queryPeriod":"month"}
或
{"intent":"query","queryStartDate":"${today.year}-06-01","queryEndDate":"${today.year}-06-10"}
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
    if (parsed is! Map) return null;
    return _correct(input, _fromJson(Map<String, dynamic>.from(parsed)));
  }

  /// Keyword words that unambiguously pin a category.
  /// The model sometimes drifts (e.g. "聚餐" -> food); these override it.
  static const Map<String, String> _strongCategory = {
    '聚餐': 'social',
    '请客': 'social',
    '送礼': 'social',
    '礼物': 'social',
    '买药': 'health',
    '药店': 'health',
    '医院': 'health',
    '看病': 'health',
    '挂号': 'health',
    '体检': 'health',
    '水果': 'fruit',
    '苹果': 'fruit',
    '香蕉': 'fruit',
    '西瓜': 'fruit',
    '草莓': 'fruit',
    '健身': 'sport',
    '游泳': 'sport',
    '瑜伽': 'sport',
    '猫粮': 'pet',
    '狗粮': 'pet',
    '猫砂': 'pet',
    '酒店': 'travel',
    '机票': 'travel',
    '旅游': 'travel',
    '电影': 'entertainment',
    '奶茶': 'milk_tea',
    '咖啡': 'milk_tea',
    '星巴克': 'milk_tea',
    '打车': 'transport',
    '加油': 'transport',
    '地铁': 'transport',
    '公交': 'transport',
    '房租': 'housing',
    '学费': 'education',
    '工资': 'salary',
    '奖金': 'bonus',
    '退款': 'other_in',
    '报销': 'other_in',
  };

  /// Apply keyword overrides on top of the model result.
  AiParseResult _correct(String input, AiParseResult r) {
    if (r.items.isNotEmpty) {
      return AiParseResult(
        intent: r.intent,
        items: r.items.map((e) => _correct(input, e)).toList(),
      );
    }
    if (r.intent != 'record') return r;

    // The model often merges "早餐10块午餐25" into one record; split it here
    final split = _splitMultiRecord(input);
    if (split != null) return split;

    // Longest matching strong keyword wins
    String? forced;
    var bestLen = 0;
    for (final entry in _strongCategory.entries) {
      if (input.contains(entry.key) && entry.key.length > bestLen) {
        bestLen = entry.key.length;
        forced = entry.value;
      }
    }
    if (forced == null || forced == r.categoryId) return r;

    // Only override when the target lives in the matching type
    final isIncome = forced == 'salary' ||
        forced == 'bonus' ||
        forced == 'other_in';
    if (isIncome && r.type != 'income') return r;
    if (!isIncome && r.type == 'income') return r;

    return AiParseResult(
      intent: r.intent,
      type: r.type,
      amount: r.amount,
      categoryId: forced,
      remark: r.remark,
      date: r.date,
    );
  }

  /// Split sentences that carry several independent amounts, e.g.
  /// "早餐10块午餐25" -> two records. Returns null when there is only one.
  AiParseResult? _splitMultiRecord(String input) {
    // Cut the sentence right before each spend/income cue word. Every chunk
    // that contains an amount becomes one record:
    //   "早餐10块午餐25" -> ["早餐10块", "午餐25"]
    final cueRe = RegExp(
      r'(?=早餐|午餐|晚餐|早饭|午饭|晚饭|夜宵|打车|地铁|公交|加油|奶茶|咖啡|'
      r'水果|聚餐|请客|礼物|买药|电影|房租|学费|工资|奖金)',
    );
    final chunks = <String>[];
    var last = 0;
    for (final m in cueRe.allMatches(input)) {
      if (m.start > last) {
        final chunk = input.substring(last, m.start).trim();
        if (chunk.isNotEmpty) chunks.add(chunk);
        last = m.start;
      }
    }
    if (last < input.length) chunks.add(input.substring(last).trim());
    if (chunks.length < 2) return null;

    final items = <AiParseResult>[];
    for (final chunk in chunks) {
      final amount = _extractAmount(chunk);
      if (amount == null || amount <= 0) continue;
      final type = _detectType(chunk);
      items.add(AiParseResult(
        intent: 'record',
        type: type,
        amount: amount,
        categoryId: _detectCategory(chunk, type),
        remark: _extractRemark(chunk),
        date: _detectDate(chunk),
      ));
    }
    if (items.length < 2) return null;
    return AiParseResult(intent: 'record', items: items);
  }

  /// Build an [AiParseResult] from the JSON returned by the model.
  /// Supports the multi-record "items" array; every item is a record.
  AiParseResult _fromJson(Map<String, dynamic> parsed) {
    final items = <AiParseResult>[];
    final rawItems = parsed['items'];
    if (rawItems is List) {
      for (final entry in rawItems) {
        if (entry is Map) {
          final item = Map<String, dynamic>.from(entry);
          item['intent'] ??= 'record';
          items.add(_fromJson(item));
        }
      }
    }
    return AiParseResult(
      intent: parsed['intent'] ?? 'unknown',
      type: parsed['type'],
      amount: _toDouble(parsed['amount']),
      categoryId: parsed['categoryId'],
      remark: parsed['remark'],
      date: parsed['date'] as String?,
      queryPeriod: parsed['queryPeriod'],
      queryCategoryId: parsed['queryCategoryId'],
      queryMood: parsed['queryMood'],
      queryLocation: parsed['queryLocation'],
      queryStartDate: parsed['queryStartDate'],
      queryEndDate: parsed['queryEndDate'],
      queryRequireLocation: parsed['queryRequireLocation'] == true,
      items: items,
    );
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  /// Local keyword fallback parsing (used only when the API is unavailable)
  AiParseResult _localParse(String input) {
    final text = input.trim();
    if (text.isEmpty) return const AiParseResult(intent: 'unknown');

    // Several amounts in one sentence -> several records
    final split = _splitMultiRecord(text);
    if (split != null) return split;

    final amount = _extractAmount(text);

    if (amount == null) {
      // No amount: either a query or a category follow-up awaiting the amount
      if (_isQueryIntent(text)) return _buildQueryResult(text);
      final type = _detectType(text);
      final categoryId = _detectCategory(text, type);
      if (!_isOther(categoryId)) {
        return AiParseResult(
          intent: 'record',
          type: type,
          categoryId: categoryId,
          date: _detectDate(text),
        );
      }
      return const AiParseResult(intent: 'unknown');
    }

    if (amount <= 0) return const AiParseResult(intent: 'unknown');

    final hasRecordIntent = RegExp(
      r'(花|消费|支出|记|买了|买|付|充值|转|收入|赚|工资|奖金|退款|报销|返现)',
    ).hasMatch(text);
    final type = _detectType(text);
    final categoryId = _detectCategory(text, type);

    if (!hasRecordIntent && _isOther(categoryId)) {
      // A bare number that does not look like a record: maybe a query
      if (_isQueryIntent(text)) return _buildQueryResult(text);
      return const AiParseResult(intent: 'unknown');
    }

    return AiParseResult(
      intent: 'record',
      type: type,
      amount: amount,
      categoryId: categoryId,
      remark: _extractRemark(text),
      date: _detectDate(text),
    );
  }

  /// Query result that keeps the category / mood / location / date-range
  /// filters (the earlier version dropped them and queried the whole month).
  AiParseResult _buildQueryResult(String text) {
    final type = _detectType(text);
    final categoryId = _detectCategory(text, type);

    var location = _detectLocation(text);
    // "Starbucks" is both a landmark and a milk-tea keyword: if it matches a
    // category, treat it as the category and skip the extra location filter
    if (location != null && !_isOther(_detectCategory(location, 'expense'))) {
      location = null;
    }

    // "有定位的消费" = only records that have coordinates
    final requireLocation =
        RegExp(r'(有定位|带定位|定位的|有位置的|带位置)').hasMatch(text);

    final range = _detectDateRange(text);
    return AiParseResult(
      intent: 'query',
      queryPeriod: _detectQueryPeriod(text),
      queryCategoryId: _isOther(categoryId) ? null : categoryId,
      queryMood: _detectMood(text),
      queryLocation: location,
      queryStartDate: range?[0],
      queryEndDate: range?[1],
      queryRequireLocation: requireLocation,
    );
  }

  bool _isOther(String categoryId) =>
      categoryId == 'other' || categoryId == 'other_in';

  bool _isQueryIntent(String text) {
    const keywords = [
      '花了多少', '消费', '收入', '支出', '账单', '汇总', '统计',
      '查询', '查一下', '多少', '多少钱', '总共', '一共', '合计',
      '总计', '查看', '看看',
    ];
    if (keywords.any((k) => text.contains(k))) return true;
    // Filter-only phrasings that carry no record intent, e.g. "有定位的消费"
    return RegExp(r'(有定位|带定位|定位的|的消费|的记录|的账单|的时候)')
        .hasMatch(text);
  }

  String _detectQueryPeriod(String text) {
    if (text.contains('今天') || text.contains('今日')) return 'today';
    if (text.contains('本周') || text.contains('这周')) return 'week';
    if (text.contains('今年')) return 'year';
    return 'month'; // Default to this month
  }

  /// Mood keyword -> mood id
  String? _detectMood(String text) {
    const map = {
      '开心': 'happy', '高兴': 'happy', '爽': 'happy',
      '一般': 'normal', '还行': 'normal',
      '难过': 'sad', '伤心': 'sad', 'emo': 'sad',
      '生气': 'angry', '烦': 'angry',
      '焦虑': 'anxious', '紧张': 'anxious',
    };
    for (final entry in map.entries) {
      if (text.contains(entry.key)) return entry.value;
    }
    return null;
  }

  /// Location after "在", e.g. "在公司楼下的消费" -> "公司楼下"
  String? _detectLocation(String text) {
    final m = RegExp(
      r'在\s*([\u4e00-\u9fa5A-Za-z0-9]{1,12}?)\s*(?:的|消费|花|吃|买|喝|住|看|玩|用)',
    ).firstMatch(text);
    if (m == null) return null;
    final loc = m.group(1)!.trim();
    const ignored = ['这', '那', '哪', '这里', '那里', '哪里'];
    if (loc.isEmpty || ignored.contains(loc)) return null;
    return loc;
  }

  /// Explicit date range: "6月1号到6月10号", "6月1日", "2026-06-01", "上个月", "去年"
  List<String>? _detectDateRange(String text) {
    final now = DateTime.now();

    // ISO date(s)
    final iso =
        RegExp(r'(\d{4})-(\d{1,2})-(\d{1,2})').allMatches(text).toList();
    if (iso.isNotEmpty) {
      final first = _formatDate(DateTime(
        int.parse(iso.first.group(1)!),
        int.parse(iso.first.group(2)!),
        int.parse(iso.first.group(3)!),
      ));
      final last = iso.length > 1
          ? _formatDate(DateTime(
              int.parse(iso.last.group(1)!),
              int.parse(iso.last.group(2)!),
              int.parse(iso.last.group(3)!),
            ))
          : first;
      return [first, last];
    }

    // M月D号 to M月D号
    final range = RegExp(
      r'(\d{1,2})月(\d{1,2})[日号]?\s*(?:到|至|~|-|－|—)\s*(?:(\d{1,2})月)?(\d{1,2})[日号]?',
    ).firstMatch(text);
    if (range != null) {
      final m1 = int.parse(range.group(1)!);
      final d1 = int.parse(range.group(2)!);
      final m2 = range.group(3) != null ? int.parse(range.group(3)!) : m1;
      final d2 = int.parse(range.group(4)!);
      return [
        _formatDate(DateTime(now.year, m1, d1)),
        _formatDate(DateTime(now.year, m2, d2)),
      ];
    }

    // Single M月D号
    final single = RegExp(r'(\d{1,2})月(\d{1,2})[日号]').firstMatch(text);
    if (single != null) {
      final d = _formatDate(DateTime(
        now.year,
        int.parse(single.group(1)!),
        int.parse(single.group(2)!),
      ));
      return [d, d];
    }

    if (text.contains('上个月') || text.contains('上月')) {
      final firstOfPrev = DateTime(now.year, now.month - 1, 1);
      final lastOfPrev = DateTime(now.year, now.month, 0);
      return [_formatDate(firstOfPrev), _formatDate(lastOfPrev)];
    }
    if (text.contains('去年')) {
      return ['${now.year - 1}-01-01', '${now.year - 1}-12-31'];
    }
    return null;
  }

  /// Income vs expense
  String _detectType(String text) {
    const incomeKeywords = [
      '工资', '薪水', '月薪', '收入', '奖金', '年终', '提成',
      '理财', '利息', '分红', '股票', '基金', '兼职', '副业',
      '外快', '租金', '收租', '转入', '收到', '退款', '退回',
      '返现', '报销', '收款', '中奖', '赚了', '赚',
    ];
    if (incomeKeywords.any((k) => text.contains(k))) return 'income';
    // Red packet is ambiguous: receiving is income, sending is expense
    if (text.contains('红包') && RegExp(r'(收|领|抢|得|进)').hasMatch(text)) {
      return 'income';
    }
    return 'expense';
  }

  /// Per-category priority used to break ties on equal keyword length
  static const Map<String, int> _categoryPriority = {
    'health': 90,
    'social': 88,
    'pet': 86,
    'sport': 84,
    'travel': 82,
    'education': 80,
    'digital': 78,
    'clothing': 76,
    'housing': 74,
    'transport': 72,
    'milk_tea': 70,
    'snack': 68,
    'fruit': 66,
    'food': 64,
    'entertainment': 62,
    'transfer': 60,
    'red_packet': 58,
    'shopping': 40,
    'salary': 90,
    'bonus': 88,
    'invest': 86,
    'part_time': 84,
    'rent': 82,
  };

  static const Map<String, List<String>> _categoryKeywords = {
    'food': [
      '吃饭', '餐', '饭', '外卖', '食堂', '午餐', '晚餐', '早餐',
      '火锅', '烧烤', '餐厅', '菜', '肉', '蛋', '包子', '饺子', '夜宵',
    ],
    'milk_tea': ['奶茶', '咖啡', '星巴克', '饮料', '果汁', '茶'],
    'snack': ['零食', '薯片', '巧克力', '蛋糕', '甜品'],
    'fruit': [
      '水果', '苹果', '香蕉', '西瓜', '梨', '橙', '葡萄', '草莓', '桃',
      '芒果', '橘', '柚', '樱桃',
    ],
    'transport': [
      '打车', '出租', '地铁', '公交', '高铁', '火车', '飞机', '油费',
      '加油', '停车',
    ],
    'shopping': ['买', '购物', '超市', '淘宝', '京东', '拼多多', '日用'],
    'entertainment': ['电影', '游戏', 'KTV', '娱乐', '演出', '门票'],
    'health': ['医院', '药', '看病', '体检', '挂号', '药店'],
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

  String _detectCategory(String text, String type) {
    final categories = type == 'expense'
        ? CategoryOrderService.instance.expense
        : incomeCategories;

    var bestId = type == 'expense' ? 'other' : 'other_in';
    var bestScore = -1;

    for (final entry in _categoryKeywords.entries) {
      final id = entry.key;
      if (!categories.any((c) => c.id == id)) continue;
      final priority = _categoryPriority[id] ?? 0;
      // The category name itself is a keyword too ("交通", "购物", "医疗")
      final category = categories.firstWhere((c) => c.id == id);
      final keywords = <String>[category.name, ...entry.value];
      for (final keyword in keywords) {
        if (keyword.isEmpty || !text.contains(keyword)) continue;
        // Longer keywords win first (聚餐 > 餐), then higher priority (药 > 买)
        final score = keyword.length * 1000 + priority;
        if (score > bestScore) {
          bestScore = score;
          bestId = id;
        }
      }
    }
    return bestId;
  }

  /// Pick the most likely amount from the sentence.
  ///
  /// 1. A number followed by a currency unit (元/块/圆)
  /// 2. Then a number right after a spend/income cue (花/付/消费/收入/共...)
  /// 3. Otherwise the largest number that is not a date or a count
  double? _extractAmount(String text) {
    const unitAfter = ['元', '块', '圆'];
    const ignoreAfter = [
      '号', '日', '月', '年', '点', '时', '分', '秒',
      '个', '人', '份', '杯', '瓶', '张', '次', '只', '件',
      '颗', '袋', '盒', '包', '斤', '克', '公里', '米', '楼',
    ];
    const cueBefore = [
      '花', '付', '消费', '收入', '赚', '充', '共', '一共',
      '总计', '合计', '收', '退', '返', '报',
    ];

    double? unitHit;
    double? cueHit;
    double? maxHit;

    for (final m in RegExp(r'\d+(?:\.\d+)?').allMatches(text)) {
      final value = double.tryParse(m.group(0)!);
      if (value == null || value <= 0) continue;

      final afterEnd = m.end + 2 <= text.length ? m.end + 2 : text.length;
      final after = text.substring(m.end, afterEnd);
      final beforeStart = m.start - 8 >= 0 ? m.start - 8 : 0;
      final before = text.substring(beforeStart, m.start);

      final hasUnit = unitAfter.any((u) => after.startsWith(u));
      final ignored = ignoreAfter.any((u) => after.startsWith(u)) ||
          after.startsWith(':') ||
          after.startsWith('：');
      final hasCue = cueBefore.any((c) => before.contains(c));

      if (hasUnit) unitHit ??= value;
      if (!ignored && hasCue) cueHit ??= value;
      if (!ignored && (maxHit == null || value > maxHit)) maxHit = value;
    }

    // When every number is a date/count (e.g. "6月1号吃饭") there is no amount
    return unitHit ?? cueHit ?? maxHit ?? _parseChineseAmount(text);
  }

  /// Fallback for Chinese numerals followed by a currency unit ("二十五块")
  double? _parseChineseAmount(String text) {
    final m =
        RegExp(r'([零一二两三四五六七八九十百千万]+)(?:元|块钱|块)').firstMatch(text);
    if (m == null) return null;
    final value = _chineseToInt(m.group(1)!);
    return value > 0 ? value.toDouble() : null;
  }

  int _chineseToInt(String s) {
    const digits = {
      '零': 0, '一': 1, '二': 2, '两': 2, '三': 3, '四': 4,
      '五': 5, '六': 6, '七': 7, '八': 8, '九': 9,
    };
    const units = {'十': 10, '百': 100, '千': 1000};
    var total = 0;
    var section = 0;
    int? current;
    for (final ch in s.split('')) {
      if (digits.containsKey(ch)) {
        current = digits[ch];
      } else if (units.containsKey(ch)) {
        section += (current ?? 1) * units[ch]!;
        current = null;
      } else if (ch == '万') {
        total += (section + (current ?? 0)) * 10000;
        section = 0;
        current = null;
      }
    }
    return total + section + (current ?? 0);
  }

  String? _extractRemark(String text) {
    var remark = text.replaceAll(RegExp(r'\d+(?:\.\d+)?'), '');
    remark = remark.replaceAll(RegExp(r'(元|块钱|块|钱)'), '');
    remark = remark.replaceAll(RegExp(r'[个份杯瓶张次只件颗袋盒]'), '');
    remark = remark.replaceAll(
      RegExp(r'(记一笔|记|花了|花掉|花|消费|支出|收入|赚了|付了|付|买了|买|充值|转账给)'),
      '',
    );
    remark = remark.trim();
    if (remark.isEmpty) return null;
    return remark.length > 20 ? remark.substring(0, 20) : remark;
  }

  /// Detect the date (today/yesterday/the day before/X days ago/X last week)
  String? _detectDate(String text) {
    final now = DateTime.now();

    if (text.contains('大前天')) {
      return _formatDate(now.subtract(const Duration(days: 3)));
    }
    if (text.contains('前天')) {
      return _formatDate(now.subtract(const Duration(days: 2)));
    }
    if (text.contains('昨天')) {
      return _formatDate(now.subtract(const Duration(days: 1)));
    }
    if (text.contains('今天') || text.contains('今日')) {
      return _formatDate(now);
    }

    // X last week
    final weekdayMatch = RegExp(r'上周([一二三四五六日天])').firstMatch(text);
    if (weekdayMatch != null) {
      const weekdayMap = {
        '一': 1, '二': 2, '三': 3, '四': 4, '五': 5, '六': 6, '日': 7, '天': 7,
      };
      final targetDay = weekdayMap[weekdayMatch.group(1)]!;
      final daysAgo = now.weekday + 7 - targetDay;
      return _formatDate(now.subtract(Duration(days: daysAgo)));
    }

    // X days ago
    final daysAgoMatch = RegExp(r'(\d+)天前').firstMatch(text);
    if (daysAgoMatch != null) {
      final days = int.tryParse(daysAgoMatch.group(1)!) ?? 0;
      if (days > 0 && days <= 30) {
        return _formatDate(now.subtract(Duration(days: days)));
      }
    }

    return null; // Defaults to today
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}

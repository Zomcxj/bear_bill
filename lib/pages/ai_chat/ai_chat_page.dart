import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../services/database_service.dart';
import '../../services/glm_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/utils.dart' as utils;
import 'widgets/chat_bubble.dart';
import 'widgets/chat_input_bar.dart';

/// AI 对话式记账页面
class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _addWelcomeMessage() {
    _messages.add(const ChatMessage(
      id: 'welcome',
      text: '你好！我是小熊记账助手 🐻\n\n你可以直接告诉我消费内容，比如：\n• "午餐花了25"\n• "打车18元"\n• "工资收入8000"\n\n也可以问我：\n• "这个月花了多少"',
      isUser: false,
    ));
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend(String text) async {
    // 添加用户消息
    setState(() {
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: text,
        isUser: true,
      ));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final result = await GlmService.instance.parseUserInput(text);

      if (result.isRecord) {
        await _handleRecordResult(result);
      } else if (result.isQuery) {
        await _handleQueryResult(result);
      } else {
        _addBotMessage('抱歉，我没有理解你的意思 😅\n\n试试这样说：\n• "午餐花了25"\n• "打车18元"');
      }
    } catch (e) {
      _addBotMessage('出了点问题，请稍后再试 😢', type: ChatMessageType.error);
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  Future<void> _handleRecordResult(AiParseResult result) async {
    final category = getCategoryById(
      result.categoryId!,
      isExpense: result.type == 'expense',
    );

    final msgId = DateTime.now().millisecondsSinceEpoch.toString();
    setState(() {
      _messages.add(ChatMessage(
        id: msgId,
        text: '',
        isUser: false,
        type: ChatMessageType.recordConfirm,
        data: {
          'type': result.type,
          'amount': result.amount,
          'categoryId': result.categoryId,
          'categoryName': category?.name ?? '其他',
          'categoryIcon': category?.icon ?? '📦',
          'remark': result.remark,
        },
      ));
    });
  }

  Future<void> _handleQueryResult(AiParseResult result) async {
    final appProvider = context.read<AppProvider>();
    final bookId = appProvider.currentBookId;
    final now = DateTime.now();
    final period = result.queryPeriod ?? 'month';

    List<RecordModel> records;
    switch (period) {
      case 'today':
        records = await DatabaseService.instance.getTodayRecords(bookId: bookId);
        break;
      case 'week':
        records = await DatabaseService.instance.getWeekRecords(bookId: bookId);
        break;
      case 'year':
        final yearStr = '${now.year}';
        records = await DatabaseService.instance.getMonthRecords(
          '$yearStr-${now.month.toString().padLeft(2, '0')}',
          bookId: bookId,
        );
        // 获取全年数据
        records = [];
        for (int m = 1; m <= 12; m++) {
          final monthRecords = await DatabaseService.instance.getMonthRecords(
            '$yearStr-${m.toString().padLeft(2, '0')}',
            bookId: bookId,
          );
          records.addAll(monthRecords);
        }
        break;
      case 'month':
      default:
        final monthStr =
            '${now.year}-${now.month.toString().padLeft(2, '0')}';
        records = await DatabaseService.instance.getMonthRecords(
          monthStr,
          bookId: bookId,
        );
    }

    double totalExpense = 0;
    double totalIncome = 0;
    final Map<String, Map<String, dynamic>> categoryBreakdown = {};

    for (final r in records) {
      if (r.type == 'expense') {
        totalExpense += r.amount;
        final key = r.categoryId;
        if (!categoryBreakdown.containsKey(key)) {
          categoryBreakdown[key] = {
            'name': r.categoryName,
            'icon': r.categoryIcon,
            'amount': 0.0,
          };
        }
        categoryBreakdown[key]!['amount'] =
            (categoryBreakdown[key]!['amount'] as double) + r.amount;
      } else {
        totalIncome += r.amount;
      }
    }

    final msgId = DateTime.now().millisecondsSinceEpoch.toString();
    setState(() {
      _messages.add(ChatMessage(
        id: msgId,
        text: '',
        isUser: false,
        type: ChatMessageType.queryResult,
        data: {
          'period': period,
          'totalExpense': totalExpense,
          'totalIncome': totalIncome,
          'count': records.length,
          'categoryBreakdown': categoryBreakdown,
        },
      ));
    });
  }

  void _addBotMessage(String text, {ChatMessageType type = ChatMessageType.text}) {
    setState(() {
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: text,
        isUser: false,
        type: type,
      ));
    });
  }

  Future<void> _confirmRecord(ChatMessage msg) async {
    final data = msg.data!;
    final appProvider = context.read<AppProvider>();
    final type = data['type'] as String;
    final amount = data['amount'] as double;
    final categoryId = data['categoryId'] as String;
    final categoryName = data['categoryName'] as String;
    final categoryIcon = data['categoryIcon'] as String;
    final remark = data['remark'] as String?;

    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final category = getCategoryById(categoryId, isExpense: type == 'expense');

    final record = RecordModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      bookId: appProvider.currentBookId,
      type: type,
      amount: amount,
      categoryId: categoryId,
      categoryName: categoryName,
      categoryIcon: categoryIcon,
      categoryColor: category?.color,
      remark: remark,
      date: dateStr,
      month: dateStr.substring(0, 7),
      dateTs: now.millisecondsSinceEpoch,
      createdAt: now,
    );

    await DatabaseService.instance.insertRecord(record);
    NotificationService.instance.refreshTodaySummary();

    final achievements = await appProvider.onRecordAdded(
      type: type,
      amount: amount,
    );
    final checkInAchievements = await appProvider.recordCheckIn();
    achievements.addAll(checkInAchievements);

    _addBotMessage(
      '记账成功！${type == 'expense' ? '-' : '+'}¥${amount.toStringAsFixed(2)} ${categoryName}',
    );

    if (achievements.isNotEmpty) {
      final names = achievements.map((a) => '${a.emoji} ${a.title}').join('\n');
      _addBotMessage('解锁新成就！\n$names');
    }

    _scrollToBottom();
  }

  void _modifyRecord(ChatMessage msg) {
    // 删除确认消息，让用户重新输入
    setState(() {
      _messages.remove(msg);
    });
    _addBotMessage('好的，请告诉我正确的信息～');
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPage,
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🐻', style: TextStyle(fontSize: 20)),
            SizedBox(width: 8),
            Text(
              'AI 记账',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.primary,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 提示条
          if (!GlmService.instance.isConfigured)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: AppTheme.primaryLight,
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: AppTheme.primaryDark),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '未配置 GLM API Key，使用本地关键词解析（精度较低）',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.primaryDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // 消息列表
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  // 加载指示器
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLight,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Center(
                            child: Text('🐻', style: TextStyle(fontSize: 20)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.bgCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: AppTheme.border.withOpacity(0.5)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.primary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '思考中...',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final msg = _messages[index];
                return ChatBubble(
                  message: msg,
                  onConfirm: msg.type == ChatMessageType.recordConfirm
                      ? () => _confirmRecord(msg)
                      : null,
                  onModify: msg.type == ChatMessageType.recordConfirm
                      ? () => _modifyRecord(msg)
                      : null,
                );
              },
            ),
          ),
          // 输入栏
          ChatInputBar(onSend: _handleSend),
        ],
      ),
    );
  }
}

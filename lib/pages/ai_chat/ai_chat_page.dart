import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/database_service.dart';
import '../../services/glm_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_design_system.dart';
import '../../theme/glass_materials.dart';
import '../add_record/add_record_page.dart';
import 'ai_chat_location_mixin.dart';
import 'ai_chat_query_mixin.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/chat_input_bar.dart';
import '../../widgets/glass_sub_page_bar.dart';

/// AI conversational bookkeeping page
class AiChatPage extends StatefulWidget {
  final String? initialText;

  const AiChatPage({super.key, this.initialText});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage>
    with AiChatLocationMixin, AiChatQueryMixin {
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  final Map<String, MoodModel?> _msgMoods = {};
  final Set<String> _confirmedMessageIds = {}; // Confirmed message IDs, prevents duplicate records

  @override
  List<ChatMessage> get messages => _messages;

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
    if (widget.initialText != null && widget.initialText!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleSend(widget.initialText!);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _addWelcomeMessage() {
    _messages.add(const ChatMessage(
      id: 'welcome',
      text:
          '你好！我是小熊记账助手 🐻\n\n你可以直接告诉我消费内容，比如：\n• "午餐花了25"\n• "昨天打车18元"\n• "前天奶茶12"\n• "工资收入8000"\n\n也可以说分类名，我会追问金额：\n• "交通"、"购物"、"餐饮"\n\n或者问我：\n• "这个月花了多少"\n• "餐饮这个月花了多少"\n• "开心时候的消费"\n• "在星巴克的记录"\n• "6月1号到10号的账单"',
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

  // Category info pending an amount (used for multi-turn dialogue)
  Map<String, dynamic>? _pendingCategory;

  Future<void> _handleSend(String text) async {
    // Append the user message
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
      // A pending category waits for an amount. Accept it only when the reply
      // is basically just a number (optionally with a unit/date); anything
      // else is a brand-new sentence and must not inherit the old context.
      if (_pendingCategory != null) {
        final pending = _pendingCategory;
        _pendingCategory = null;
        final amount = _amountOnlyReply(text);
        if (amount != null) {
          await _handleRecordResult(AiParseResult(
            intent: 'record',
            type: pending!['type'] as String,
            amount: amount,
            categoryId: pending['categoryId'] as String,
            remark: pending['remark'] as String?,
            date: pending['date'] as String?,
          ));
          setState(() => _isLoading = false);
          _scrollToBottom();
          return;
        }
      }

      final result = await GlmService.instance.parseUserInput(text);

      // One sentence may contain several records (multi-item result)
      final multi = result.items.where((e) => e.isRecord).toList();
      final primary = result.items.isNotEmpty ? result.items.first : result;

      if (multi.isNotEmpty) {
        for (final item in multi) {
          await _handleRecordResult(item);
        }
      } else if (primary.isRecord) {
        await _handleRecordResult(primary);
      } else if (primary.intent == 'record' && primary.amount == null) {
        // Category recognized but no amount; ask for the amount
        final category = getCategoryById(
          primary.categoryId ?? 'other',
          isExpense: primary.type == 'expense',
        );
        final icon = category?.icon ?? '📦';
        final name = category?.name ?? '消费';
        _pendingCategory = {
          'type': primary.type ?? 'expense',
          'categoryId': primary.categoryId ?? 'other',
          'remark': primary.remark,
          'date': primary.date,
        };
        _addBotMessage('$icon 请问${name}花了多少钱？');
      } else if (primary.isQuery) {
        await _handleQueryResult(primary);
      } else {
        _addBotMessage(
            '抱歉，我没有理解你的意思 😅\n\n试试这样说：\n• "午餐花了25"\n• "打车18元"\n• "交通"（然后告诉我金额）');
      }
    } catch (e) {
      _addBotMessage('出了点问题，请稍后再试 😢', type: ChatMessageType.error);
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  /// Parse a reply that is essentially just an amount ("30", "30块", "三十").
  /// Returns null for anything longer, so full sentences are re-parsed fresh.
  double? _amountOnlyReply(String text) {
    final t = text
        .replaceAll(RegExp(r'[元块圆钱]'), '')
        .replaceAll(RegExp(r'[\s,，。．.]'), '')
        .trim();
    if (t.isEmpty) return null;
    // Digits only, or a short pure-Chinese numeral
    if (RegExp(r'^\d+(\.\d+)?$').hasMatch(t)) {
      final v = double.tryParse(t);
      return (v != null && v > 0) ? v : null;
    }
    if (RegExp(r'^[零一二两三四五六七八九十百千万]{1,8}$').hasMatch(t)) {
      final v = GlmService.instance.parseChineseNumber(t);
      return v > 0 ? v.toDouble() : null;
    }
    return null;
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
          'date': result.date,
        },
      ));
      msgLocationLoading[msgId] = true;
    });

    // Automatically fetch GPS location
    fetchLocationForMsg(msgId);
  }

  Future<void> _handleQueryResult(AiParseResult result) async {
    await handleQueryResult(result);
  }

  void _addBotMessage(String text,
      {ChatMessageType type = ChatMessageType.text}) {
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
    // Prevent duplicate records
    if (_confirmedMessageIds.contains(msg.id)) return;
    _confirmedMessageIds.add(msg.id);

    final data = msg.data!;
    final appProvider = context.read<AppProvider>();
    final type = data['type'] as String;
    final amount = data['amount'] as double;
    final categoryId = data['categoryId'] as String;
    final categoryName = data['categoryName'] as String;
    final categoryIcon = data['categoryIcon'] as String;
    final remark = data['remark'] as String?;
    final dateStr = data['date'] as String?;

    final now = DateTime.now();
    final date = dateStr != null && dateStr.length == 10
        ? DateTime.tryParse(dateStr) ?? now
        : now;
    final finalDateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final category = getCategoryById(categoryId, isExpense: type == 'expense');

    // Read mood and location
    final mood = _msgMoods[msg.id];
    final location = msgLocations[msg.id];
    final lat = msgLat[msg.id];
    final lng = msgLng[msg.id];

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
      date: finalDateStr,
      month: finalDateStr.substring(0, 7),
      dateTs: date.millisecondsSinceEpoch,
      createdAt: now,
      mood: mood?.id,
      moodEmoji: mood?.emoji,
      location: location,
      latitude: lat,
      longitude: lng,
    );

    await DatabaseService.instance.insertRecord(record);
    NotificationService.instance.refreshTodaySummary();

    // Save the frequently visited place
    if (location != null && lat != null && lng != null) {
      await DatabaseService.instance.upsertFavoriteLocation(
        name: location,
        address: location,
        latitude: lat,
        longitude: lng,
      );
    }

    // Clean up state
    _msgMoods.remove(msg.id);
    msgLocations.remove(msg.id);
    msgLat.remove(msg.id);
    msgLng.remove(msg.id);
    msgLocationLoading.remove(msg.id);

    final achievements = await appProvider.onRecordAdded(
      type: type,
      amount: amount,
    );
    final checkInAchievements = await appProvider.recordCheckIn();
    achievements.addAll(checkInAchievements);

    String dateLabel = '';
    if (finalDateStr !=
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}') {
      try {
        final d = DateTime.parse(finalDateStr);
        dateLabel = d.year == now.year
            ? ' (${d.month}月${d.day}日)'
            : ' (${d.year}年${d.month}月${d.day}日)';
      } catch (_) {
        dateLabel = ' ($finalDateStr)';
      }
    }
    final moodLabel = mood != null ? ' ${mood.emoji}' : '';
    _addBotMessage(
      '记账成功！${type == 'expense' ? '-' : '+'}¥${amount.toStringAsFixed(2)} $categoryName$dateLabel$moodLabel',
    );

    if (achievements.isNotEmpty) {
      final names = achievements.map((a) => '${a.emoji} ${a.title}').join('\n');
      _addBotMessage('解锁新成就！\n$names');
    }

    _scrollToBottom();
  }

  void _modifyRecord(ChatMessage msg) {
    final data = msg.data;
    if (data == null) return;

    // Read mood and location (cleared after saving)
    final location = msgLocations[msg.id];
    final lat = msgLat[msg.id];
    final lng = msgLng[msg.id];
    final mood = _msgMoods[msg.id];

    // Clean up mood and location state
    _msgMoods.remove(msg.id);
    msgLocations.remove(msg.id);
    msgLat.remove(msg.id);
    msgLng.remove(msg.id);
    msgLocationLoading.remove(msg.id);

    // Remove the confirmation message
    setState(() {
      _messages.remove(msg);
    });

    // Build a temporary RecordModel carrying all entered data (including location)
    final type = data['type'] as String? ?? 'expense';
    final amount = data['amount'] as double? ?? 0;
    final categoryId = data['categoryId'] as String? ?? 'other';
    final categoryName = data['categoryName'] as String? ?? '其他';
    final categoryIcon = data['categoryIcon'] as String? ?? '📦';
    final remark = data['remark'] as String?;
    final dateStr = data['date'] as String?;

    final now = DateTime.now();
    final date = dateStr != null && dateStr.length == 10
        ? DateTime.tryParse(dateStr) ?? now
        : now;
    final finalDateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final category = getCategoryById(categoryId, isExpense: type == 'expense');

    final tempRecord = RecordModel(
      id: 'temp_edit',
      bookId: 'default',
      type: type,
      amount: amount,
      categoryId: categoryId,
      categoryName: categoryName,
      categoryIcon: categoryIcon,
      categoryColor: category?.color,
      remark: remark,
      date: finalDateStr,
      month: finalDateStr.substring(0, 7),
      dateTs: date.millisecondsSinceEpoch,
      createdAt: now,
      mood: mood?.id,
      moodEmoji: mood?.emoji,
      location: location,
      latitude: lat,
      longitude: lng,
    );

    // Navigate to the add-record page with prefilled data; go back to the home page after saving
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddRecordPage(prefillRecord: tempRecord),
      ),
    ).then((saved) {
      if (saved == true && mounted) {
        // Saved successfully; go back to the home page
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>(); // theme rebuild
    return Scaffold(
      backgroundColor: DS.background,
      appBar: const GlassSubPageBar(title: '🐻 AI 记账'),
      body: Column(
        children: [
          // Notice banner
          if (!GlmService.instance.isConfigured)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: DS.surfaceContainerHigh,
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 14, color: DS.emphasis),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '未配置 GLM API Key，使用本地关键词解析（精度较低）',
                      style: TextStyle(
                        fontSize: 11,
                        color: DS.emphasis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Message list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(vertical: 12),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  // Loading indicator
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: DS.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Center(
                            child: Text('🐻', style: TextStyle(fontSize: 20)),
                          ),
                        ),
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: DS.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(16),
                            // Glass theme has no border; unchanged when off
                            border: shouldUseLiquidGlass(context)
                                ? null
                                : Border.all(
                                    color: DS.outlineVariant.withOpacity(0.5)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: DS.emphasis,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                '思考中...',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: DS.onSurfaceVariant,
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
                  selectedMood: _msgMoods[msg.id],
                  onMoodChanged: msg.type == ChatMessageType.recordConfirm
                      ? (mood) => setState(() => _msgMoods[msg.id] = mood)
                      : null,
                  location: msgLocations[msg.id],
                  locationLoading: msgLocationLoading[msg.id] ?? false,
                  onLocationTap: msg.type == ChatMessageType.recordConfirm
                      ? () => showLocationOptions(msg.id, () => setState(() {}))
                      : null,
                  confirmed: _confirmedMessageIds.contains(msg.id),
                );
              },
            ),
          ),
          // Input bar
          ChatInputBar(onSend: _handleSend),
        ],
      ),
    );
  }
}

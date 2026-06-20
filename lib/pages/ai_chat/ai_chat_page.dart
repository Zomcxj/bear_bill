import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../services/amap_location_service.dart';
import '../../services/database_service.dart';
import '../../services/glm_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_design_system.dart';
import '../add_record/add_record_page.dart';
import '../add_record/widgets/map_picker_page.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/chat_input_bar.dart';

/// AI 对话式记账页面
class AiChatPage extends StatefulWidget {
  final String? initialText;

  const AiChatPage({super.key, this.initialText});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  // 每条确认消息的心情和定位状态
  final Map<String, MoodModel?> _msgMoods = {};
  final Map<String, String?> _msgLocations = {};
  final Map<String, double?> _msgLat = {};
  final Map<String, double?> _msgLng = {};
  final Map<String, bool> _msgLocationLoading = {};

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
      text: '你好！我是小熊记账助手 🐻\n\n你可以直接告诉我消费内容，比如：\n• "午餐花了25"\n• "昨天打车18元"\n• "前天奶茶12"\n• "工资收入8000"\n\n也可以说分类名，我会追问金额：\n• "交通"、"购物"、"餐饮"\n\n或者问我：\n• "这个月花了多少"\n• "餐饮这个月花了多少"\n• "开心时候的消费"\n• "在星巴克的记录"\n• "6月1号到10号的账单"',
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

  // 待补充金额的分类信息（用于连续对话）
  Map<String, dynamic>? _pendingCategory;

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
      // 如果有待补充金额的分类，先尝试把当前输入当金额
      if (_pendingCategory != null) {
        final amountMatch = RegExp(r'(\d+\.?\d*)').firstMatch(text.trim());
        if (amountMatch != null) {
          final amount = double.parse(amountMatch.group(1)!);
          if (amount > 0) {
            final pending = _pendingCategory!;
            _pendingCategory = null;
            final result = AiParseResult(
              intent: 'record',
              type: pending['type'] as String,
              amount: amount,
              categoryId: pending['categoryId'] as String,
              remark: pending['remark'] as String?,
              date: pending['date'] as String?,
            );
            await _handleRecordResult(result);
            setState(() => _isLoading = false);
            _scrollToBottom();
            return;
          }
        }
        // 输入不是金额，清空待补充状态，继续正常解析
        _pendingCategory = null;
      }

      final result = await GlmService.instance.parseUserInput(text);

      if (result.isRecord) {
        await _handleRecordResult(result);
      } else if (result.intent == 'record' && result.amount == null) {
        // 识别到分类但没有金额，追问金额
        final category = getCategoryById(
          result.categoryId ?? 'other',
          isExpense: result.type == 'expense',
        );
        final icon = category?.icon ?? '📦';
        final name = category?.name ?? '消费';
        _pendingCategory = {
          'type': result.type ?? 'expense',
          'categoryId': result.categoryId ?? 'other',
          'remark': result.remark,
          'date': result.date,
        };
        _addBotMessage('$icon 请问${name}花了多少钱？');
      } else if (result.isQuery) {
        await _handleQueryResult(result);
      } else {
        _addBotMessage('抱歉，我没有理解你的意思 😅\n\n试试这样说：\n• "午餐花了25"\n• "打车18元"\n• "交通"（然后告诉我金额）');
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
          'date': result.date,
        },
      ));
      _msgLocationLoading[msgId] = true;
    });

    // 自动获取 GPS 定位
    _fetchLocationForMsg(msgId);
  }

  Future<void> _fetchLocationForMsg(String msgId) async {
    try {
      // 检查定位服务
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() => _msgLocationLoading[msgId] = false);
        return;
      }

      // 检查权限
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _msgLocationLoading[msgId] = false);
        return;
      }

      // 获取位置
      Position? position = await Geolocator.getLastKnownPosition();
      try {
        position ??= await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
        ).timeout(const Duration(seconds: 12));
      } catch (_) {
        // 定位超时或失败
      }

      if (!mounted || position == null) {
        if (mounted) setState(() => _msgLocationLoading[msgId] = false);
        return;
      }

      _msgLat[msgId] = position.latitude;
      _msgLng[msgId] = position.longitude;

      // 反向地理编码
      String? address;
      try {
        final amapResult = await AmapLocationService.instance
            .reverseGeocode(position.latitude, position.longitude)
            .timeout(const Duration(seconds: 5), onTimeout: () => null);
        address = amapResult?.shortAddress;
      } catch (_) {}

      // 降级：Android 原生 Geocoder
      if (address == null || address.isEmpty) {
        try {
          final result = await const MethodChannel('bear_bill/location')
              .invokeMethod<String>('reverseGeocode', {
            'latitude': position.latitude,
            'longitude': position.longitude,
          });
          address = result;
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _msgLocations[msgId] = address;
          _msgLocationLoading[msgId] = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _msgLocationLoading[msgId] = false);
    }
  }

  Future<void> _handleQueryResult(AiParseResult result) async {
    final appProvider = context.read<AppProvider>();
    final bookId = appProvider.currentBookId;
    final now = DateTime.now();
    final period = result.queryPeriod ?? 'month';

    // 根据时间段计算日期范围
    String? startDate;
    String? endDate;
    String periodLabel;

    // 自定义日期范围优先
    if (result.queryStartDate != null || result.queryEndDate != null) {
      startDate = result.queryStartDate;
      endDate = result.queryEndDate;
      periodLabel = _formatDateRangeLabel(startDate, endDate);
    } else {
      switch (period) {
        case 'today':
          startDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
          endDate = startDate;
          periodLabel = '今日';
          break;
        case 'week':
          final weekStart = now.subtract(Duration(days: now.weekday - 1));
          startDate = '${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';
          endDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
          periodLabel = '本周';
          break;
        case 'year':
          startDate = '${now.year}-01-01';
          endDate = '${now.year}-12-31';
          periodLabel = '${now.year}年';
          break;
        case 'month':
        default:
          startDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
          endDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-31';
          periodLabel = '${now.month}月';
      }
    }

    // 使用灵活查询
    List<RecordModel> records = await DatabaseService.instance.queryRecords(
      startDate: startDate,
      endDate: endDate,
      categoryId: result.queryCategoryId,
      mood: result.queryMood,
      locationKeyword: result.queryLocation,
      bookId: bookId,
    );

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

    // 构建筛选描述
    String filterDesc = '';
    if (result.queryCategoryId != null) {
      final cat = getCategoryById(result.queryCategoryId!, isExpense: true);
      filterDesc += '${cat?.icon ?? ''} ${cat?.name ?? result.queryCategoryId} ';
    }
    if (result.queryMood != null) {
      final mood = moods.where((m) => m.id == result.queryMood).firstOrNull;
      filterDesc += '${mood?.emoji ?? ''} ${mood?.label ?? result.queryMood}心情 ';
    }
    if (result.queryLocation != null) {
      filterDesc += '📍${result.queryLocation} ';
    }

    final msgId = DateTime.now().millisecondsSinceEpoch.toString();
    setState(() {
      _messages.add(ChatMessage(
        id: msgId,
        text: '',
        isUser: false,
        type: ChatMessageType.queryResult,
        data: {
          'period': periodLabel,
          'filterDesc': filterDesc.trim(),
          'totalExpense': totalExpense,
          'totalIncome': totalIncome,
          'count': records.length,
          'categoryBreakdown': categoryBreakdown,
        },
      ));
    });
  }

  String _formatDateRangeLabel(String? start, String? end) {
    if (start == null && end == null) return '';
    String label = '';
    if (start != null) {
      try {
        final d = DateTime.parse(start);
        label = '${d.month}月${d.day}日';
      } catch (_) {
        label = start;
      }
    }
    if (end != null && end != start) {
      try {
        final d = DateTime.parse(end);
        label += '~${d.month}月${d.day}日';
      } catch (_) {
        label += '~$end';
      }
    }
    return label;
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
    final dateStr = data['date'] as String?;

    final now = DateTime.now();
    final date = dateStr != null && dateStr.length == 10
        ? DateTime.tryParse(dateStr) ?? now
        : now;
    final finalDateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final category = getCategoryById(categoryId, isExpense: type == 'expense');

    // 读取心情和定位
    final mood = _msgMoods[msg.id];
    final location = _msgLocations[msg.id];
    final lat = _msgLat[msg.id];
    final lng = _msgLng[msg.id];

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

    // 保存常去地点
    if (location != null && lat != null && lng != null) {
      await DatabaseService.instance.upsertFavoriteLocation(
        name: location,
        address: location,
        latitude: lat,
        longitude: lng,
      );
    }

    // 清理状态
    _msgMoods.remove(msg.id);
    _msgLocations.remove(msg.id);
    _msgLat.remove(msg.id);
    _msgLng.remove(msg.id);
    _msgLocationLoading.remove(msg.id);

    final achievements = await appProvider.onRecordAdded(
      type: type,
      amount: amount,
    );
    final checkInAchievements = await appProvider.recordCheckIn();
    achievements.addAll(checkInAchievements);

    String dateLabel = '';
    if (finalDateStr != '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}') {
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

    // 清理心情和定位状态
    _msgMoods.remove(msg.id);
    _msgLocations.remove(msg.id);
    _msgLat.remove(msg.id);
    _msgLng.remove(msg.id);
    _msgLocationLoading.remove(msg.id);

    // 删除确认消息
    setState(() {
      _messages.remove(msg);
    });

    // 跳转到记账页，预填类型
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddRecordPage(
          initialType: data['type'] as String?,
        ),
      ),
    );
  }

  void _showLocationOptions(String msgId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.my_location, color: DS.primary),
              title: Text('重新获取 GPS 定位'),
              onTap: () {
                Navigator.pop(ctx);
                setState(() {
                  _msgLocationLoading[msgId] = true;
                  _msgLocations[msgId] = null;
                });
                _fetchLocationForMsg(msgId);
              },
            ),
            ListTile(
              leading: Icon(Icons.map, color: DS.primary),
              title: Text('地图选点'),
              onTap: () {
                Navigator.pop(ctx);
                _openMapPicker(msgId);
              },
            ),
            if (_msgLocations[msgId] != null)
              ListTile(
                leading: Icon(Icons.clear, color: DS.outline),
                title: Text('清除位置'),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _msgLocations[msgId] = null;
                    _msgLat[msgId] = null;
                    _msgLng[msgId] = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openMapPicker(String msgId) async {
    LatLng? initialCenter;
    if (_msgLat[msgId] != null && _msgLng[msgId] != null) {
      initialCenter = LatLng(_msgLat[msgId]!, _msgLng[msgId]!);
    }

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => MapPickerPage(initialCenter: initialCenter),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _msgLocations[msgId] = result['address'] as String?;
        _msgLat[msgId] = result['latitude'] as double?;
        _msgLng[msgId] = result['longitude'] as double?;
        _msgLocationLoading[msgId] = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DS.background,
      appBar: AppBar(
        title: Row(
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
        backgroundColor: DS.primary,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 提示条
          if (!GlmService.instance.isConfigured)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: DS.surfaceContainerHigh,
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: DS.primaryContainer),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '未配置 GLM API Key，使用本地关键词解析（精度较低）',
                      style: TextStyle(
                        fontSize: 11,
                        color: DS.primaryContainer,
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
              padding: EdgeInsets.symmetric(vertical: 12),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  // 加载指示器
                  return Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
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
                            border: Border.all(
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
                                  color: DS.primary,
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
                  location: _msgLocations[msg.id],
                  locationLoading: _msgLocationLoading[msg.id] ?? false,
                  onLocationTap: msg.type == ChatMessageType.recordConfirm
                      ? () => _showLocationOptions(msg.id)
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

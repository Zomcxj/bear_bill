import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../services/database_service.dart';
import '../../services/glm_service.dart';
import 'ai_chat_page.dart';
import 'widgets/chat_bubble.dart';

/// AI 记账页 - 查询相关功能
mixin AiChatQueryMixin on State<AiChatPage> {
  List<ChatMessage> get messages;

  Future<void> handleQueryResult(AiParseResult result) async {
    final appProvider = context.read<AppProvider>();
    final bookId = appProvider.currentBookId;
    final now = DateTime.now();
    final period = result.queryPeriod ?? 'month';

    String? startDate;
    String? endDate;
    String periodLabel;

    if (result.queryStartDate != null || result.queryEndDate != null) {
      startDate = result.queryStartDate;
      endDate = result.queryEndDate;
      periodLabel = _formatDateRangeLabel(startDate, endDate);
    } else {
      switch (period) {
        case 'today':
          startDate =
              '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
          endDate = startDate;
          periodLabel = '今日';
          break;
        case 'week':
          final weekStart = now.subtract(Duration(days: now.weekday - 1));
          startDate =
              '${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';
          endDate =
              '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
          periodLabel = '本周';
          break;
        case 'year':
          startDate = '${now.year}-01-01';
          endDate = '${now.year}-12-31';
          periodLabel = '${now.year}年';
          break;
        case 'month':
        default:
          startDate =
              '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
          endDate =
              '${now.year}-${now.month.toString().padLeft(2, '0')}-31';
          periodLabel = '${now.month}月';
      }
    }

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

    String filterDesc = '';
    if (result.queryCategoryId != null) {
      final cat =
          getCategoryById(result.queryCategoryId!, isExpense: true);
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
      messages.add(ChatMessage(
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
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../services/database_service.dart';
import '../../services/glm_service.dart';
import 'ai_chat_page.dart';
import 'widgets/chat_bubble.dart';

/// AI recording page - query-related features
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
          startDate = _formatDate(DateTime(now.year, now.month, 1));
          endDate = _formatDate(DateTime(now.year, now.month + 1, 0));
          periodLabel = '${now.month}月';
      }
    }

    // "有定位的消费": filter by the presence of coordinates
    List<RecordModel> records = result.queryRequireLocation
        ? await DatabaseService.instance.getRecordsWithLocation(
            bookId: bookId,
          )
        : await DatabaseService.instance.queryRecords(
            startDate: startDate,
            endDate: endDate,
            categoryId: result.queryCategoryId,
            mood: result.queryMood,
            locationKeyword: result.queryLocation,
            bookId: bookId,
          );

    if (result.queryRequireLocation) {
      records = records.where((r) {
        if (r.date.compareTo(startDate ?? '') < 0) return false;
        if (r.date.compareTo(endDate ?? '9999-12-31') > 0) return false;
        if (result.queryCategoryId != null &&
            r.categoryId != result.queryCategoryId) {
          return false;
        }
        if (result.queryMood != null && r.mood != result.queryMood) return false;
        if (result.queryLocation != null &&
            !(r.location ?? '').contains(result.queryLocation!)) {
          return false;
        }
        return true;
      }).toList();
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

    String filterDesc = '';
    if (result.queryCategoryId != null) {
      final id = result.queryCategoryId!;
      // Category ids may live in either the expense or the income list
      final cat = getCategoryById(id, isExpense: true) ??
          getCategoryById(id, isExpense: false);
      filterDesc += '${cat?.icon ?? ''} ${cat?.name ?? id} ';
    }
    if (result.queryMood != null) {
      final mood = moods.where((m) => m.id == result.queryMood).firstOrNull;
      filterDesc += '${mood?.emoji ?? ''} ${mood?.label ?? result.queryMood}心情 ';
    }
    if (result.queryLocation != null) {
      filterDesc += '📍${result.queryLocation} ';
    }
    if (result.queryRequireLocation) {
      filterDesc += '📍有定位 ';
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

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
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

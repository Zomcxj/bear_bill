import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/app_card.dart';
import '../../add_record/add_record_page.dart';
import '../../ai_chat/ai_chat_page.dart';

/// 快捷记账入口（对齐小程序 6列 Grid 布局）
class QuickEntries extends StatelessWidget {
  const QuickEntries({super.key});

  // 常用高频分类
  static final List<Map<String, dynamic>> _entries = [
    {
      'id': '__ai__',
      'icon': '🤖',
      'label': 'AI记账',
      'color': Color(0xFF74B9FF),
      'type': '__ai__',
    },
    {
      'id': 'food',
      'icon': '🍜',
      'label': '餐饮',
      'color': AppTheme.primaryLight,
      'type': 'expense'
    },
    {
      'id': 'transport',
      'icon': '🚗',
      'label': '交通',
      'color': Color(0xFFB2F2BB),
      'type': 'expense'
    },
    {
      'id': 'shopping',
      'icon': '🛍️',
      'label': '购物',
      'color': Color(0xFFA5D8FF),
      'type': 'expense'
    },
    {
      'id': 'milk_tea',
      'icon': '🧋',
      'label': '奶茶',
      'color': Color(0xFFFFE066),
      'type': 'expense'
    },
    {
      'id': 'snack',
      'icon': '🍿',
      'label': '零食',
      'color': Color(0xFFFFD8A8),
      'type': 'expense'
    },
    {
      'id': 'housing',
      'icon': '🏠',
      'label': '居住',
      'color': Color(0xFFE5DBFF),
      'type': 'expense'
    },
    {
      'id': 'entertainment',
      'icon': '🎮',
      'label': '娱乐',
      'color': Color(0xFFD0BFFF),
      'type': 'expense'
    },
    {
      'id': 'salary',
      'icon': '💰',
      'label': '工资',
      'color': Color(0xFFB2F2BB),
      'type': 'income'
    },
    {
      'id': 'bonus',
      'icon': '🎁',
      'label': '奖金',
      'color': Color(0xFFFFE066),
      'type': 'income'
    },
    {
      'id': 'transfer',
      'icon': '💸',
      'label': '转账',
      'color': Color(0xFFFFC9A9),
      'type': 'income'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '⚡ 快捷记账',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          // 水平滑动列表（更紧凑，无垂直空白）
          SizedBox(
            height: 70,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(), // 弹性滚动效果
              itemCount: _entries.length,
              itemBuilder: (context, index) {
                final entry = _entries[index];
                return Padding(
                  padding: EdgeInsets.only(
                    right: index < _entries.length - 1 ? 12 : 0,
                  ),
                  child: SizedBox(
                    width: 52,
                    child: _QuickEntryItem(
                      icon: entry['icon'],
                      label: entry['label'],
                      color: entry['color'],
                      categoryId: entry['id'],
                      recordType: entry['type'] ?? 'expense',
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickEntryItem extends StatelessWidget {
  final String icon;
  final String label;
  final Color color;
  final String categoryId;
  final String recordType; // expense | income

  const _QuickEntryItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.categoryId,
    required this.recordType,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (recordType == '__ai__') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AiChatPage()),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddRecordPage(
                preselectedCategory: categoryId,
                initialType: recordType,
              ),
            ),
          );
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3), width: 1),
            ),
            child: Center(
              child: Text(icon, style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

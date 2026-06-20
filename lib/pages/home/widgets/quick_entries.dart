import 'package:flutter/material.dart';

import '../../../theme/app_design_system.dart';
import '../../../widgets/glass_card.dart';
import '../../add_record/add_record_page.dart';
import '../../ai_chat/ai_chat_page.dart';

/// 快捷记账入口 — 水平滑动 + 圆形分类图标
class QuickEntries extends StatelessWidget {
  const QuickEntries({super.key});

  static final List<Map<String, dynamic>> _entries = [
    {
      'id': '__ai__',
      'icon': Icons.auto_awesome,
      'label': 'AI记账',
      'color': DS.secondaryContainer,
      'type': '__ai__',
    },
    {
      'id': 'food',
      'icon': Icons.restaurant,
      'label': '餐饮',
      'color': const Color(0xFFFFD6E0),
      'type': 'expense'
    },
    {
      'id': 'transport',
      'icon': Icons.directions_car,
      'label': '交通',
      'color': const Color(0xFFB2F2BB),
      'type': 'expense'
    },
    {
      'id': 'shopping',
      'icon': Icons.shopping_bag,
      'label': '购物',
      'color': const Color(0xFFA5D8FF),
      'type': 'expense'
    },
    {
      'id': 'milk_tea',
      'icon': Icons.coffee,
      'label': '奶茶',
      'color': const Color(0xFFFFE066),
      'type': 'expense'
    },
    {
      'id': 'snack',
      'icon': Icons.cookie,
      'label': '零食',
      'color': const Color(0xFFFFD8A8),
      'type': 'expense'
    },
    {
      'id': 'housing',
      'icon': Icons.home,
      'label': '居住',
      'color': const Color(0xFFE5DBFF),
      'type': 'expense'
    },
    {
      'id': 'entertainment',
      'icon': Icons.sports_esports,
      'label': '娱乐',
      'color': const Color(0xFFD0BFFF),
      'type': 'expense'
    },
    {
      'id': 'salary',
      'icon': Icons.account_balance_wallet,
      'label': '工资',
      'color': const Color(0xFFB2F2BB),
      'type': 'income'
    },
    {
      'id': 'bonus',
      'icon': Icons.card_giftcard,
      'label': '奖金',
      'color': const Color(0xFFFFE066),
      'type': 'income'
    },
    {
      'id': 'transfer',
      'icon': Icons.swap_horiz,
      'label': '转账',
      'color': const Color(0xFFFFC9A9),
      'type': 'income'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: EdgeInsets.symmetric(horizontal: DS.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt, size: 18, color: DS.secondaryContainer),
              SizedBox(width: DS.xs),
              Text('快捷记账', style: DS.headlineSm),
            ],
          ),
          SizedBox(height: DS.sm),
          SizedBox(
            height: 70,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _entries.length,
              itemBuilder: (context, index) {
                final entry = _entries[index];
                return Padding(
                  padding: EdgeInsets.only(
                    right: index < _entries.length - 1 ? DS.sm : 0,
                  ),
                  child: SizedBox(
                    width: 52,
                    child: _QuickEntryItem(
                      icon: entry['icon'] as IconData,
                      label: entry['label'] as String,
                      color: entry['color'] as Color,
                      categoryId: entry['id'] as String,
                      recordType: entry['type'] as String,
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
  final IconData icon;
  final String label;
  final Color color;
  final String categoryId;
  final String recordType;

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
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3), width: 1),
            ),
            child: Icon(icon, size: 20, color: DS.onSurface),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: DS.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

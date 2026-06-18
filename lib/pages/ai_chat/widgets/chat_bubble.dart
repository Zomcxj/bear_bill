import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

/// 聊天消息类型
enum ChatMessageType { text, recordConfirm, queryResult, error }

/// 聊天消息数据
class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final ChatMessageType type;
  final Map<String, dynamic>? data;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    this.type = ChatMessageType.text,
    this.data,
  });
}

/// 消息气泡组件
class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onConfirm;
  final VoidCallback? onModify;

  const ChatBubble({
    super.key,
    required this.message,
    this.onConfirm,
    this.onModify,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) _buildAvatar(),
          if (!message.isUser) const SizedBox(width: 8),
          Flexible(child: _buildBubble(context)),
          if (message.isUser) const SizedBox(width: 8),
          if (message.isUser) _buildUserAvatar(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Center(
        child: Text('🐻', style: TextStyle(fontSize: 20)),
      ),
    );
  }

  Widget _buildUserAvatar() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppTheme.info.withOpacity(0.2),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Center(
        child: Icon(Icons.person, size: 20, color: AppTheme.info),
      ),
    );
  }

  Widget _buildBubble(BuildContext context) {
    switch (message.type) {
      case ChatMessageType.recordConfirm:
        return _buildRecordBubble(context);
      case ChatMessageType.queryResult:
        return _buildQueryBubble();
      case ChatMessageType.error:
        return _buildTextBubble(isError: true);
      case ChatMessageType.text:
        return _buildTextBubble();
    }
  }

  Widget _buildTextBubble({bool isError = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: message.isUser
            ? AppTheme.primary
            : (isError ? Colors.red[50] : AppTheme.bgCard),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(message.isUser ? 16 : 4),
          bottomRight: Radius.circular(message.isUser ? 4 : 16),
        ),
        border: message.isUser
            ? null
            : Border.all(color: AppTheme.border.withOpacity(0.5)),
      ),
      child: Text(
        message.text,
        style: TextStyle(
          fontSize: 15,
          color: message.isUser
              ? Colors.white
              : (isError ? Colors.red[700] : AppTheme.textPrimary),
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildRecordBubble(BuildContext context) {
    final data = message.data ?? {};
    final type = data['type'] as String? ?? 'expense';
    final amount = data['amount'] as double? ?? 0;
    final categoryName = data['categoryName'] as String? ?? '';
    final categoryIcon = data['categoryIcon'] as String? ?? '';
    final remark = data['remark'] as String?;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(16),
        ),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 确认标题
          Row(
            children: [
              Text(categoryIcon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                '确认记账',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // 详情
          _buildDetailRow('分类', categoryName),
          _buildDetailRow(
            '金额',
            '${type == 'expense' ? '-' : '+'}¥${amount.toStringAsFixed(2)}',
            valueColor: type == 'expense' ? AppTheme.primaryDark : AppTheme.success,
          ),
          if (remark != null && remark.isNotEmpty)
            _buildDetailRow('备注', remark),
          const SizedBox(height: 12),
          // 按钮
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onModify,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppTheme.textHint),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: Text('修改',
                      style: TextStyle(color: AppTheme.textSecondary)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('确认'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQueryBubble() {
    final data = message.data ?? {};
    final totalExpense = data['totalExpense'] as double? ?? 0;
    final totalIncome = data['totalIncome'] as double? ?? 0;
    final count = data['count'] as int? ?? 0;
    final period = data['period'] as String? ?? '';
    final categoryBreakdown = data['categoryBreakdown'] as Map<String, dynamic>?;

    final periodLabel = {
      'today': '今日',
      'week': '本周',
      'month': '本月',
      'year': '今年',
    }[period] ?? period;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(16),
        ),
        border: Border.all(color: AppTheme.info.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$periodLabel账单汇总',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          _buildDetailRow('共 $count 笔记录', ''),
          if (totalExpense > 0)
            _buildDetailRow(
              '总支出',
              '¥${totalExpense.toStringAsFixed(2)}',
              valueColor: AppTheme.primaryDark,
            ),
          if (totalIncome > 0)
            _buildDetailRow(
              '总收入',
              '¥${totalIncome.toStringAsFixed(2)}',
              valueColor: AppTheme.success,
            ),
          if (categoryBreakdown != null && categoryBreakdown.isNotEmpty) ...[
            const SizedBox(height: 8),
            Divider(height: 1, color: AppTheme.divider),
            const SizedBox(height: 8),
            Text(
              '分类明细',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            ...categoryBreakdown.entries.take(5).map((e) {
              final cat = e.value as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${cat['icon'] ?? ''} ${cat['name'] ?? ''}',
                      style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                    ),
                    Text(
                      '¥${(cat['amount'] as double? ?? 0).toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: valueColor ?? AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

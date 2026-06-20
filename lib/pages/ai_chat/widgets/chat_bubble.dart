import 'package:flutter/material.dart';

import '../../../models/category_model.dart';
import '../../../theme/app_design_system.dart';

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
  final MoodModel? selectedMood;
  final Function(MoodModel?)? onMoodChanged;
  final String? location;
  final bool locationLoading;
  final VoidCallback? onLocationTap;

  const ChatBubble({
    super.key,
    required this.message,
    this.onConfirm,
    this.onModify,
    this.selectedMood,
    this.onMoodChanged,
    this.location,
    this.locationLoading = false,
    this.onLocationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) _buildAvatar(),
          if (!message.isUser) SizedBox(width: 8),
          Flexible(child: _buildBubble(context)),
          if (message.isUser) SizedBox(width: 8),
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
        color: DS.surfaceContainerHigh,
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
        color: DS.secondaryContainer.withOpacity(0.2),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Center(
        child: Icon(Icons.person, size: 20, color: DS.secondaryContainer),
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
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: message.isUser
            ? DS.primary
            : (isError ? Colors.red[50] : DS.surfaceContainerLowest),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(message.isUser ? 16 : 4),
          bottomRight: Radius.circular(message.isUser ? 4 : 16),
        ),
        border: message.isUser
            ? null
            : Border.all(color: DS.outlineVariant.withOpacity(0.5)),
      ),
      child: Text(
        message.text,
        style: TextStyle(
          fontSize: 15,
          color: message.isUser
              ? Colors.white
              : (isError ? Colors.red[700] : DS.onSurface),
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
    final dateStr = data['date'] as String?;

    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DS.surfaceContainerLowest,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(16),
        ),
        border: Border.all(color: DS.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 确认标题
          Row(
            children: [
              Text(categoryIcon, style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text(
                '确认记账',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: DS.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          // 详情
          _buildDetailRow('分类', categoryName),
          _buildDetailRow(
            '金额',
            '${type == 'expense' ? '-' : '+'}¥${amount.toStringAsFixed(2)}',
            valueColor: type == 'expense' ? DS.primaryContainer : DS.secondary,
          ),
          if (remark != null && remark.isNotEmpty)
            _buildDetailRow('备注', remark),
          _buildDetailRow('日期', _formatDateLabel(dateStr)),
          SizedBox(height: 10),
          // 心情选择
          _buildMoodRow(),
          SizedBox(height: 8),
          // 定位信息
          _buildLocationRow(),
          SizedBox(height: 12),
          // 按钮
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onModify,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: DS.outline),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DS.radiusSm),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: Text('修改',
                      style: TextStyle(color: DS.onSurfaceVariant)),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DS.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DS.radiusSm),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: Text('确认'),
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
    final periodLabel = data['period'] as String? ?? '';
    final filterDesc = data['filterDesc'] as String? ?? '';
    final categoryBreakdown = data['categoryBreakdown'] as Map<String, dynamic>?;

    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DS.surfaceContainerLowest,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(16),
        ),
        border: Border.all(color: DS.secondaryContainer.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${periodLabel}账单汇总${filterDesc.isNotEmpty ? ' · $filterDesc' : ''}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: DS.onSurface,
            ),
          ),
          SizedBox(height: 10),
          _buildDetailRow('共 $count 笔记录', ''),
          if (totalExpense > 0)
            _buildDetailRow(
              '总支出',
              '¥${totalExpense.toStringAsFixed(2)}',
              valueColor: DS.primaryContainer,
            ),
          if (totalIncome > 0)
            _buildDetailRow(
              '总收入',
              '¥${totalIncome.toStringAsFixed(2)}',
              valueColor: DS.secondary,
            ),
          if (categoryBreakdown != null && categoryBreakdown.isNotEmpty) ...[
            SizedBox(height: 8),
            Divider(height: 1, color: DS.outlineVariant),
            SizedBox(height: 8),
            Text(
              '分类明细',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: DS.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 6),
            ...categoryBreakdown.entries.take(5).map((e) {
              final cat = e.value as Map<String, dynamic>;
              return Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${cat['icon'] ?? ''} ${cat['name'] ?? ''}',
                      style: TextStyle(fontSize: 13, color: DS.onSurface),
                    ),
                    Text(
                      '¥${(cat['amount'] as double? ?? 0).toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 13, color: DS.onSurfaceVariant),
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

  Widget _buildMoodRow() {
    return Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '心情',
            style: TextStyle(fontSize: 13, color: DS.onSurfaceVariant),
          ),
          SizedBox(width: 8),
          ...moods.map((mood) {
            final isSelected = selectedMood?.id == mood.id;
            return GestureDetector(
              onTap: () {
                if (onMoodChanged == null) return;
                onMoodChanged!(isSelected ? null : mood);
              },
              child: Container(
                margin: EdgeInsets.only(right: 6),
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected ? DS.surfaceContainerHigh : DS.background,
                  borderRadius: BorderRadius.circular(DS.radiusFull),
                  border: Border.all(
                    color: isSelected ? DS.primary : DS.outlineVariant,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  '${mood.emoji}${isSelected ? " ${mood.label}" : ""}',
                  style: TextStyle(fontSize: isSelected ? 12 : 16),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLocationRow() {
    final hasLocation = location != null && location!.isNotEmpty;
    return GestureDetector(
      onTap: onLocationTap,
      child: Row(
        children: [
          Icon(Icons.location_on, size: 14, color: DS.onSurfaceVariant),
          SizedBox(width: 4),
          Expanded(
            child: locationLoading
                ? Row(
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: DS.outline,
                        ),
                      ),
                      SizedBox(width: 6),
                      Text(
                        '定位中...',
                        style: TextStyle(
                          fontSize: 13,
                          color: DS.outline,
                        ),
                      ),
                    ],
                  )
                : Text(
                    hasLocation ? location! : '点击获取位置',
                    style: TextStyle(
                      fontSize: 13,
                      color: hasLocation
                          ? DS.onSurfaceVariant
                          : DS.outline,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: DS.onSurfaceVariant),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: valueColor ?? DS.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateLabel(String? dateStr) {
    if (dateStr == null || dateStr.length != 10) {
      final now = DateTime.now();
      return '${now.month}月${now.day}日';
    }
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      // 同年省略年份
      if (date.year == now.year) {
        return '${date.month}月${date.day}日';
      }
      return '${date.year}年${date.month}月${date.day}日';
    } catch (_) {
      return dateStr;
    }
  }
}

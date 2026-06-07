import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../../models/models.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/utils.dart' as utils;

/// 将 hex 颜色字符串转换为 Color
Color _hexToColor(String hex) {
  final buffer = StringBuffer();
  if (hex.length == 6 || hex.length == 7) buffer.write('ff');
  buffer.write(hex.replaceFirst('#', ''));
  return Color(int.parse(buffer.toString(), radix: 16));
}

/// 账单分组列表 - 按日期分组，支持左滑删除
class RecordGroupList extends StatelessWidget {
  final List<Map<String, dynamic>> groupedRecords;
  final Function(String) onDelete;
  final Function(RecordModel)? onRecordTap;

  const RecordGroupList({
    super.key,
    required this.groupedRecords,
    required this.onDelete,
    this.onRecordTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.sm),
      itemCount: groupedRecords.length,
      itemBuilder: (context, index) {
        final group = groupedRecords[index];
        return _buildDateGroup(group);
      },
    );
  }

  Widget _buildDateGroup(Map<String, dynamic> group) {
    final records = group['records'] as List<RecordModel>;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 日期标题
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.primaryBg,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppRadius.lg),
                topRight: Radius.circular(AppRadius.lg),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      group['label'],
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      group['weekday'],
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textHint,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (group['dayExpense'] > 0)
                      Text(
                        '支 ¥${utils.FormatUtils.formatAmount(group['dayExpense'])}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                    if (group['dayExpense'] > 0 && group['dayIncome'] > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text('|',
                            style: TextStyle(
                                color: AppTheme.textHint, fontSize: 12)),
                      ),
                    if (group['dayIncome'] > 0)
                      Text(
                        '收 ¥${utils.FormatUtils.formatAmount(group['dayIncome'])}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.success,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // 该日期的账单列表
          ...List.generate(
            records.length,
            (index) => Column(
              children: [
                _buildRecordItem(records[index]),
                if (index < records.length - 1)
                  Divider(
                      height: 1, thickness: 1, color: AppTheme.divider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordItem(RecordModel record) {
    final category =
        getCategoryById(record.categoryId, isExpense: record.type == 'expense');

    return Slidable(
      key: ValueKey(record.id),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) => onDelete(record.id),
            backgroundColor: AppTheme.primaryDark,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: '删除',
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: () {
          if (onRecordTap != null) {
            onRecordTap!(record);
          }
        },
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              // 分类图标
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _hexToColor(category?.color ?? '#B0B0B0')
                      .withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Center(
                  child: Text(
                    category?.icon ?? '📦',
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),

              const SizedBox(width: AppSpacing.sm),

              // 分类名称和备注
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category?.name ?? '未分类',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (record.remark != null && record.remark!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        record.remark!,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textHint,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // 金额
              Text(
                utils.FormatUtils.formatAmountWithSign(record.amount,
                    type: record.type),
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

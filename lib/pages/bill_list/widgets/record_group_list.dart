import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../../models/models.dart';
import '../../../theme/app_design_system.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/utils.dart' as utils;
import '../../../providers/theme_provider.dart';
import 'package:provider/provider.dart';

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
    context.watch<ThemeProvider>(); // theme rebuild
    return ListView.builder(
      padding: EdgeInsets.only(left: DS.sm, right: DS.sm, bottom: DS.sm),
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
      margin: EdgeInsets.only(bottom: DS.sm),
      decoration: DS.glassDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 日期标题
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: DS.base, vertical: 12),
            decoration: BoxDecoration(
              color: DS.background,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(DS.radiusMd),
                topRight: Radius.circular(DS.radiusMd),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      group['label'],
                      style: DS.labelMd.copyWith(
                        color: DS.onSurface,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      group['weekday'],
                      style: DS.labelSm.copyWith(
                        color: DS.outline,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (group['dayExpense'] > 0)
                      Text(
                        '支 ¥${utils.FormatUtils.formatAmount(group['dayExpense'])}',
                        style: DS.labelSm.copyWith(
                          color: DS.primaryContainer,
                        ),
                      ),
                    if (group['dayExpense'] > 0 && group['dayIncome'] > 0)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Text('|',
                            style: TextStyle(
                                color: DS.outline, fontSize: 12)),
                      ),
                    if (group['dayIncome'] > 0)
                      Text(
                        '收 ¥${utils.FormatUtils.formatAmount(group['dayIncome'])}',
                        style: DS.labelSm.copyWith(
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
                      height: 1, thickness: 1, color: DS.outlineVariant),
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
        extentRatio: 0.3,
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) => onDelete(record.id),
            backgroundColor: DS.primaryContainer,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            borderRadius: BorderRadius.circular(DS.radiusSm),
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
          padding: EdgeInsets.all(DS.base),
          child: Row(
            children: [
              // 分类图标
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _hexToColor(category?.color ?? '#B0B0B0')
                      .withOpacity(0.2),
                  borderRadius: BorderRadius.circular(DS.radiusXs),
                ),
                child: Center(
                  child: Text(
                    category?.icon ?? '📦',
                    style: TextStyle(fontSize: 22),
                  ),
                ),
              ),

              SizedBox(width: DS.base),

              // 分类名称和备注
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category?.name ?? '未分类',
                      style: DS.bodyMd.copyWith(
                        fontWeight: FontWeight.w500,
                        color: DS.onSurface,
                      ),
                    ),
                    if (record.remark != null && record.remark!.isNotEmpty) ...[
                      SizedBox(height: 2),
                      Text(
                        record.remark!,
                        style: DS.labelSm.copyWith(
                          color: DS.outline,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (record.images.isNotEmpty) ...[
                      SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.image, size: 12, color: DS.outline),
                          SizedBox(width: 2),
                          Text(
                            '${record.images.length}张图片',
                            style: DS.labelSm.copyWith(
                              color: DS.outline,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // 金额
              Text(
                utils.FormatUtils.formatAmountWithSign(record.amount,
                    type: record.type),
                style: DS.labelMd.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: DS.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

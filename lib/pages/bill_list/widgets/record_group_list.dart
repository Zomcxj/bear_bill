import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../../models/models.dart';
import '../../../theme/app_design_system.dart';
import '../../../widgets/glass_dialog_shell.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/glass_materials.dart';
import '../../../utils/utils.dart' as utils;
import '../../../providers/theme_provider.dart';
import 'package:provider/provider.dart';

/// Convert a hex color string to a Color
Color _hexToColor(String hex) {
  final buffer = StringBuffer();
  if (hex.length == 6 || hex.length == 7) buffer.write('ff');
  buffer.write(hex.replaceFirst('#', ''));
  return Color(int.parse(buffer.toString(), radix: 16));
}

/// Grouped bill list - grouped by date, supports swipe-to-delete
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
      // Extra bottom padding in glass mode: keeps the last item clear of the floating glass bar
      padding: EdgeInsets.only(
        left: DS.sm,
        right: DS.sm,
        bottom: DS.sm + glassBottomInset(context),
      ),
      itemCount: groupedRecords.length,
      itemBuilder: (context, index) {
        final group = groupedRecords[index];
        return _buildDateGroup(context, group);
      },
    );
  }

  Widget _buildDateGroup(BuildContext context, Map<String, dynamic> group) {
    final records = group['records'] as List<RecordModel>;

    return GlassSurface(
      margin: EdgeInsets.only(bottom: DS.sm),
      fallbackDecoration: DS.glassDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date header
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: DS.base, vertical: 12),
            decoration: BoxDecoration(
              // Glass mode: header uses a glass tint (matches the card glass instead of a solid cap)
              color: shouldUseLiquidGlass(context)
                  ? DS.heroCardBg
                  : DS.background,
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
                          // Dynamic expense color: near-black in light mode / light red in dark mode
                          // (the constant primaryContainer is near-black and unreadable on dark backgrounds)
                          color: DS.chartExpense,
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

          // Records for this date
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
            // Delete = destructive action, red (the constant primaryContainer is invisible in dark mode)
            backgroundColor: const Color(0xFFE5484D),
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
              // Category icon
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

              // Category name and remark
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

              // Amount
              Text(
                utils.FormatUtils.formatAmountWithSign(record.amount,
                    type: record.type),
                style: DS.labelMd.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  // Colored by income/expense (same as the statistics page): dynamic red for
                  // expense, green for income, readable in both light and dark mode
                  color: record.type == 'expense'
                      ? DS.chartExpense
                      : AppTheme.success,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

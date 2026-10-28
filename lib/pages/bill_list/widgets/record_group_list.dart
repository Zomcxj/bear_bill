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
      // 玻璃模式底部留白：避免最后一项被浮动玻璃底栏盖住
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
          // 日期标题
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: DS.base, vertical: 12),
            decoration: BoxDecoration(
              // 玻璃态：页眉转玻璃 tint（贴近整卡玻璃，不再实色压顶）
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
                          // 动态支出色：浅色近黑 / 深色浅红（常量
                          // primaryContainer 近黑，深色下黑底黑字不可见）
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
            // 删除 = 破坏性操作，红色（常量 primaryContainer 深色下不可见）
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
                  // 按收支着色（与统计页一致）：支出动态红、收入绿，
                  // 深浅色都动态可读
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

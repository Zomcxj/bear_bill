import 'dart:io';

import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart'
    show GlassContainer, GlassQuality;
import '../../../models/record_model.dart';
import '../../../theme/app_design_system.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/utils.dart' as utils;
import '../../../providers/theme_provider.dart';
import 'package:provider/provider.dart';
import '../../../theme/glass_materials.dart';
import '../../../widgets/glass_dialog_shell.dart';

/// 账单详情对话框 - 显示记录的完整信息
class RecordDetailDialog extends StatelessWidget {
  final RecordModel record;

  const RecordDetailDialog({
    super.key,
    required this.record,
  });

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>(); // theme rebuild
    final glass = shouldUseLiquidGlass(context);
    if (glass) {
      return GlassContainer(
        shape: GlassMaterials.shape(DS.radiusMd),
        settings: GlassMaterials.bar(),
        quality: GlassQuality.standard,
        // 弹窗在独立路由里，没有父 LiquidGlassLayer：
        // grouped 模式会忽略 per-widget settings，必须自建图层
        useOwnLayer: true,
        padding: EdgeInsets.zero,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: _buildBody(context, glass: true),
        ),
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DS.radiusMd),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: _buildBody(context, glass: false),
      ),
    );
  }

  Widget _buildBody(BuildContext context, {required bool glass}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 标题栏
        Container(
          padding: EdgeInsets.all(DS.gutter),
          decoration: BoxDecoration(
            color: record.isExpense
                ? DS.chartExpense.withOpacity(0.12)
                : AppTheme.success.withOpacity(0.12),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(DS.radiusMd),
              topRight: Radius.circular(DS.radiusMd),
            ),
          ),
          child: Row(
            children: [
              Text(
                record.categoryIcon,
                style: TextStyle(fontSize: 32),
              ),
              SizedBox(width: DS.base),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.categoryName,
                      style: DS.headlineSm.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${utils.DateUtils.formatDayCN(record.date)} ${record.createdAt.hour.toString().padLeft(2, '0')}:${record.createdAt.minute.toString().padLeft(2, '0')}:${record.createdAt.second.toString().padLeft(2, '0')}',
                      style: DS.labelSm.copyWith(
                        color: DS.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: DS.onSurface),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),

        // 内容区域
        Flexible(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(DS.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 金额
                _buildInfoRow(
                  label: '金额',
                  value: Text(
                    '${record.isExpense ? '-' : '+'}¥${utils.FormatUtils.formatAmountWithComma(record.amount)}',
                    style: TextStyle(
                      fontSize: 20,
                      color:
                          record.isExpense ? DS.chartExpense : DS.chartIncome,
                      fontWeight: FontWeight.bold,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),

                Divider(height: 24),

                // 类型
                _buildInfoRow(
                  label: '类型',
                  value: Text(
                    record.isExpense ? '支出' : '收入',
                    style: DS.bodyMd.copyWith(
                      color: DS.onSurface,
                    ),
                  ),
                ),

                // 备注（如果有）
                if (record.remark != null && record.remark!.isNotEmpty) ...[
                  Divider(height: 24),
                  _buildInfoRow(
                    label: '备注',
                    value: Text(
                      record.remark!,
                      style: DS.bodyMd.copyWith(
                        color: DS.onSurface,
                      ),
                    ),
                  ),
                ],

                // 心情（如果有）
                if (record.moodEmoji != null) ...[
                  Divider(height: 24),
                  _buildInfoRow(
                    label: '心情',
                    value: Row(
                      children: [
                        Text(
                          record.moodEmoji!,
                          style: TextStyle(fontSize: 22),
                        ),
                      ],
                    ),
                  ),
                ],

                // 位置（如果有）
                if (record.location != null && record.location!.isNotEmpty) ...[
                  Divider(height: 24),
                  _buildInfoRow(
                    label: '位置',
                    value: Text(
                      record.location!,
                      style: DS.bodyMd.copyWith(
                        color: DS.onSurface,
                      ),
                    ),
                  ),
                ],

                // 图片（如果有）
                if (record.images.isNotEmpty) ...[
                  Divider(height: 24),
                  Text(
                    '图片',
                    style: DS.labelMd.copyWith(
                      color: DS.onSurface,
                    ),
                  ),
                  SizedBox(height: DS.base),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: record.images.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => _showImagePreview(context, index),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(DS.radiusXs),
                          child: Image.file(
                            File(record.images[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                ],

                // 标签（如果有）
                if (record.tags.isNotEmpty) ...[
                  Divider(height: 24),
                  Text(
                    '标签',
                    style: DS.labelMd.copyWith(
                      color: DS.onSurface,
                    ),
                  ),
                  SizedBox(height: DS.base),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: record.tags.map((tag) {
                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: glass
                              ? (DS.isDark
                                  ? Colors.white.withOpacity(0.12)
                                  : Colors.white.withOpacity(0.60))
                              : DS.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(DS.radiusXs),
                        ),
                        child: Text(
                          tag,
                          style: DS.labelSm.copyWith(
                            color: DS.emphasis,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required String label,
    required Widget value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: DS.bodyMd.copyWith(
              color: DS.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(child: value),
      ],
    );
  }

  void _showImagePreview(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            child: Image.file(
              File(record.images[index]),
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

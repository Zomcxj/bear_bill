import 'dart:io';

import 'package:flutter/material.dart';
import '../../../models/record_model.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/utils.dart' as utils;

/// 账单详情对话框 - 显示记录的完整信息
class RecordDetailDialog extends StatelessWidget {
  final RecordModel record;

  const RecordDetailDialog({
    super.key,
    required this.record,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题栏
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: record.isExpense
                    ? AppTheme.primaryDark.withOpacity(0.1)
                    : AppTheme.success.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppRadius.lg),
                  topRight: Radius.circular(AppRadius.lg),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    record.categoryIcon,
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.categoryName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          utils.DateUtils.formatDayCN(record.date),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // 内容区域
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
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
                          color: record.isExpense
                              ? AppTheme.primaryDark
                              : AppTheme.success,
                          fontWeight: FontWeight.bold,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),

                    const Divider(height: 24),

                    // 类型
                    _buildInfoRow(
                      label: '类型',
                      value: Text(
                        record.isExpense ? '支出' : '收入',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),

                    // 备注（如果有）
                    if (record.remark != null && record.remark!.isNotEmpty) ...[
                      const Divider(height: 24),
                      _buildInfoRow(
                        label: '备注',
                        value: Text(
                          record.remark!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],

                    // 心情（如果有）
                    if (record.moodEmoji != null) ...[
                      const Divider(height: 24),
                      _buildInfoRow(
                        label: '心情',
                        value: Row(
                          children: [
                            Text(
                              record.moodEmoji!,
                              style: const TextStyle(fontSize: 22),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // 位置（如果有）
                    if (record.location != null &&
                        record.location!.isNotEmpty) ...[
                      const Divider(height: 24),
                      _buildInfoRow(
                        label: '位置',
                        value: Text(
                          record.location!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],

                    // 图片（如果有）
                    if (record.images.isNotEmpty) ...[
                      const Divider(height: 24),
                      const Text(
                        '图片',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
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
                              borderRadius: BorderRadius.circular(AppRadius.sm),
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
                      const Divider(height: 24),
                      const Text(
                        '标签',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: record.tags.map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryLight,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.primary,
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
        ),
      ),
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
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/models.dart';
import '../../../providers/app_provider.dart';
import '../../../services/database_service.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/utils.dart' as utils;
import '../../../main.dart';
import '../../record_detail/record_detail_page.dart';

/// 将 hex 颜色字符串转换为 Color
Color _hexToColor(String hex) {
  final buffer = StringBuffer();
  if (hex.length == 6 || hex.length == 7) buffer.write('ff');
  buffer.write(hex.replaceFirst('#', ''));
  return Color(int.parse(buffer.toString(), radix: 16));
}

/// 今日账单列表（对齐小程序 section-card + record-item 样式）
class TodayRecords extends StatefulWidget {
  const TodayRecords({super.key});

  @override
  State<TodayRecords> createState() => _TodayRecordsState();
}

class _TodayRecordsState extends State<TodayRecords> {
  List<RecordModel> _records = [];
  double _todayExpense = 0.0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTodayRecords();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final appProvider = Provider.of<AppProvider>(context, listen: false);
        appProvider.addListener(_loadTodayRecords);
      } catch (_) {}
    });
  }

  Future<void> _loadTodayRecords() async {
    setState(() => _loading = true);

    final appProvider = context.read<AppProvider>();
    final today = utils.DateUtils.getToday();

    final records = await DatabaseService.instance.getRecordsByDate(
      date: today,
      bookId: appProvider.currentBookId,
    );

    double expense = 0.0;
    for (final record in records) {
      if (record.type == 'expense') {
        expense += record.amount;
      }
    }

    if (mounted) {
      setState(() {
        _records = records;
        _todayExpense = expense;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppTheme.border, width: 1),
        boxShadow: AppShadow.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '📋 今日账单',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  if (!_loading && _records.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        '-¥${utils.FormatUtils.formatAmount(_todayExpense)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.primaryDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  tabSwitchNotifier.value = -1;
                  tabSwitchNotifier.value = 1;
                },
                child: Row(
                  children: [
                    Text(
                      '全部',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.primary,
                      ),
                    ),
                    Text(
                      '›',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // 内容区域
          if (_loading)
            _buildSkeleton()
          else if (_records.isEmpty)
            _buildEmpty()
          else
            _buildRecordList(),
        ],
      ),
    );
  }

  /// 骨架屏加载态
  Widget _buildSkeleton() {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        children: List.generate(3, (_) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.bgSection,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        height: 14,
                        width: double.infinity * 0.6,
                        decoration: BoxDecoration(
                          color: AppTheme.bgSection,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 10,
                        width: double.infinity * 0.4,
                        decoration: BoxDecoration(
                          color: AppTheme.bgSection,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  /// 空状态
  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: [
          const Text('🐾', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 8),
          Text(
            '今天还没记账呢',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '快把第一笔花销记下来吧',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textHint,
            ),
          ),
        ],
      ),
    );
  }

  /// 记录列表（最多 5 条）
  Widget _buildRecordList() {
    final displayRecords = _records.take(5).toList();

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        children: [
          for (int i = 0; i < displayRecords.length; i++) ...[
            _buildRecordItem(displayRecords[i]),
            if (i < displayRecords.length - 1)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 0),
                child: Divider(height: 1, color: AppTheme.divider),
              ),
          ],
          // 超过 5 条提示
          if (_records.length > 5)
            GestureDetector(
              onTap: () {
                tabSwitchNotifier.value = -1;
                tabSwitchNotifier.value = 1;
              },
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Center(
                  child: Text(
                    '还有 ${_records.length - 5} 条，点击查看全部 ›',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 单条记录（对齐小程序 record-item 样式）
  Widget _buildRecordItem(RecordModel record) {
    final category =
        getCategoryById(record.categoryId, isExpense: record.type == 'expense');
    final catColor = _hexToColor(category?.color ?? '#B0B0B0');

    return GestureDetector(
      onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RecordDetailPage(recordId: record.id),
                    ),
                  );
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            // 分类图标
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: catColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  category?.icon ?? '📦',
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // 分类名 + 备注
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category?.name ?? '未分类',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  if (record.remark != null && record.remark!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        record.remark!,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textHint,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (record.location != null && record.location!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '📍 ${record.location!}',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (record.images.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '🖼️ 已添加 ${record.images.length} 张图片',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // 金额 + 时间
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${record.type == 'income' ? '+' : '-'}¥${utils.FormatUtils.formatAmount(record.amount)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: record.type == 'income'
                        ? AppTheme.success
                        : AppTheme.textPrimary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  '${record.createdAt.hour.toString().padLeft(2, '0')}:${record.createdAt.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textHint,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      appProvider.removeListener(_loadTodayRecords);
    } catch (_) {}
    super.dispose();
  }
}

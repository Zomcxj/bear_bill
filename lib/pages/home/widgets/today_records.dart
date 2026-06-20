import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/models.dart';
import '../../../providers/app_provider.dart';
import '../../../services/database_service.dart';
import '../../../theme/app_design_system.dart';
import '../../../utils/utils.dart' as utils;
import '../../../widgets/glass_card.dart';
import '../../../main.dart';
import '../../record_detail/record_detail_page.dart';

/// 将 hex 颜色字符串转换为 Color
Color _hexToColor(String hex) {
  final buffer = StringBuffer();
  if (hex.length == 6 || hex.length == 7) buffer.write('ff');
  buffer.write(hex.replaceFirst('#', ''));
  return Color(int.parse(buffer.toString(), radix: 16));
}

/// 今日账单列表 — 玻璃卡片风格
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
    return GlassCard(
      margin: EdgeInsets.symmetric(horizontal: DS.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.receipt_long, size: 18, color: DS.onSurface),
                  SizedBox(width: DS.xs),
                  Text('今日账单', style: DS.headlineSm),
                  if (!_loading && _records.isNotEmpty)
                    Container(
                      margin: EdgeInsets.only(left: DS.sm),
                      padding: EdgeInsets.symmetric(
                        horizontal: DS.sm,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: DS.errorContainer,
                        borderRadius: BorderRadius.circular(DS.radiusFull),
                      ),
                      child: Text(
                        '-¥${utils.FormatUtils.formatAmount(_todayExpense)}',
                        style: TextStyle(
                          fontFamily: DS.fontLabel,
                          fontSize: 12,
                          color: DS.error,
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
                    Text('全部', style: DS.labelSm.copyWith(color: DS.secondary)),
                    Icon(Icons.chevron_right, size: 14, color: DS.secondary),
                  ],
                ),
              ),
            ],
          ),
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

  Widget _buildSkeleton() {
    return Padding(
      padding: EdgeInsets.only(top: DS.gutter),
      child: Column(
        children: List.generate(3, (_) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: DS.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(DS.radiusSm),
                  ),
                ),
                SizedBox(width: DS.gutter),
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        height: 14,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: DS.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      SizedBox(height: DS.sm),
                      Container(
                        height: 10,
                        width: 120,
                        decoration: BoxDecoration(
                          color: DS.surfaceContainerHigh,
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

  Widget _buildEmpty() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: DS.gutter),
      child: Column(
        children: [
          Icon(Icons.receipt_long, size: 32, color: DS.outlineVariant),
          SizedBox(height: DS.xs),
          Text(
            '今天还没记账呢',
            style: DS.labelSm.copyWith(color: DS.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordList() {
    final displayRecords = _records.take(5).toList();

    return Padding(
      padding: EdgeInsets.only(top: DS.xs),
      child: Column(
        children: [
          for (int i = 0; i < displayRecords.length; i++) ...[
            _buildRecordItem(displayRecords[i]),
            if (i < displayRecords.length - 1)
              Divider(height: 1, color: DS.outlineVariant),
          ],
          if (_records.length > 5)
            GestureDetector(
              onTap: () {
                tabSwitchNotifier.value = -1;
                tabSwitchNotifier.value = 1;
              },
              child: Padding(
                padding: EdgeInsets.only(top: DS.sm),
                child: Center(
                  child: Text(
                    '还有 ${_records.length - 5} 条，点击查看全部 ›',
                    style: DS.labelSm.copyWith(color: DS.secondary),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

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
        padding: EdgeInsets.symmetric(vertical: DS.sm),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: catColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  category?.icon ?? '📦',
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ),
            SizedBox(width: DS.gutter),
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
                  if (record.remark != null && record.remark!.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Text(
                        record.remark!,
                        style: DS.labelSm.copyWith(color: DS.outline),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (record.location != null && record.location!.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Row(
                        children: [
                          Icon(Icons.location_on, size: 12, color: DS.outline),
                          SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              record.location!,
                              style: DS.labelSm.copyWith(color: DS.onSurfaceVariant),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${record.type == 'income' ? '+' : '-'}¥${utils.FormatUtils.formatAmount(record.amount)}',
                  style: TextStyle(
                    fontFamily: DS.fontDisplay,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: record.type == 'income'
                        ? DS.secondary
                        : DS.onSurface,
                  ),
                ),
                Text(
                  '${record.createdAt.hour.toString().padLeft(2, '0')}:${record.createdAt.minute.toString().padLeft(2, '0')}',
                  style: DS.labelSm.copyWith(color: DS.outline),
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

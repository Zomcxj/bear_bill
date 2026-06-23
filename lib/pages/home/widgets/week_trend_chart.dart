import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/app_provider.dart';
import '../../../services/database_service.dart';
import '../../../theme/app_design_system.dart';
import '../../../utils/utils.dart' as utils;
import '../../../widgets/glass_card.dart';
import '../../statistics/statistics_page.dart';
import '../../../providers/theme_provider.dart';

/// 本周消费趋势图 — 玻璃卡片风格
class WeekTrendChart extends StatefulWidget {
  const WeekTrendChart({super.key});

  @override
  State<WeekTrendChart> createState() => _WeekTrendChartState();
}

class _WeekTrendChartState extends State<WeekTrendChart> {
  List<Map<String, dynamic>> _weekData = [];
  double _maxAmount = 1.0;

  @override
  void initState() {
    super.initState();
    _loadWeekData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final appProvider = Provider.of<AppProvider>(context, listen: false);
        appProvider.addListener(_loadWeekData);
      } catch (_) {}
    });
  }

  Future<void> _loadWeekData() async {
    final appProvider = context.read<AppProvider>();
    final weekRecords = await DatabaseService.instance.getWeekRecords(
      bookId: appProvider.currentBookId,
    );

    final today = DateTime.now();
    final data = <Map<String, dynamic>>[];
    double maxAmount = 1.0;

    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final dateStr = utils.DateUtils.formatDate(date);
      final dayLabel = utils.DateUtils.getWeekday(date);

      final dayRecords = weekRecords
          .where((r) => r.date == dateStr && r.type == 'expense')
          .toList();
      final amount = dayRecords.fold(0.0, (sum, r) => sum + r.amount);

      if (amount > maxAmount) maxAmount = amount;

      data.add({
        'date': dateStr,
        'day': dayLabel,
        'amount': amount,
        'isToday': i == 0,
      });
    }

    if (mounted) {
      setState(() {
        _weekData = data;
        _maxAmount = maxAmount;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>(); // theme rebuild
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
                  Icon(Icons.insights, size: 18, color: DS.onSurface),
                  SizedBox(width: DS.xs),
                  Text('本周趋势', style: DS.headlineSm),
                ],
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const StatisticsPage()),
                  );
                },
                child: Row(
                  children: [
                    Text(
                      '详细统计',
                      style: DS.labelSm.copyWith(color: DS.secondary),
                    ),
                    Icon(Icons.chevron_right, size: 14, color: DS.secondary),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: DS.sm),
          SizedBox(
            height: 110,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _maxAmount * 1.2,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final data = _weekData[groupIndex];
                      return BarTooltipItem(
                        '¥${utils.FormatUtils.formatAmount(data['amount'])}',
                        TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < _weekData.length) {
                          final data = _weekData[index];
                          return Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: Text(
                              data['day'],
                              style: TextStyle(
                                fontFamily: DS.fontLabel,
                                fontSize: 11,
                                fontWeight: data['isToday']
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: data['isToday']
                                    ? DS.primary
                                    : DS.outline,
                              ),
                            ),
                          );
                        }
                        return Text('');
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: _weekData.asMap().entries.map((entry) {
                  final index = entry.key;
                  final data = entry.value;
                  final amount = data['amount'] as double;
                  final isToday = data['isToday'] as bool;

                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: amount,
                        color: isToday ? DS.primary : DS.secondaryContainer,
                        width: 22,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: _maxAmount * 1.2,
                          color: DS.surfaceContainerHigh,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      appProvider.removeListener(_loadWeekData);
    } catch (_) {}
    super.dispose();
  }
}

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

/// 甜甜圈图组件
class DonutChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  final double total;

  const DonutChartWidget({
    super.key,
    required this.categories,
    required this.total,
  });

  static final List<Color> _colors = [
    AppTheme.primary,
    AppTheme.primaryLight,
    Color(0xFFFFD93D),
    Color(0xFF6BCB77),
    Color(0xFF74C0FC),
    Color(0xFFCC5DE8),
    Color(0xFFFFA94D),
    Color(0xFFA5D8FF),
    Color(0xFFB2F2BB),
    Color(0xFFFFE066),
  ];

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty || total == 0) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🐻', style: TextStyle(fontSize: 40)),
            SizedBox(height: 8),
            Text(
              '暂无数据',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 200,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: PieChart(
        PieChartData(
          sections: categories.asMap().entries.map((entry) {
            final index = entry.key;
            final category = entry.value;
            final percent = category['percent'] as double;

            return PieChartSectionData(
              value: percent,
              title: '${percent.toStringAsFixed(1)}%',
              titleStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              radius: 65,
              color: _colors[index % _colors.length],
              badgeWidget: Text(
                category['icon'],
                style: const TextStyle(fontSize: 18),
              ),
              badgePositionPercentageOffset: 0.8,
            );
          }).toList(),
          sectionsSpace: 2,
          centerSpaceRadius: 35,
          startDegreeOffset: 270,
        ),
      ),
    );
  }
}

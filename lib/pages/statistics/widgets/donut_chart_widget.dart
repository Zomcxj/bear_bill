import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_design_system.dart';
import '../../../providers/theme_provider.dart';

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
    DS.primary,
    DS.surfaceContainerHigh,
    const Color(0xFFFFD93D),
    const Color(0xFF6BCB77),
    const Color(0xFF74C0FC),
    const Color(0xFFCC5DE8),
    const Color(0xFFFFA94D),
    const Color(0xFFA5D8FF),
    const Color(0xFFB2F2BB),
    const Color(0xFFFFE066),
  ];

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>(); // theme rebuild
    if (categories.isEmpty || total == 0) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.donut_large, size: 40, color: DS.outline),
            SizedBox(height: 8),
            Text(
              '暂无数据',
              style: TextStyle(
                fontSize: 14,
                color: DS.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 200,
      padding: EdgeInsets.symmetric(vertical: DS.base),
      child: PieChart(
        PieChartData(
          sections: categories.asMap().entries.map((entry) {
            final index = entry.key;
            final category = entry.value;
            final percent = category['percent'] as double;

            return PieChartSectionData(
              value: percent,
              title: '${percent.toStringAsFixed(1)}%',
              titleStyle: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              radius: 65,
              color: _colors[index % _colors.length],
              badgeWidget: Text(
                category['icon'],
                style: TextStyle(fontSize: 18),
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

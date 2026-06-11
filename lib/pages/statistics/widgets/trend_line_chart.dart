import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/app_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../services/database_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_card.dart';

/// 近6个月收支趋势折线图
class TrendLineChart extends StatefulWidget {
  const TrendLineChart({super.key});

  @override
  State<TrendLineChart> createState() => _TrendLineChartState();
}

class _TrendLineChartState extends State<TrendLineChart> {
  List<Map<String, dynamic>> _data = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final appProvider = context.read<AppProvider>();
    final now = DateTime.now();

    final data = <Map<String, dynamic>>[];
    for (int i = 5; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i);
      final monthStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}';
      final stats = await DatabaseService.instance.getMonthStatistics(
        monthStr,
        bookId: appProvider.currentBookId,
      );
      data.add({
        'month': date.month,
        'label': '${date.month}月',
        'expense': stats['expense'] as double? ?? 0.0,
        'income': stats['income'] as double? ?? 0.0,
      });
    }

    if (mounted) {
      setState(() {
        _data = data;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>(); // 确保深色模式切换时重建

    if (_loading) {
      return AppCard(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        borderRadius: AppRadius.md,
        showShadow: false,
        child: const SizedBox(
          height: 260,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_data.isEmpty) return const SizedBox.shrink();

    // 找到最大值用于计算比例
    double maxVal = 0;
    for (final d in _data) {
      final e = d['expense'] as double;
      final i = d['income'] as double;
      if (e > maxVal) maxVal = e;
      if (i > maxVal) maxVal = i;
    }
    if (maxVal == 0) maxVal = 1; // 避免除零

    return AppCard(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      borderRadius: AppRadius.md,
      showShadow: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '📈 收支趋势',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              _buildLegend(),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Container(
              height: 160,
              color: AppTheme.bgPage,
              child: CustomPaint(
                size: const Size(double.infinity, 160),
                painter: _TrendPainter(
                  data: _data,
                  maxVal: maxVal,
                  expenseColor: AppTheme.primary,
                  incomeColor: AppTheme.success,
                  gridColor: AppTheme.border,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // 月份标签
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _data
                .map((d) => Text(
                      d['label'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textHint,
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: AppTheme.primary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text('支出', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        const SizedBox(width: 12),
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: AppTheme.success,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text('收入', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
      ],
    );
  }
}

/// 自定义折线画笔
class _TrendPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final double maxVal;
  final Color expenseColor;
  final Color incomeColor;
  final Color gridColor;

  _TrendPainter({
    required this.data,
    required this.maxVal,
    required this.expenseColor,
    required this.incomeColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final padLeft = 16.0; // 左右留白防止圆点超出
    final padRight = 16.0;
    final chartWidth = size.width - padLeft - padRight;
    final chartHeight = size.height - 30; // 留出顶部空间给数值标签
    final chartTop = 20.0;
    final stepX = chartWidth / (data.length - 1).clamp(1, 999);

    // 画网格线
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;
    for (int i = 0; i <= 4; i++) {
      final y = chartTop + chartHeight * i / 4;
      canvas.drawLine(Offset(padLeft, y), Offset(size.width - padRight, y), gridPaint);
    }

    // 画折线
    _drawLine(canvas, size, chartTop, chartHeight, stepX, padLeft, 'expense', expenseColor);
    _drawLine(canvas, size, chartTop, chartHeight, stepX, padLeft, 'income', incomeColor);
  }

  void _drawLine(Canvas canvas, Size size, double chartTop, double chartHeight,
      double stepX, double padLeft, String key, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    final path = Path();
    bool first = true;

    for (int i = 0; i < data.length; i++) {
      final value = (data[i][key] as double);
      final x = padLeft + i * stepX;
      final ratio = maxVal > 0 ? value / maxVal : 0;
      final y = chartTop + chartHeight * (1 - ratio);

      if (first) {
        path.moveTo(x, y);
        first = false;
      } else {
        path.lineTo(x, y);
      }

      // 画圆点
      canvas.drawCircle(Offset(x, y), 4, dotPaint);

      // 画数值标签（只在有值时显示）
      if (value > 0) {
        final label = value >= 10000
            ? '${(value / 10000).toStringAsFixed(1)}w'
            : value >= 1000
                ? '${(value / 1000).toStringAsFixed(1)}k'
                : value.toStringAsFixed(0);
        textPainter.text = TextSpan(
          text: label,
          style: TextStyle(
            fontSize: 9,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, y - textPainter.height - 4),
        );
      }
    }

    // 画折线
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

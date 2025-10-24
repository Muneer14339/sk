// lib/features/training/presentation/widgets/split_time_chart.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../../core/theme/app_theme.dart';

/// SplitTimeChart
/// - Draws a smooth polyline of split times
/// - Shows a dashed average line
/// - Highlights the selected shot with a vertical guide & dot
class SplitTimeChart extends StatelessWidget {
  final List<double> splits;
  final int? selectedIndex;

  const SplitTimeChart({
    super.key,
    required this.splits,
    this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: CustomPaint(
        painter: _SplitTimeChartPainter(splits, selectedIndex, context),
        size: Size.infinite,
      ),
    );
  }
}

class _SplitTimeChartPainter extends CustomPainter {
  final List<double> splits;
  final int? selectedIndex;
  final BuildContext context;

  _SplitTimeChartPainter(this.splits, this.selectedIndex, this.context);

  @override
  void paint(Canvas canvas, Size size) {
    if (splits.isEmpty) return;

    final padding = 16.0;
    final chartLeft = padding;
    final chartRight = size.width - padding;
    final chartTop = padding + 8;
    final chartBottom = size.height - padding;
    final chartWidth = chartRight - chartLeft;
    final chartHeight = chartBottom - chartTop;

    final minValue = splits.reduce(math.min);
    final maxValue = splits.reduce(math.max);
    final avg = splits.reduce((a, b) => a + b) / splits.length;
    final range = (maxValue - minValue).abs() < 1e-9 ? 1.0 : (maxValue - minValue);

    // Background
    final bgPaint = Paint()
      ..color = AppTheme.surface(context)
      ..style = PaintingStyle.fill;
    final bgRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(16),
    );
    canvas.drawRRect(bgRRect, bgPaint);

    // Outer border (subtle)
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(bgRRect, borderPaint);

    // Grid lines (3 horizontals)
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..strokeWidth = 1;
    for (int i = 0; i <= 3; i++) {
      final y = chartTop + chartHeight * (i / 3);
      canvas.drawLine(Offset(chartLeft, y), Offset(chartRight, y), gridPaint);
    }

    // Map splits to points (x across bars, y inverted by value)
    Offset pointFor(int i) {
      final t = splits.length == 1 ? 0.5 : i / (splits.length - 1);
      final x = chartLeft + chartWidth * t;
      final norm = (splits[i] - minValue) / range;
      final y = chartBottom - chartHeight * norm;
      return Offset(x, y);
    }

    // Polyline path
    final path = Path();
    for (int i = 0; i < splits.length; i++) {
      final p = pointFor(i);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }

    // Draw line
    final linePaint = Paint()
      ..color = AppTheme.primary(context)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(path, linePaint);

    // Dots
    final dotPaint = Paint()
      ..color = AppTheme.primary(context)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < splits.length; i++) {
      final p = pointFor(i);
      canvas.drawCircle(p, 3.5, dotPaint);
      // White outline for visibility
      canvas.drawCircle(p, 3.5, Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5);
    }

    // Average line (dashed)
    final avgNorm = (avg - minValue) / range;
    final avgY = chartBottom - chartHeight * avgNorm;
    final dashWidth = 6.0;
    final dashSpace = 4.0;
    double startX = chartLeft;
    final avgPaint = Paint()
      ..color = AppTheme.primary(context).withValues(alpha: 0.5)
      ..strokeWidth = 1.2;
    while (startX < chartRight) {
      final endX = math.min(startX + dashWidth, chartRight);
      canvas.drawLine(Offset(startX, avgY), Offset(endX, avgY), avgPaint);
      startX = endX + dashSpace;
    }

    // Selected index guideline & halo
    if (selectedIndex != null && selectedIndex! >= 0 && selectedIndex! < splits.length) {
      final sp = pointFor(selectedIndex!);
      final guidePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.2)
        ..strokeWidth = 1;
      canvas.drawLine(Offset(sp.dx, chartTop), Offset(sp.dx, chartBottom), guidePaint);

      // Halo
      canvas.drawCircle(sp, 7, Paint()
        ..color = AppTheme.primary(context).withValues(alpha: 0.25)
        ..style = PaintingStyle.fill);
      canvas.drawCircle(sp, 7, Paint()
        ..color = AppTheme.primary(context)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5);
    }

    // Edge labels: "fast" at min, "slow" at max
    final labelStyle = TextStyle(color: AppTheme.textSecondary(context), fontSize: 11);
    final tpFast = TextPainter(
      text: TextSpan(text: 'fast ${minValue.toStringAsFixed(2)}s', style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    tpFast.paint(canvas, Offset(chartLeft, chartTop - 16));

    final tpSlow = TextPainter(
      text: TextSpan(text: 'slow ${maxValue.toStringAsFixed(2)}s', style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    tpSlow.paint(canvas, Offset(chartRight - tpSlow.width, chartTop - 16));
  }

  @override
  bool shouldRepaint(covariant _SplitTimeChartPainter oldDelegate) {
    return oldDelegate.splits != splits || oldDelegate.selectedIndex != selectedIndex;
  }
}
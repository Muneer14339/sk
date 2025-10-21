// lib/features/training/presentation/widgets/split_time_chart.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../../core/theme/app_colors.dart';

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
      height: 120,
      child: CustomPaint(
        painter: _SplitTimeChartPainter(splits, selectedIndex),
        size: Size.infinite,
      ),
    );
  }
}

class _SplitTimeChartPainter extends CustomPainter {
  final List<double> splits;
  final int? selectedIndex;

  _SplitTimeChartPainter(this.splits, this.selectedIndex);

  @override
  void paint(Canvas canvas, Size size) {
    if (splits.isEmpty) return;

    final paint = Paint()
      ..color = AppColors.kPrimaryTeal
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final minValue = splits.reduce(math.min);
    final maxValue = splits.reduce(math.max);
    final range = maxValue - minValue;
    final padding = 20.0;

    // Draw baseline
    final baselinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(padding, size.height - padding),
      Offset(size.width - padding, size.height - padding),
      baselinePaint,
    );

    // Draw line chart
    final path = Path();
    for (int i = 0; i < splits.length; i++) {
      final x = padding + (i / (splits.length - 1)) * (size.width - 2 * padding);
      final normalizedValue = range == 0 ? 0.5 : (splits[i] - minValue) / range;
      final y = size.height - padding - normalizedValue * (size.height - 2 * padding);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);

    // Draw points
    for (int i = 0; i < splits.length; i++) {
      final x = padding + (i / (splits.length - 1)) * (size.width - 2 * padding);
      final normalizedValue = range == 0 ? 0.5 : (splits[i] - minValue) / range;
      final y = size.height - padding - normalizedValue * (size.height - 2 * padding);

      final pointPaint = Paint()
        ..color = selectedIndex == i + 1 ? AppColors.kSuccess : AppColors.kPrimaryTeal
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), selectedIndex == i + 1 ? 6 : 4, pointPaint);

      // Draw vertical line for selected
      if (selectedIndex == i + 1) {
        final linePaint = Paint()
          ..color = AppColors.kSuccess.withValues(alpha: 0.3)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;
        canvas.drawLine(
          Offset(x, padding),
          Offset(x, size.height - padding),
          linePaint,
        );
      }
    }

    // Draw labels
    final textStyle = TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11);
    final minLabel = TextPainter(
      text: TextSpan(text: 'fast ${minValue.toStringAsFixed(2)}s', style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    minLabel.paint(canvas, Offset(padding, padding - 5));

    final maxLabel = TextPainter(
      text: TextSpan(text: 'slow ${maxValue.toStringAsFixed(2)}s', style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    maxLabel.paint(canvas, Offset(size.width - padding - maxLabel.width, padding - 5));
  }

  @override
  bool shouldRepaint(covariant _SplitTimeChartPainter oldDelegate) {
    return oldDelegate.splits != splits || oldDelegate.selectedIndex != selectedIndex;
  }
}
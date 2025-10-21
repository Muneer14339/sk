import 'package:flutter/widgets.dart';

import '../../../core/theme/app_colors.dart';

/// Dynamic target rings with equal spacing between each ring
class DynamicTargetRings extends StatelessWidget {
  final int ringCount;
  final Color? ringColor;
  final Color? fillColor;
  final double targetSize;

  const DynamicTargetRings({
    super.key,
    this.ringCount = 6,
    this.ringColor,
    this.fillColor,
    required this.targetSize,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(targetSize),
      painter: _TargetPainter(
        ringCount: ringCount,
        ringColor: ringColor ?? AppColors.kRedColor,
        fillColor: fillColor ?? AppColors.kRedColor,
      ),
    );
  }
}

/// Static target rings with equal spacing between each ring
class StaticTargetRings extends StatelessWidget {
  final int ringCount;
  final Color? ringColor;
  final Color? fillColor;

  const StaticTargetRings({
    super.key,
    this.ringCount = 6,
    this.ringColor,
    this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxDimension = constraints.maxHeight < constraints.maxWidth
            ? constraints.maxHeight
            : constraints.maxWidth;
        final responsiveSize = maxDimension ;

        return Center(
          child: SizedBox(
            width: responsiveSize,
            height: responsiveSize,
            child: CustomPaint(
              painter: _TargetPainter(
                ringCount: ringCount,
                ringColor: ringColor ?? AppColors.kRedColor,
                fillColor: fillColor ?? AppColors.kRedColor,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Painter for target rings with mathematically equal spacing
class _TargetPainter extends CustomPainter {
  final int ringCount;
  final Color ringColor;
  final Color fillColor;

  _TargetPainter({
    required this.ringCount,
    required this.ringColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // Calculate equal spacing between rings
    // Formula: gap = maxRadius / (ringCount - 0.5)
    // This ensures center ring diameter equals the gap
    final gap = maxRadius / (ringCount - 0.5);
    final strokeWidth = gap * 0.06; // Proportional stroke width

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = ringColor;

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = fillColor;

    // Draw rings from outermost to innermost
    for (int i = ringCount; i >= 1; i--) {
      // Calculate radius: gap/2 + (i-1) * gap = gap * (i - 0.5)
      final radius = gap * (i - 0.5);

      // Fill center ring if it's the innermost one
      if (i == 1 && fillColor != AppColors.transparent) {
        canvas.drawCircle(center, radius, fillPaint);
      }

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
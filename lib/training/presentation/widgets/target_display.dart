// lib/features/training/presentation/widgets/target_display.dart
// CHANGE: Only background color updated to white

import 'package:flutter/material.dart';

import '../../../../core/services/prefs.dart';
import '../../../core/theme/app_colors.dart';
import '../bloc/sensitivity_settings/counter_sens_bloc.dart';
import 'target_rings.dart';

class TargetDisplay extends StatelessWidget {
  const TargetDisplay(
      {super.key,
        required this.traceDisplayMode, // ✅ NEW parameter
      required this.tracePoints,
      required this.visGate,
      required this.thetaInstDeg,
      required this.hideOverDeg,
      required this.isInPostShotMode,
      required this.postShotStartIndex,
      required this.shotMarkers,
      required this.lastDrawX,
      required this.lastDrawY,
      required this.isResetting,
      required this.selectedDistance});

  final List<Offset> tracePoints;
  final bool visGate;
  final double thetaInstDeg;
  final double hideOverDeg;
  final bool isInPostShotMode;
  final int postShotStartIndex;
  final List<ShotMarker> shotMarkers;
  final double lastDrawX;
  final double lastDrawY;
  final bool isResetting;
  final String selectedDistance;
  final TraceDisplayMode traceDisplayMode; // ✅ NEW

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, parentConstraints) {
      final parentWidth = parentConstraints.maxWidth;
      final deviceWidth = parentWidth;
      final double displayPx =
          displayedWidthForDistance(deviceWidth, int.parse(selectedDistance));
      return Container(
        width: parentWidth,
        height: parentWidth,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final containerWidth = constraints.maxWidth;
            final containerHeight = constraints.maxHeight;
            final actualCenterX = containerWidth / 2;
            final actualCenterY = containerHeight / 2;
            final maxPreviewSide = constraints.maxHeight / 2;
            final targetSize = displayPx.clamp(16.0, maxPreviewSide) / 2;

            return Stack(
              children: [
                // Crosshair
                CustomPaint(
                    painter: CrosshairPainter(),
                    size: Size(containerWidth, containerHeight)),

                // Target Rings
                SizedBox(
                    width: containerWidth,
                    height: containerHeight,
                    child: StaticTargetRings(ringCount: 6)),

                // Traceline path - only show when conditions are met
                if (traceDisplayMode == TraceDisplayMode.tracelineAndDot &&
                    tracePoints.isNotEmpty && visGate)
                  CustomPaint(
                      painter: TracelinePainter(
                          tracePoints,
                          containerWidth,
                          containerHeight,
                          [],
                          isInPostShotMode,
                          postShotStartIndex),
                      size: Size(containerWidth, containerHeight)),

                // Shot markers rendered separately (always visible)
                if (shotMarkers.isNotEmpty)
                  CustomPaint(
                      painter: ShotMarkersPainter(
                          shotMarkers, containerWidth, containerHeight),
                      size: Size(containerWidth, containerHeight)),

                // ✅ CHANGED: Show dot in tracelineAndDot OR dotOnly modes
                if ((traceDisplayMode == TraceDisplayMode.tracelineAndDot ||
                    traceDisplayMode == TraceDisplayMode.dotOnly) &&
                    visGate && !isResetting)
                  Positioned(
                      left: _convertToDisplayX(lastDrawX, containerWidth) - 4.5,
                      top: _convertToDisplayY(lastDrawY, containerHeight) - 4.5,
                      child: Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                              color: const Color(0xFF9BC1FF),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: const Color(0xFFCFE0FF), width: 1),
                              boxShadow: [
                                BoxShadow(
                                    color: const Color(0xFF79A9FF)
                                        .withValues(alpha: 0.35),
                                    blurRadius: 14,
                                    spreadRadius: 0)
                              ]))),

                // Mini target preview (top right)
                Align(
                  alignment: Alignment.topRight,
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: SizedBox(
                      width: targetSize,
                      height: targetSize,
                      child: DynamicTargetRings(
                        fillColor: AppColors.kRedColor,
                        ringColor: AppColors.kRedColor,
                        ringCount: 6,
                        targetSize: targetSize,
                      ),
                    ),
                  ),
                ),

                // Center reference ring (0.0° - perfect center)
                Positioned(
                  left: actualCenterX - 4,
                  top: actualCenterY - 4,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF34D399),
                      border: Border.all(
                        color: const Color(0xFF10B981),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
    });
  }

  final double baselineMeters = 7.0;

  double displayedWidthForDistance(double deviceWidthPx, int distanceMeters) {
    double scale = baselineMeters / distanceMeters;
    if (scale > 3.0) scale = 3.0;
    return deviceWidthPx * scale;
  }

  double _convertToDisplayX(double internalX, double containerWidth) {
    return (internalX / 400.0) * containerWidth;
  }

  double _convertToDisplayY(double internalY, double containerHeight) {
    return (internalY / 400.0) * containerHeight;
  }
}

// CrosshairPainter - unchanged
class CrosshairPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..strokeWidth = 1.0;

    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ShotMarker class - unchanged
class ShotMarker {
  final Offset position;
  final DateTime timestamp;
  final double accuracy;

  ShotMarker({
    required this.position,
    required this.timestamp,
    required this.accuracy,
  });
}

// TracelinePainter - unchanged
class TracelinePainter extends CustomPainter {
  final List<Offset> points;
  final double containerWidth;
  final double containerHeight;
  final List<ShotMarker> shotMarkers;
  final bool isInPostShotMode;
  final int postShotStartIndex;

  TracelinePainter(
    this.points,
    this.containerWidth,
    this.containerHeight,
    this.shotMarkers,
    this.isInPostShotMode,
    this.postShotStartIndex,
  );

  // target_display.dart - Line 222 se replace karo

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    canvas.save();
    final clipPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(16),
      ));
    canvas.clipPath(clipPath);

    final offsetPoints = points
        .map(
          (point) => Offset(
            _convertInternalToDisplayX(point.dx, containerWidth),
            _convertInternalToDisplayY(point.dy, containerHeight),
          ),
        )
        .toList();

    for (int i = 0; i < offsetPoints.length - 1; i++) {
      final currentPoint = offsetPoints[i];
      final nextPoint = offsetPoints[i + 1];

      bool isPostShot = isInPostShotMode && i >= postShotStartIndex;

      final linePaint = Paint()
        ..color = isPostShot ? const Color(0xFFEF4444) : const Color(0xFF7AA2FF)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      canvas.drawLine(currentPoint, nextPoint, linePaint);
    }

    _drawShotMarkers(canvas, size);

    canvas.restore(); // Restore canvas state
  }

  void _drawShotMarkers(Canvas canvas, Size size) {
    for (final marker in shotMarkers) {
      final displayX =
          _convertInternalToDisplayX(marker.position.dx, containerWidth);
      final displayY =
          _convertInternalToDisplayY(marker.position.dy, containerHeight);
      final displayPos = Offset(displayX, displayY);

      final markerPaint = Paint()
        ..color = _getShotMarkerColor(marker.accuracy)
        ..style = PaintingStyle.fill;

      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(displayPos, 8, markerPaint);
      canvas.drawCircle(displayPos, 8, borderPaint);

      final indicatorPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill
        ..strokeWidth = 1.0;

      canvas.drawLine(
        Offset(displayPos.dx - 3, displayPos.dy),
        Offset(displayPos.dx + 3, displayPos.dy),
        indicatorPaint,
      );
      canvas.drawLine(
        Offset(displayPos.dx, displayPos.dy - 3),
        Offset(displayPos.dx, displayPos.dy + 3),
        indicatorPaint,
      );
    }
  }

  Color _getShotMarkerColor(double accuracy) {
    if (accuracy <= 0.15) return AppColors.greenColor;
    if (accuracy <= 0.6) return AppColors.appYellow;
    // if (accuracy <= 0.6) return const Color(0xFFEF4444);
    return const Color(0xFF6B7280);
  }

  double _convertInternalToDisplayX(double internalX, double containerWidth) {
    return (internalX / 400.0) * containerWidth;
  }

  double _convertInternalToDisplayY(double internalY, double containerHeight) {
    return (internalY / 400.0) * containerHeight;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ShotMarkersPainter - unchanged
class ShotMarkersPainter extends CustomPainter {
  final List<ShotMarker> shotMarkers;
  final double containerWidth;
  final double containerHeight;

  ShotMarkersPainter(
    this.shotMarkers,
    this.containerWidth,
    this.containerHeight,
  );

  @override
  void paint(Canvas canvas, Size size) {
    for (final marker in shotMarkers) {
      final displayX =
          _convertInternalToDisplayX(marker.position.dx, containerWidth);
      final displayY =
          _convertInternalToDisplayY(marker.position.dy, containerHeight);
      final displayPos = Offset(displayX, displayY);

      final markerPaint = Paint()
        ..color = _getShotMarkerColor(marker.accuracy)
        ..style = PaintingStyle.fill;

      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(displayPos, 8, markerPaint);
      canvas.drawCircle(displayPos, 8, borderPaint);

      final indicatorPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawLine(
        Offset(displayPos.dx - 3, displayPos.dy),
        Offset(displayPos.dx + 3, displayPos.dy),
        indicatorPaint,
      );
      canvas.drawLine(
        Offset(displayPos.dx, displayPos.dy - 3),
        Offset(displayPos.dx, displayPos.dy + 3),
        indicatorPaint,
      );
    }
  }

  Color _getShotMarkerColor(double accuracy) {
    if (accuracy <= 0.1525) return AppColors.greenColor;
    if (accuracy <= 0.7) return AppColors.appYellow;
    // if (accuracy <= 0.6) return const Color(0xFFEF4444);
    return const Color(0xFF6B7280);
  }

  double _convertInternalToDisplayX(double internalX, double containerWidth) {
    return (internalX / 400.0) * containerWidth;
  }

  double _convertInternalToDisplayY(double internalY, double containerHeight) {
    return (internalY / 400.0) * containerHeight;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

import 'package:flutter/material.dart';
import 'package:pulse_skadi/features/training/data/model/streaming_model.dart';

class TracePainter extends CustomPainter {
  final List<TracePoint> points;

  TracePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final preShotPoints =
        points.where((tp) => tp.phase == TracePhase.preShot).toList();
    final shotPoints =
        points.where((tp) => tp.phase == TracePhase.shot).toList();
    final postShotPoints =
        points.where((tp) => tp.phase == TracePhase.postShot).toList();

    // 🔧 Sampling rate (FPS or Hz)
    const double sampleRate = 60; // samples per second
    const double highlightSeconds = 5;
    final int highlightCount = (highlightSeconds * sampleRate).round();

    // 🔍 Split preShotPoints into yellow + blue
    List<TracePoint> yellowPreShot = [];
    List<TracePoint> bluePreShot = [];

    if (shotPoints.isNotEmpty) {
      final firstShotIndex = points.indexOf(shotPoints.first);

      // Get last N preShot points before first shot
      final recentPreShot = <TracePoint>[];

      for (int i = firstShotIndex - 1; i >= 0; i--) {
        if (points[i].phase == TracePhase.preShot) {
          recentPreShot.insert(0, points[i]);
          if (recentPreShot.length == highlightCount) break;
        }
      }

      yellowPreShot = recentPreShot;
      bluePreShot =
          preShotPoints.where((tp) => !yellowPreShot.contains(tp)).toList();
    } else {
      bluePreShot = preShotPoints; // No shot yet, all blue
    }

    // 🔵 Draw older Pre-shot points
    if (bluePreShot.isNotEmpty) {
      paint.color = const Color(0xFF17A2B8).withOpacity(0.8); // Blue
      paint.strokeWidth = 2.5;
      _drawPhaseLines(canvas, size, bluePreShot, paint, 'Pre-shot-Blue');
    }

    // 🟡 Draw last 0.15s Pre-shot points
    if (yellowPreShot.isNotEmpty) {
      paint.color = Colors.amber.withOpacity(0.9); // Yellow
      paint.strokeWidth = 3.0;
      _drawPhaseLines(canvas, size, yellowPreShot, paint, 'Pre-shot-Yellow');
    }

    // 🔴 Draw Shot points
    if (shotPoints.isNotEmpty) {
      paint.color = const Color(0xFFDC3545).withOpacity(0.9); // Bright Red
      paint.strokeWidth = 3.5;
      _drawPhaseLines(canvas, size, shotPoints, paint, 'Shot');
    }

    // 🔴 Draw Post-shot points
    if (postShotPoints.isNotEmpty) {
      paint.color = const Color(0xFFDC3545).withOpacity(0.7); // Light Red
      paint.strokeWidth = 2.5;
      _drawPhaseLines(canvas, size, postShotPoints, paint, 'Post-shot');
    }

    _drawShotMarkers(canvas, size, shotPoints);
  }

  void _drawPhaseLines(Canvas canvas, Size size, List<TracePoint> phasePoints,
      Paint paint, String phaseName) {
    if (phasePoints.length < 2) return;

    final path = Path();
    bool pathStarted = false;

    for (int i = 0; i < phasePoints.length; i++) {
      final point = phasePoints[i].point;

      final x = ((point.x + 90) / 180) * size.width;
      final y = ((point.y + 90) / 180) * size.height;

      final clampedX = x.clamp(0.0, size.width);
      final clampedY = y.clamp(0.0, size.height);

      if (!pathStarted) {
        path.moveTo(clampedX, clampedY);
        pathStarted = true;
      } else {
        if (i > 0) {
          final prevPoint = phasePoints[i - 1].point;
          final prevX = ((prevPoint.x + 90) / 180) * size.width;
          final prevY = ((prevPoint.y + 90) / 180) * size.height;

          final controlX = (prevX.clamp(0.0, size.width) + clampedX) / 2;
          final controlY = (prevY.clamp(0.0, size.height) + clampedY) / 2;

          path.quadraticBezierTo(controlX, controlY, clampedX, clampedY);
        } else {
          path.lineTo(clampedX, clampedY);
        }
      }
    }

    if (pathStarted) {
      canvas.drawPath(path, paint);
    }
  }

  void _drawShotMarkers(Canvas canvas, Size size, List<TracePoint> shotPoints) {
    if (shotPoints.isEmpty) return;

    final markerPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFDC3545);

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.white;

    final glowPaint = Paint()
      ..color = const Color(0xFFDC3545).withOpacity(0.3)
      ..style = PaintingStyle.fill;

    for (var tp in shotPoints) {
      final point = tp.point;
      final x = ((point.x + 90) / 180) * size.width;
      final y = ((point.y + 90) / 180) * size.height;

      final clampedX = x.clamp(0.0, size.width);
      final clampedY = y.clamp(0.0, size.height);

      canvas.drawCircle(Offset(clampedX, clampedY), 8.0, glowPaint);
      canvas.drawCircle(Offset(clampedX, clampedY), 5.0, markerPaint);
      canvas.drawCircle(Offset(clampedX, clampedY), 5.0, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant TracePainter oldDelegate) {
    return oldDelegate.points != points;
  }

  @override
  bool shouldRebuildSemantics(covariant TracePainter oldDelegate) {
    return false;
  }
}

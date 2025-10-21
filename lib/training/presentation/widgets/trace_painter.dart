import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../../core/theme/app_colors.dart';
import '../../data/model/streaming_model.dart';

class TracePainter extends CustomPainter {
  final List<TracePoint> points;
  final double smoothingFactor;
  final bool enableInterpolation;
  final int interpolationPoints;
  final bool enableVelocityBasedSmoothing;
  final bool enableAdaptiveThickness;
  final double movementDampening;
  final double responseDelay; // Adds delay to make movement slower
  final double targetRadius; // Target area radius for clipping
  final bool showCurrentPositionMarker; // NEW: Show current position marker
  final bool animateCurrentMarker; // NEW: Animate the current position marker
  final double currentMarkerSize; // NEW: Size of current position marker
  final bool showShotPointMarker; // NEW: Show marker only on shot points

  final Map<String, List<TracePoint>> _phaseCache = {};

  TracePainter(
    this.points, {
    this.smoothingFactor = 0.3,
    this.enableInterpolation = true,
    this.interpolationPoints = 3,
    this.enableVelocityBasedSmoothing = true,
    this.enableAdaptiveThickness = true,
    this.movementDampening = 0.5,
    this.responseDelay = 0.1,
    this.targetRadius = 1.0,
    this.showCurrentPositionMarker = false,
    this.animateCurrentMarker = true,
    this.currentMarkerSize = 8.0,
    this.showShotPointMarker = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    // Separate points by phase with caching
    final preShotPoints = _getCachedPhasePoints(TracePhase.preShot);
    final shotPoints = _getCachedPhasePoints(TracePhase.shot);
    final postShotPoints = _getCachedPhasePoints(TracePhase.postShot);

    // 🔧 Enhanced sampling and highlighting
    const double sampleRate = 60; // samples per second
    const double highlightSeconds = 0.55;
    final int highlightCount = (highlightSeconds * sampleRate).round();

    // 🔍 Split preShotPoints into yellow (recent) + blue (older)
    List<TracePoint> yellowPreShot = [];
    List<TracePoint> bluePreShot = [];

    if (shotPoints.isNotEmpty) {
      final firstShotIndex = points.indexOf(shotPoints.first);
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

    // 🔵 Draw older Pre-shot points with smooth lines
    if (bluePreShot.isNotEmpty) {
      _drawSmoothPhaseLines(
          canvas,
          size,
          bluePreShot,
          const Color(0xFF00008B), // Blue
          2.5,
          'Pre-shot-Blue');
    }

    // 🟡 Draw recent Pre-shot points (last 0.15s) with enhanced visibility
    if (yellowPreShot.isNotEmpty) {
      _drawSmoothPhaseLines(
          canvas,
          size,
          yellowPreShot,
          AppColors.kPrimaryTeal, // Yellow
          3.0,
          'Pre-shot-Yellow');
    }

    // 🔴 Draw Shot points with enhanced visibility
    if (shotPoints.isNotEmpty) {
      _drawSmoothPhaseLines(
          canvas,
          size,
          shotPoints,
          AppColors.bacgroundPaintColorDark, // Bright Red
          3.5,
          'Shot');
    }

    // 🔴 Draw Post-shot points
    if (postShotPoints.isNotEmpty) {
      _drawSmoothPhaseLines(
          canvas,
          size,
          postShotPoints,
          const Color(0xFF800080), // Light Red
          2.5,
          'Post-shot');
    }

    // Draw enhanced shot markers only if enabled
    if (showShotPointMarker) {
      _drawEnhancedShotMarkers(canvas, size, shotPoints);
    }

    // 🎯 NEW: Draw current position marker (head of trace line) only if enabled
    if (showCurrentPositionMarker && points.isNotEmpty) {
      _drawCurrentPositionMarker(canvas, size, points.last);
    }
  }

  /// NEW: Draw current position marker at the head of trace line
  void _drawCurrentPositionMarker(
      Canvas canvas, Size size, TracePoint currentPoint) {
    final point = currentPoint.point;
    final x = _mapSensorToScreen(point.x.toDouble(), size.width, -4.5, 4.5);
    final y = _mapSensorToScreen(point.y.toDouble(), size.height, -4.5, 4.5);

    // Check if current point is within target area
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final maxRadius = (size.width * targetRadius) / 2;
    final distanceFromCenter =
        math.sqrt(math.pow(x - centerX, 2) + math.pow(y - centerY, 2));

    if (distanceFromCenter > maxRadius)
      return; // Don't draw if outside target area

    // Get animation value for pulsing effect (if animated)
    double animationValue = 1.0;
    if (animateCurrentMarker) {
      // Simple pulsing animation based on system time
      final now = DateTime.now().millisecondsSinceEpoch;
      animationValue =
          0.7 + 0.3 * math.sin(now / 200.0); // Pulse between 0.7 and 1.0
    }

    final markerRadius = currentMarkerSize * 0.4 * animationValue;

    // Determine marker color based on current phase
    Color markerColor;
    Color glowColor;
    switch (currentPoint.phase) {
      case TracePhase.preShot:
        markerColor = const Color(0xFF00008B); // Green for active movement
        glowColor = const Color(0xFF00008B).withValues(alpha: 0.4);
        break;
      case TracePhase.shot:
        markerColor = const Color(0xFF254117); // Gold for shot
        glowColor = const Color(0xFF254117).withValues(alpha: 0.6);
        break;
      case TracePhase.postShot:
        markerColor = const Color(0xFF800080); // Orange for post-shot
        glowColor = const Color(0xFF800080).withValues(alpha: 0.4);
        break;
    }

    // Draw outer glow ring
    final outerGlowPaint = Paint()
      ..color = glowColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(x, y), markerRadius * 2.0, outerGlowPaint);

    // Draw middle glow ring
    final middleGlowPaint = Paint()
      ..color = glowColor.withValues(alpha: glowColor.alpha * 0.7)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(x, y), markerRadius * 1.5, middleGlowPaint);

    // Draw main marker circle
    final markerPaint = Paint()
      ..color = markerColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(x, y), markerRadius, markerPaint);

    // Draw white border for better visibility
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(Offset(x, y), markerRadius, borderPaint);

    // Draw inner highlight dot
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(x, y), markerRadius * 0.3, highlightPaint);

    // Draw directional indicator (arrow pointing in movement direction)
    if (points.length > 1) {
      _drawDirectionalIndicator(canvas, x, y, markerRadius, markerColor);
    }
  }

  /// NEW: Draw directional indicator showing movement direction
  void _drawDirectionalIndicator(
      Canvas canvas, double x, double y, double radius, Color color) {
    if (points.length < 2) return;

    final currentPoint = points.last.point;
    final prevPoint = points[points.length - 2].point;

    // Calculate movement direction
    final deltaX = currentPoint.x - prevPoint.x;
    final deltaY = currentPoint.y - prevPoint.y;
    final distance = math.sqrt(deltaX * deltaX + deltaY * deltaY);

    if (distance < 0.01) return; // No significant movement

    // Normalize direction vector
    final dirX = deltaX / distance;
    final dirY = deltaY / distance;

    // Convert to screen coordinates direction
    final screenDirX = dirX * 50; // Scale for visibility
    final screenDirY = dirY * 50;

    // Draw arrow pointing in movement direction
    final arrowPaint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    // Arrow line
    final startX = x + dirX * radius * 1.5;
    final startY = y + dirY * radius * 1.5;
    final endX = startX + screenDirX * 0.3;
    final endY = startY + screenDirY * 0.3;

    canvas.drawLine(Offset(startX, startY), Offset(endX, endY), arrowPaint);

    // Arrow head
    final arrowHeadLength = radius * 0.8;
    final arrowAngle = math.pi / 6; // 30 degrees

    final headX1 = endX -
        arrowHeadLength *
            math.cos(math.atan2(screenDirY, screenDirX) - arrowAngle);
    final headY1 = endY -
        arrowHeadLength *
            math.sin(math.atan2(screenDirY, screenDirX) - arrowAngle);
    final headX2 = endX -
        arrowHeadLength *
            math.cos(math.atan2(screenDirY, screenDirX) + arrowAngle);
    final headY2 = endY -
        arrowHeadLength *
            math.sin(math.atan2(screenDirY, screenDirX) + arrowAngle);

    canvas.drawLine(Offset(endX, endY), Offset(headX1, headY1), arrowPaint);
    canvas.drawLine(Offset(endX, endY), Offset(headX2, headY2), arrowPaint);
  }

  /// Get cached phase points for better performance
  List<TracePoint> _getCachedPhasePoints(TracePhase phase) {
    final cacheKey = '${phase.name}_${points.length}';

    if (_phaseCache.containsKey(cacheKey)) {
      return _phaseCache[cacheKey]!;
    }

    final phasePoints = points.where((tp) => tp.phase == phase).toList();
    _phaseCache[cacheKey] = phasePoints;

    // Limit cache size to prevent memory issues
    if (_phaseCache.length > 20) {
      final oldestKey = _phaseCache.keys.first;
      _phaseCache.remove(oldestKey);
    }

    return phasePoints;
  }

  void _drawSmoothPhaseLines(
      Canvas canvas,
      Size size,
      List<TracePoint> phasePoints,
      Color color,
      double strokeWidth,
      String phaseName) {
    if (phasePoints.length < 2) return;

    // Apply smoothing to reduce jitter
    final smoothedPoints = _applySmoothing(phasePoints);

    // Apply velocity-based smoothing if enabled
    final velocitySmoothedPoints = enableVelocityBasedSmoothing
        ? _applyVelocityBasedSmoothing(smoothedPoints)
        : smoothedPoints;

    // Apply interpolation for smoother curves
    final interpolatedPoints = enableInterpolation
        ? _interpolatePoints(velocitySmoothedPoints, interpolationPoints)
        : velocitySmoothedPoints;

    // Apply movement filtering to remove rapid movements
    final filteredPoints = _filterRapidMovements(interpolatedPoints);

    // Filter points to only include those within target area
    final targetFilteredPoints =
        _filterPointsWithinTarget(filteredPoints, size);

    if (targetFilteredPoints.length < 2) return;

    // Draw smooth path with adaptive thickness (clipped to target area)
    _drawSmoothPathWithAdaptiveThickness(
        canvas, size, targetFilteredPoints, color, strokeWidth);
  }

  /// Filter out rapid movements to make trace line slower
  List<TracePoint> _filterRapidMovements(List<TracePoint> points) {
    if (points.length < 3) return points;

    final filtered = <TracePoint>[];
    filtered.add(points.first);

    for (int i = 1; i < points.length - 1; i++) {
      final prev = points[i - 1].point;
      final current = points[i].point;
      final next = points[i + 1].point;

      // Calculate movement distance
      final distance1 = math.sqrt(
          math.pow(current.x - prev.x, 2) + math.pow(current.y - prev.y, 2));
      final distance2 = math.sqrt(
          math.pow(next.x - current.x, 2) + math.pow(next.y - current.y, 2));

      // Filter out movements that are too rapid (adjust threshold as needed)
      final maxAllowedMovement = 0.1; // Smaller value = slower movement

      if (distance1 < maxAllowedMovement && distance2 < maxAllowedMovement) {
        // Movement is slow enough, keep the point
        filtered.add(points[i]);
      } else {
        // Movement is too rapid, interpolate to slow it down
        final interpolatedX = (prev.x + current.x + next.x) / 3;
        final interpolatedY = (prev.y + current.y + next.y) / 3;

        filtered.add(TracePoint(
            Point3D(interpolatedX, interpolatedY, 0), points[i].phase));
      }
    }

    filtered.add(points.last);
    return filtered;
  }

  /// Filter points to only include those within the target area
  List<TracePoint> _filterPointsWithinTarget(
      List<TracePoint> points, Size size) {
    final targetFiltered = <TracePoint>[];
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final maxRadius = (size.width * targetRadius) / 2; // Target area radius

    for (final point in points) {
      // Convert sensor coordinates to screen coordinates
      final x =
          _mapSensorToScreen(point.point.x.toDouble(), size.width, -4.5, 4.5);
      final y =
          _mapSensorToScreen(point.point.y.toDouble(), size.height, -4.5, 4.5);

      // Calculate distance from center
      final distanceFromCenter =
          math.sqrt(math.pow(x - centerX, 2) + math.pow(y - centerY, 2));

      // Only include points within the target area
      if (distanceFromCenter <= maxRadius) {
        targetFiltered.add(point);
      }
    }

    return targetFiltered;
  }

  List<TracePoint> _applySmoothing(List<TracePoint> points) {
    if (points.length < 3) return points;

    final smoothed = <TracePoint>[];
    smoothed.add(points.first); // Keep first point

    for (int i = 1; i < points.length - 1; i++) {
      final prev = points[i - 1].point;
      final current = points[i].point;
      final next = points[i + 1].point;

      // Apply weighted average smoothing with dampening
      final smoothedX = prev.x * smoothingFactor +
          current.x * (1 - 2 * smoothingFactor) +
          next.x * smoothingFactor;
      final smoothedY = prev.y * smoothingFactor +
          current.y * (1 - 2 * smoothingFactor) +
          next.y * smoothingFactor;

      // Apply movement dampening to reduce sensitivity
      final dampedX = current.x + (smoothedX - current.x) * movementDampening;
      final dampedY = current.y + (smoothedY - current.y) * movementDampening;

      smoothed.add(TracePoint(Point3D(dampedX, dampedY, 0), points[i].phase));
    }

    smoothed.add(points.last); // Keep last point
    return smoothed;
  }

  List<TracePoint> _applyVelocityBasedSmoothing(List<TracePoint> points) {
    if (points.length < 3) return points;

    final velocitySmoothed = <TracePoint>[];
    velocitySmoothed.add(points.first);

    for (int i = 1; i < points.length - 1; i++) {
      final prev = points[i - 1].point;
      final current = points[i].point;
      final next = points[i + 1].point;

      // Calculate velocity (movement speed)
      final velocity1 = math.sqrt(
          math.pow(current.x - prev.x, 2) + math.pow(current.y - prev.y, 2));
      final velocity2 = math.sqrt(
          math.pow(next.x - current.x, 2) + math.pow(next.y - current.y, 2));
      final avgVelocity = (velocity1 + velocity2) / 2;

      // Apply adaptive smoothing based on velocity with dampening
      // Higher velocity = less smoothing (more responsive)
      // Lower velocity = more smoothing (less jitter)
      final adaptiveSmoothingFactor =
          math.min(0.4, math.max(0.1, avgVelocity * 0.5));

      final smoothedX = prev.x * adaptiveSmoothingFactor +
          current.x * (1 - 2 * adaptiveSmoothingFactor) +
          next.x * adaptiveSmoothingFactor;
      final smoothedY = prev.y * adaptiveSmoothingFactor +
          current.y * (1 - 2 * adaptiveSmoothingFactor) +
          next.y * adaptiveSmoothingFactor;

      // Apply movement dampening and response delay
      final dampedX = current.x +
          (smoothedX - current.x) * movementDampening * (1 - responseDelay);
      final dampedY = current.y +
          (smoothedY - current.y) * movementDampening * (1 - responseDelay);

      velocitySmoothed
          .add(TracePoint(Point3D(dampedX, dampedY, 0), points[i].phase));
    }

    velocitySmoothed.add(points.last);
    return velocitySmoothed;
  }

  List<TracePoint> _interpolatePoints(
      List<TracePoint> points, int interpolationCount) {
    if (points.length < 2) return points;

    final interpolated = <TracePoint>[];

    for (int i = 0; i < points.length - 1; i++) {
      final current = points[i];
      final next = points[i + 1];

      interpolated.add(current);

      // Add interpolated points between current and next
      for (int j = 1; j <= interpolationCount; j++) {
        final t = j / (interpolationCount + 1);
        final interpolatedX =
            current.point.x + (next.point.x - current.point.x) * t;
        final interpolatedY =
            current.point.y + (next.point.y - current.point.y) * t;

        interpolated.add(TracePoint(
            Point3D(interpolatedX, interpolatedY, 0), current.phase));
      }
    }

    interpolated.add(points.last);
    return interpolated;
  }

  void _drawSmoothPathWithAdaptiveThickness(Canvas canvas, Size size,
      List<TracePoint> points, Color color, double baseStrokeWidth) {
    if (points.length < 2) return;

    // Save canvas state for clipping
    canvas.save();

    // Create circular clip path for target area
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width * targetRadius) / 2;
    final clipPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));

    // Apply clipping to canvas
    canvas.clipPath(clipPath);

    final path = Path();
    bool pathStarted = false;

    for (int i = 0; i < points.length; i++) {
      final point = points[i].point;

      // Convert sensor coordinates to screen coordinates with better scaling
      final x = _mapSensorToScreen(point.x.toDouble(), size.width, -4.5, 4.5);
      final y = _mapSensorToScreen(point.y.toDouble(), size.height, -4.5, 4.5);

      if (!pathStarted) {
        path.moveTo(x, y);
        pathStarted = true;
      } else {
        if (i > 0) {
          final prevPoint = points[i - 1].point;
          final prevX =
              _mapSensorToScreen(prevPoint.x.toDouble(), size.width, -4.5, 4.5);
          final prevY = _mapSensorToScreen(
              prevPoint.y.toDouble(), size.height, -4.5, 4.5);

          // Use quadratic Bezier curves for smoother lines
          final controlX = (prevX + x) / 2;
          final controlY = (prevY + y) / 2;

          path.quadraticBezierTo(controlX, controlY, x, y);
        } else {
          path.lineTo(x, y);
        }
      }
    }

    if (pathStarted) {
      // Draw with adaptive thickness if enabled
      if (enableAdaptiveThickness && points.length > 2) {
        _drawPathWithAdaptiveThickness(
            canvas, path, points, color, baseStrokeWidth);
      } else {
        // Draw with fixed thickness
        final paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = color
          ..strokeWidth = baseStrokeWidth;
        canvas.drawPath(path, paint);
      }
    }

    // Restore canvas state (remove clipping)
    canvas.restore();
  }

  void _drawPathWithAdaptiveThickness(Canvas canvas, Path path,
      List<TracePoint> points, Color color, double baseStrokeWidth) {
    // Calculate velocity at each point for adaptive thickness
    final velocities = <double>[];

    for (int i = 0; i < points.length; i++) {
      if (i == 0 || i == points.length - 1) {
        velocities.add(0.0); // Start and end points have no velocity
      } else {
        final prev = points[i - 1].point;
        final current = points[i].point;
        final next = points[i + 1].point;

        final velocity1 = math.sqrt(
            math.pow(current.x - prev.x, 2) + math.pow(current.y - prev.y, 2));
        final velocity2 = math.sqrt(
            math.pow(next.x - current.x, 2) + math.pow(next.y - current.y, 2));
        velocities.add((velocity1 + velocity2) / 2);
      }
    }

    // Find max velocity for normalization
    final maxVelocity = velocities.reduce(math.max);
    if (maxVelocity == 0) {
      // Fall back to fixed thickness
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color
        ..strokeWidth = baseStrokeWidth;
      canvas.drawPath(path, paint);
      return;
    }

    // Draw path with velocity-based thickness
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;

    // Adaptive thickness: faster movement = thicker line
    final adaptiveWidth =
        baseStrokeWidth + (velocities.last / maxVelocity) * 2.0;
    paint.strokeWidth =
        adaptiveWidth.clamp(baseStrokeWidth * 0.5, baseStrokeWidth * 2.0);

    canvas.drawPath(path, paint);
  }

  double _mapSensorToScreen(double sensorValue, double screenSize,
      double minSensor, double maxSensor) {
    // Map sensor values (-2.5 to 2.5) to screen coordinates (0 to screenSize)
    final normalized = (sensorValue - minSensor) / (maxSensor - minSensor);
    return normalized * screenSize;
  }

  void _drawEnhancedShotMarkers(
      Canvas canvas, Size size, List<TracePoint> shotPoints) {
    if (shotPoints.isEmpty) return;

    for (var tp in shotPoints) {
      final point = tp.point;
      final x = _mapSensorToScreen(point.x.toDouble(), size.width, -4.5, 4.5);
      final y = _mapSensorToScreen(point.y.toDouble(), size.height, -4.5, 4.5);

      // Draw outer glow
      // final glowPaint = Paint()
      //   ..color = AppColors.kPrimaryTeal.withValues(alpha: 0.4)
      //   ..style = PaintingStyle.fill;
      // canvas.drawCircle(Offset(x, y), 9.0, glowPaint);

      // Draw main marker
      final markerPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = AppColors.kRedColor;
      canvas.drawCircle(Offset(x, y), 4.0, markerPaint);

      // Draw white border
      // final borderPaint = Paint()
      //   ..style = PaintingStyle.stroke
      //   ..strokeWidth = 2.0
      //   ..color = Colors.white;
      // canvas.drawCircle(Offset(x, y), 6.0, borderPaint);

      // Draw inner highlight
      final highlightPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = AppColors.kSuccess.withValues(alpha: 0.8);
      canvas.drawCircle(Offset(x, y), 2.0, highlightPaint);
    }
  }

  @override
  bool shouldRepaint(covariant TracePainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.smoothingFactor != smoothingFactor ||
        oldDelegate.enableInterpolation != enableInterpolation ||
        oldDelegate.interpolationPoints != interpolationPoints ||
        oldDelegate.enableVelocityBasedSmoothing !=
            enableVelocityBasedSmoothing ||
        oldDelegate.enableAdaptiveThickness != enableAdaptiveThickness ||
        oldDelegate.movementDampening != movementDampening ||
        oldDelegate.responseDelay != responseDelay ||
        oldDelegate.targetRadius != targetRadius ||
        oldDelegate.showCurrentPositionMarker != showCurrentPositionMarker ||
        oldDelegate.animateCurrentMarker != animateCurrentMarker ||
        oldDelegate.currentMarkerSize != currentMarkerSize ||
        oldDelegate.showShotPointMarker != showShotPointMarker;
  }

  @override
  bool shouldRebuildSemantics(covariant TracePainter oldDelegate) {
    return false;
  }
}

// lib/features/training/domain/entities/shot_analysis.dart
import 'package:equatable/equatable.dart';

// Three phases of shot analysis
class ShotPhase extends Equatable {
  final DateTime startTime;
  final DateTime endTime;
  final Duration duration;
  final List<SensorReading> readings;
  final Map<String, double> metrics;

  const ShotPhase({
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.readings,
    required this.metrics,
  });

  @override
  List<Object?> get props => [startTime, endTime, duration, readings, metrics];
}

class ShotAnalysis extends Equatable {
  final int shotNumber;
  final DateTime shotTimestamp;
  final ShotPhase preShot;   // 2-3 seconds before
  final ShotPhase triggerEvent; // Shot moment
  final ShotPhase postShot;  // 1-2 seconds after
  final Map<String, dynamic> overallMetrics;
  final String analysisNotes;

  const ShotAnalysis({
    required this.shotNumber,
    required this.shotTimestamp,
    required this.preShot,
    required this.triggerEvent,
    required this.postShot,
    required this.overallMetrics,
    this.analysisNotes = '',
  });

  // Generate coaching feedback based on analysis
  List<String> get coachingTips {
    List<String> tips = [];

    // Pre-shot analysis
    final preShotDrift = preShot.metrics['drift'] ?? 0.0;
    final preShotStability = preShot.metrics['stability'] ?? 0.0;

    if (preShotDrift > 0.5) {
      tips.add("Pre-shot hold drifted ${preShotDrift.toStringAsFixed(1)}° - work on stability");
    }

    if (preShotStability < 70) {
      tips.add("Pre-shot stability was ${preShotStability.toStringAsFixed(0)}% - improve hold consistency");
    }

    // Post-shot analysis
    final recoveryTime = postShot.metrics['recoveryTime'] ?? 0.0;
    final muzzleRise = postShot.metrics['muzzleRise'] ?? 0.0;

    if (recoveryTime > 1.5) {
      tips.add("Recovery time: ${recoveryTime.toStringAsFixed(1)}s - work on follow-through");
    }

    if (muzzleRise > 2.0) {
      tips.add("Muzzle rise: ${muzzleRise.toStringAsFixed(1)}° - check grip and stance");
    }

    return tips;
  }

  @override
  List<Object?> get props => [
    shotNumber, shotTimestamp, preShot, triggerEvent, postShot,
    overallMetrics, analysisNotes
  ];
}

// Shot detection event
class ShotDetectedEvent extends Equatable {
  final DateTime timestamp;
  final int shotNumber;
  final double magnitude;
  final bool isValidShot;
  final String reason;
  final ShotAnalysis? analysis;

  const ShotDetectedEvent({
    required this.timestamp,
    required this.shotNumber,
    required this.magnitude,
    required this.isValidShot,
    this.reason = '',
    this.analysis,
  });

  @override
  List<Object?> get props => [timestamp, shotNumber, magnitude, isValidShot, reason, analysis];
}

// Sensor reading class for shot analysis
class SensorReading extends Equatable {
  final DateTime timestamp;
  final double x, y, z;
  final double magnitude;
  final double cant, tilt;

  const SensorReading({
    required this.timestamp,
    required this.x,
    required this.y,
    required this.z,
    required this.magnitude,
    required this.cant,
    required this.tilt,
  });

  // ✅ ADD: toString method for better debugging
  @override
  String toString() {
    return 'SensorReading(${timestamp.millisecondsSinceEpoch}, '
        'cant: ${cant.toStringAsFixed(3)}°, '
        'tilt: ${tilt.toStringAsFixed(3)}°, '
        'mag: ${magnitude.toStringAsFixed(3)})';
  }

  @override
  List<Object?> get props => [timestamp, x, y, z, magnitude, cant, tilt];
}
// lib/features/training/data/model/shot_trace_model.dart
import 'dart:collection';

import 'streaming_model.dart';

class ShotTraceData {
  final int shotNumber;
  final DateTime timestamp;
  final Queue<TracePoint> tracePoints;
  final double maxMagnitude;
  final Map<String, dynamic> metrics;
  final String analysisNotes;

  ShotTraceData({
    required this.shotNumber,
    required this.timestamp,
    required this.tracePoints,
    required this.maxMagnitude,
    required this.metrics,
    this.analysisNotes = '',
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'shotNumber': shotNumber,
      'timestamp': timestamp.toIso8601String(),
      'tracePoints': tracePoints
          .map((tp) => {
                'x': tp.point.x,
                'y': tp.point.y,
                'z': tp.point.z,
                'phase': tp.phase.toString(),
              })
          .toList(),
      'maxMagnitude': maxMagnitude,
      'metrics': metrics,
      'analysisNotes': analysisNotes,
    };
  }

  // Create from JSON
  factory ShotTraceData.fromJson(Map<String, dynamic> json) {
    Queue<TracePoint> points = Queue<TracePoint>();

    if (json['tracePoints'] != null) {
      for (var pointData in json['tracePoints']) {
        TracePhase phase;
        switch (pointData['phase']) {
          case 'TracePhase.preShot':
            phase = TracePhase.preShot;
            break;
          case 'TracePhase.shot':
            phase = TracePhase.shot;
            break;
          case 'TracePhase.postShot':
            phase = TracePhase.postShot;
            break;
          default:
            phase = TracePhase.preShot;
        }

        points.add(TracePoint(
          Point3D(pointData['x'].toDouble(), pointData['y'].toDouble(),
              pointData['z'].toDouble()),
          phase,
        ));
      }
    }

    return ShotTraceData(
      shotNumber: json['shotNumber'] ?? 0,
      timestamp: DateTime.parse(json['timestamp']),
      tracePoints: points,
      maxMagnitude: json['maxMagnitude']?.toDouble() ?? 0.0,
      metrics: json['metrics'] ?? {},
      analysisNotes: json['analysisNotes'] ?? '',
    );
  }

  ShotTraceData copyWith({
    int? shotNumber,
    DateTime? timestamp,
    Queue<TracePoint>? tracePoints,
    double? maxMagnitude,
    Map<String, dynamic>? metrics,
    String? analysisNotes,
  }) {
    return ShotTraceData(
      shotNumber: shotNumber ?? this.shotNumber,
      timestamp: timestamp ?? this.timestamp,
      tracePoints: tracePoints ?? this.tracePoints,
      maxMagnitude: maxMagnitude ?? this.maxMagnitude,
      metrics: metrics ?? this.metrics,
      analysisNotes: analysisNotes ?? this.analysisNotes,
    );
  }
}

// lib/features/training/data/model/steadiness_shot_data.dart
import 'package:flutter/material.dart';
import 'package:pa_sreens/training/data/model/streaming_model.dart';

class SteadinessShotData {
  final int shotNumber;
  final DateTime timestamp;
  final Offset position; // Shot position on target
  final int score; // Score from 0-10
  final double thetaDot; // Angular deviation in degrees
  final double accuracy; // 0.0 to 1.0 (0.0 = perfect center, 1.0 = edge)
  final List<TracePoint> tracelinePoints; // Complete traceline for this shot
  final Map<String, dynamic> metrics; // Additional metrics
  final String analysisNotes;

  SteadinessShotData({
    required this.shotNumber,
    required this.timestamp,
    required this.position,
    required this.score,
    required this.thetaDot,
    required this.accuracy,
    required this.tracelinePoints,
    this.metrics = const {},
    this.analysisNotes = '',
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'shotNumber': shotNumber,
      'timestamp': timestamp.toIso8601String(),
      'position': {
        'x': position.dx,
        'y': position.dy,
      },
      'score': score,
      'thetaDot': thetaDot,
      'accuracy': accuracy,
      'tracelinePoints': tracelinePoints
          .map((point) => {
                'x': point.point.x,
                'y': point.point.y,
                'z': point.point.z,
                'phase': point.phase.toString(),
              })
          .toList(),
      'metrics': metrics,
      'analysisNotes': analysisNotes,
    };
  }

  // Create from JSON
  factory SteadinessShotData.fromJson(Map<String, dynamic> json) {
    List<TracePoint> points = [];

    if (json['tracelinePoints'] != null) {
      for (var pointData in json['tracelinePoints']) {
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

    return SteadinessShotData(
      shotNumber: json['shotNumber'] ?? 0,
      timestamp: DateTime.parse(json['timestamp']),
      position: Offset(
        json['position']['x'].toDouble(),
        json['position']['y'].toDouble(),
      ),
      score: json['score'] ?? 0,
      thetaDot: json['thetaDot']?.toDouble() ?? 0.0,
      accuracy: json['accuracy']?.toDouble() ?? 0.0,
      tracelinePoints: points,
      metrics: json['metrics'] ?? {},
      analysisNotes: json['analysisNotes'] ?? '',
    );
  }

  SteadinessShotData copyWith({
    int? shotNumber,
    DateTime? timestamp,
    Offset? position,
    int? score,
    double? thetaDot,
    double? accuracy,
    List<TracePoint>? tracelinePoints,
    Map<String, dynamic>? metrics,
    String? analysisNotes,
  }) {
    return SteadinessShotData(
      shotNumber: shotNumber ?? this.shotNumber,
      timestamp: timestamp ?? this.timestamp,
      position: position ?? this.position,
      score: score ?? this.score,
      thetaDot: thetaDot ?? this.thetaDot,
      accuracy: accuracy ?? this.accuracy,
      tracelinePoints: tracelinePoints ?? this.tracelinePoints,
      metrics: metrics ?? this.metrics,
      analysisNotes: analysisNotes ?? this.analysisNotes,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SteadinessShotData &&
        other.shotNumber == shotNumber &&
        other.timestamp == timestamp &&
        other.position == position &&
        other.score == score &&
        other.thetaDot == thetaDot &&
        other.accuracy == accuracy &&
        _listEquals(other.tracelinePoints, tracelinePoints) &&
        _mapEquals(other.metrics, metrics) &&
        other.analysisNotes == analysisNotes;
  }

  @override
  int get hashCode {
    return shotNumber.hashCode ^
        timestamp.hashCode ^
        position.hashCode ^
        score.hashCode ^
        thetaDot.hashCode ^
        accuracy.hashCode ^
        tracelinePoints.hashCode ^
        metrics.hashCode ^
        analysisNotes.hashCode;
  }

  // Helper method to compare lists
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }

  // Helper method to compare maps
  bool _mapEquals<K, V>(Map<K, V>? a, Map<K, V>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (final K key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }
}

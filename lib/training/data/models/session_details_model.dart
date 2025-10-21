// lib/features/training/data/models/session_details_model.dart
import '../../domain/entities/session_details_entity.dart';

class SessionDetailsModel extends SessionDetailsEntity {
  const SessionDetailsModel({
    required super.sessionId,
    required super.programName,
    required super.sessionDate,
    required super.duration,
    required super.totalShots,
    required super.shots,
    required super.metadata,
    required super.metrics,
    required super.isSuccess,
    required super.aiInsights,
  });

  factory SessionDetailsModel.fromJson(Map<String, dynamic> json) {
    return SessionDetailsModel(
      sessionId: json['sessionId'] ?? '',
      programName: json['programName'] ?? '',
      sessionDate: DateTime.parse(json['sessionDate']),
      duration: json['duration'] ?? '',
      totalShots: json['totalShots'] ?? 0,
      shots: (json['shots'] as List<dynamic>)
          .map((shot) => ShotDetailsModel.fromJson(shot))
          .toList(),
      metadata: SessionMetadataModel.fromJson(json['metadata']),
      metrics: SessionMetricsModel.fromJson(json['metrics']),
      isSuccess: json['isSuccess'] ?? false,
      aiInsights: json['aiInsights'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'programName': programName,
      'sessionDate': sessionDate.toIso8601String(),
      'duration': duration,
      'totalShots': totalShots,
      'shots':
          shots.map((shot) => (shot as ShotDetailsModel).toJson()).toList(),
      'metadata': (metadata as SessionMetadataModel).toJson(),
      'metrics': (metrics as SessionMetricsModel).toJson(),
      'isSuccess': isSuccess,
      'aiInsights': aiInsights,
    };
  }
}

class ShotDetailsModel extends ShotDetailsEntity {
  const ShotDetailsModel({
    required super.id,
    required super.x,
    required super.y,
    required super.score,
    required super.timestamp,
    required super.metrics,
    required super.hasTraceData,
  });

  factory ShotDetailsModel.fromJson(Map<String, dynamic> json) {
    return ShotDetailsModel(
      id: json['id'] ?? 0,
      x: (json['x'] ?? 0.0).toDouble(),
      y: (json['y'] ?? 0.0).toDouble(),
      score: json['score'] ?? 0,
      timestamp: DateTime.parse(json['timestamp']),
      metrics: Map<String, double>.from(json['metrics'] ?? {}),
      hasTraceData: json['hasTraceData'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'x': x,
      'y': y,
      'score': score,
      'timestamp': timestamp.toIso8601String(),
      'metrics': metrics,
      'hasTraceData': hasTraceData,
    };
  }
}

class SessionMetadataModel extends SessionMetadataEntity {
  const SessionMetadataModel({
    required super.firearm,
    required super.optic,
    required super.ammunition,
    required super.distance,
    required super.conditions,
  });

  factory SessionMetadataModel.fromJson(Map<String, dynamic> json) {
    return SessionMetadataModel(
      firearm: json['firearm'] ?? '',
      optic: json['optic'] ?? '',
      ammunition: json['ammunition'] ?? '',
      distance: json['distance'] ?? '',
      conditions: json['conditions'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'firearm': firearm,
      'optic': optic,
      'ammunition': ammunition,
      'distance': distance,
      'conditions': conditions,
    };
  }
}

class SessionMetricsModel extends SessionMetricsEntity {
  const SessionMetricsModel({
    required super.averageScore,
    required super.successRate,
    required super.groupSize,
    required super.programMetrics,
  });

  factory SessionMetricsModel.fromJson(Map<String, dynamic> json) {
    return SessionMetricsModel(
      averageScore: (json['averageScore'] ?? 0.0).toDouble(),
      successRate: (json['successRate'] ?? 0.0).toDouble(),
      groupSize: (json['groupSize'] ?? 0.0).toDouble(),
      programMetrics: Map<String, double>.from(json['programMetrics'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'averageScore': averageScore,
      'successRate': successRate,
      'groupSize': groupSize,
      'programMetrics': programMetrics,
    };
  }
}

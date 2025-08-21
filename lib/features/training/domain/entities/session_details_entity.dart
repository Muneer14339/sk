// lib/features/training/domain/entities/session_details_entity.dart
import 'package:equatable/equatable.dart';

class SessionDetailsEntity extends Equatable {
  final String sessionId;
  final String programName;
  final DateTime sessionDate;
  final String duration;
  final int totalShots;
  final List<ShotDetailsEntity> shots;
  final SessionMetadataEntity metadata;
  final SessionMetricsEntity metrics;
  final bool isSuccess;
  final String aiInsights;

  const SessionDetailsEntity({
    required this.sessionId,
    required this.programName,
    required this.sessionDate,
    required this.duration,
    required this.totalShots,
    required this.shots,
    required this.metadata,
    required this.metrics,
    required this.isSuccess,
    required this.aiInsights,
  });

  @override
  List<Object?> get props => [
        sessionId,
        programName,
        sessionDate,
        duration,
        totalShots,
        shots,
        metadata,
        metrics,
        isSuccess,
        aiInsights,
      ];
}

class ShotDetailsEntity extends Equatable {
  final int id;
  final double x;
  final double y;
  final int score;
  final DateTime timestamp;
  final Map<String, double> metrics;
  final bool hasTraceData;

  const ShotDetailsEntity({
    required this.id,
    required this.x,
    required this.y,
    required this.score,
    required this.timestamp,
    required this.metrics,
    required this.hasTraceData,
  });

  @override
  List<Object?> get props => [
        id,
        x,
        y,
        score,
        timestamp,
        metrics,
        hasTraceData,
      ];
}

class SessionMetadataEntity extends Equatable {
  final String firearm;
  final String optic;
  final String ammunition;
  final String distance;
  final String conditions;

  const SessionMetadataEntity({
    required this.firearm,
    required this.optic,
    required this.ammunition,
    required this.distance,
    required this.conditions,
  });

  @override
  List<Object?> get props => [
        firearm,
        optic,
        ammunition,
        distance,
        conditions,
      ];
}

class SessionMetricsEntity extends Equatable {
  final double averageScore;
  final double successRate;
  final double groupSize;
  final Map<String, double> programMetrics;

  const SessionMetricsEntity({
    required this.averageScore,
    required this.successRate,
    required this.groupSize,
    required this.programMetrics,
  });

  @override
  List<Object?> get props => [
        averageScore,
        successRate,
        groupSize,
        programMetrics,
      ];
}

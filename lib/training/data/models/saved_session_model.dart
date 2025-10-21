// lib/features/training/data/models/saved_session_model.dart


import '../model/shot_trace_model.dart';
import '../model/steadiness_shot_data.dart';

class SavedSessionModel {
  final String id;
  final String userId;
  final String programName;
  final DateTime startedAt;
  final int totalShots;
  final int distancePresetKey;
  final String angleRangeKey;
  final List<ShotTraceData> sessionShotTraces;
  final List<SteadinessShotData> steadinessShots;
  final List<int> missedShotNumbers; // NEW

  const SavedSessionModel({
    required this.id,
    required this.userId,
    required this.programName,
    required this.startedAt,
    required this.totalShots,
    required this.distancePresetKey,
    required this.angleRangeKey,
    required this.sessionShotTraces,
    required this.steadinessShots,
    this.missedShotNumbers = const [], // NEW: Default empty
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'programName': programName,
      'startedAt': startedAt.toIso8601String(),
      'totalShots': totalShots,
      'distancePresetKey': distancePresetKey,
      'angleRangeKey': angleRangeKey,
      'sessionShotTraces': sessionShotTraces.map((e) => e.toJson()).toList(),
      'steadinessShots': steadinessShots.map((e) => e.toJson()).toList(),
      'missedShotNumbers': missedShotNumbers, // NEW
    };
  }

  factory SavedSessionModel.fromFirestore(
      String id, Map<String, dynamic> json) {
    print('------- $json');
    return SavedSessionModel(
      id: id,
      userId: json['userId'] ?? '',
      programName: json['programName'] ?? '',
      startedAt: DateTime.parse(json['startedAt']),
      totalShots: (json['totalShots'] ?? 0) as int,
      distancePresetKey: 7,
      angleRangeKey: json['angleRangeKey'] ?? 'default',
      sessionShotTraces: (json['sessionShotTraces'] as List<dynamic>? ?? [])
          .map((e) => ShotTraceData.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      steadinessShots: (json['steadinessShots'] as List<dynamic>? ?? [])
          .map((e) => SteadinessShotData.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      missedShotNumbers: (json['missedShotNumbers'] as List<dynamic>? ?? []) // NEW: Handle old data
          .map((e) => e as int)
          .toList(),
    );
  }
}
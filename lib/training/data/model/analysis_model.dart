

import 'package:pa_sreens/training/data/model/streaming_model.dart';

class AnalysisModel {
  final int? shotNumber;
  final DateTime? timestamp;
  final double? maxMagnitude;
  final List<TracePoint>? tracePoints;
  final AnalysisMetrics? metrics;
  final String? analysisNotes;
  final int? score;

  AnalysisModel({
    this.shotNumber,
    this.timestamp,
    this.maxMagnitude,
    this.tracePoints,
    this.metrics,
    this.analysisNotes,
    this.score,
  });

  factory AnalysisModel.fromJson(Map<String, dynamic> json) {
    return AnalysisModel(
      shotNumber: json['shotNumber'] as int?,
      timestamp: json['timestamp'].runtimeType == DateTime
          ? json['timestamp'] as DateTime
          : DateTime.parse(json['timestamp']),
      maxMagnitude: (json['maxMagnitude'] as num?)?.toDouble(),
      tracePoints: json['tracePoints'] as List<TracePoint>?,
      metrics: json['metrics'] != null
          ? AnalysisMetrics.fromJson(json['metrics'])
          : null,
      analysisNotes: json['analysisNotes'] as String?,
      score: json['score'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'shotNumber': shotNumber,
      'timestamp': timestamp?.toIso8601String(),
      'maxMagnitude': maxMagnitude,
      'tracePoints': tracePoints,
      'metrics': metrics?.toJson(),
      'analysisNotes': analysisNotes,
      'score': score,
    };
  }
}

class AnalysisMetrics {
  final String? status;
  final int? preShotCount;
  final int? shotCount;
  final int? postShotCount;
  final int? totalPoints;
  final bool? isBalanced;
  final bool? smoothingApplied;

  AnalysisMetrics({
    this.status,
    this.preShotCount,
    this.shotCount,
    this.postShotCount,
    this.totalPoints,
    this.isBalanced,
    this.smoothingApplied,
  });

  factory AnalysisMetrics.fromJson(Map<String, dynamic> json) {
    return AnalysisMetrics(
      status: json['status'] as String?,
      preShotCount: json['preShotCount'] as int?,
      shotCount: json['shotCount'] as int?,
      postShotCount: json['postShotCount'] as int?,
      totalPoints: json['totalPoints'] as int?,
      isBalanced: json['isBalanced'] as bool?,
      smoothingApplied: json['smoothingApplied'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'preShotCount': preShotCount,
      'shotCount': shotCount,
      'postShotCount': postShotCount,
      'totalPoints': totalPoints,
      'isBalanced': isBalanced,
      'smoothingApplied': smoothingApplied,
    };
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../armory/domain/entities/armory_loadout.dart';

class ProgramsModel {
  final String? programName;
  final String? programDescription;
  final String? modeName;
  final String? trainingType;
  final String? focusArea;
  final String? difficultyLevel;
  final int? noOfShots;
  final String? timePressure;
  final ArmoryLoadout? weaponProfile;
  final String? recommenedDistance;
  final String? successThreshold;
  final String? successCriteria;
  final String? timeLimit;
  final List<PerformanceMetrics>? performanceMetrics;
  final String? type;
  final String? badge;
  final String? badgeColor;

  ProgramsModel({
    this.programName,
    this.programDescription,
    this.modeName,
    this.trainingType,
    this.focusArea,
    this.difficultyLevel,
    this.noOfShots,
    this.timePressure,
    this.weaponProfile,
    this.recommenedDistance,
    this.successThreshold,
    this.successCriteria,
    this.timeLimit,
    this.performanceMetrics,
    this.type,
    this.badge,
    this.badgeColor,
  });

  Map<String, dynamic> toMap() {
    return {
      'programName': programName,
      'programDescription': programDescription,
      'modeName': modeName,
      'trainingType': trainingType,
      'focusArea': focusArea,
      'difficultyLevel': difficultyLevel,
      'noOfShots': noOfShots,
      'timePressure': timePressure,
      'weaponProfileId': weaponProfile?.id,
      'recommenedDistance': recommenedDistance,
      'successThreshold': successThreshold,
      'successCriteria': successCriteria,
      'timeLimit': timeLimit,
      'performanceMetrics':
      performanceMetrics?.map((e) => e.toMap()).toList(),
      'type': type,
      'badge': badge,
      'badgeColor': badgeColor,
    };
  }

  ProgramsModel copyWith({
    String? programName,
    String? programDescription,
    String? modeName,
    String? trainingType,
    String? focusArea,
    String? difficultyLevel,
    int? noOfShots,
    String? timePressure,
    ArmoryLoadout? weaponProfile,
    String? recommenedDistance,
    String? successThreshold,
    String? successCriteria,
    String? timeLimit,
    List<PerformanceMetrics>? performanceMetrics,
    String? type,
    String? badge,
    String? badgeColor,
  }) {
    return ProgramsModel(
      programName: programName ?? this.programName,
      programDescription: programDescription ?? this.programDescription,
      modeName: modeName ?? this.modeName,
      trainingType: trainingType ?? this.trainingType,
      focusArea: focusArea ?? this.focusArea,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      noOfShots: noOfShots ?? this.noOfShots,
      timePressure: timePressure ?? this.timePressure,
      weaponProfile: weaponProfile ?? this.weaponProfile,
      recommenedDistance: recommenedDistance ?? this.recommenedDistance,
      successThreshold: successThreshold ?? this.successThreshold,
      successCriteria: successCriteria ?? this.successCriteria,
      timeLimit: timeLimit ?? this.timeLimit,
      performanceMetrics: performanceMetrics ?? this.performanceMetrics,
      type: type ?? this.type,
      badge: badge ?? this.badge,
      badgeColor: badgeColor ?? this.badgeColor,
    );
  }
}

class PerformanceMetrics {
  final String? stability;
  final String? target;
  final String? unit;

  PerformanceMetrics({
    this.stability,
    this.target,
    this.unit,
  });

  Map<String, dynamic> toMap() {
    return {
      'stability': stability,
      'target': target,
      'unit': unit,
    };
  }

  PerformanceMetrics copyWith({
    String? stability,
    String? target,
    String? unit,
  }) {
    return PerformanceMetrics(
      stability: stability ?? this.stability,
      target: target ?? this.target,
      unit: unit ?? this.unit,
    );
  }
}
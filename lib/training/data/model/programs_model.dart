import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../armory/domain/entities/armory_loadout.dart';
import 'drill_model.dart';

class ProgramsModel {
  final String? programName;
  final String? programDescription;
  final String? modeName;
  final String? focusArea;
  final String? timePressure;
  final ArmoryLoadout? loadout;

  // ✅ moved OUT of ProgramsModel: trainingType, difficultyLevel, noOfShots,
  //    timeLimit, recommenedDistance → now inside DrillModel
  //    Keep program-level success/metrics separate from drill.

  final String? successThreshold;
  final String? successCriteria;
  final List<PerformanceMetrics>? performanceMetrics;

  final String? type;
  final String? badge;
  final String? badgeColor;

  /// NEW: nested drill object
  final DrillModel? drill;

  ProgramsModel({
    this.programName,
    this.programDescription,
    this.modeName,
    this.focusArea,
    this.timePressure,
    this.loadout,
    this.successThreshold,
    this.successCriteria,
    this.performanceMetrics,
    this.type,
    this.badge,
    this.badgeColor,
    this.drill,
  });

  Map<String, dynamic> toMap() {
    return {
      'programName': programName,
      'programDescription': programDescription,
      'modeName': modeName,
      'focusArea': focusArea,
      'timePressure': timePressure,
      'weaponProfileId': loadout?.id,
      'successThreshold': successThreshold,
      'successCriteria': successCriteria,
      'performanceMetrics': performanceMetrics?.map((e) => e.toMap()).toList(),
      'type': type,
      'badge': badge,
      'badgeColor': badgeColor,
      'drill': drill?.toMap(), // ✅ nested
    };
  }

  ProgramsModel copyWith({
    String? programName,
    String? programDescription,
    String? modeName,
    String? focusArea,
    String? timePressure,
    ArmoryLoadout? loadout,
    String? successThreshold,
    String? successCriteria,
    List<PerformanceMetrics>? performanceMetrics,
    String? type,
    String? badge,
    String? badgeColor,
    DrillModel? drill,
  }) {
    return ProgramsModel(
      programName: programName ?? this.programName,
      programDescription: programDescription ?? this.programDescription,
      modeName: modeName ?? this.modeName,
      focusArea: focusArea ?? this.focusArea,
      timePressure: timePressure ?? this.timePressure,
      loadout: loadout ?? this.loadout,
      successThreshold: successThreshold ?? this.successThreshold,
      successCriteria: successCriteria ?? this.successCriteria,
      performanceMetrics: performanceMetrics ?? this.performanceMetrics,
      type: type ?? this.type,
      badge: badge ?? this.badge,
      badgeColor: badgeColor ?? this.badgeColor,
      drill: drill ?? this.drill,
    );
  }
}

class PerformanceMetrics {
  final String? stability;
  final String? target;
  final String? unit;

  PerformanceMetrics({this.stability, this.target, this.unit});

  Map<String, dynamic> toMap() {
    return {'stability': stability, 'target': target, 'unit': unit};
  }

  PerformanceMetrics copyWith({String? stability, String? target, String? unit}) {
    return PerformanceMetrics(
      stability: stability ?? this.stability,
      target: target ?? this.target,
      unit: unit ?? this.unit,
    );
  }
}

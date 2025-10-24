import 'package:cloud_firestore/cloud_firestore.dart';

class DrillModel {
  final String name;                 // e.g., "Open Practice" or custom name
  final String fireType;             // "Dry Fire" | "Live Fire"
  final String sensitivity;          // "Beginner" | "Intermediate" | "Advanced"
  final String distanceYards;        // "7" | "10" | ...
  final String timer;                // "Free" | "Par" | "Cadence"
  final int? customTimeSeconds;      // null if Free; value if Par/Cadence
  final String startSignal;          // "Beep" | "Voice Standby" | "None"
  final String scoring;              // "Time-only" | "Score-only" | "Time+Score"
  final int? plannedRounds;          // e.g., 10
  final String environment;          // "Indoor" | "Outdoor"
  final String? notes;               // optional

  const DrillModel({
    required this.name,
    required this.fireType,
    required this.sensitivity,
    required this.distanceYards,
    required this.timer,
    this.customTimeSeconds,
    required this.startSignal,
    required this.scoring,
    this.plannedRounds,
    required this.environment,
    this.notes,
  });

  /// sensible default for “Open Practice”
  factory DrillModel.openPractice() => const DrillModel(
    name: 'Open Practice',
    fireType: 'Dry Fire',
    sensitivity: 'Advanced',
    distanceYards: '7',
    timer: 'Free',
    customTimeSeconds: null,
    startSignal: 'Beep',
    scoring: 'Time+Score',
    plannedRounds: 10,
    environment: 'Indoor',
    notes: 'Default open practice',
  );

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'fireType': fireType,
      'sensitivity': sensitivity,
      'distanceYards': distanceYards,
      'timer': timer,
      'customTimeSeconds': customTimeSeconds,
      'startSignal': startSignal,
      'scoring': scoring,
      'plannedRounds': plannedRounds,
      'environment': environment,
      'notes': notes,
    };
  }

  factory DrillModel.fromMap(Map<String, dynamic> map) {
    return DrillModel(
      name: map['name'] ?? 'Open Practice',
      fireType: map['fireType'] ?? 'Dry Fire',
      sensitivity: map['sensitivity'] ?? 'Advanced',
      distanceYards: map['distanceYards']?.toString() ?? '7',
      timer: map['timer'] ?? 'Free',
      customTimeSeconds: map['customTimeSeconds'],
      startSignal: map['startSignal'] ?? 'Beep',
      scoring: map['scoring'] ?? 'Time+Score',
      plannedRounds: map['plannedRounds'],
      environment: map['environment'] ?? 'Indoor',
      notes: map['notes'],
    );
  }

  DrillModel copyWith({
    String? name,
    String? fireType,
    String? sensitivity,
    String? distanceYards,
    String? timer,
    int? customTimeSeconds,
    String? startSignal,
    String? scoring,
    int? plannedRounds,
    String? environment,
    String? notes,
  }) {
    return DrillModel(
      name: name ?? this.name,
      fireType: fireType ?? this.fireType,
      sensitivity: sensitivity ?? this.sensitivity,
      distanceYards: distanceYards ?? this.distanceYards,
      timer: timer ?? this.timer,
      customTimeSeconds: customTimeSeconds ?? this.customTimeSeconds,
      startSignal: startSignal ?? this.startSignal,
      scoring: scoring ?? this.scoring,
      plannedRounds: plannedRounds ?? this.plannedRounds,
      environment: environment ?? this.environment,
      notes: notes ?? this.notes,
    );
  }
}

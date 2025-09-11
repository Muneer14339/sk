// lib/features/training/presentation/bloc/training_session/training_session_state.dart - Enhanced version
import 'package:equatable/equatable.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:pulse_skadi/features/training/data/model/programs_model.dart';
import 'package:pulse_skadi/features/training/data/model/shot_trace_model.dart';
import 'package:pulse_skadi/features/training/data/model/steadiness_shot_data.dart';
import 'package:pulse_skadi/features/training/presentation/pages/live_training.dart';
import 'package:pulse_skadi/features/training/data/model/streaming_model.dart';

class TrainingSessionState extends Equatable {
  final bool isTraining;
  final DateTime? sessionStartTime;
  final int shotCount;
  final List<ShotData> shotData;
  final bool hapticEnabled;
  final bool sessionCompleted;
  final String aiFeedbackText;
  final bool isSensorsEnabled;
  final StreamingModel? sensorStream;
  final int ditCommand;
  final int dvcCommand;
  final int swdCommand;
  final int swbdCommand;
  final int avdCommand;
  final int avdtCommand;
  final BluetoothDevice? device;
  final ProgramsModel? program;
  final List<ShotTraceData> sessionShotTraces; // ✅ NEW: Shot traces data
  final List<SteadinessShotData> steadinessShots; // ✅ NEW: Steadiness shot data

  const TrainingSessionState({
    this.isTraining = false,
    this.sessionStartTime,
    this.shotCount = 0,
    this.shotData = const [],
    this.hapticEnabled = true,
    this.sessionCompleted = false,
    this.aiFeedbackText =
        "Ready for your training session. Connect your RT sensor and begin when ready.",
    this.isSensorsEnabled = false,
    this.sensorStream,
    this.ditCommand = 0,
    this.dvcCommand = 0,
    this.swdCommand = 0,
    this.swbdCommand = 0,
    this.avdCommand = 0,
    this.avdtCommand = 0,
    this.device,
    this.program,
    this.sessionShotTraces = const [], // ✅ NEW: Initialize empty shot traces
    this.steadinessShots = const [], // ✅ NEW: Initialize empty steadiness shots
  });

  TrainingSessionState copyWith({
    bool? isTraining,
    DateTime? sessionStartTime,
    int? shotCount,
    List<ShotData>? shotData,
    bool? hapticEnabled,
    bool? sessionCompleted,
    String? aiFeedbackText,
    bool? isSensorsEnabled,
    StreamingModel? sensorStream,
    int? ditCommand,
    int? dvcCommand,
    int? swdCommand,
    int? swbdCommand,
    int? avdCommand,
    int? avdtCommand,
    BluetoothDevice? device,
    ProgramsModel? program,
    List<ShotTraceData>? sessionShotTraces, // ✅ NEW: Include in copyWith
    List<SteadinessShotData>? steadinessShots, // ✅ NEW: Include in copyWith
  }) {
    final newState = TrainingSessionState(
      isTraining: isTraining ?? this.isTraining,
      sessionStartTime: sessionStartTime ?? this.sessionStartTime,
      shotCount: shotCount ?? this.shotCount,
      shotData: shotData ?? this.shotData,
      hapticEnabled: hapticEnabled ?? this.hapticEnabled,
      sessionCompleted: sessionCompleted ?? this.sessionCompleted,
      aiFeedbackText: aiFeedbackText ?? this.aiFeedbackText,
      isSensorsEnabled: isSensorsEnabled ?? this.isSensorsEnabled,
      sensorStream: sensorStream ?? this.sensorStream,
      ditCommand: ditCommand ?? this.ditCommand,
      dvcCommand: dvcCommand ?? this.dvcCommand,
      swdCommand: swdCommand ?? this.swdCommand,
      swbdCommand: swbdCommand ?? this.swbdCommand,
      avdCommand: avdCommand ?? this.avdCommand,
      avdtCommand: avdtCommand ?? this.avdtCommand,
      device: device ?? this.device,
      program: program ?? this.program,
      sessionShotTraces: sessionShotTraces ?? this.sessionShotTraces, // ✅ NEW
      steadinessShots: steadinessShots ?? this.steadinessShots, // ✅ NEW
    );
    return newState;
  }

  // ✅ NEW: Helper method to get shot trace by number
  ShotTraceData? getShotTrace(int shotNumber) {
    try {
      return sessionShotTraces
          .firstWhere((trace) => trace.shotNumber == shotNumber);
    } catch (e) {
      return null;
    }
  }

  // ✅ NEW: Helper method to check if shot has trace data
  bool hasShotTrace(int shotNumber) {
    return getShotTrace(shotNumber) != null;
  }

  // ✅ NEW: Helper method to get steadiness shot by number
  SteadinessShotData? getSteadinessShot(int shotNumber) {
    try {
      return steadinessShots
          .firstWhere((shot) => shot.shotNumber == shotNumber);
    } catch (e) {
      return null;
    }
  }

  // ✅ NEW: Helper method to check if steadiness shot exists
  bool hasSteadinessShot(int shotNumber) {
    return getSteadinessShot(shotNumber) != null;
  }

  @override
  List<Object?> get props => [
        isTraining,
        sessionStartTime,
        shotCount,
        shotData,
        hapticEnabled,
        sessionCompleted,
        aiFeedbackText,
        isSensorsEnabled,
        sensorStream,
        ditCommand,
        dvcCommand,
        swdCommand,
        swbdCommand,
        avdCommand,
        avdtCommand,
        device,
        program,
        sessionShotTraces, // ✅ NEW: Include in props for equality comparison
        steadinessShots, // ✅ NEW: Include in props for equality comparison
      ];
}

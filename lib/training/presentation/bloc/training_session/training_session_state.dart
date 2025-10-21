// lib/features/training/presentation/bloc/training_session/training_session_state.dart
import 'package:equatable/equatable.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../../../data/model/programs_model.dart';
import '../../../data/model/shot_trace_model.dart';
import '../../../data/model/steadiness_shot_data.dart';
import '../../../data/model/streaming_model.dart';
import '../../widgets/target_display.dart';

class TrainingSessionState extends Equatable {
  // Core session state
  final bool isTraining;
  final bool isCalibrationMode; // NEW: Separate calibration mode
  final DateTime? sessionStartTime;
  final Duration? sessionTotalTime;
  final bool sessionCompleted;
  final bool waitingForLastShotTrace;
  final int shotCount;
  final int missedShotCount; // NEW: Track missed shots
  final List<Map<String, dynamic>> shotLog;

  // Sensor state
  final bool isSensorsEnabled;
  final StreamingModel? sensorStream;
  final BluetoothDevice? device;
  final ProgramsModel? program;

  // Trace and visual state - MOVED FROM UI
  final List<Offset> tracePoints;
  final List<ShotMarker> shotMarkers;
  final double lastDrawX;
  final double lastDrawY;
  final bool visGate;
  final DateTime? visGateTS;
  final bool isInPostShotMode;
  final int postShotStartIndex;

  // Sensor data processing - MOVED FROM UI
  final double thetaInstDeg;
  final double lastAngle;
  final List<Map<String, dynamic>> readings;

  // Steady hold detection - MOVED FROM UI
  final DateTime? holdStart;
  final DateTime? goalHoldStart;

  // Settings state
  final String selectedDistance;
  final String selectedAngleRange;

  // Adaptive scaling system - MOVED FROM UI
  final double scaleAbs;
  final double currentScale;
  final DateTime? lastScaleUpdate;
  final List<double> recentSway;

  // Traceline system - MOVED FROM UI
  final List<TracePoint> tracelineBuffer;
  final double lastTraceX;
  final double lastTraceY;
  final Offset? lastShotPosition;

  final bool lastShotDetectedUI;
  final bool hasNavigatedToSessionDetail;

  // Ring configuration - MOVED FROM UI
  final Map<int, double> ringRadii;
  final Map<int, Offset> ringLabels;
  final Map<int, double> scoreRadii;

  // Distance and angle presets - MOVED FROM UI
  final Map<String, Map<String, dynamic>> distancePresets;
  final Map<String, Map<String, dynamic>> angleRangePresets;

  // Timer state
  final Timer? sessionTimer;

  // Data storage
  final List<ShotTraceData> sessionShotTraces;
  final List<SteadinessShotData> steadinessShots;

  // Session saving state
  final String? saveError;
  final bool? isSavingSession;
  final bool? isSessionSaved;
  final String? sensorError;

  final List<int> missedShotNumbers; // NEW: Track which shots were missed

  // Add this field in TrainingSessionState class
  final bool isPaused; // NEW

  final Duration? pausedDuration; // NEW: Pause ke time ka total duration
  final DateTime? pauseStartTime; // NEW: Jab pause kiya tha

  const TrainingSessionState({
    // Core session state
    this.isTraining = false,
    this.isCalibrationMode = false, // NEW
    this.sessionStartTime,
    this.sessionTotalTime,
    this.sessionCompleted = false,
    this.waitingForLastShotTrace = false,
    this.shotCount = 0,
    this.missedShotCount = 0, // NEW: Default to 0
    this.shotLog = const [],

    // Sensor state
    this.isSensorsEnabled = false,
    this.sensorStream,
    this.device,
    this.program,

    // Trace and visual state
    this.tracePoints = const [],
    this.shotMarkers = const [],
    this.lastDrawX = 200.0,
    this.lastDrawY = 200.0,
    this.visGate = false,
    this.visGateTS,
    this.isInPostShotMode = false,
    this.postShotStartIndex = 0,

    // Sensor data processing
    this.thetaInstDeg = 0.0,
    this.lastAngle = 0.0,
    this.readings = const [],

    // Steady hold detection
    this.holdStart,
    this.goalHoldStart,

    // Settings state
    this.selectedDistance = '7',
    this.selectedAngleRange = 'default',

    // Adaptive scaling system
    this.scaleAbs = 0.0,
    this.currentScale = 1.0,
    this.lastScaleUpdate,
    this.recentSway = const [],

    // Traceline system
    this.tracelineBuffer = const [],
    this.lastTraceX = 200.0,
    this.lastTraceY = 200.0,
    this.lastShotPosition,

    // Post-shot tracking
    this.lastShotDetectedUI = false,
    this.hasNavigatedToSessionDetail = false,

    // Ring configuration
    this.ringRadii = const {},
    this.ringLabels = const {},
    this.scoreRadii = const {},

    // Distance and angle presets
    this.distancePresets = const {
      '7': {
        'name': 'Beginner-',
        'distance': 6.4008, // 7yd → meters
        'linearTolerance': 10.0,
        'description': '7 yd',
      },
      '10': {
        'name': 'Intermediate-',
        'distance': 9.144, // 10yd → meters
        'linearTolerance': 10.0,
        'description': '10 yd',
      },
      '15': {
        'name': 'Good-',
        'distance': 13.716, // 15yd → meters
        'linearTolerance': 10.0,
        'description': '15 yd',
      },
      '20': {
        'name': 'Advanced-',
        'distance': 18.288, // 15yd → meters
        'linearTolerance': 10.0,
        'description': '20 yd',
      },
      '25': {
        'name': 'Expert-',
        'distance': 22.86, // 25yd → meters
        'linearTolerance': 10.0,
        'description': '25 yd',
      },
    },

    this.angleRangePresets = const {
      'default': {
        'name': 'Default',
        'multiplier': 1.0,
        'description': 'Current sensitivity'
      },
      '10deg': {
        'name': '10 Degrees',
        'multiplier': 4.0,
        'description': 'Less sensitive'
      },
      '20deg': {
        'name': '20 Degrees',
        'multiplier': 8.0,
        'description': 'Low sensitivity'
      },
      '45deg': {
        'name': '45 Degrees',
        'multiplier': 18.0,
        'description': 'Much less sensitive'
      },
      '90deg': {
        'name': '90 Degrees',
        'multiplier': 36.0,
        'description': 'Least sensitive'
      },
      '100deg': {
        'name': '100 Degrees',
        'multiplier': 40.0,
        'description': 'Least sensitive'
      },
      '200deg': {
        'name': '200 Degrees',
        'multiplier': 80.0,
        'description': 'Least sensitive'
      },
      '300deg': {
        'name': '300 Degrees',
        'multiplier': 120.0,
        'description': 'Least sensitive'
      },
    },

    // Timer
    this.sessionTimer,

    // Data storage
    this.sessionShotTraces = const [],
    this.steadinessShots = const [],

    // Session saving state
    this.saveError,
    this.isSavingSession,
    this.isSessionSaved,

    this.sensorError,

    this.missedShotNumbers = const [], // NEW

    this.isPaused = false, // NEW: default false

    this.pausedDuration, // NEW
    this.pauseStartTime, // NEW
  });

  TrainingSessionState copyWith({
    // Core session state
    bool? isTraining,
    bool? isCalibrationMode, // NEW
    DateTime? sessionStartTime,
    Duration? sessionTotalTime,
    bool? sessionCompleted,
    bool? waitingForLastShotTrace,
    int? shotCount,
    int? missedShotCount, // NEW: Add to copyWith
    List<Map<String, dynamic>>? shotLog,

    // Sensor state
    bool? isSensorsEnabled,
    StreamingModel? sensorStream,
    BluetoothDevice? device,
    ProgramsModel? program,

    // Trace and visual state
    List<Offset>? tracePoints,
    List<ShotMarker>? shotMarkers,
    double? lastDrawX,
    double? lastDrawY,
    bool? visGate,
    DateTime? visGateTS,
    bool? isInPostShotMode,
    int? postShotStartIndex,

    // Sensor data processing
    double? thetaInstDeg,
    double? lastAngle,
    List<Map<String, dynamic>>? readings,

    // Steady hold detection
    DateTime? holdStart,
    DateTime? goalHoldStart,

    // Settings state
    String? selectedDistance,
    String? selectedAngleRange,

    // Adaptive scaling system
    double? scaleAbs,
    double? currentScale,
    DateTime? lastScaleUpdate,
    List<double>? recentSway,

    // Traceline system
    List<TracePoint>? tracelineBuffer,
    double? lastTraceX,
    double? lastTraceY,
    Offset? lastShotPosition,

    // Post-shot tracking
    bool? lastShotDetectedUI,
    bool? hasNavigatedToSessionDetail,

    // Ring configuration
    Map<int, double>? ringRadii,
    Map<int, Offset>? ringLabels,
    Map<int, double>? scoreRadii,

    // Distance and angle presets
    Map<String, Map<String, dynamic>>? distancePresets,
    Map<String, Map<String, dynamic>>? angleRangePresets,

    // Timer
    Timer? sessionTimer,

    // Data storage
    List<ShotTraceData>? sessionShotTraces,
    List<SteadinessShotData>? steadinessShots,

    // Save Session
    bool? isSavingSession,
    String? saveError,
    bool? isSessionSaved,
    String? sensorError,

    List<int>? missedShotNumbers, // NEW

    bool? isPaused, // NEW

    Duration? pausedDuration, // NEW
    DateTime? pauseStartTime, // NEW

  }) {
    return TrainingSessionState(
      // Core session state
      isTraining: isTraining ?? this.isTraining,
      isCalibrationMode: isCalibrationMode ?? this.isCalibrationMode, // NEW
      sessionStartTime: sessionStartTime ?? this.sessionStartTime,
      sessionTotalTime: sessionTotalTime ?? this.sessionTotalTime,
      sessionCompleted: sessionCompleted ?? this.sessionCompleted,
      waitingForLastShotTrace:
          waitingForLastShotTrace ?? this.waitingForLastShotTrace,
      shotCount: shotCount ?? this.shotCount,
      missedShotCount: missedShotCount ?? this.missedShotCount, // NEW
      shotLog: shotLog ?? this.shotLog,

      // Sensor state
      isSensorsEnabled: isSensorsEnabled ?? this.isSensorsEnabled,
      sensorStream: sensorStream ?? this.sensorStream,
      device: device ?? this.device,
      program: program ?? this.program,

      // Trace and visual state
      tracePoints: tracePoints ?? this.tracePoints,
      shotMarkers: shotMarkers ?? this.shotMarkers,
      lastDrawX: lastDrawX ?? this.lastDrawX,
      lastDrawY: lastDrawY ?? this.lastDrawY,
      visGate: visGate ?? this.visGate,
      visGateTS: visGateTS ?? this.visGateTS,
      isInPostShotMode: isInPostShotMode ?? this.isInPostShotMode,
      postShotStartIndex: postShotStartIndex ?? this.postShotStartIndex,

      // Sensor data processing
      thetaInstDeg: thetaInstDeg ?? this.thetaInstDeg,
      lastAngle: lastAngle ?? this.lastAngle,
      readings: readings ?? this.readings,

      // Steady hold detection
      holdStart: holdStart ?? this.holdStart,
      goalHoldStart: goalHoldStart ?? this.goalHoldStart,

      // Settings state
      selectedDistance: selectedDistance ?? this.selectedDistance,
      selectedAngleRange: selectedAngleRange ?? this.selectedAngleRange,

      // Adaptive scaling system
      scaleAbs: scaleAbs ?? this.scaleAbs,
      currentScale: currentScale ?? this.currentScale,
      lastScaleUpdate: lastScaleUpdate ?? this.lastScaleUpdate,
      recentSway: recentSway ?? this.recentSway,

      // Traceline system
      tracelineBuffer: tracelineBuffer ?? this.tracelineBuffer,
      lastTraceX: lastTraceX ?? this.lastTraceX,
      lastTraceY: lastTraceY ?? this.lastTraceY,
      lastShotPosition: lastShotPosition ?? this.lastShotPosition,

      // Post-shot tracking
      lastShotDetectedUI: lastShotDetectedUI ?? this.lastShotDetectedUI,
      hasNavigatedToSessionDetail:
          hasNavigatedToSessionDetail ?? this.hasNavigatedToSessionDetail,

      // Ring configuration
      ringRadii: ringRadii ?? this.ringRadii,
      ringLabels: ringLabels ?? this.ringLabels,
      scoreRadii: scoreRadii ?? this.scoreRadii,

      // Distance and angle presets
      distancePresets: distancePresets ?? this.distancePresets,
      angleRangePresets: angleRangePresets ?? this.angleRangePresets,

      // Timer
      sessionTimer: sessionTimer ?? this.sessionTimer,

      // Data storage
      sessionShotTraces: sessionShotTraces ?? this.sessionShotTraces,
      steadinessShots: steadinessShots ?? this.steadinessShots,

      // Session saving state
      isSavingSession: isSavingSession ?? this.isSavingSession,
      saveError: saveError ?? this.saveError,
      isSessionSaved: isSessionSaved ?? this.isSessionSaved,
      sensorError: sensorError,

      missedShotNumbers: missedShotNumbers ?? this.missedShotNumbers, // NEW

      isPaused: isPaused ?? this.isPaused, // NEW

      pausedDuration: pausedDuration ?? this.pausedDuration, // NEW
      pauseStartTime: pauseStartTime ?? this.pauseStartTime, // NEW
    );
  }

  // MODIFY: sessionDuration getter
  Duration? get sessionDuration {
    if (sessionStartTime == null) return null;

    // If paused, return frozen duration
    if (isPaused && pausedDuration != null) {
      return pausedDuration;
    }

    // If running, calculate from adjusted start time
    return DateTime.now().difference(sessionStartTime!);
  }

  ShotTraceData? getShotTrace(int shotNumber) {
    try {
      return sessionShotTraces
          .firstWhere((trace) => trace.shotNumber == shotNumber);
    } catch (e) {
      return null;
    }
  }

  SteadinessShotData? getSteadinessShot(int shotNumber) {
    try {
      return steadinessShots
          .firstWhere((shot) => shot.shotNumber == shotNumber);
    } catch (e) {
      return null;
    }
  }

  // Distance and angle helper methods - MOVED FROM UI
  Map<String, dynamic> get currentDistancePreset {
    return distancePresets[selectedDistance] ?? distancePresets['7']!;
  }

  Map<String, dynamic> get currentAngleRangePreset {
    return angleRangePresets[selectedAngleRange] ??
        angleRangePresets['default']!;
  }

  double get visualRing5Deg {
    const double gateValue = 2.5;
    final distance = currentDistancePreset['distance'] as double;
    final distanceAdjustment = (distance - 6.4008) * 0.05;
    final adjustedGateValue =
        gateValue * (1.0 - distanceAdjustment).clamp(0.64008, 1.0);
    final multiplier = currentAngleRangePreset['multiplier'] as double;
    return (adjustedGateValue * 3.14159 / 180) * multiplier;
  }

  double get hideOverDeg => visualRing5Deg * 1.05;
  double get showUnderDeg => visualRing5Deg * 0.95;

  @override
  List<Object?> get props => [
        // Core session state
        isTraining,
    isCalibrationMode, // NEW
        sessionStartTime,
        sessionTotalTime,
        sessionCompleted,
        waitingForLastShotTrace,
        shotCount,
        missedShotCount, // NEW: Add to props
        shotLog,

        // Sensor state
        isSensorsEnabled,
        sensorStream,
        device,
        program,

        // Trace and visual state
        tracePoints,
        shotMarkers,
        lastDrawX,
        lastDrawY,
        visGate,
        visGateTS,
        isInPostShotMode,
        postShotStartIndex,

        // Sensor data processing
        thetaInstDeg,
        lastAngle,
        readings,

        // Steady hold detection
        holdStart,
        goalHoldStart,

        // Settings state
        selectedDistance,
        selectedAngleRange,

        // Adaptive scaling system
        scaleAbs,
        currentScale,
        lastScaleUpdate,
        recentSway,

        // Traceline system
        tracelineBuffer,
        lastTraceX,
        lastTraceY,
        lastShotPosition,

        // Post-shot tracking
        lastShotDetectedUI,
        hasNavigatedToSessionDetail,

        // Ring configuration
        ringRadii,
        ringLabels,
        scoreRadii,

        // Distance and angle presets
        distancePresets,
        angleRangePresets,

        // Timer
        sessionTimer,

        // Data storage
        sessionShotTraces,
        steadinessShots,

        // Session saving state
        isSavingSession,
        saveError,
        isSessionSaved,

    sensorError,

    missedShotNumbers, // NEW

    isPaused, // NEW

    pausedDuration, // NEW
    pauseStartTime, // NEW
  ];
}

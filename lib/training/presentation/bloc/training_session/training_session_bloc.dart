// lib/features/training/presentation/bloc/training_session/training_session_bloc.dart - Shot Capture Fixed
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/prefs.dart';
import '../../../data/datasources/saved_sessions_datasource.dart';
import '../../../data/model/shot_trace_model.dart';
import '../../../data/model/steadiness_shot_data.dart';
import '../../../data/model/streaming_model.dart';
import '../../../data/models/saved_session_model.dart';
import '../../../data/repositories/ble_repository_impl.dart';
import '../../../data/repositories/saved_sessions_repository_impl.dart';
import '../../../domain/repositories/ble_repository.dart';
import '../../../domain/usecases/save_training_session.dart';
import 'training_session_event.dart';
import 'training_session_state.dart';
import '../../widgets/target_display.dart';

class TrainingSessionBloc
    extends Bloc<TrainingSessionEvent, TrainingSessionState> {
  final BleRepository bleRepository;
  StreamSubscription? _sensorStreamSubscription;
  StreamSubscription? _shotTracesSubscription;
  Timer? _sessionTimer;

  // Constants
  static const double TABLE_REST_DEG = 0.0015;
  static const double HOLD_STABLE_DEG = 0.10;
  static const int HOLD_TIME_MS = 250;
  static const int HYSTERESIS_DWELL_MS = 60;
  static const double ANG_SMOOTH_TAU = 0.12;
  static const double RAD_SMOOTH_TAU = 0.10;
// 🔧 UPDATED CONSTANTS - Shot Analysis Only
  static const int PRE_SHOT_BUFFER_LIMIT = 400; // Buffer maintains 400 packets
  static const int SHOT_ANALYSIS_LOOKBACK =
  62; // 1 second at ~60Hz for analysis
  static const int POST_SHOT_PACKETS = 0; // Fixed: was -23 (bug)
  static const int SHOT_LOOKBACK_POINTS =
  50; // Unchanged - shot point detection

  // Settings
  static const double EASING = 0.15;
  static const String DIFFICULTY = 'nov';
  static const double GATE_VALUE = 2.5;

  // Shot detection state
  static DateTime? shotDetectedTime;
  static bool wasShotDetected = false;

  // FIXED: Shot capture state management
  final Map<int, Timer> _activeShotCaptureTimers = {};

  // Add this at class level (around line 70, with other instance variables)
  // Add at class level (around line 70)
  FlutterTts? _flutterTts;
  bool _ttsInitialized = false;

  TrainingSessionBloc({required this.bleRepository})
      : super(const TrainingSessionState()) {
    // Core session events
    // ✅ Initialize TTS
    _initializeTts();
    on<StartTrainingSession>(_onStartTrainingSession);
    on<StopTrainingSession>(_onStopTrainingSession);
    on<EnableSensors>(_onEnableSensors);
    on<DisableSensors>(_onDisableSensors);

    // Sensor data processing events
    on<ProcessSensorData>(_onProcessSensorData);

    // Settings events
    on<UpdateDistancePreset>(_onUpdateDistancePreset);
    on<UpdateAngleRange>(_onUpdateAngleRange);

    // Shot handling events - FIXED implementations
    on<DetectShotEvent>(_onDetectShotEvent);
    on<ProcessShotAtPosition>(_onProcessShotAtPosition);
    on<IncrementMissedShot>(_onIncrementMissedShot);

    // Trace management events
    on<ResetTrace>(_onResetTrace);

    // Ring system events
    on<InitializeRingSystem>(_onInitializeRingSystem);
    on<RecomputeScoreRadii>(_onRecomputeScoreRadii);

    // Timer events
    on<StartSessionTimer>(_onStartSessionTimer);
    on<StopSessionTimer>(_onStopSessionTimer);
    on<UpdateSessionTimer>(_onUpdateSessionTimer);

    // FIXED: Complete shot capture implementations
    on<StartShotCapture>(_onStartShotCapture);
    on<ContinuePostShotCapture>(_onContinuePostShotCapture);
    on<CompleteShotCapture>(_onCompleteShotCapture);

    // Existing events
    on<AddSteadinessShot>(_onAddSteadinessShot);
    on<ShotTracesUpdated>(_onShotTracesUpdated);
    on<ClearLastSession>(_onClearLastSession);
    on<Recalibrate>(_onRecalibrate);
    on<SendCommand>(_onSendCommand);
    on<SaveSession>(_saveCurrentSession);

    // Initialize ring system on bloc creation
    add(const InitializeRingSystem());
    add(const RecomputeScoreRadii(DIFFICULTY));

    // FIXED: Save session on bloc creation

    // Navigation events
    on<NavigateToSessionDetail>(_onNavigateToSessionDetail);

    on<StartCalibrationSession>(_onStartCalibrationSession); // NEW
    on<StopCalibrationSession>(_onStopCalibrationSession); // NEW

    on<ClearPostShotDisplay>(_onClearPostShotDisplay);

    // Add this handler in constructor
    on<HandleSensorError>(_onHandleSensorError);

    on<PauseTrainingSession>(_onPauseTrainingSession); // NEW
    on<ResumeTrainingSession>(_onResumeTrainingSession); // NEW

    on<SendHapticCommand>(_onSendHapticCommand);

    on<ClearSessionCompletionFlag>(_onClearSessionCompletionFlag);
  }

  // ✅ Replace _initializeTts method
  Future<void> _initializeTts() async {
    try {
      _flutterTts = FlutterTts();
      await _flutterTts?.setLanguage("en-US");
      await _flutterTts?.setSpeechRate(0.5);
      await _flutterTts?.setVolume(1.0);
      await _flutterTts?.setPitch(1.0);
      _ttsInitialized = true;
      print('✅ TTS initialized successfully');
    } catch (e) {
      print('❌ TTS initialization failed: $e');
      _ttsInitialized = false;
    }
  }


  // Add this new handler method (around line 1070):
  void _onClearSessionCompletionFlag(
      ClearSessionCompletionFlag event, Emitter<TrainingSessionState> emit)
  {
    emit(state.copyWith(sessionJustCompleted: false));
  }

  void _onNavigateToSessionDetail(
      NavigateToSessionDetail event, Emitter<TrainingSessionState> emit) {
    emit(state.copyWith(hasNavigatedToSessionDetail: true));
  }

  void _onPauseTrainingSession(
      PauseTrainingSession event, Emitter<TrainingSessionState> emit)
  {
    // Calculate current duration before pausing
    final currentDuration = state.sessionStartTime != null
        ? DateTime.now().difference(state.sessionStartTime!)
        : Duration.zero;
    // ✅ Stop haptic when pausing
    if (state.device != null) {
      add(SendHapticCommand(intensity: 0, device: state.device!));
    }
    _lastHapticIntensity = 0;
    _lastHapticUpdate = null;

    emit(state.copyWith(
      isTraining: false,
      isPaused: true,
      pausedDuration: currentDuration,
      pauseStartTime: DateTime.now(),
    ));
    bleRepository.stopTrainingForSensorProcessor();
    add(const StopSessionTimer());
  }
// MODIFY: _onResumeTrainingSession
  void _onResumeTrainingSession(
      ResumeTrainingSession event, Emitter<TrainingSessionState> emit)
  {
    // Adjust start time to account for paused duration
    final adjustedStartTime = state.pausedDuration != null
        ? DateTime.now().subtract(state.pausedDuration!)
        : state.sessionStartTime ?? DateTime.now();

    emit(state.copyWith(
      isTraining: true,
      isPaused: false,
      sessionStartTime: adjustedStartTime, // NEW: Adjust start time
      pausedDuration: null, // NEW: Clear paused duration
      pauseStartTime: null, // NEW: Clear pause timestamp
    ));
    bleRepository.startTrainingForSensorProcessor();
    add(const StartSessionTimer());
  }



// ✅ Replace _onStartTrainingSession with async version
  Future<void> _onStartTrainingSession(
      StartTrainingSession event, Emitter<TrainingSessionState> emit) async
  {
    _cleanupShotCaptureTimers();

    print('🎯 Starting training session');

    // ✅ Wait for audio to play
    await _playAudioAlert(isStart: true);

    emit(state.copyWith(
        sensorError: null,
        isTraining: true,
        isCalibrationMode: false,
        sessionStartTime: DateTime.now(),
        sessionCompleted: false,
        shotCount: 0,
        missedShotCount: 0,
        shotLog: [],
        tracePoints: [],
        readings: [],
        visGate: false,
        holdStart: null,
        lastDrawX: 200.0,
        lastDrawY: 200.0,
        goalHoldStart: null,
        currentScale: state.scaleAbs,
        recentSway: [],
        lastTraceX: 200.0,
        lastTraceY: 200.0,
        shotMarkers: [],
        hasNavigatedToSessionDetail: false,
        lastShotPosition: null,
        tracelineBuffer: [],
        lastShotDetectedUI: false,
        waitingForLastShotTrace: false,
        isInPostShotMode: false,
        postShotStartIndex: 0,
        steadinessShots: [],
        sessionShotTraces: [],
        program: event.program
    ));
    bleRepository.startTrainingForSensorProcessor();
    add(const StartSessionTimer());
  }

// ✅ IMPROVED: Detect finish vs stop based on shot count
  Future<void> _onStopTrainingSession(
      StopTrainingSession event, Emitter<TrainingSessionState> emit) async
  {
    if (state.isCalibrationMode) return;

    _cleanupShotCaptureTimers();

    print('🛑 Stopping training session');

    // ✅ NEW: Check if it's a finish (has shots) or just stop
    final isFinish = state.shotCount > 0;
    await _playAudioAlert(isStart: false, isFinish: isFinish);

    if (state.device != null) {
      add(SendHapticCommand(intensity: 0, device: state.device!));
    }
    _lastHapticIntensity = 0;
    _lastHapticUpdate = null;

    emit(state.copyWith(
      sensorError: null,
      isTraining: false,
      isCalibrationMode: false,
      isPaused: false,
      pausedDuration: null,
      pauseStartTime: null,
      waitingForLastShotTrace: false,
      sessionStartTime: null,
      shotCount: 0,
      lastShotDetectedUI: false,
      isInPostShotMode: false,
      postShotStartIndex: 0,
    ));
    bleRepository.stopTrainingForSensorProcessor();
    add(const StopSessionTimer());
  }

  Future<void> _playBeep() async {
    try {
      final player = AudioPlayer();
      await player.setAsset('assets/audios/beep.mp3');
      player.play();

      // ⏱️ Stop after 300 ms no matter how long the file is
      await Future.delayed(const Duration(milliseconds: 500));
      await player.stop();
      await player.dispose();

    } catch (e) {
      print('❌ Beep error: $e');
    }
  }

// ✅ IMPROVED: Add isFinish parameter for different messages
  Future<void> _playAudioAlert({required bool isStart, bool isFinish = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final audioType = prefs.getString(audioAlertTypeKey);

      print('🔊 Audio Alert - Type: $audioType, IsStart: $isStart, IsFinish: $isFinish');

      if (audioType == null || audioType == 'Off') {
        print('🔇 Audio is OFF');
        return;
      }

      if (audioType == 'Beep') {
        print('🔔 Playing beep sound');
        await _playBeep();
      } else if (audioType == 'Voice') {
        if (!_ttsInitialized || _flutterTts == null) {
          print('⚠️ TTS not initialized, initializing now...');
          await _initializeTts();
        }

        // ✅ IMPROVED: Different messages for start/stop/finish
        final message = isStart
            ? 'Session started'
            : isFinish
            ? 'Session complete'
            : 'Session ended';
        print('🗣️ Speaking: $message');
        await _flutterTts?.speak(message);
      }
      print('✅ Audio played successfully');
    } catch (e) {
      print('❌ Audio alert error: $e');
    }
  }

// ✅ Update close() method (around line 1150)
  @override
  Future<void> close() {
    _sensorStreamSubscription?.cancel();
    _shotTracesSubscription?.cancel();
    _sessionTimer?.cancel();
    _cleanupShotCaptureTimers();
    _flutterTts?.stop();
    bleRepository.dispose();
    return super.close();
  }
  // NEW: Proper calibration session start - ensures training is configured for calibration
  void _onStartCalibrationSession(
      StartCalibrationSession event, Emitter<TrainingSessionState> emit)
  {
    _cleanupShotCaptureTimers();

    emit(state.copyWith(
      isTraining: true,
      isCalibrationMode: true, // IMPORTANT: Explicitly set to true
      sessionStartTime: DateTime.now(),
      sessionCompleted: false,
      shotCount: 0,
      missedShotCount: 0,
      shotLog: [],
      tracePoints: [],
      readings: [],
      visGate: false,
      holdStart: null,
      lastDrawX: 200.0,
      lastDrawY: 200.0,
      goalHoldStart: null,
      currentScale: state.scaleAbs,
      recentSway: [],
      lastTraceX: 200.0,
      lastTraceY: 200.0,
      shotMarkers: [],
      hasNavigatedToSessionDetail: false,
      lastShotPosition: null,
      tracelineBuffer: [],
      lastShotDetectedUI: false,
      waitingForLastShotTrace: false,
      isInPostShotMode: false,
      postShotStartIndex: 0,
      steadinessShots: [],
      sessionShotTraces: [],
    ));
    bleRepository.startTrainingForSensorProcessor();
    add(const StartSessionTimer());
  }

  // lib/features/training/presentation/bloc/training_session/training_session_bloc.dart
// Update _onStopCalibrationSession method

  void _onStopCalibrationSession(
      StopCalibrationSession event, Emitter<TrainingSessionState> emit)
  {
    if (!state.isCalibrationMode) return;

    _cleanupShotCaptureTimers();

    // ✅ Stop haptic immediately
    if (state.device != null) {
      add(SendHapticCommand(intensity: 0, device: state.device!));
    }
    _lastHapticIntensity = 0;
    _lastHapticUpdate = null;

    emit(state.copyWith(
      isTraining: false,
      isCalibrationMode: false,
      waitingForLastShotTrace: false,
      sessionStartTime: null,
      shotCount: 0,
      lastShotDetectedUI: false,
      isInPostShotMode: false,
      postShotStartIndex: 0,
    ));
    bleRepository.stopTrainingForSensorProcessor();
    add(const StopSessionTimer());
  }

  // Replace _onIncrementMissedShot method (around line 180)
  void _onIncrementMissedShot(
      IncrementMissedShot event, Emitter<TrainingSessionState> emit)
  {
    final newMissedCount = state.missedShotCount + 1;
    final updatedMissedShots = List<int>.from(state.missedShotNumbers)
      ..add(event.shotNumber);

    // ✅ NEW: Create complete shot log entry for missed shot
    final updatedShotLog = List<Map<String, dynamic>>.from(state.shotLog);
    updatedShotLog.insert(0, {
      'time': DateTime.now(),
      'theta': state.thetaInstDeg,
      'score': 0,
      'stability': 0,
    });

    // ✅ NEW: Create steadiness shot data for missed shot
    final missedShotData = SteadinessShotData(
      shotNumber: event.shotNumber,
      timestamp: DateTime.now(),
      position: Offset(state.lastDrawX, state.lastDrawY),
      score: 0,
      thetaDot: state.thetaInstDeg,
      accuracy: 0.0,
      tracelinePoints: [],
      metrics: {
        'distance': state.currentDistancePreset['distance'],
        'difficulty': DIFFICULTY,
        'gateValue': GATE_VALUE,
        'linearWobble': _calculateCurrentLinearWobble(state),
        'status': 'missed',
        'stability': 0,
        'preShotPackets': 0,
        'shotPackets': 0,
        'postShotPackets': 0,
        'totalTracelinePackets': 0,
      },
      analysisNotes: 'Missed shot - outside valid range or not visible',
    );

    final updatedSteadinessShots = List<SteadinessShotData>.from(state.steadinessShots);
    updatedSteadinessShots.add(missedShotData);

    emit(state.copyWith(
      missedShotCount: newMissedCount,
      missedShotNumbers: updatedMissedShots,
      shotLog: updatedShotLog,
      steadinessShots: updatedSteadinessShots,
    ));

    // Rest remains same...
    final targetShotCount = state.program?.drill!.plannedRounds!.toInt() ?? 5;
    final totalShots = state.shotCount + newMissedCount;

    if (totalShots >= targetShotCount) {
      bleRepository.resetShotCycleForSessionComplete();
      emit(state.copyWith(
        sessionCompleted: true,
        isTraining: false,
        waitingForLastShotTrace: false,
        sessionTotalTime: state.sessionStartTime?.difference(DateTime.now()),
      ));
      if (state.device != null) {
        //add(DisableSensors(device: state.device!));
      }
      add(const NavigateToSessionDetail());
    }
  }

  /// Calculate haptic intensity based on trace position
  int _calculateHapticIntensity(Offset position, TrainingSessionState state) {
    final distanceFromCenter = math.sqrt(
      math.pow(position.dx - 200, 2) + math.pow(position.dy - 200, 2),
    );

    // ✅ FIXED: Properly load custom settings from JSON
    final customSettingsJson = prefs?.getString(hapticCustomSettingsKey);
    Map<int, int> hapticMap = {
      10: 0, 9: 0, 8: 1, 7: 1, 6: 1, 5: 1, // Default values
    };

    if (customSettingsJson != null) {
      try {
        final decoded = jsonDecode(customSettingsJson) as Map<String, dynamic>;
        hapticMap = decoded.map((k, v) => MapEntry(int.parse(k), v as int));
      } catch (e) {
        print('❌ Error loading haptic settings: $e');
      }
    }

    // Determine ring based on distance
    for (int ring = 10; ring >= 5; ring--) {
      final ringRadius = state.ringRadii[ring] ?? double.infinity;
      if (distanceFromCenter <= ringRadius) {
        return hapticMap[ring] ?? 1;
      }
    }

    return 0; // Outside all rings
  }

// Add this variable at class level
  int _lastHapticIntensity = 0;
  DateTime? _lastHapticUpdate;

  // FIXED: _onProcessSensorData method - Proper trace clearing
  void _onProcessSensorData(
      ProcessSensorData event, Emitter<TrainingSessionState> emit)
  {
    if (!state.isTraining) return;

    // ✅ NEW: Don't process shots if session already completed
    if (state.sessionCompleted) return;

    final streamingModel = event.streamingModel;
    final now = DateTime.now();
    const dt = 0.016;

    final yaw = streamingModel.yaw;
    final pitch = streamingModel.pitch;
    final roll = streamingModel.roll;

    final w = math.sqrt(yaw * yaw + pitch * pitch + roll * roll);
    final dtheta = w * dt;
    final newThetaInstDeg = dtheta;

    // Update recent sway
    final updatedRecentSway = List<double>.from(state.recentSway);
    updatedRecentSway.add(newThetaInstDeg);
    final cutoffTime = now.millisecondsSinceEpoch - 4000;
    updatedRecentSway.removeWhere((r) => r < cutoffTime);

    // Calculate angle
    final yawRate = yaw;
    final pitchRate = pitch;
    final angleTarget = math.atan2(-pitchRate, yawRate);

    final easeSlider = EASING;
    final angAlpha = 1 -
        math.exp(-dt /
            math.max(0.01, ANG_SMOOTH_TAU * (1 + (0.5 - easeSlider) * 1.5)));
    final newLastAngle = _emaAngle(state.lastAngle, angleTarget, angAlpha);

    // Update readings
    final updatedReadings = List<Map<String, dynamic>>.from(state.readings);
    updatedReadings
        .add({'ts': now.millisecondsSinceEpoch, 'theta': newThetaInstDeg});
    final cutoff = now.millisecondsSinceEpoch - 500;
    updatedReadings.removeWhere((r) => r['ts'] < cutoff);

    // Calculate new position
    final newPosition =
    _calculateDistanceAwarePosition(newThetaInstDeg, newLastAngle, state);
    final radAlpha = 1 - math.exp(-dt / math.max(0.01, RAD_SMOOTH_TAU));
    final newLastDrawX =
        state.lastDrawX + (newPosition.dx - state.lastDrawX) * radAlpha;
    final newLastDrawY =
        state.lastDrawY + (newPosition.dy - state.lastDrawY) * radAlpha;

    // Calculate distance from center for visibility check
    final distanceFromCenter = math.sqrt(
        math.pow(newLastDrawX - 200, 2) + math.pow(newLastDrawY - 200, 2));
    final ring5Radius = state.ringRadii[5] ?? 190.0;
    final hideThreshold = ring5Radius * 1.05;
    final showThreshold = ring5Radius * 0.95;

    final tableRest = (newThetaInstDeg < TABLE_REST_DEG);
    final wasVisible = state.visGate;

    // Visibility logic
    bool newVisGate = state.visGate;
    DateTime? newVisGateTS = state.visGateTS;

    if (!state.visGate) {
      if (!tableRest && distanceFromCenter <= showThreshold) {
        if (state.visGateTS == null ||
            now.difference(state.visGateTS!).inMilliseconds >
                HYSTERESIS_DWELL_MS) {
          newVisGate = true;
        }
      } else {
        newVisGateTS = now;
      }
    }
    else {
      if (tableRest || distanceFromCenter >= hideThreshold) {
        if (state.visGateTS == null ||
            now.difference(state.visGateTS!).inMilliseconds >
                HYSTERESIS_DWELL_MS) {
          newVisGate = false;
        }
      } else {
        newVisGateTS = now;
      }
    }

    // lib/features/training/presentation/bloc/training_session/training_session_bloc.dart
// Replace the haptic logic in _onProcessSensorData (around line 250)

    /// ✅ UPDATED: Only send haptic when training AND visible
    if (state.isTraining && !state.isPaused && newVisGate) {
      final hapticEnabled = prefs?.getBool(hapticEnabledKey) ?? true;

      if (hapticEnabled) {
        final now = DateTime.now();
        final shouldUpdate = _lastHapticUpdate == null ||
            now.difference(_lastHapticUpdate!).inMilliseconds > 500;

        if (shouldUpdate) {
          final currentPosition = Offset(newLastDrawX, newLastDrawY);
          final newIntensity = _calculateHapticIntensity(currentPosition, state);

          if (newIntensity != _lastHapticIntensity && state.device != null) {
            _lastHapticIntensity = newIntensity;
            _lastHapticUpdate = now;

            add(SendHapticCommand(
              intensity: newIntensity,
              device: state.device!,
            ));
          }
        }
      }
    }
// ✅ ADDED: Stop haptic when not visible
    else if (!newVisGate && _lastHapticIntensity != 0 && state.device != null) {
      _lastHapticIntensity = 0;
      _lastHapticUpdate = null;
      add(SendHapticCommand(intensity: 0, device: state.device!));
    }
    // ✅ FIXED: Shot detection and trace clearing logic
    bool shouldClearTrace = false;

    if (streamingModel.shotDetected) {
      if (!wasShotDetected) {
        shotDetectedTime = now;
        wasShotDetected = true;
      }
    } else if (shotDetectedTime != null &&
        (now.millisecondsSinceEpoch -
            shotDetectedTime!.millisecondsSinceEpoch <=
            1000)) {
      // Still in post-shot window - don't clear
    } else {
      if (wasShotDetected) {
        wasShotDetected = false;
        shouldClearTrace = true;
      } else {
        shouldClearTrace = true;
      }
    }

    // ✅ FIXED: Handle trace clearing BEFORE processing new trace points
    if (shouldClearTrace) {
      if (!newVisGate) {
        // Clear everything and emit early - DO NOT continue processing
        emit(state.copyWith(
          tracePoints: [],
          readings: [],
          lastShotPosition: null,
          isInPostShotMode: false,
          postShotStartIndex: 0,
          tracelineBuffer: [],
          thetaInstDeg: newThetaInstDeg,
          lastAngle: newLastAngle,
          visGate: newVisGate,
          visGateTS: newVisGateTS,
          lastDrawX: newLastDrawX,
          lastDrawY: newLastDrawY,
          sensorStream: streamingModel,
          recentSway: updatedRecentSway,
          lastShotDetectedUI: streamingModel.shotDetected,
        ));
        bleRepository.recalibrate();
        return; // ✅ IMPORTANT: Exit early to prevent overwriting
      } else if (!wasVisible && newVisGate) {
        // Reset to center and emit early
        emit(state.copyWith(
          lastDrawX: 200.0,
          lastDrawY: 200.0,
          tracePoints: [const Offset(200.0, 200.0)],
          lastAngle: 0.0,
          lastTraceX: 200.0,
          lastTraceY: 200.0,
          isInPostShotMode: false,
          postShotStartIndex: 0,
          thetaInstDeg: newThetaInstDeg,
          readings: updatedReadings,
          visGate: newVisGate,
          visGateTS: newVisGateTS,
          sensorStream: streamingModel,
          recentSway: updatedRecentSway,
          lastShotDetectedUI: streamingModel.shotDetected,
        ));

        return; // ✅ IMPORTANT: Exit early
      }
    }

    // ✅ FIXED: Only process trace points if we didn't clear
    final preset = state.currentDistancePreset;
    final distance = preset['distance'] as double;
    final movementThreshold = 2.0 + (distance - 6.4008) * 0.1;
    final moveDistance = math.sqrt(
        math.pow(newLastDrawX - state.lastTraceX, 2) +
            math.pow(newLastDrawY - state.lastTraceY, 2));

    final newLastShotPosition = Offset(newLastDrawX, newLastDrawY);
    List<Offset> updatedTracePoints = List<Offset>.from(state.tracePoints);
    List<TracePoint> updatedTracelineBuffer =
    List<TracePoint>.from(state.tracelineBuffer);
    double newLastTraceX = state.lastTraceX;
    double newLastTraceY = state.lastTraceY;

    if (moveDistance >= movementThreshold) {
      updatedTracePoints.add(Offset(newLastDrawX, newLastDrawY));
      newLastTraceX = newLastDrawX;
      newLastTraceY = newLastDrawY;

      final tracePoint = TracePoint(
          Point3D(newLastDrawX, newLastDrawY, 0.0), TracePhase.preShot);
      updatedTracelineBuffer.add(tracePoint);

      if (updatedTracelineBuffer.length > PRE_SHOT_BUFFER_LIMIT) {
        updatedTracelineBuffer.removeAt(0);
      }
    }

    // Emit updated state (normal flow - no clearing happened)
    emit(state.copyWith(
      thetaInstDeg: newThetaInstDeg,
      lastAngle: newLastAngle,
      readings: updatedReadings,
      visGate: newVisGate,
      visGateTS: newVisGateTS,
      lastDrawX: newLastDrawX,
      lastDrawY: newLastDrawY,
      lastShotPosition: newLastShotPosition,
      tracePoints: updatedTracePoints,
      tracelineBuffer: updatedTracelineBuffer,
      lastTraceX: newLastTraceX,
      lastTraceY: newLastTraceY,
      sensorStream: streamingModel,
      recentSway: updatedRecentSway,
    ));

    // Handle shot detection
    final currentShotDetected = streamingModel.shotDetected;
    final shotEdgeUI = !state.lastShotDetectedUI && currentShotDetected;

    // Update _onProcessSensorData - change IncrementMissedShot call
    if (shotEdgeUI) {
      if (state.isCalibrationMode) {
        add(const DetectShotEvent());
      } else {
        if (!newVisGate || updatedTracelineBuffer.length <= 50) {
          final nextShotNumber =
              state.shotCount + state.missedShotCount + 1; // NEW
          add(IncrementMissedShot(
              shotNumber: nextShotNumber)); // NEW: Pass shot number
        } else {
          add(const DetectShotEvent());
        }
      }
    }

    emit(state.copyWith(lastShotDetectedUI: currentShotDetected));
  }

  // Settings event handlers
  void _onUpdateDistancePreset(
      UpdateDistancePreset event, Emitter<TrainingSessionState> emit)
  {
    final preset =
        state.distancePresets[event.distance] ?? state.distancePresets['7']!;
    final edgeDeg = preset['distance'] as double;
    final newScaleAbs = 190.0 / edgeDeg;

    emit(state.copyWith(
      selectedDistance: event.distance, // REMOVE: int.parse() - keep as String
      scaleAbs: newScaleAbs,
      currentScale: newScaleAbs,
      lastScaleUpdate: null,
      recentSway: [],
      goalHoldStart: null,
    ));

    add(const RecomputeScoreRadii(DIFFICULTY));
  }

  void _onUpdateAngleRange(
      UpdateAngleRange event, Emitter<TrainingSessionState> emit)
  {
    emit(state.copyWith(selectedAngleRange: event.angleRange));
  }

  void _onDetectShotEvent(
      DetectShotEvent event, Emitter<TrainingSessionState> emit)
  {
    final now = DateTime.now();
    Offset shotPosition;
    int actualLookback = 0;

    // Calculate shot position from buffer (existing logic)
    if (state.tracelineBuffer.length >= SHOT_ANALYSIS_LOOKBACK) {
      final lookbackIndex =
          state.tracelineBuffer.length - SHOT_ANALYSIS_LOOKBACK;
      final lookbackPoint = state.tracelineBuffer[lookbackIndex];
      shotPosition = Offset(lookbackPoint.point.x, lookbackPoint.point.y);
      actualLookback = SHOT_ANALYSIS_LOOKBACK;
    } else if (state.tracelineBuffer.isNotEmpty) {
      final earliestPoint = state.tracelineBuffer.first;
      shotPosition = Offset(earliestPoint.point.x, earliestPoint.point.y);
      actualLookback = state.tracelineBuffer.length;
    } else {
      shotPosition = Offset(state.lastDrawX, state.lastDrawY);
    }

    if (shotPosition.dx.isNaN || shotPosition.dy.isNaN) {
      shotPosition = const Offset(200.0, 200.0);
    }

    // ✅ NEW: Validate shot position is within ring 5 radius
    final distanceFromCenter = math.sqrt(math.pow(shotPosition.dx - 200, 2) +
        math.pow(shotPosition.dy - 200, 2));
    final ring5Radius = state.ringRadii[5] ?? 190.0;

    // ✅ If shot outside valid range, count as missed
    if (distanceFromCenter > ring5Radius) {
      final nextShotNumber = state.shotCount + state.missedShotCount + 1;
      add(IncrementMissedShot(shotNumber: nextShotNumber));
      return; // ✅ Don't process shot
    }

    // ✅ Valid shot - process normally
    emit(state.copyWith(
      isInPostShotMode: true,
      postShotStartIndex:
      math.max(0, state.tracePoints.length - actualLookback),
    ));

    add(ProcessShotAtPosition(
        shotPosition: shotPosition,
        timestamp: now,
        lookbackPoints: actualLookback));
  }

  // File: training_session_bloc.dart (around line 680)

  void _onProcessShotAtPosition(
      ProcessShotAtPosition event, Emitter<TrainingSessionState> emit)
  {
    final distanceFromCenter = math.sqrt(
        math.pow(event.shotPosition.dx - 200, 2) +
            math.pow(event.shotPosition.dy - 200, 2)
    );
    final maxRadius = 190.0;
    final accuracy = (distanceFromCenter / maxRadius).clamp(0.0, 1.0);

    final score = _calculateScoreAtPosition(event.shotPosition, state);
    final thetaDot = _calculateThetaDotAtPosition(event.shotPosition, state);

    final shotMarker = ShotMarker(
      position: event.shotPosition,
      timestamp: event.timestamp,
      accuracy: accuracy,
    );

    final updatedShotMarkers = List<ShotMarker>.from(state.shotMarkers);
    updatedShotMarkers.add(shotMarker);
    if (updatedShotMarkers.length > 20) {
      updatedShotMarkers.removeAt(0);
    }

    // ✅ Calculate stability here as well
    final double ring10Radius = state.ringRadii[10] ?? 0.0;
    final double ring5Radius = state.ringRadii[5] ?? 190.0;

    int stabilityPercent;
    if (distanceFromCenter <= ring10Radius) {
      stabilityPercent = 100;
    } else if (distanceFromCenter > ring5Radius) {
      stabilityPercent = 0;
    } else {
      final double ratio = (distanceFromCenter - ring10Radius) / (ring5Radius - ring10Radius);
      stabilityPercent = (100 - ratio * 100).clamp(0, 100).round();
    }

    final updatedShotLog = List<Map<String, dynamic>>.from(state.shotLog);
    updatedShotLog.insert(0, {
      'time': event.timestamp,
      'theta': thetaDot,
      'score': score,
      'stability': stabilityPercent,
    });

    final newShotCount = state.shotCount + 1;
    final actualShotNumber = newShotCount + state.missedShotCount;

    emit(state.copyWith(
      shotMarkers: updatedShotMarkers,
      shotLog: updatedShotLog,
      shotCount: newShotCount,
    ));

    add(StartShotCapture(
      shotPosition: event.shotPosition,
      lookbackPoints: event.lookbackPoints,
      shotNumber: actualShotNumber,
    ));

    HapticFeedback.mediumImpact();

    final totalShots = newShotCount + state.missedShotCount;
    if (totalShots >= (state.program?.drill!.plannedRounds!.toInt() ?? 5)) {
      emit(state.copyWith(waitingForLastShotTrace: true));
    }
  }

// 2. Update _onStartShotCapture
  void _onStartShotCapture(
      StartShotCapture event, Emitter<TrainingSessionState> emit)
  {
    final shotNumber = event.shotNumber; // NEW: Use passed shot number
    final currentBuffer = List<TracePoint>.from(state.tracelineBuffer);

    final updatedBuffer = <TracePoint>[];
    final shotIndex = math.max(0, currentBuffer.length - event.lookbackPoints);

    const postShotLimit = 30;

    for (int i = 0; i < currentBuffer.length; i++) {
      TracePhase phase;
      if (i < shotIndex) {
        phase = TracePhase.preShot;
      } else if (i == shotIndex) {
        phase = TracePhase.shot;
      } else {
        phase = TracePhase.postShot;
        if (i > shotIndex + postShotLimit) {
          continue;
        }
      }

      updatedBuffer.add(TracePoint(
        currentBuffer[i].point,
        phase,
      ));
    }

    _storeImmediateShotData(
        event.shotPosition,
        _calculateScoreAtPosition(event.shotPosition, state),
        _calculateThetaDotAtPosition(event.shotPosition, state),
        (math.sqrt(math.pow(event.shotPosition.dx - 200, 2) +
            math.pow(event.shotPosition.dy - 200, 2)) /
            190.0)
            .clamp(0.0, 1.0),
        DateTime.now(),
        shotNumber,
        updatedBuffer);

    add(ContinuePostShotCapture(
        shotTracelineBuffer: updatedBuffer,
        shotPosition: event.shotPosition,
        existingPostShotPoints: 0,
        shotNumber: shotNumber)); // NEW: Pass shot number
  }

// 3. Update _onContinuePostShotCapture
  void _onContinuePostShotCapture(
      ContinuePostShotCapture event, Emitter<TrainingSessionState> emit)
  {
    final shotNumber = event.shotNumber; // NEW: Use passed shot number
    final completeBuffer = List<TracePoint>.from(event.shotTracelineBuffer);
    int newExistingPostShotPoints = event.existingPostShotPoints;

    if (newExistingPostShotPoints >= POST_SHOT_PACKETS) {
      print(
          '🎯 Post-shot capture for shot $shotNumber complete. Final count: $newExistingPostShotPoints');
      add(CompleteShotCapture(
          completeBuffer, shotNumber)); // NEW: Pass shot number
      return;
    }

    _activeShotCaptureTimers[shotNumber]?.cancel();

    final currentPosition = Offset(state.lastDrawX, state.lastDrawY);
    final postShotPoint = TracePoint(
        Point3D(currentPosition.dx, currentPosition.dy, 0.0),
        TracePhase.postShot);

    completeBuffer.add(postShotPoint);
    newExistingPostShotPoints++;

    _activeShotCaptureTimers[shotNumber] =
        Timer(const Duration(milliseconds: 16), () {
          if (state.isTraining) {
            add(ContinuePostShotCapture(
              shotTracelineBuffer: completeBuffer,
              shotPosition: event.shotPosition,
              existingPostShotPoints: newExistingPostShotPoints,
              shotNumber: shotNumber, // NEW: Pass shot number
            ));
          }
        });
  }

// 4. Update _onCompleteShotCapture
  // File: training_session_bloc.dart (around line 770)

  void _onCompleteShotCapture(
      CompleteShotCapture event, Emitter<TrainingSessionState> emit)
  {
    final shotNumber = event.shotNumber;
    print('🎯 Completing shot capture for shot $shotNumber');

    final completeTraceline = event.completeTraceline;

    // ✅ FIXED: Extract actual shot point position from traceline
    final shotPoint = completeTraceline.firstWhere(
          (tp) => tp.phase == TracePhase.shot,
      orElse: () => completeTraceline.isNotEmpty
          ? completeTraceline.first
          : TracePoint(Point3D(200, 200, 0), TracePhase.shot),
    );

    final shotPosition = Offset(shotPoint.point.x, shotPoint.point.y);
    final now = DateTime.now();

    final distanceFromCenter = math.sqrt(
        math.pow(shotPosition.dx - 200, 2) + math.pow(shotPosition.dy - 200, 2)
    );
    final maxRadius = 190.0;
    final accuracy = (distanceFromCenter / maxRadius).clamp(0.0, 1.0);

    // ✅ Calculate score using extracted shot position
    final score = _calculateScoreAtPosition(shotPosition, state);
    final thetaDot = _calculateThetaDotAtPosition(shotPosition, state);

    final preShotCount = completeTraceline.where((p) => p.phase == TracePhase.preShot).length;
    final shotCount = completeTraceline.where((p) => p.phase == TracePhase.shot).length;
    final postShotCount = completeTraceline.where((p) => p.phase == TracePhase.postShot).length;

    print('_onCompleteShotCapture 🎯 Shot $shotNumber complete: Pre=$preShotCount, Shot=$shotCount, Post=$postShotCount, Total=${completeTraceline.length}');

    // ✅ Calculate stability using shot position
    final double ring10Radius = state.ringRadii[10] ?? 0.0;
    final double ring5Radius = state.ringRadii[5] ?? 190.0;

    int stabilityPercent;
    if (distanceFromCenter <= ring10Radius) {
      stabilityPercent = 100;
    } else if (distanceFromCenter > ring5Radius) {
      stabilityPercent = 0;
    } else {
      final double ratio = (distanceFromCenter - ring10Radius) / (ring5Radius - ring10Radius);
      stabilityPercent = (100 - ratio * 100).clamp(0, 100).round();
    }

    final steadinessShotData = SteadinessShotData(
      shotNumber: shotNumber,
      timestamp: now,
      position: shotPosition,
      score: score,
      thetaDot: thetaDot,
      accuracy: accuracy,
      tracelinePoints: completeTraceline,
      metrics: {
        'distance': state.currentDistancePreset['distance'],
        'difficulty': DIFFICULTY,
        'gateValue': GATE_VALUE,
        'linearWobble': _calculateCurrentLinearWobble(state),
        'status': 'complete',
        'preShotPackets': preShotCount,
        'shotPackets': shotCount,
        'postShotPackets': postShotCount,
        'totalTracelinePackets': completeTraceline.length,
        'stability': stabilityPercent,  // ✅ Use calculated stability
      },
      analysisNotes: 'Complete traceline: $preShotCount pre-shot + $shotCount shot + $postShotCount post-shot packets',
    );

    add(AddSteadinessShot(steadinessShotData));

    Timer(const Duration(milliseconds: 5), () {
      add(const ClearPostShotDisplay());
    });

    // ✅ ADD THIS: Check completion AFTER data saved
    final targetShotCount = state.program?.drill!.plannedRounds!.toInt() ?? 5;
    final totalShots = state.shotCount + state.missedShotCount;

    if (totalShots >= targetShotCount) {
      _completeSessionImmediately(emit);
    }
  }

  // ✅ NEW: Helper method to immediately complete session
  void _completeSessionImmediately(Emitter<TrainingSessionState> emit) {
    bleRepository.resetShotCycleForSessionComplete();

    if (state.device != null) {
      bleRepository.sendHapticCommand(0, state.device!);
      _lastHapticIntensity = 0;
      _lastHapticUpdate = null;
    }

    emit(state.copyWith(
      sessionCompleted: true,
      isTraining: false,
      sessionJustCompleted: true,
      waitingForLastShotTrace: false,
      sessionTotalTime: state.sessionStartTime != null
          ? DateTime.now().difference(state.sessionStartTime!)
          : null,
    ));

    add(const NavigateToSessionDetail());
  }
  // Handler update (line ~640)
  void _onClearPostShotDisplay(
      ClearPostShotDisplay event, Emitter<TrainingSessionState> emit)
  {
    emit(state.copyWith(
      isInPostShotMode: false,
      postShotStartIndex: 0,
      tracePoints: [const Offset(200.0, 200.0)], // ✅ Center point se start
      tracelineBuffer: [],
      lastDrawX: 200.0,
      lastDrawY: 200.0,
      lastTraceX: 200.0,
      lastTraceY: 200.0,
    ));
  }

  // Trace management
  void _onResetTrace(ResetTrace event, Emitter<TrainingSessionState> emit) {
    _cleanupShotCaptureTimers();

    emit(state.copyWith(
      shotLog: [],
      shotCount: 0,
      missedShotCount: 0, // NEW: Reset missed shots
      tracePoints: [],
      readings: [],
      lastDrawX: 200.0,
      lastDrawY: 200.0,
      visGate: false,
      holdStart: null,
      goalHoldStart: null,
      currentScale: state.scaleAbs,
      recentSway: [],
      shotMarkers: [],
      lastShotPosition: null,
      tracelineBuffer: [],
      lastTraceX: 200.0,
      lastTraceY: 200.0,
    ));

    add(const RecomputeScoreRadii(DIFFICULTY));
  }

  // Ring system
  void _onInitializeRingSystem(
      InitializeRingSystem event, Emitter<TrainingSessionState> emit)
  {
    const double ring5Radius = 190.0;
    const double bandWidth = ring5Radius / 5.5;
    const double r10 = bandWidth / 2;

    final ringRadii = <int, double>{
      10: r10,
      9: r10 + 1 * bandWidth,
      8: r10 + 2 * bandWidth,
      7: r10 + 3 * bandWidth,
      6: r10 + 4 * bandWidth,
      5: r10 + 5 * bandWidth,
    };

    const center = Offset(200, 200);
    const labelInset = 12.0;

    final ringLabels = <int, Offset>{};
    for (int i = 10; i >= 5; i--) {
      ringLabels[i] = Offset(
        center.dx,
        center.dy - math.max(0, ringRadii[i]! - labelInset),
      );
    }

    emit(state.copyWith(
      ringRadii: ringRadii,
      ringLabels: ringLabels,
    ));
  }

  void _onRecomputeScoreRadii(
      RecomputeScoreRadii event, Emitter<TrainingSessionState> emit)
  {
    if (state.ringRadii.isEmpty) return;

    final base = [
      state.ringRadii[10]!,
      state.ringRadii[9]!,
      state.ringRadii[8]!,
      state.ringRadii[7]!,
      state.ringRadii[6]!,
      state.ringRadii[5]!
    ];

    final scores = [10, 9, 8, 7, 6, 5];
    final step = event.difficulty == 'pro'
        ? 0.0
        : event.difficulty == 'adv'
        ? 0.5
        : event.difficulty == 'int'
        ? 1.0
        : event.difficulty == 'nov'
        ? 2.0
        : 3.0;

    final scoreRadii = <int, double>{};
    for (int i = 0; i < scores.length; i++) {
      double pos = i + step;
      if (pos >= base.length - 1) {
        scoreRadii[scores[i]] = base[base.length - 1];
        continue;
      }
      final lo = pos.floor();
      final hi = pos.ceil();
      final t = pos - lo;
      final r = base[lo] + (base[hi] - base[lo]) * t;
      scoreRadii[scores[i]] = math.min(r, base[base.length - 1]);
    }

    emit(state.copyWith(scoreRadii: scoreRadii));
  }

  // Timer management
  void _onStartSessionTimer(
      StartSessionTimer event, Emitter<TrainingSessionState> emit) {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.isTraining) {
        add(const UpdateSessionTimer());
      } else {
        add(const StopSessionTimer());
      }
    });
  }

  void _onStopSessionTimer(
      StopSessionTimer event, Emitter<TrainingSessionState> emit)
  {
    _sessionTimer?.cancel();
    _sessionTimer = null;
  }

  void _onUpdateSessionTimer(
      UpdateSessionTimer event, Emitter<TrainingSessionState> emit)
  {
    // Timer update handled through state.sessionDuration getter
  }

  // Helper methods
  double _emaAngle(double prev, double next, double alpha) {
    const twoPi = math.pi * 2;
    double d = next - prev;
    if (d > math.pi)
      next -= twoPi;
    else if (d < -math.pi) next += twoPi;
    return prev + alpha * (next - prev);
  }

  Offset _calculateDistanceAwarePosition(
      double thetaInstDeg, double angle, TrainingSessionState state)
  {
    final preset = state.currentDistancePreset;
    final distance = preset['distance'] as double;

    final normalizedTheta =
    (thetaInstDeg / state.visualRing5Deg).clamp(0.0, 1.0);
    final baseRadius = normalizedTheta * (state.ringRadii[5] ?? 190.0);

    final distanceMultiplier = math.pow(distance / 6.4008, 1.4);
    final scaledRadius = baseRadius * math.max(distanceMultiplier, 1.1);

    final newX = 200 + scaledRadius * math.cos(angle);
    final newY = 200 + scaledRadius * math.sin(angle);

    return Offset(newX, newY);
  }

  int _calculateScoreAtPosition(Offset position, TrainingSessionState state) {
    // ✅ Calculate distance from exact center (200, 200)
    final distanceFromCenter = math.sqrt(
        math.pow(position.dx - 200, 2) + math.pow(position.dy - 200, 2)
    );

    // ✅ Check rings from innermost (10) to outermost (5)
    // Center se bahar ki taraf
    if (distanceFromCenter <= (state.ringRadii[10] ?? 0)) return 10;
    if (distanceFromCenter <= (state.ringRadii[9] ?? 0)) return 9;
    if (distanceFromCenter <= (state.ringRadii[8] ?? 0)) return 8;
    if (distanceFromCenter <= (state.ringRadii[7] ?? 0)) return 7;
    if (distanceFromCenter <= (state.ringRadii[6] ?? 0)) return 6;
    if (distanceFromCenter <= (state.ringRadii[5] ?? 0)) return 5;

    return 0; // ✅ Outside ring 5 = 0 score
  }

  double _calculateThetaDotAtPosition(
      Offset position, TrainingSessionState state)
  {
    final rPx = math
        .sqrt(math.pow(position.dx - 200, 2) + math.pow(position.dy - 200, 2));
    final f = (rPx / (state.ringRadii[5] ?? 190.0)).clamp(0.0, 1.0);
    return f * state.visualRing5Deg;
  }

  void _handleTraceClearing(
      bool wasVisible, bool newVisGate, Emitter<TrainingSessionState> emit)
  {
    if (!newVisGate) {
      emit(state.copyWith(
        tracePoints: [],
        readings: [],
        lastShotPosition: null,
        isInPostShotMode: false,
        postShotStartIndex: 0,
        tracelineBuffer: [],
      ));
    } else {
      if (!wasVisible && newVisGate) {
        emit(state.copyWith(
          lastDrawX: 200.0,
          lastDrawY: 200.0,
          tracePoints: [const Offset(200.0, 200.0)],
          lastAngle: 0.0,
          lastTraceX: 200.0,
          lastTraceY: 200.0,
          isInPostShotMode: false,
          postShotStartIndex: 0,
        ));
      }
    }
  }

  // FIXED: Store immediate shot data with complete traceline
  void _storeImmediateShotData(
      Offset shotPosition,
      int score,
      double thetaDot,
      double accuracy,
      DateTime timestamp,
      int shotNumber,
      List<TracePoint> tracelinePoints)
  {
    final steadinessShotData = SteadinessShotData(
      shotNumber: shotNumber,
      timestamp: timestamp,
      position: shotPosition,
      score: score,
      thetaDot: thetaDot,
      accuracy: accuracy,
      tracelinePoints: tracelinePoints,
      metrics: {
        'distance': state.currentDistancePreset['distance'],
        'difficulty': DIFFICULTY,
        'gateValue': GATE_VALUE,
        'linearWobble': _calculateCurrentLinearWobble(state),
        'status': 'capturing',
        'preShotPackets':
        tracelinePoints.where((p) => p.phase == TracePhase.preShot).length,
        'shotPackets':
        tracelinePoints.where((p) => p.phase == TracePhase.shot).length,
        'postShotPackets':
        tracelinePoints.where((p) => p.phase == TracePhase.postShot).length,
        'totalTracelinePackets': tracelinePoints.length,
      },
      analysisNotes: 'Shot detected - capturing complete traceline...',
    );

    add(AddSteadinessShot(steadinessShotData));
  }

  double _calculateCurrentLinearWobble(TrainingSessionState state) {
    final preset = state.currentDistancePreset;
    final distance = preset['distance'] as double;
    return distance * state.thetaInstDeg * (math.pi / 180);
  }

  void _cleanupShotCaptureTimers() {
    for (final timer in _activeShotCaptureTimers.values) {
      timer.cancel();
    }
    _activeShotCaptureTimers.clear();
  }

  // Add this method
  Future<void> _onHandleSensorError(
      HandleSensorError event, Emitter<TrainingSessionState> emit) async {
    // Stop training and disable sensors
    emit(state.copyWith(
      isTraining: false,
      isSensorsEnabled: false,
      sensorError: event.error,
    ));

    // Disconnect device if connected
    if (state.device != null) {
      try {
        await bleRepository.disconnectFromDevice(state.device!);
      } catch (e) {
        print('❌ Error disconnecting: $e');
      }
    }
  }

  Future<void> _onEnableSensors(
      EnableSensors event, Emitter<TrainingSessionState> emit) async
  {
    print('🔄 Enabling sensors...');

    emit(state.copyWith(
      sensorError: null,
      device: event.device,
      sessionShotTraces: [],
    ));

    if (bleRepository is BleRepositoryImpl) {
      final repo = bleRepository as BleRepositoryImpl;
      _shotTracesSubscription?.cancel();
      _shotTracesSubscription = repo.shotTracesStream.listen((shotTraces) {
        add(ShotTracesUpdated(shotTraces));
      });
    }

    try {
      await bleRepository.enableBleSensorsOnly(event.device);
      final stream = bleRepository.enableSensors(event.device);

      print('✅ Stream received, listening for data...');

      // ✅ NEW: Timeout for initial data reception
      bool receivedFirstData = false;
      final dataTimeout = Timer(const Duration(seconds: 5), () {
        if (!receivedFirstData && state.isSensorsEnabled) {
          emit(state.copyWith(
            isSensorsEnabled: false,
            sensorError:
            'Sensor timeout: No data received. Please reconnect and try again.',
            isTraining: false,
          ));
        }
      });

      await emit.forEach<StreamingModel>(stream, onData: (streamingModel) {
        if (!receivedFirstData) {
          receivedFirstData = true;
          dataTimeout.cancel();
          // ✅ Only set enabled after first data received
          return state.copyWith(isSensorsEnabled: true);
        }
        add(ProcessSensorData(streamingModel));
        return state;
      },
          // Also update the onError in emit.forEach:
          onError: (error, stackTrace) {
            dataTimeout.cancel();
            print('❌ Stream error: $error');
            final errorMessage = _getUserFriendlyError(error.toString());

            // ✅ NEW: Trigger error handling
            add(HandleSensorError(errorMessage));

            return state.copyWith(
              isSensorsEnabled: false,
              sensorError: errorMessage,
              isTraining: false,
            );
          });
    } // In _onEnableSensors method, replace the catch block:
    catch (e) {
      print('❌ Enable sensors failed: $e');
      final errorMessage = _getUserFriendlyError(e.toString());

      emit(state.copyWith(
        isSensorsEnabled: false,
        sensorError: errorMessage,
      ));

      // ✅ NEW: Trigger error handling
      add(HandleSensorError(errorMessage));
    }
  }

  // ✅ NEW: Convert technical errors to user-friendly messages
  String _getUserFriendlyError(String technicalError) {
    if (technicalError.contains('timeout')) {
      return 'Sensor not responding. Please:\n1. Turn sensor off and on\n2. Reconnect\n3. Try again';
    } else if (technicalError.contains('Null check')) {
      return 'Sensor connection unstable. Please reconnect device.';
    } else if (technicalError.contains('stream')) {
      return 'Data stream error. Please reconnect sensor.';
    } else {
      return 'Sensor error: Please reconnect and try again.';
    }
  }

  Future<void> _onDisableSensors(
      DisableSensors event, Emitter<TrainingSessionState> emit) async
  {
    // ✅ Stop haptic before disabling sensors
    try {
      await bleRepository.sendHapticCommand(0, event.device);
      _lastHapticIntensity = 0;
      _lastHapticUpdate = null;
    } catch (e) {
      print('⚠ Error stopping haptic: $e');
    }

    await bleRepository.disableSensors(event.device);
    await _sensorStreamSubscription?.cancel();
    await _shotTracesSubscription?.cancel();
    _sensorStreamSubscription = null;
    _shotTracesSubscription = null;
    _cleanupShotCaptureTimers();

    emit(state.copyWith(
      isSensorsEnabled: false,
      sensorStream: null,
      waitingForLastShotTrace: false,
    ));
  }

  Future<void> _onAddSteadinessShot(
      AddSteadinessShot event, Emitter<TrainingSessionState> emit) async
  {
    final updatedShots = List<SteadinessShotData>.from(state.steadinessShots);
    final existingIndex = updatedShots
        .indexWhere((shot) => shot.shotNumber == event.shotData.shotNumber);

    if (existingIndex != -1) {
      updatedShots[existingIndex] = event.shotData;
    } else {
      updatedShots.add(event.shotData);
    }

    emit(state.copyWith(steadinessShots: updatedShots));
  }

  Future<void> _onShotTracesUpdated(
      ShotTracesUpdated event, Emitter<TrainingSessionState> emit) async
  {
    emit(state.copyWith(sessionShotTraces: event.shotTraces));
    _checkSessionCompletion(emit, event.shotTraces);
  }

  void _checkSessionCompletion(
      Emitter<TrainingSessionState> emit, List<ShotTraceData> shotTraces)
  {
    if (!state.waitingForLastShotTrace) return;

    final targetShotCount = state.program?.drill!.plannedRounds!.toInt() ?? 5;
    final totalShots = state.shotCount + state.missedShotCount;
    bool hasCompletedSession = totalShots >= targetShotCount;

    if (hasCompletedSession) {
      bleRepository.resetShotCycleForSessionComplete();

      // ✅ Stop haptic on session complete
      if (state.device != null) {
        bleRepository.sendHapticCommand(0, state.device!);
        _lastHapticIntensity = 0;
        _lastHapticUpdate = null;
      }

      emit(state.copyWith(
        sessionCompleted: true,
        isTraining: false,
        sessionJustCompleted: true, // NEW
        waitingForLastShotTrace: false,
        sessionTotalTime: state.sessionStartTime?.difference(DateTime.now()),
      ));

      if (state.device != null) {
        //add(DisableSensors(device: state.device!));
      }
      add(const NavigateToSessionDetail());
    }
  }

  void _onClearLastSession(
      ClearLastSession event, Emitter<TrainingSessionState> emit)
  {
    _cleanupShotCaptureTimers();
    emit( TrainingSessionState(
        shotCount: 0,
        steadinessShots: [],
        sessionShotTraces: [],
        sessionStartTime: null,
        isTraining: false,
        waitingForLastShotTrace: false,
        sessionTotalTime: null,
        isSensorsEnabled: true,
        sensorStream: null,
        shotLog: [],
        tracePoints: [],
        readings: [],
        visGate: false,
        holdStart: null,
        goalHoldStart: null,
        currentScale: 1.0,
        recentSway: [],
        lastTraceX: 200.0,
        lastTraceY: 200.0,
        shotMarkers: [],
        hasNavigatedToSessionDetail: false,
        lastShotPosition: null,
        tracelineBuffer: [],
        lastShotDetectedUI: false,
        isInPostShotMode: false,
        postShotStartIndex: 0,
        device: event.device
    ));
  }

  void _onRecalibrate(Recalibrate event, Emitter<TrainingSessionState> emit) {
    bleRepository.recalibrate();
    emit(state.copyWith(sessionShotTraces: []));
  }

  Future<void> _saveCurrentSession(
      SaveSession event, Emitter<TrainingSessionState> emit) async
  {
    if ((state.sessionShotTraces.isEmpty && state.steadinessShots.isEmpty) ||
        state.sessionStartTime == null) {
      emit(state.copyWith(saveError: 'No data to save'));
      return;
    }

    emit(state.copyWith(isSavingSession: true, isSessionSaved: false));

    final repo = SavedSessionsRepositoryImpl(SavedSessionsDataSourceImpl());
    final usecase = SaveTrainingSession(repo);
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    final session = SavedSessionModel(
      id: '',
      userId: uid,
      programName: state.program?.programName ?? 'Training Session',
      startedAt: state.sessionStartTime!,
      totalShots: state.shotCount,
      distancePresetKey: int.parse(state.selectedDistance),
      angleRangeKey: state.selectedAngleRange,
      sessionShotTraces: state.sessionShotTraces,
      steadinessShots: state.steadinessShots,
      missedShotNumbers: state.missedShotNumbers, // NEW: Save missed shots
    );

    final result = await usecase(session);
    result.fold(
            (l) => emit(state.copyWith(
            saveError: l.message,
            isSavingSession: false,
            isSessionSaved: false)),
            (id) => emit(state.copyWith(
            saveError: null, isSavingSession: false, isSessionSaved: true)));
  }

  Future<void> _onSendHapticCommand(
      SendHapticCommand event, Emitter<TrainingSessionState> emit) async
  {
    await bleRepository.sendHapticCommand(event.intensity, event.device);
  }

  Future<void> _onSendCommand(
      SendCommand event, Emitter<TrainingSessionState> emit) async
  {
    await bleRepository.sendcommand(
      event.ditCommand,
      event.dvcCommand,
      event.swdCommand,
      event.swbdCommand,
      event.avdCommand,
      event.avdtCommand,
      event.hapticCommand,
      event.device,
    );
  }


}
// lib/features/training/presentation/bloc/training_session/training_session_bloc.dart - Fixed version
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/ble_repository_impl.dart';
import 'training_session_event.dart';
import 'training_session_state.dart';
import 'package:pulse_skadi/features/training/domain/repositories/ble_repository.dart';
import 'package:pulse_skadi/features/training/data/model/shot_trace_model.dart';
import 'package:pulse_skadi/features/training/data/model/steadiness_shot_data.dart';
import 'dart:async';
import 'package:pulse_skadi/features/training/data/model/streaming_model.dart';

class TrainingSessionBloc
    extends Bloc<TrainingSessionEvent, TrainingSessionState> {
  final BleRepository bleRepository;
  StreamSubscription? _sensorStreamSubscription;
  StreamSubscription? _shotTracesSubscription;

  // Track previous shotDetected value for edge detection
  bool _lastShotDetected = false;

  // ✅ NEW: Track shot traces data
  List<ShotTraceData> _sessionShotTraces = [];

  // ✅ NEW: Track steadiness shot data
  final List<SteadinessShotData> _steadinessShots = [];

  // ✅ NEW: Session completion tracking
  bool _waitingForLastShotTrace = false;
  int _targetShotCount = 0;

  TrainingSessionBloc({required this.bleRepository})
      : super(const TrainingSessionState()) {
    on<StartTrainingSession>(_onStartTrainingSession);
    on<StopTrainingSession>(_onStopTrainingSession);
    // on<SimulateShot>(_onSimulateShot);
    on<ClearTarget>(_onClearTarget);
    on<ToggleHaptic>(_onToggleHaptic);
    on<UpdateAIFeedback>(_onUpdateAIFeedback);
    on<EnableSensors>(_onEnableSensors);
    on<DisableSensors>(_onDisableSensors);
    on<SendCommand>(_onSendCommand);
    on<Recalibrate>(_onRecalibrate);
    on<ShotTracesUpdated>(_onShotTracesUpdated);
    on<AddSteadinessShot>(_onAddSteadinessShot);
  }

  void _onStartTrainingSession(
      StartTrainingSession event, Emitter<TrainingSessionState> emit) {
    print('[TrainingSessionBloc] StartTrainingSession event received');

    // ✅ ENHANCED: Reset shot traces data for new session
    _sessionShotTraces.clear();
    _steadinessShots.clear(); // ✅ NEW: Reset steadiness shots
    _lastShotDetected = false;
    _waitingForLastShotTrace = false;
    _targetShotCount = state.program?.noOfShots ?? 5;

    // ✅ FIX: Set target shot count in BLE repository
    bleRepository.setTargetShotCount(_targetShotCount);

    emit(state.copyWith(
        isTraining: true,
        sessionStartTime: DateTime.now(),
        sessionCompleted: false,
        hapticEnabled: false,
        shotCount: 0,
        shotData: [],
        sessionShotTraces: [],
        steadinessShots: [],
        aiFeedbackText:
            "${state.program?.programName} session started. Focus on ${state.program?.performanceMetrics?.map((m) => m.stability).join(' and ')}."));
  }

  void _onStopTrainingSession(
      StopTrainingSession event, Emitter<TrainingSessionState> emit) {
    print('[TrainingSessionBloc] StopTrainingSession event received');

    // ✅ ENHANCED: Provide session summary with shot traces
    String feedbackText = "Session complete. Analyzing results...";
    if (_sessionShotTraces.isNotEmpty) {
      feedbackText =
          "Session complete. ${_sessionShotTraces.length} shots analyzed with trace data. ";

      try {
        double avgStability = _sessionShotTraces
                .map((trace) =>
                    trace.metrics['preShotStability'] as double? ?? 0.0)
                .reduce((a, b) => a + b) /
            _sessionShotTraces.length;
        feedbackText +=
            "Average pre-shot stability: ${avgStability.toStringAsFixed(1)}%";
      } catch (e) {
        print('[TrainingSessionBloc] Error calculating session summary: $e');
      }
    }

    // ✅ Reset session completion tracking
    _waitingForLastShotTrace = false;

    emit(state.copyWith(
        isTraining: false,
        sessionStartTime: null,
        shotCount: 0,
        shotData: [],
        aiFeedbackText: feedbackText));
  }

  void _onClearTarget(ClearTarget event, Emitter<TrainingSessionState> emit) {
    // ✅ ENHANCED: Also clear shot traces data and reset completion tracking
    _sessionShotTraces.clear();
    _waitingForLastShotTrace = false;
    _targetShotCount = 0;
    emit(TrainingSessionState());
  }

  void _onToggleHaptic(ToggleHaptic event, Emitter<TrainingSessionState> emit) {
    emit(state.copyWith(hapticEnabled: !state.hapticEnabled));
  }

  void _onUpdateAIFeedback(
      UpdateAIFeedback event, Emitter<TrainingSessionState> emit) {
    emit(state.copyWith(aiFeedbackText: event.feedback));
  }

  Future<void> _onEnableSensors(
      EnableSensors event, Emitter<TrainingSessionState> emit) async {
    print('[TrainingSessionBloc] EnableSensors event received');

    _sessionShotTraces.clear();
    _lastShotDetected = false;
    _waitingForLastShotTrace = false;
    _targetShotCount = event.program.noOfShots ?? 0;

    emit(state.copyWith(
        isSensorsEnabled: true,
        device: event.device,
        program: event.program,
        sensorStream: null,
        shotCount: 0,
        shotData: [],
        sessionShotTraces: []));

    if (bleRepository is BleRepositoryImpl) {
      final repo = bleRepository as BleRepositoryImpl;
      _shotTracesSubscription = repo.shotTracesStream.listen((shotTraces) {
        _sessionShotTraces = shotTraces;
        add(ShotTracesUpdated(shotTraces));
      });
    }

    final stream = bleRepository.enableSensors(event.device);

    await emit.forEach<StreamingModel>(
      stream,
      onData: (streamingModel) {
        TrainingSessionState newState = state.copyWith(
            sensorStream: streamingModel,
            sessionShotTraces: List.from(_sessionShotTraces));

        bool shotEdge =
            !_lastShotDetected && streamingModel.shotDetected == true;
        _lastShotDetected = streamingModel.shotDetected == true;

        // if (shotEdge) {
        //   String analysisText = _generateShotAnalysisFeedback(streamingModel);
        //
        //   int newShotCount = state.shotCount + 1;
        //   if (newShotCount >= _targetShotCount) {
        //     _waitingForLastShotTrace = true;
        //     add(DisableSensors(device: event.device));
        //     newState = newState.copyWith(
        //         shotCount: newShotCount,
        //         sessionCompleted: true,
        //         isTraining: false,
        //         aiFeedbackText:
        //             "Last shot detected! Collecting complete trace data...");
        //   } else {
        //     newState = newState.copyWith(
        //         shotCount: newShotCount, aiFeedbackText: analysisText);
        //   }
        // }

        return newState;
      },
      onError: (error, stackTrace) {
        return state.copyWith(isSensorsEnabled: false);
      },
    );
  }

  Future<void> _onDisableSensors(
      DisableSensors event, Emitter<TrainingSessionState> emit) async {
    print('[TrainingSessionBloc] DisableSensors event received');
    await bleRepository.disableSensors(event.device);
    _sensorStreamSubscription?.cancel();
    _shotTracesSubscription?.cancel();
    _sensorStreamSubscription = null;
    _shotTracesSubscription = null;

    _waitingForLastShotTrace = false;

    emit(state.copyWith(isSensorsEnabled: false, sensorStream: null));
  }

  Future<void> _onSendCommand(
      SendCommand event, Emitter<TrainingSessionState> emit) async {
    print('[TrainingSessionBloc] SendCommand event received');
    await bleRepository.sendcommand(
        event.ditCommand,
        event.dvcCommand,
        event.swdCommand,
        event.swbdCommand,
        event.avdCommand,
        event.avdtCommand,
        event.device);
    emit(state.copyWith(
        ditCommand: event.ditCommand,
        dvcCommand: event.dvcCommand,
        swdCommand: event.swdCommand,
        swbdCommand: event.swbdCommand,
        avdCommand: event.avdCommand,
        avdtCommand: event.avdtCommand));
  }

  Future<void> _onRecalibrate(
      Recalibrate event, Emitter<TrainingSessionState> emit) async {
    print('[TrainingSessionBloc] Recalibrate event received');
    bleRepository.recalibrate();

    // ✅ ENHANCED: Clear shot traces data on recalibration and reset completion tracking
    _sessionShotTraces.clear();
    _waitingForLastShotTrace = false;

    emit(state.copyWith(
      aiFeedbackText: "Recalibrated. Ready for precise shooting.",
      sessionShotTraces: [],
    ));
  }

  // ✅ ENHANCED: Handle shot traces update events with session completion check
  Future<void> _onShotTracesUpdated(
      ShotTracesUpdated event, Emitter<TrainingSessionState> emit) async {
    emit(state.copyWith(
      sessionShotTraces: event.shotTraces,
    ));

    // ✅ NEW: Check if we should complete the session
    _checkSessionCompletion(emit, event.shotTraces);
  }

  // ✅ NEW: Handle adding steadiness shot data
  Future<void> _onAddSteadinessShot(
      AddSteadinessShot event, Emitter<TrainingSessionState> emit) async {
    print(
        '[TrainingSessionBloc] AddSteadinessShot event received for shot ${event.shotData.shotNumber}');

    // Check if shot already exists (for updating)
    final existingIndex = _steadinessShots
        .indexWhere((shot) => shot.shotNumber == event.shotData.shotNumber);

    bool stateChanged = false;

    if (existingIndex != -1) {
      // Update existing shot data only if it's different
      final existingShot = _steadinessShots[existingIndex];
      if (existingShot != event.shotData) {
        _steadinessShots[existingIndex] = event.shotData;
        stateChanged = true;
        print(
            '[TrainingSessionBloc] Updated existing shot ${event.shotData.shotNumber}');
      } else {
        print(
            '[TrainingSessionBloc] Shot ${event.shotData.shotNumber} unchanged, skipping update');
      }
    } else {
      // Add new shot data
      _steadinessShots.add(event.shotData);
      stateChanged = true;
      print(
          '[TrainingSessionBloc] Added new shot ${event.shotData.shotNumber}');
    }

    // Only emit if state actually changed
    if (stateChanged) {
      emit(state.copyWith(
        steadinessShots: List.from(_steadinessShots),
      ));
    }
  }

  // ✅ NEW: Check if session should be completed based on shot traces
  void _checkSessionCompletion(
      Emitter<TrainingSessionState> emit, List<ShotTraceData> shotTraces) {
    // Only check for completion if we're waiting for the last shot trace
    if (!_waitingForLastShotTrace) return;

    // Check if we have received the trace for the last shot
    bool hasLastShotTrace = shotTraces.length >= _targetShotCount;

    if (hasLastShotTrace) {
      print(
          '[TrainingSessionBloc] ✅ Last shot trace received! Completing session...');

      // Get the latest shot trace for final feedback
      final lastShotTrace = shotTraces.last;
      final stability =
          lastShotTrace.metrics['preShotStability'] as double? ?? 0.0;

      String finalFeedback =
          "Session complete! Final shot: ${stability.toStringAsFixed(1)}% stability. ";
      finalFeedback += _generateSessionSummary();

      _waitingForLastShotTrace = false;

      // ✅ FIX: Reset shot cycle in BLE repository when session is truly complete
      bleRepository.resetShotCycleForSessionComplete();

      emit(state.copyWith(
          sessionCompleted: true,
          isTraining: false,
          aiFeedbackText: finalFeedback));

      // Disable sensors after session completion
      if (state.device != null) {
        add(DisableSensors(device: state.device!));
      }
    } else {
      print(
          '[TrainingSessionBloc] ⏳ Waiting for last shot trace... (${shotTraces.length}/$_targetShotCount)');
    }
  }

  // ✅ ENHANCED: Generate shot analysis feedback with trace data
  String _generateShotAnalysisFeedback(StreamingModel streamingModel) {
    int shotNumber = state.shotCount + 1;

    // Check if we have trace data for this shot
    final currentShotTrace =
        _sessionShotTraces.isNotEmpty ? _sessionShotTraces.last : null;

    if (currentShotTrace != null && currentShotTrace.tracePoints.isNotEmpty) {
      final stability =
          currentShotTrace.metrics['preShotStability'] as double? ?? 0.0;
      final recoveryTime =
          currentShotTrace.metrics['recoveryTime'] as int? ?? 0;
      final totalPoints = currentShotTrace.tracePoints.length;

      // Count points by phase for better feedback
      final preShotCount = currentShotTrace.tracePoints
          .where((tp) => tp.phase == TracePhase.preShot)
          .length;
      final shotCount = currentShotTrace.tracePoints
          .where((tp) => tp.phase == TracePhase.shot)
          .length;
      final postShotCount = currentShotTrace.tracePoints
          .where((tp) => tp.phase == TracePhase.postShot)
          .length;

      if (stability > 80.0) {
        return "Shot #$shotNumber: Excellent pre-shot stability ${stability.toStringAsFixed(1)}%! Complete traceline saved with $totalPoints points.";
      } else if (stability > 60.0) {
        return "Shot #$shotNumber: Good stability ${stability.toStringAsFixed(1)}%. Traceline captured: $preShotCount pre-shot + $postShotCount recovery points.";
      } else {
        return "Shot #$shotNumber: Focus on stability ${stability.toStringAsFixed(1)}%. Complete trace saved for analysis.";
      }
    }

    // Fallback to basic feedback
    if (streamingModel.points.length > 50) {
      int preShotPoints = 0;
      int postShotPoints = 0;

      for (var point in streamingModel.points) {
        switch (point.phase) {
          case TracePhase.preShot:
            preShotPoints++;
            break;
          case TracePhase.postShot:
            postShotPoints++;
            break;
          case TracePhase.shot:
            break;
        }
      }

      if (preShotPoints > 30) {
        return "Shot #$shotNumber: Good pre-shot stability detected. Complete traceline being processed...";
      } else if (postShotPoints > 20) {
        return "Shot #$shotNumber: Recovery data captured. Analyzing complete shot cycle...";
      }
    }

    return "Shot #$shotNumber detected! Processing complete traceline (pre-shot + shot + post-shot)...";
  }

  // ✅ ENHANCED: Generate session summary with trace data
  String _generateSessionSummary() {
    if (_sessionShotTraces.isEmpty) {
      return "Session completed with ${state.shotCount} shots.";
    }

    try {
      // Calculate average metrics from trace data
      double avgStability = 0.0;
      double avgRecoveryTime = 0.0;
      int validTraces = 0;

      for (var trace in _sessionShotTraces) {
        final stability = trace.metrics['preShotStability'] as double?;
        final recovery = trace.metrics['recoveryTime'] as int?;

        if (stability != null) {
          avgStability += stability;
          validTraces++;
        }

        if (recovery != null) {
          avgRecoveryTime += recovery;
        }
      }

      if (validTraces > 0) {
        avgStability /= validTraces;
        avgRecoveryTime /= _sessionShotTraces.length;

        return "Avg stability: ${avgStability.toStringAsFixed(1)}%, "
            "Recovery: ${avgRecoveryTime.toStringAsFixed(0)}ms. $validTraces complete traces analyzed.";
      }
    } catch (e) {
      print('[TrainingSessionBloc] Error generating session summary: $e');
    }

    return "Session completed with ${state.shotCount} shots analyzed with trace data.";
  }

  @override
  Future<void> close() {
    _sensorStreamSubscription?.cancel();
    _shotTracesSubscription?.cancel();
    _sessionShotTraces.clear();
    _waitingForLastShotTrace = false;
    bleRepository.dispose();
    return super.close();
  }
}

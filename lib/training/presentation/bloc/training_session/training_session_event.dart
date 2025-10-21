// lib/features/training/presentation/bloc/training_session/training_session_event.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter/material.dart';

import '../../../data/model/programs_model.dart';
import '../../../data/model/shot_trace_model.dart';
import '../../../data/model/steadiness_shot_data.dart';
import '../../../data/model/streaming_model.dart';

abstract class TrainingSessionEvent extends Equatable {
  const TrainingSessionEvent();

  @override
  List<Object?> get props => [];
}

// Core session events
class StartTrainingSession extends TrainingSessionEvent {
  final ProgramsModel program;
  const StartTrainingSession({required this.program});
}

class StopTrainingSession extends TrainingSessionEvent {
  const StopTrainingSession();
}

class ClearLastSession extends TrainingSessionEvent {
  final BluetoothDevice device;
  const ClearLastSession({required this.device});
}

class EnableSensors extends TrainingSessionEvent {
  final BluetoothDevice device;

  const EnableSensors({required this.device});

  @override
  List<Object?> get props => [device];
}

class DisableSensors extends TrainingSessionEvent {
  final BluetoothDevice device;

  const DisableSensors({required this.device});

  @override
  List<Object?> get props => [device];
}

// Main sensor data processing event - MOVED FROM UI
class ProcessSensorData extends TrainingSessionEvent {
  final StreamingModel streamingModel;

  const ProcessSensorData(this.streamingModel);

  @override
  List<Object?> get props => [streamingModel];
}

// Settings events - MOVED FROM UI
class UpdateDistancePreset extends TrainingSessionEvent {
  final String distance;

  const UpdateDistancePreset(this.distance);

  @override
  List<Object?> get props => [distance];
}

class UpdateAngleRange extends TrainingSessionEvent {
  final String angleRange;

  const UpdateAngleRange(this.angleRange);

  @override
  List<Object?> get props => [angleRange];
}

// Shot handling events - MOVED FROM UI
class DetectShotEvent extends TrainingSessionEvent {
  const DetectShotEvent();
}

class AddShotMarkerEvent extends TrainingSessionEvent {
  final Offset position;
  final DateTime timestamp;

  const AddShotMarkerEvent({
    required this.position,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [position, timestamp];
}

class ProcessShotAtPosition extends TrainingSessionEvent {
  final Offset shotPosition;
  final DateTime timestamp;
  final int lookbackPoints;

  const ProcessShotAtPosition({
    required this.shotPosition,
    required this.timestamp,
    this.lookbackPoints = 0,
  });

  @override
  List<Object?> get props => [shotPosition, timestamp, lookbackPoints];
}

// Trace management events - MOVED FROM UI
class ResetTrace extends TrainingSessionEvent {
  const ResetTrace();
}

class ClearTracePoints extends TrainingSessionEvent {
  const ClearTracePoints();
}

class AddTracePoint extends TrainingSessionEvent {
  final Offset position;

  const AddTracePoint(this.position);

  @override
  List<Object?> get props => [position];
}

class UpdateVisibilityGate extends TrainingSessionEvent {
  final bool visGate;
  final DateTime? timestamp;

  const UpdateVisibilityGate({
    required this.visGate,
    this.timestamp,
  });

  @override
  List<Object?> get props => [visGate, timestamp];
}

// Steady hold events - MOVED FROM UI
class UpdateSteadyHold extends TrainingSessionEvent {
  final bool steady;
  final DateTime timestamp;

  const UpdateSteadyHold({
    required this.steady,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [steady, timestamp];
}

// Adaptive scaling events - MOVED FROM UI
class UpdateAdaptiveScaling extends TrainingSessionEvent {
  const UpdateAdaptiveScaling();
}

class AddRecentSwayData extends TrainingSessionEvent {
  final double swayValue;

  const AddRecentSwayData(this.swayValue);

  @override
  List<Object?> get props => [swayValue];
}

// Ring system events - MOVED FROM UI
class InitializeRingSystem extends TrainingSessionEvent {
  const InitializeRingSystem();
}

class RecomputeScoreRadii extends TrainingSessionEvent {
  final String difficulty;

  const RecomputeScoreRadii(this.difficulty);

  @override
  List<Object?> get props => [difficulty];
}

// Session timer events
class StartSessionTimer extends TrainingSessionEvent {
  const StartSessionTimer();
}

class StopSessionTimer extends TrainingSessionEvent {
  const StopSessionTimer();
}

class UpdateSessionTimer extends TrainingSessionEvent {
  const UpdateSessionTimer();
}

// Update StartShotCapture event
class StartShotCapture extends TrainingSessionEvent {
  final Offset shotPosition;
  final int lookbackPoints;
  final int shotNumber; // NEW

  const StartShotCapture({
    required this.shotPosition,
    this.lookbackPoints = 0,
    required this.shotNumber, // NEW
  });

  @override
  List<Object?> get props => [shotPosition, lookbackPoints, shotNumber]; // NEW
}

// Update ContinuePostShotCapture event
class ContinuePostShotCapture extends TrainingSessionEvent {
  final List<TracePoint> shotTracelineBuffer;
  final Offset shotPosition;
  final int existingPostShotPoints;
  final int shotNumber; // NEW

  const ContinuePostShotCapture({
    required this.shotTracelineBuffer,
    required this.shotPosition,
    required this.existingPostShotPoints,
    required this.shotNumber, // NEW
  });

  @override
  List<Object?> get props => [
        shotTracelineBuffer,
        shotPosition,
        existingPostShotPoints,
        shotNumber
      ]; // NEW
}

// Update CompleteShotCapture event
class CompleteShotCapture extends TrainingSessionEvent {
  final List<TracePoint> completeTraceline;
  final int shotNumber; // NEW

  const CompleteShotCapture(this.completeTraceline, this.shotNumber); // NEW

  @override
  List<Object?> get props => [completeTraceline, shotNumber]; // NEW
}

// Existing events
class AddSteadinessShot extends TrainingSessionEvent {
  final SteadinessShotData shotData;

  const AddSteadinessShot(this.shotData);

  @override
  List<Object?> get props => [shotData];
}

class ShotTracesUpdated extends TrainingSessionEvent {
  final List<ShotTraceData> shotTraces;

  const ShotTracesUpdated(this.shotTraces);

  @override
  List<Object?> get props => [shotTraces];
}



class Recalibrate extends TrainingSessionEvent {
  const Recalibrate();
}

class SendCommand extends TrainingSessionEvent {
  final int ditCommand;
  final int dvcCommand;
  final int swdCommand;
  final int swbdCommand;
  final int avdCommand;
  final int avdtCommand;
  final int hapticCommand;
  final BluetoothDevice device;

  const SendCommand({
    required this.ditCommand,
    required this.dvcCommand,
    required this.swdCommand,
    required this.swbdCommand,
    required this.avdCommand,
    required this.avdtCommand,
    required this.hapticCommand,
    required this.device,
  });

  @override
  List<Object?> get props => [
        ditCommand,
        dvcCommand,
        swdCommand,
        swbdCommand,
        avdCommand,
        avdtCommand,
        hapticCommand,
        device,
      ];
}

// Navigation events
class NavigateToSessionDetail extends TrainingSessionEvent {
  const NavigateToSessionDetail();
}

class ShowScoreToast extends TrainingSessionEvent {
  final int score;
  final double thetaDot;

  const ShowScoreToast({
    required this.score,
    required this.thetaDot,
  });

  @override
  List<Object?> get props => [score, thetaDot];
}

class ShowDistanceToast extends TrainingSessionEvent {
  final String distance;

  const ShowDistanceToast(this.distance);

  @override
  List<Object?> get props => [distance];
}

class SaveSession extends TrainingSessionEvent {
  const SaveSession();

  @override
  List<Object?> get props => [];
}

// NEW: Event for tracking missed shots
// Update IncrementMissedShot event
class IncrementMissedShot extends TrainingSessionEvent {
  final int shotNumber; // NEW: Add shot number

  const IncrementMissedShot({required this.shotNumber}); // NEW

  @override
  List<Object?> get props => [shotNumber]; // NEW
}

// NEW: Calibration session events
class StartCalibrationSession extends TrainingSessionEvent {
  const StartCalibrationSession();
}

class StopCalibrationSession extends TrainingSessionEvent {
  const StopCalibrationSession();
}

// Add after CompleteShotCapture
class ClearPostShotDisplay extends TrainingSessionEvent {
  const ClearPostShotDisplay();
}

// Add this new event class
class HandleSensorError extends TrainingSessionEvent {
  final String error;

  const HandleSensorError(this.error);

  @override
  List<Object?> get props => [error];
}

// Add these two new events

class PauseTrainingSession extends TrainingSessionEvent {
  const PauseTrainingSession();
}

class ResumeTrainingSession extends TrainingSessionEvent {
  const ResumeTrainingSession();
}

class SendHapticCommand extends TrainingSessionEvent {
  final int intensity;
  final BluetoothDevice device;

  const SendHapticCommand({
    required this.intensity,
    required this.device,
  });

  @override
  List<Object?> get props => [intensity, device];
}
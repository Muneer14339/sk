import 'package:equatable/equatable.dart';
import 'package:pulse_skadi/features/training/data/model/programs_model.dart';
import 'package:pulse_skadi/features/training/data/model/streaming_model.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../../data/model/shot_trace_model.dart';
import '../../../data/model/steadiness_shot_data.dart';

abstract class TrainingSessionEvent extends Equatable {
  const TrainingSessionEvent();

  @override
  List<Object?> get props => [];
}

class StartTrainingSession extends TrainingSessionEvent {
  const StartTrainingSession();

  @override
  List<Object?> get props => [];
}

class StopTrainingSession extends TrainingSessionEvent {}

class SimulateShot extends TrainingSessionEvent {
  final StreamingModel? streamingModel;
  const SimulateShot(this.streamingModel);

  @override
  List<Object?> get props => [streamingModel];
}

class ClearTarget extends TrainingSessionEvent {}

class Recalibrate extends TrainingSessionEvent {}

class ToggleHaptic extends TrainingSessionEvent {}

class UpdateAIFeedback extends TrainingSessionEvent {
  final String feedback;
  const UpdateAIFeedback(this.feedback);

  @override
  List<Object?> get props => [feedback];
}

class EnableSensors extends TrainingSessionEvent {
  final BluetoothDevice device;
  final ProgramsModel program;
  const EnableSensors({required this.device, required this.program});
  @override
  List<Object?> get props => [device, program];
}

class DisableSensors extends TrainingSessionEvent {
  final BluetoothDevice device;
  const DisableSensors({required this.device});
  @override
  List<Object?> get props => [device];
}

class SendCommand extends TrainingSessionEvent {
  final int ditCommand;
  final int dvcCommand;
  final int swdCommand;
  final int swbdCommand;
  final int avdCommand;
  final int avdtCommand;
  final BluetoothDevice device;
  const SendCommand({
    required this.ditCommand,
    required this.dvcCommand,
    required this.swdCommand,
    required this.swbdCommand,
    required this.avdCommand,
    required this.avdtCommand,
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
        device
      ];
}

class ShotTracesUpdated extends TrainingSessionEvent {
  final List<ShotTraceData> shotTraces;

  const ShotTracesUpdated(this.shotTraces);

  @override
  List<Object?> get props => [shotTraces];
}

class AddSteadinessShot extends TrainingSessionEvent {
  final SteadinessShotData shotData;

  const AddSteadinessShot(this.shotData);

  @override
  List<Object?> get props => [shotData];
}

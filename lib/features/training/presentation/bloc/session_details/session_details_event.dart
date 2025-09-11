// lib/features/training/presentation/bloc/session_details/session_details_event.dart
import 'package:equatable/equatable.dart';

abstract class SessionDetailsEvent extends Equatable {
  const SessionDetailsEvent();

  @override
  List<Object?> get props => [];
}

class LoadSessionDetails extends SessionDetailsEvent {
  final String sessionId;

  const LoadSessionDetails(this.sessionId);

  @override
  List<Object?> get props => [sessionId];
}

class SelectShot extends SessionDetailsEvent {
  final int shotId;

  const SelectShot(this.shotId);

  @override
  List<Object?> get props => [shotId];
}

class ChangeView extends SessionDetailsEvent {
  final String view;

  const ChangeView(this.view);

  @override
  List<Object?> get props => [view];
}

class ExportSessionData extends SessionDetailsEvent {
  final String sessionId;

  const ExportSessionData(this.sessionId);

  @override
  List<Object?> get props => [sessionId];
}

class ShareSessionResults extends SessionDetailsEvent {
  final String sessionId;

  const ShareSessionResults(this.sessionId);

  @override
  List<Object?> get props => [sessionId];
}

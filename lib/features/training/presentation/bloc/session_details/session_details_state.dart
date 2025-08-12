// lib/features/training/presentation/bloc/session_details/session_details_state.dart
import 'package:equatable/equatable.dart';
import 'package:pulse_skadi/features/training/domain/entities/session_details_entity.dart';

abstract class SessionDetailsState extends Equatable {
  const SessionDetailsState();

  @override
  List<Object?> get props => [];
}

class SessionDetailsInitial extends SessionDetailsState {}

class SessionDetailsLoading extends SessionDetailsState {}

class SessionDetailsLoaded extends SessionDetailsState {
  final SessionDetailsEntity sessionDetails;
  final int? selectedShotId;
  final String currentView;
  final List<TracePoint> currentTracePoints;

  const SessionDetailsLoaded({
    required this.sessionDetails,
    this.selectedShotId,
    this.currentView = 'overview',
    this.currentTracePoints = const [],
  });

  SessionDetailsLoaded copyWith({
    SessionDetailsEntity? sessionDetails,
    int? selectedShotId,
    String? currentView,
    List<TracePoint>? currentTracePoints,
  }) {
    return SessionDetailsLoaded(
      sessionDetails: sessionDetails ?? this.sessionDetails,
      selectedShotId: selectedShotId ?? this.selectedShotId,
      currentView: currentView ?? this.currentView,
      currentTracePoints: currentTracePoints ?? this.currentTracePoints,
    );
  }

  @override
  List<Object?> get props => [
        sessionDetails,
        selectedShotId,
        currentView,
        currentTracePoints,
      ];
}

class SessionDetailsError extends SessionDetailsState {
  final String message;

  const SessionDetailsError(this.message);

  @override
  List<Object?> get props => [message];
}

class SessionDetailsExporting extends SessionDetailsState {}

class SessionDetailsSharing extends SessionDetailsState {}

// Simple TracePoint class for the state
class TracePoint {
  final double x;
  final double y;
  final String phase;

  const TracePoint({
    required this.x,
    required this.y,
    required this.phase,
  });

  @override
  List<Object?> get props => [x, y, phase];
}

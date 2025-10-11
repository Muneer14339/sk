// lib/features/training/presentation/bloc/saved_sessions/saved_sessions_event.dart
import 'package:equatable/equatable.dart';

abstract class SavedSessionsEvent extends Equatable {
  const SavedSessionsEvent();
  @override
  List<Object?> get props => [];
}

class LoadSavedSessions extends SavedSessionsEvent {
  const LoadSavedSessions();
}

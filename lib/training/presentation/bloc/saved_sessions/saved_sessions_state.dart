// lib/features/training/presentation/bloc/saved_sessions/saved_sessions_state.dart
import 'package:equatable/equatable.dart';

import '../../../data/models/saved_session_model.dart';

class SavedSessionsState extends Equatable {
  final bool isLoading;
  final List<SavedSessionModel> sessions;
  final String? error;

  const SavedSessionsState({
    this.isLoading = false,
    this.sessions = const [],
    this.error,
  });

  SavedSessionsState copyWith({
    bool? isLoading,
    List<SavedSessionModel>? sessions,
    String? error,
  }) {
    return SavedSessionsState(
      isLoading: isLoading ?? this.isLoading,
      sessions: sessions ?? this.sessions,
      error: error,
    );
  }

  @override
  List<Object?> get props => [isLoading, sessions, error];
}

// lib/features/training/presentation/bloc/saved_sessions/saved_sessions_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/list_saved_sessions.dart';
import 'saved_sessions_event.dart';
import 'saved_sessions_state.dart';
class SavedSessionsBloc extends Bloc<SavedSessionsEvent, SavedSessionsState> {
  final ListSavedSessions listSavedSessions;

  SavedSessionsBloc({required this.listSavedSessions})
      : super(const SavedSessionsState()) {
    on<LoadSavedSessions>(_onLoadSavedSessions);
  }

  Future<void> _onLoadSavedSessions(
      LoadSavedSessions event, Emitter<SavedSessionsState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    final result = await listSavedSessions();
    result.fold(
      (l) => emit(state.copyWith(isLoading: false, error: l.message)),
      (sessions) => emit(
        state.copyWith(isLoading: false, sessions: sessions, error: null),
      ),
    );
  }
}

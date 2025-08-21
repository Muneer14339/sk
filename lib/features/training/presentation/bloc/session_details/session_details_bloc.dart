// lib/features/training/presentation/bloc/session_details/session_details_bloc.dart
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pulse_skadi/features/training/domain/usecases/get_session_details.dart';
import 'package:pulse_skadi/features/training/domain/usecases/export_session_data.dart'
    as export_use_case;
import 'package:pulse_skadi/features/training/domain/usecases/share_session_results.dart'
    as share_use_case;
import 'package:pulse_skadi/features/training/presentation/bloc/session_details/session_details_event.dart';
import 'package:pulse_skadi/features/training/presentation/bloc/session_details/session_details_state.dart';

class SessionDetailsBloc
    extends Bloc<SessionDetailsEvent, SessionDetailsState> {
  final GetSessionDetails getSessionDetails;
  final export_use_case.ExportSessionData exportSessionData;
  final share_use_case.ShareSessionResults shareSessionResults;

  SessionDetailsBloc({
    required this.getSessionDetails,
    required this.exportSessionData,
    required this.shareSessionResults,
  }) : super(SessionDetailsInitial()) {
    on<LoadSessionDetails>(_onLoadSessionDetails);
    on<SelectShot>(_onSelectShot);
    on<ChangeView>(_onChangeView);
    on<ExportSessionData>(_onExportSessionData);
    on<ShareSessionResults>(_onShareSessionResults);
  }

  Future<void> _onLoadSessionDetails(
    LoadSessionDetails event,
    Emitter<SessionDetailsState> emit,
  ) async {
    emit(SessionDetailsLoading());

    final result = await getSessionDetails(event.sessionId);

    result.fold(
      (failure) => emit(SessionDetailsError(failure.message)),
      (sessionDetails) => emit(SessionDetailsLoaded(
        sessionDetails: sessionDetails,
      )),
    );
  }

  void _onSelectShot(
    SelectShot event,
    Emitter<SessionDetailsState> emit,
  ) {
    if (state is SessionDetailsLoaded) {
      final currentState = state as SessionDetailsLoaded;

      // Get trace points for the selected shot from training session
      List<TracePoint> tracePoints = [];

      // Try to get actual trace data from training session
      // This would need to be passed from the training session bloc
      // For now, we'll create mock trace points
      tracePoints = _generateMockTracePoints(event.shotId);

      emit(currentState.copyWith(
        selectedShotId: event.shotId,
        currentView: 'shots',
        currentTracePoints: tracePoints,
      ));
    }
  }

  void _onChangeView(ChangeView event, Emitter<SessionDetailsState> emit) {
    if (state is SessionDetailsLoaded) {
      final currentState = state as SessionDetailsLoaded;
      emit(currentState.copyWith(currentView: event.view));
    }
  }

  Future<void> _onExportSessionData(
    ExportSessionData event,
    Emitter<SessionDetailsState> emit,
  ) async {
    emit(SessionDetailsExporting());

    final result = await exportSessionData(event.sessionId);

    result.fold(
      (failure) => emit(SessionDetailsError(failure.message)),
      (_) {
        if (state is SessionDetailsLoaded) {
          emit(state as SessionDetailsLoaded);
        }
      },
    );
  }

  Future<void> _onShareSessionResults(
    ShareSessionResults event,
    Emitter<SessionDetailsState> emit,
  ) async {
    emit(SessionDetailsSharing());

    final result = await shareSessionResults(event.sessionId);

    result.fold(
      (failure) => emit(SessionDetailsError(failure.message)),
      (_) {
        if (state is SessionDetailsLoaded) {
          emit(state as SessionDetailsLoaded);
        }
      },
    );
  }

  // Mock trace points generation
  List<TracePoint> _generateMockTracePoints(int shotId) {
    final List<TracePoint> points = [];
    final baseX = 140.0 + (shotId * 2.0);
    final baseY = 140.0 + (shotId * 1.5);

    // Pre-shot points
    for (int i = 0; i < 10; i++) {
      points.add(TracePoint(
          x: baseX + (i * 0.1), y: baseY + (i * 0.05), phase: 'preShot'));
    }

    // Shot point
    points.add(TracePoint(
      x: baseX + 1.0,
      y: baseY + 0.5,
      phase: 'shot',
    ));

    // Post-shot points
    for (int i = 0; i < 5; i++) {
      points.add(TracePoint(
        x: baseX + 1.0 + (i * 0.2),
        y: baseY + 0.5 + (i * 0.1),
        phase: 'postShot',
      ));
    }

    return points;
  }
}

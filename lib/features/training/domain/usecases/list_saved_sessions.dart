// lib/features/training/domain/usecases/list_saved_sessions.dart
import 'package:dartz/dartz.dart';
import 'package:pulse_skadi/core/errors/failures.dart';
import 'package:pulse_skadi/features/training/data/models/saved_session_model.dart';
import 'package:pulse_skadi/features/training/domain/repositories/saved_sessions_repository.dart';

class ListSavedSessions {
  final SavedSessionsRepository repository;

  ListSavedSessions(this.repository);

  Future<Either<Failure, List<SavedSessionModel>>> call() async {
    return repository.listSessions();
  }
}

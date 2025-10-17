// lib/features/training/domain/usecases/save_training_session.dart
import 'package:dartz/dartz.dart';
import 'package:pulse_skadi/core/errors/failures.dart';
import 'package:pulse_skadi/features/training/data/models/saved_session_model.dart';
import 'package:pulse_skadi/features/training/domain/repositories/saved_sessions_repository.dart';

class SaveTrainingSession {
  final SavedSessionsRepository repository;

  SaveTrainingSession(this.repository);

  Future<Either<Failure, String>> call(SavedSessionModel session) async {
    return repository.saveSession(session);
  }
}

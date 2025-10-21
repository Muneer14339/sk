// lib/features/training/domain/usecases/save_training_session.dart
import 'package:dartz/dartz.dart';
import '../../../core/error/old_failuers.dart';
import '../../data/models/saved_session_model.dart';
import '../repositories/saved_sessions_repository.dart';

class SaveTrainingSession {
  final SavedSessionsRepository repository;

  SaveTrainingSession(this.repository);

  Future<Either<Failure, String>> call(SavedSessionModel session) async {
    return repository.saveSession(session);
  }
}

// lib/features/training/domain/usecases/list_saved_sessions.dart
import 'package:dartz/dartz.dart';

import '../../../core/error/old_failuers.dart';
import '../../data/models/saved_session_model.dart';
import '../repositories/saved_sessions_repository.dart';

class ListSavedSessions {
  final SavedSessionsRepository repository;

  ListSavedSessions(this.repository);

  Future<Either<Failure, List<SavedSessionModel>>> call() async {
    return repository.listSessions();
  }
}

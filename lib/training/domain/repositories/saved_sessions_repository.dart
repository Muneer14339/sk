// lib/features/training/domain/repositories/saved_sessions_repository.dart
import 'package:dartz/dartz.dart';

import '../../../core/error/old_failuers.dart';
import '../../data/models/saved_session_model.dart';

abstract class SavedSessionsRepository {
  Future<Either<Failure, String>> saveSession(SavedSessionModel session);
  Future<Either<Failure, List<SavedSessionModel>>> listSessions();
  Future<Either<Failure, SavedSessionModel>> getSession(String sessionId);
}

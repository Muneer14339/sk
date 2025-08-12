// lib/features/training/domain/repositories/session_details_repository.dart
import 'package:dartz/dartz.dart';
import 'package:pulse_skadi/core/errors/failures.dart';
import 'package:pulse_skadi/features/training/domain/entities/session_details_entity.dart';

abstract class SessionDetailsRepository {
  Future<Either<Failure, SessionDetailsEntity>> getSessionDetails(
      String sessionId);
  Future<Either<Failure, List<SessionDetailsEntity>>> getAllSessions();
  Future<Either<Failure, void>> exportSessionData(String sessionId);
  Future<Either<Failure, void>> shareSessionResults(String sessionId);
}

// lib/features/training/domain/usecases/get_session_details.dart
import 'package:dartz/dartz.dart';
import 'package:pulse_skadi/core/errors/failures.dart';
import 'package:pulse_skadi/core/usecases/usecase.dart';
import 'package:pulse_skadi/features/training/domain/entities/session_details_entity.dart';
import 'package:pulse_skadi/features/training/domain/repositories/session_details_repository.dart';

class GetSessionDetails implements UseCase<SessionDetailsEntity, String> {
  final SessionDetailsRepository repository;

  GetSessionDetails(this.repository);

  @override
  Future<Either<Failure, SessionDetailsEntity>> call(String sessionId) async {
    return await repository.getSessionDetails(sessionId);
  }
}

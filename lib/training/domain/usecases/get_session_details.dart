// lib/features/training/domain/usecases/get_session_details.dart
import 'package:dartz/dartz.dart';
import '../../../../core/usecases/old_useCases.dart';

import '../../../core/error/old_failuers.dart';
import '../entities/session_details_entity.dart';
import '../repositories/session_details_repository.dart';

class GetSessionDetails implements UseCase<SessionDetailsEntity, String> {
  final SessionDetailsRepository repository;

  GetSessionDetails(this.repository);

  @override
  Future<Either<Failure, SessionDetailsEntity>> call(String sessionId) async {
    return await repository.getSessionDetails(sessionId);
  }
}

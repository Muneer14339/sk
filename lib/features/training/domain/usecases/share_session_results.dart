// lib/features/training/domain/usecases/share_session_results.dart
import 'package:dartz/dartz.dart';
import 'package:pulse_skadi/core/errors/failures.dart';
import 'package:pulse_skadi/core/usecases/usecase.dart';
import 'package:pulse_skadi/features/training/domain/repositories/session_details_repository.dart';

class ShareSessionResults implements UseCase<void, String> {
  final SessionDetailsRepository repository;

  ShareSessionResults(this.repository);

  @override
  Future<Either<Failure, void>> call(String sessionId) async {
    return await repository.shareSessionResults(sessionId);
  }
}

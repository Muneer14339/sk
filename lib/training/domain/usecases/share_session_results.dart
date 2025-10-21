// lib/features/training/domain/usecases/share_session_results.dart
import 'package:dartz/dartz.dart';

import '../../../core/error/old_failuers.dart';
import '../../../../core/usecases/old_useCases.dart';
import '../repositories/session_details_repository.dart';

class ShareSessionResults implements UseCase<void, String> {
  final SessionDetailsRepository repository;

  ShareSessionResults(this.repository);

  @override
  Future<Either<Failure, void>> call(String sessionId) async {
    return await repository.shareSessionResults(sessionId);
  }
}

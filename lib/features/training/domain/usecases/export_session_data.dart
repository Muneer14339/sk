// lib/features/training/domain/usecases/export_session_data.dart
import 'package:dartz/dartz.dart';
import 'package:pulse_skadi/core/errors/failures.dart';
import 'package:pulse_skadi/core/usecases/usecase.dart';
import 'package:pulse_skadi/features/training/domain/repositories/session_details_repository.dart';

class ExportSessionData implements UseCase<void, String> {
  final SessionDetailsRepository repository;

  ExportSessionData(this.repository);

  @override
  Future<Either<Failure, void>> call(String sessionId) async {
    return await repository.exportSessionData(sessionId);
  }
}

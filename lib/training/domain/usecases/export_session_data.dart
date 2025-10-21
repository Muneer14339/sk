// lib/features/training/domain/usecases/export_session_data.dart
import 'package:dartz/dartz.dart';
import '../../../../core/usecases/old_useCases.dart';
import '../../../core/error/old_failuers.dart';
import '../repositories/session_details_repository.dart';

class ExportSessionData implements UseCase<void, String> {
  final SessionDetailsRepository repository;

  ExportSessionData(this.repository);

  @override
  Future<Either<Failure, void>> call(String sessionId) async {
    return await repository.exportSessionData(sessionId);
  }
}

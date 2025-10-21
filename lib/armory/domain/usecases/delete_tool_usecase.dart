// lib/user_dashboard/domain/usecases/delete_maintenance_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../repositories/armory_repository.dart';
import '../entities/armory_maintenance.dart';

class DeleteToolUseCase implements UseCase<void, DeleteToolParams> {
  final ArmoryRepository repository;

  DeleteToolUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteToolParams params) async {
    return await repository.deleteTool(params.userId, params.tool.id!);
  }
}
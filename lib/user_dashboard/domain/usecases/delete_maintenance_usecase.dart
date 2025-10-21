// lib/user_dashboard/domain/usecases/delete_maintenance_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../repositories/armory_repository.dart';
import '../entities/armory_maintenance.dart';

class DeleteMaintenanceUseCase implements UseCase<void, DeleteMaintenanceParams> {
  final ArmoryRepository repository;

  DeleteMaintenanceUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteMaintenanceParams params) async {
    return await repository.deleteMaintenance(params.userId, params.maintenance.id!);
  }
}
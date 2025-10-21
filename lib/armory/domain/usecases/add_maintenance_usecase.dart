import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../entities/armory_maintenance.dart';
import '../repositories/armory_repository.dart';

// lib/user_dashboard/domain/usecases/add_maintenance_usecase.dart
class AddMaintenanceUseCase implements UseCase<void, AddMaintenanceParams> {
  final ArmoryRepository repository;

  AddMaintenanceUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(AddMaintenanceParams params) async {
    return await repository.addMaintenance(params.userId, params.maintenance);
  }
}
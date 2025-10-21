// lib/user_dashboard/domain/usecases/get_maintenance_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../entities/armory_maintenance.dart';
import '../repositories/armory_repository.dart';

class GetMaintenanceUseCase implements UseCase<List<ArmoryMaintenance>, UserIdParams> {
  final ArmoryRepository repository;

  GetMaintenanceUseCase(this.repository);

  @override
  Future<Either<Failure, List<ArmoryMaintenance>>> call(UserIdParams params) async {
    return await repository.getMaintenance(params.userId);
  }
}
// lib/user_dashboard/domain/usecases/get_firearms_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../entities/armory_firearm.dart';
import '../repositories/armory_repository.dart';
// lib/user_dashboard/domain/usecases/add_gear_usecase.dart
class AddGearUseCase implements UseCase<void, AddGearParams> {
  final ArmoryRepository repository;

  AddGearUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(AddGearParams params) async {
    return await repository.addGear(params.userId, params.gear);
  }
}
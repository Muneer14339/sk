// lib/user_dashboard/domain/usecases/get_firearms_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../entities/armory_firearm.dart';
import '../repositories/armory_repository.dart';
// lib/user_dashboard/domain/usecases/add_ammunition_usecase.dart
class AddAmmunitionUseCase implements UseCase<void, AddAmmunitionParams> {
  final ArmoryRepository repository;

  AddAmmunitionUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(AddAmmunitionParams params) async {
    return await repository.addAmmunition(params.userId, params.ammunition);
  }
}
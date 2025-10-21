// lib/user_dashboard/domain/usecases/delete_ammunition_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../repositories/armory_repository.dart';
import '../entities/armory_ammunition.dart';

class DeleteAmmunitionUseCase implements UseCase<void, DeleteAmmunitionParams> {
  final ArmoryRepository repository;

  DeleteAmmunitionUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteAmmunitionParams params) async {
    return await repository.deleteAmmunition(params.userId, params.ammunition.id!);
  }
}
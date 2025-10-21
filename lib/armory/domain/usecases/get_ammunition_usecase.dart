// lib/user_dashboard/domain/usecases/get_ammunition_usecase.dart
import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../entities/armory_ammunition.dart';
import '../repositories/armory_repository.dart';

class GetAmmunitionUseCase implements UseCase<List<ArmoryAmmunition>, UserIdParams> {
  final ArmoryRepository repository;

  GetAmmunitionUseCase(this.repository);

  @override
  Future<Either<Failure, List<ArmoryAmmunition>>> call(UserIdParams params) async {
    return await repository.getAmmunition(params.userId);
  }
}
// lib/user_dashboard/domain/usecases/get_firearms_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../entities/armory_firearm.dart';
import '../repositories/armory_repository.dart';

class GetFirearmsUseCase implements UseCase<List<ArmoryFirearm>, UserIdParams> {
  final ArmoryRepository repository;

  GetFirearmsUseCase(this.repository);

  @override
  Future<Either<Failure, List<ArmoryFirearm>>> call(UserIdParams params) async {
    return await repository.getFirearms(params.userId);
  }
}
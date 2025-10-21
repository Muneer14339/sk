// lib/user_dashboard/domain/usecases/get_firearms_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../entities/armory_firearm.dart';
import '../entities/armory_loadout.dart';
import '../repositories/armory_repository.dart';

// lib/user_dashboard/domain/usecases/get_loadouts_usecase.dart
class GetLoadoutsUseCase implements UseCase<List<ArmoryLoadout>, UserIdParams> {
  final ArmoryRepository repository;

  GetLoadoutsUseCase(this.repository);

  @override
  Future<Either<Failure, List<ArmoryLoadout>>> call(UserIdParams params) async {
    return await repository.getLoadouts(params.userId);
  }
}
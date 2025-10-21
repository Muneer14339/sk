// lib/user_dashboard/domain/usecases/get_firearms_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../entities/armory_gear.dart';
import '../repositories/armory_repository.dart';
// lib/user_dashboard/domain/usecases/get_gear_usecase.dart
class GetGearUseCase implements UseCase<List<ArmoryGear>, UserIdParams> {
  final ArmoryRepository repository;

  GetGearUseCase(this.repository);

  @override
  Future<Either<Failure, List<ArmoryGear>>> call(UserIdParams params) async {
    return await repository.getGear(params.userId);
  }
}
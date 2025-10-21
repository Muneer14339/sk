// lib/user_dashboard/domain/usecases/get_firearms_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../entities/armory_firearm.dart';
import '../repositories/armory_repository.dart';
// lib/user_dashboard/domain/usecases/add_loadout_usecase.dart
class AddLoadoutUseCase implements UseCase<void, AddLoadoutParams> {
  final ArmoryRepository repository;

  AddLoadoutUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(AddLoadoutParams params) async {
    return await repository.addLoadout(params.userId, params.loadout);
  }
}
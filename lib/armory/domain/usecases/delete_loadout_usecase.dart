// lib/user_dashboard/domain/usecases/delete_loadout_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../repositories/armory_repository.dart';
import '../entities/armory_loadout.dart';

class DeleteLoadoutUseCase implements UseCase<void, DeleteLoadoutParams> {
  final ArmoryRepository repository;

  DeleteLoadoutUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteLoadoutParams params) async {
    return await repository.deleteLoadout(params.userId, params.loadout.id!);
  }
}
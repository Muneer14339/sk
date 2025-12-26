// lib/user_dashboard/domain/usecases/delete_gear_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../repositories/armory_repository.dart';

class DeleteGearUseCase implements UseCase<void, DeleteGearParams> {
  final ArmoryRepository repository;

  DeleteGearUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteGearParams params) async {
    return await repository.deleteGear(params.userId, params.gear.id!);
  }
}
// lib/user_dashboard/domain/usecases/add_firearm_usecase.dart
import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../repositories/armory_repository.dart';

class AddFirearmUseCase implements UseCase<void, AddFirearmParams> {
  final ArmoryRepository repository;

  AddFirearmUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(AddFirearmParams params) async {
    return await repository.addFirearm(params.userId, params.firearm);
  }
}
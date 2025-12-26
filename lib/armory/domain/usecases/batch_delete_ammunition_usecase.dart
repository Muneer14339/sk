// lib/armory/domain/usecases/batch_delete_ammunition_usecase.dart - NEW FILE

import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../repositories/armory_repository.dart';

class BatchDeleteAmmunitionUseCase implements UseCase<void, BatchDeleteAmmunitionParams> {
  final ArmoryRepository repository;

  BatchDeleteAmmunitionUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(BatchDeleteAmmunitionParams params) async {
    return await repository.batchDeleteAmmunition(params.userId, params.ammunitionIds);
  }
}

class BatchDeleteAmmunitionParams {
  final String userId;
  final List<String> ammunitionIds;

  BatchDeleteAmmunitionParams({required this.userId, required this.ammunitionIds});
}
// lib/armory/domain/usecases/batch_delete_loadouts_usecase.dart - NEW FILE

import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../repositories/armory_repository.dart';

class BatchDeleteLoadoutsUseCase implements UseCase<void, BatchDeleteLoadoutsParams> {
  final ArmoryRepository repository;

  BatchDeleteLoadoutsUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(BatchDeleteLoadoutsParams params) async {
    return await repository.batchDeleteLoadouts(params.userId, params.loadoutIds);
  }
}

class BatchDeleteLoadoutsParams {
  final String userId;
  final List<String> loadoutIds;

  BatchDeleteLoadoutsParams({required this.userId, required this.loadoutIds});
}
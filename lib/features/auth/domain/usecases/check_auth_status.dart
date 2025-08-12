import 'package:dartz/dartz.dart';
import 'package:pulse_skadi/core/errors/failures.dart';
import 'package:pulse_skadi/core/usecases/usecase.dart';
import 'package:pulse_skadi/features/auth/domain/entities/user_entity.dart';
import 'package:pulse_skadi/features/auth/domain/repositories/auth_repository.dart';

class CheckAuthStatus implements UseCase<UserEntity, NoParams> {
  final AuthRepository repository;

  CheckAuthStatus(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(NoParams params) async {
    return await repository.getCurrentUser();
  }
}

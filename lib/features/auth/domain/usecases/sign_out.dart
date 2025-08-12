import 'package:dartz/dartz.dart';
import 'package:pulse_skadi/core/usecases/usecase.dart';
import 'package:pulse_skadi/features/auth/domain/repositories/auth_repository.dart';
import 'package:pulse_skadi/core/errors/failures.dart';

class SignOutParams {
  SignOutParams();
}

class SignOut implements UseCase<void, SignOutParams> {
  final AuthRepository repository;

  SignOut(this.repository);

  @override
  Future<Either<Failure, void>> call(SignOutParams params) async {
    return await repository.signOut();
  }
}

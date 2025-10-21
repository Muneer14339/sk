import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class SignupUseCase implements UseCase<User, SignupParams> {
  final AuthRepository repository;

  SignupUseCase(this.repository);

  @override
  Future<Either<Failure, User>> call(SignupParams params) async {
    return await repository.signup(
      params.firstName,
      params.email,
      params.password,
      params.location,
    );
  }
}

class SignupParams {
  final String firstName;
  final String email;
  final String password;
  final String? location;

  SignupParams({
    required this.firstName,
    required this.email,
    required this.password,
    this.location,
  });
}
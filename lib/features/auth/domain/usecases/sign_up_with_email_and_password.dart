import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pulse_skadi/core/errors/failures.dart';
import 'package:pulse_skadi/core/usecases/usecase.dart';
import 'package:pulse_skadi/features/auth/domain/repositories/auth_repository.dart';

class SignUpWithEmailAndPasswordParams {
  final String email;
  final String password;
  final String displayName;

  SignUpWithEmailAndPasswordParams({
    required this.email,
    required this.password,
    required this.displayName,
  });
}

class SignUpWithEmailAndPassword
    implements UseCase<UserCredential, SignUpWithEmailAndPasswordParams> {
  final AuthRepository repository;

  SignUpWithEmailAndPassword(this.repository);

  @override
  Future<Either<Failure, UserCredential>> call(
      SignUpWithEmailAndPasswordParams params) async {
    return await repository.signUpWithEmailAndPassword(
      email: params.email,
      password: params.password,
      displayName: params.displayName,
    );
  }
}

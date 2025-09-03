import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pulse_skadi/core/errors/failures.dart';
import 'package:pulse_skadi/core/usecases/usecase.dart';
import 'package:pulse_skadi/features/auth/domain/repositories/auth_repository.dart';

class SignInWithEmailAndPasswordParams {
  final String email;
  final String password;

  SignInWithEmailAndPasswordParams({
    required this.email,
    required this.password,
  });
}

class SignInWithEmailAndPassword
    implements UseCase<UserCredential, SignInWithEmailAndPasswordParams> {
  final AuthRepository repository;

  SignInWithEmailAndPassword(this.repository);

  @override
  Future<Either<Failure, UserCredential>> call(
      SignInWithEmailAndPasswordParams params) async {
    return await repository.signInWithEmailAndPassword(
      email: params.email,
      password: params.password,
    );
  }
}

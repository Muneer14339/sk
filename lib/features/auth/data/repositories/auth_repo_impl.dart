import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pulse_skadi/core/errors/failures.dart';
import 'package:pulse_skadi/features/auth/data/remote/service/auth_service.dart';
import 'package:pulse_skadi/features/auth/domain/entities/user_entity.dart';
import 'package:pulse_skadi/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthService authService;
  AuthRepositoryImpl(this.authService);
  @override
  Future<Either<Failure, UserCredential>> signInWithEmailAndPassword(
      {required String email, required String password}) async {
    return authService.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<Either<Failure, UserCredential>> signUpWithEmailAndPassword(
      {required String displayName,
      required String email,
      required String password}) async {
    return authService.signUpWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<Either<Failure, Unit>> signOut() async {
    await authService.signOut();
    return const Right(unit);
  }

  @override
  Future<Either<Failure, void>> forgotPassword(String email) async {
    await authService.forgotPassword(email);
    return const Right(unit);
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    User? user = await authService.getCurrentUser();
    if (user != null) {
      return Right(UserEntity(id: user.uid, email: user.email!));
    } else {
      return Left(NetworkFailure('User not found'));
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    return await authService.isAuthenticated();
  }

  @override
  Future<Either<Failure, UserEntity>> signInWithApple() async {
    return signInWithApple();
  }

  @override
  Future<Either<Failure, UserEntity>> signInWithGoogle() async {
    return signInWithGoogle();
  }

  @override
  Future<Either<Failure, UserEntity>> updateProfile(
      {required String userId, String? displayName, String? photoUrl}) async {
    return updateProfile(
        userId: userId, displayName: displayName, photoUrl: photoUrl);
  }
}

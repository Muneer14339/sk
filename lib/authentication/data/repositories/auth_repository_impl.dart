import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, User>> login(String email, String password) async {
    try {
      final user = await remoteDataSource.login(email, password);
      return Right(user);
    } on Exception catch (e) {
      // Extract message from Exception
      final message = e.toString().replaceFirst('Exception: ', '');
      return Left(AuthFailure(message));
    } catch (e) {
      return Left(AuthFailure('An unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, User>> signup(String firstName, String email, String password, String? location) async {
    try {
      final user = await remoteDataSource.signup(firstName, email, password, location);
      return Right(user);
    } on Exception catch (e) {
      // Extract message from Exception
      final message = e.toString().replaceFirst('Exception: ', '');
      return Left(AuthFailure(message));
    } catch (e) {
      return Left(AuthFailure('An unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, User>> signInWithGoogle() async {
    try {
      final user = await remoteDataSource.signInWithGoogle();
      return Right(user);
    } on Exception catch (e) {
      // Extract message from Exception
      final message = e.toString().replaceFirst('Exception: ', '');
      return Left(AuthFailure(message));
    } catch (e) {
      return Left(AuthFailure('An unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await remoteDataSource.logout();
      return const Right(null);
    } on Exception catch (e) {
      // Extract message from Exception
      final message = e.toString().replaceFirst('Exception: ', '');
      return Left(AuthFailure(message));
    } catch (e) {
      return Left(AuthFailure('An unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    try {
      final user = await remoteDataSource.getCurrentUser();
      return Right(user);
    } on Exception catch (e) {
      // Extract message from Exception
      final message = e.toString().replaceFirst('Exception: ', '');
      return Left(AuthFailure(message));
    } catch (e) {
      return Left(AuthFailure('An unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, void>> sendPasswordResetEmail(String email) async {
    try {
      await remoteDataSource.sendPasswordResetEmail(email);
      return const Right(null);
    } on Exception catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      return Left(AuthFailure(message));
    } catch (e) {
      return Left(AuthFailure('An unexpected error occurred'));
    }
  }
}
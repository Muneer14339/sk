import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<Either<Failure, User>> login(String email, String password);
  Future<Either<Failure, User>> signup(String firstName, String email, String password, String? location);
  Future<Either<Failure, User>> signInWithGoogle(); // NEW
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, User?>> getCurrentUser();
}
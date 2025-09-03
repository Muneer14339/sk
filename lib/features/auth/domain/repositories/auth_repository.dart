import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pulse_skadi/core/errors/failures.dart';
import 'package:pulse_skadi/features/auth/domain/entities/user_entity.dart';

abstract class AuthRepository {
  // Check if user is authenticated
  Future<bool> isAuthenticated();

  // Get current user
  Future<Either<Failure, UserEntity>> getCurrentUser();

  // Sign in with email and password
  Future<Either<Failure, UserCredential>> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  // Sign up with email and password
  Future<Either<Failure, UserCredential>> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  });

  // Sign in with Google
  Future<Either<Failure, UserEntity>> signInWithGoogle();

  // Sign in with Apple
  Future<Either<Failure, UserEntity>> signInWithApple();

  // Sign out
  Future<Either<Failure, void>> signOut();

  // Forgot password
  Future<Either<Failure, void>> forgotPassword(String email);

  // Update user profile
  Future<Either<Failure, UserEntity>> updateProfile({
    required String userId,
    String? displayName,
    String? photoUrl,
  });
}

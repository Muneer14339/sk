import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pulse_skadi/core/errors/failures.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Either<Failure, UserCredential>> signInWithEmailAndPassword(
      {required String email, required String password}) async {
    try {
      return Right(await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      ));
    } catch (e) {
      if (e is FirebaseAuthException) {
        return Left(FirebaseFailure(e.message.toString()));
      }
      return Left(FirebaseFailure(e.toString()));
    }
  }

  Future<Either<Failure, UserCredential>> signUpWithEmailAndPassword(
      {required String email, required String password}) async {
    try {
      return Right(await _auth.createUserWithEmailAndPassword(
          email: email, password: password));
    } catch (e) {
      if (e is FirebaseAuthException) {
        return Left(FirebaseFailure(e.message.toString()));
      }
      return Left(FirebaseFailure(e.toString()));
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<User?> getCurrentUser() async {
    return _auth.currentUser;
  }

  Future<bool> isAuthenticated() async {
    return _auth.currentUser != null;
  }

  Future<void> forgotPassword(String email) async {
    return _auth.sendPasswordResetEmail(email: email);
  }
}

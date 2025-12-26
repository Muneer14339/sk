import 'package:encrypt/encrypt.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/error/firebase_error_handler.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login(String email, String password);
  Future<UserModel> signup(String firstName, String email, String password, String? location);
  Future<UserModel> signInWithGoogle();
  Future<void> logout();
  Future<UserModel?> getCurrentUser();
  Future<void> sendPasswordResetEmail(String email);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;
  final GoogleSignIn googleSignIn;

  AuthRemoteDataSourceImpl({
    required this.firebaseAuth,
    required this.firestore,
    required this.googleSignIn,
  });

  @override
  Future<UserModel> login(String email, String password) async {
    try {
      final result = await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        await firestore.collection('users').doc(result.user!.uid).update({
          'currentlyLogin': 'PA',
        });

        final userDoc = await firestore
            .collection('users')
            .doc(result.user!.uid)
            .get();

        if (userDoc.exists) {
          return UserModel.fromFirestore(userDoc.data()!, result.user!.uid);
        } else {
          return UserModel.fromFirebaseUser(result.user!);
        }
      } else {
        throw Exception('Login failed');
      }
    } catch (e) {
      throw Exception(FirebaseErrorHandler.getAuthErrorMessage(e));
    }
  }

  @override
  Future<UserModel> signup(String firstName, String email, String password, String? location) async {
    try {
      final result = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        await result.user!.updateDisplayName(firstName);
        await result.user!.reload();

        String encryptedPassword = encryptValue(password, result.user!.uid);

        final userData = {
          'uid': result.user!.uid,
          'email': email,
          'firstName': firstName,
          'location': location,
          'createdAt': FieldValue.serverTimestamp(),
          'role': 0,
          'registeredFrom': 'PA',
          'currentlyLogin': 'PA',
          'password': encryptedPassword
        };

        await firestore
            .collection('users')
            .doc(result.user!.uid)
            .set(userData);

        return UserModel.fromSignup(
            uid: result.user!.uid,
            email: email,
            firstName: firstName,
            location: location,
            createdAt: DateTime.now(),
            registeredFrom: 'PA',
            currentlyLogin: 'PA'
        );
      } else {
        throw Exception('Signup failed');
      }
    } catch (e) {
      throw Exception(FirebaseErrorHandler.getAuthErrorMessage(e));
    }
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Sign-in was cancelled');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await firebaseAuth.signInWithCredential(credential);

      if (result.user != null) {
        final user = result.user!;
        final userDoc = await firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          // ✅ Existing user - update currentlyLogin
          await firestore.collection('users').doc(user.uid).update({
            'currentlyLogin': 'PA',
          });

          return UserModel.fromFirestore(userDoc.data()!, user.uid);
        } else {
          // ✅ New Google user - create profile
          final userData = {
            'uid': user.uid,
            'email': user.email ?? '',
            'firstName': user.displayName ?? 'Google User',
            'location': null,
            'createdAt': FieldValue.serverTimestamp(),
            'role': 0,
            'registeredFrom': 'PA',
            'currentlyLogin': 'PA',
          };

          await firestore.collection('users').doc(user.uid).set(userData);

          return UserModel.fromSignup(
              uid: user.uid,
              email: user.email ?? '',
              firstName: user.displayName ?? 'Google User',
              location: null,
              createdAt: DateTime.now(),
              registeredFrom: 'PA',
              currentlyLogin: 'PA'
          );
        }
      } else {
        throw Exception('Google Sign In failed');
      }
    } on FirebaseAuthException catch (e) {
      // ✅ Better error handling
      if (e.code == 'account-exists-with-different-credential') {
        throw Exception('An account already exists with this email. Please login with your password first.');
      }
      throw Exception(FirebaseErrorHandler.getAuthErrorMessage(e));
    } catch (e) {
      throw Exception(FirebaseErrorHandler.getAuthErrorMessage(e));
    }
  }

  @override
  Future<void> logout() async {
    try {
      await googleSignIn.signOut();
      await firebaseAuth.signOut();
    } catch (e) {
      throw Exception(FirebaseErrorHandler.getAuthErrorMessage(e));
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = firebaseAuth.currentUser;
      if (user != null) {
        final userDoc = await firestore
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          return UserModel.fromFirestore(userDoc.data()!, user.uid);
        } else {
          return UserModel.fromFirebaseUser(user);
        }
      }
      return null;
    } catch (e) {
      throw Exception(FirebaseErrorHandler.getFirestoreErrorMessage(e));
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await firebaseAuth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception(FirebaseErrorHandler.getAuthErrorMessage(e));
    }
  }

  /// Encrypt a value using AES-256
  String encryptValue(String value, String keyString) {
    final key = Key.fromUtf8(keyString.padRight(32, '0').substring(0, 32));
    final iv = IV.fromLength(16); // 16-byte IV
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));

    final encrypted = encrypter.encrypt(value, iv: iv);
    return encrypted.base64;
  }

  /// Decrypt a value using AES-256
  String decryptValue(String encryptedValue, String keyString) {
    final key = Key.fromUtf8(keyString.padRight(32, '0').substring(0, 32));
    final iv = IV.fromLength(16); // must be same as used in encryption
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));

    final decrypted = encrypter.decrypt64(encryptedValue, iv: iv);
    return decrypted;
  }
}
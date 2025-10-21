// lib/core/utils/firebase_error_handler.dart
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseErrorHandler {
  static String getAuthErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
      // Login errors
        case 'user-not-found':
          return 'No user found with this email address';
        case 'wrong-password':
          return 'Incorrect password. Please try again';
        case 'invalid-email':
          return 'Invalid email address format';
        case 'user-disabled':
          return 'This account has been disabled';
        case 'too-many-requests':
          return 'Too many failed attempts. Please try again later';
        case 'invalid-credential':
          return 'Invalid email or password';

      // Signup errors
        case 'email-already-in-use':
          return 'An account already exists with this email';
        case 'weak-password':
          return 'Password is too weak. Use at least 6 characters';
        case 'operation-not-allowed':
          return 'Email/password accounts are not enabled';

      // Google Sign In errors
        case 'account-exists-with-different-credential':
          return 'An account already exists with a different sign-in method';
        case 'popup-closed-by-user':
          return 'Sign-in popup was closed';
        case 'cancelled-popup-request':
          return 'Sign-in was cancelled';

      // Network errors
        case 'network-request-failed':
          return 'Network error. Please check your internet connection';

        default:
          return 'Authentication failed. Please try again';
      }
    } else if (error.toString().contains('cancelled')) {
      return 'Sign-in was cancelled';
    } else if (error.toString().contains('network')) {
      return 'Network error. Please check your internet connection';
    } else {
      return 'An unexpected error occurred. Please try again';
    }
  }

  static String getFirestoreErrorMessage(dynamic error) {
    if (error.toString().contains('permission-denied')) {
      return 'You do not have permission to perform this action';
    } else if (error.toString().contains('not-found')) {
      return 'Requested data not found';
    } else if (error.toString().contains('network')) {
      return 'Network error. Please check your internet connection';
    } else {
      return 'An error occurred. Please try again';
    }
  }
}
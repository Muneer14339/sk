import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'exceptions.dart';

abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure(this.message, {this.code});

  @override
  List<Object?> get props => [message, code];

  @override
  String toString() => 'Failure(message: $message, code: $code)';
}

// General failures
class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.code});
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class ValidationFailure extends Failure {
  final Map<String, List<String>>? errors;

  const ValidationFailure(super.message, {this.errors});

  @override
  List<Object?> get props => [message, errors];
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'Unauthorized']);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Not Found']);
}

class FirebaseFailure extends Failure {
  const FirebaseFailure(super.message, {super.code});
}

// Extension to convert exceptions to failures
extension ExceptionToFailure on Exception {
  Failure toFailure() {
    if (this is ServerException) {
      return ServerFailure(
        (this as ServerException).message,
        code: (this as ServerException).statusCode.toString(),
      );
    } else if (this is CacheException) {
      return CacheFailure((this as CacheException).message);
    } else if (this is NetworkException) {
      return NetworkFailure((this as NetworkException).message);
    } else if (this is ValidationException) {
      return ValidationFailure(
        (this as ValidationException).message,
        errors: (this as ValidationException).errors,
      );
    } else if (this is UnauthorizedException) {
      return const UnauthorizedFailure();
    } else if (this is NotFoundException) {
      return const NotFoundFailure();
    } else if (this is FirebaseException) {
      final e = this as FirebaseException;
      return FirebaseFailure(
        e.message ?? 'Something went wrong with Firebase',
        code: e.code,
      );
    } else {
      return ServerFailure(toString());
    }
  }
}
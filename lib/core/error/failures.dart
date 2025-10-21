import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  const Failure();

  @override
  List<Object> get props => [];
}

class AuthFailure extends Failure {
  final String message;
  const AuthFailure(this.message);

  @override
  List<Object> get props => [message];

  @override
  String toString() => message;
}

class ValidationFailure extends Failure {
  final String message;
  const ValidationFailure(this.message);

  @override
  List<Object> get props => [message];

  @override
  String toString() => message;
}

class FileFailure extends Failure {
  final String message;
  const FileFailure(this.message);

  @override
  List<Object> get props => [message];

  @override
  String toString() => message;
}

import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class CheckAuthStatusEvent extends AuthEvent {}

class SignInWithEmailAndPasswordEvent extends AuthEvent {
  final String email;
  final String password;

  const SignInWithEmailAndPasswordEvent({
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [email, password];
}

class SignUpWithEmailAndPasswordEvent extends AuthEvent {
  final String email;
  final String password;
  final String displayName;

  const SignUpWithEmailAndPasswordEvent({
    required this.email,
    required this.password,
    required this.displayName,
  });

  @override
  List<Object> get props => [email, password, displayName];
}

class SignInWithGoogle extends AuthEvent {}

class SignInWithApple extends AuthEvent {}

class SignOutEvent extends AuthEvent {}

class ForgotPassword extends AuthEvent {
  final String email;

  const ForgotPassword(this.email);

  @override
  List<Object> get props => [email];
}

class UpdateProfile extends AuthEvent {
  final String? displayName;
  final String? photoUrl;

  const UpdateProfile({
    this.displayName,
    this.photoUrl,
  });

  @override
  List<Object> get props => [displayName ?? '', photoUrl ?? ''];
}

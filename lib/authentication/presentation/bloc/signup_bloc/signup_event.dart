import 'package:equatable/equatable.dart';

abstract class SignupEvent extends Equatable {
  const SignupEvent();

  @override
  List<Object?> get props => [];
}

class SignupRequested extends SignupEvent {
  final String firstName;
  final String email;
  final String password;
  final String? location;

  const SignupRequested({
    required this.firstName,
    required this.email,
    required this.password,
    this.location,
  });

  @override
  List<Object?> get props => [firstName, email, password, location];
}

class GoogleSignUpRequested extends SignupEvent { // NEW
  const GoogleSignUpRequested();
}
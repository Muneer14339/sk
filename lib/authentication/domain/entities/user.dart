import 'package:equatable/equatable.dart';

// domain/entities/user.dart
class User extends Equatable {
  final String uid;
  final String email;
  final String firstName;
  final String? location;
  final DateTime createdAt;
  final int role;
  final String? registeredFrom; // NEW
  final String? currentlyLogin; // NEW

  const User({
    required this.uid,
    required this.email,
    required this.firstName,
    this.location,
    required this.role,
    required this.createdAt,
    this.registeredFrom,
    this.currentlyLogin,
  });

  @override
  List<Object?> get props =>
      [uid, email, firstName, location, createdAt, role, registeredFrom, currentlyLogin];
}

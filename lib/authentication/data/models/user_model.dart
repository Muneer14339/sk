import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user.dart';

// data/models/user_model.dart
class UserModel extends User {
  const UserModel({
    required super.uid,
    required super.email,
    required super.firstName,
    super.location,
    required super.createdAt,
    super.role = 0,
    super.registeredFrom,
    super.currentlyLogin,
  });

  factory UserModel.fromFirebaseUser(firebase.User firebaseUser) {
    return UserModel(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      firstName: firebaseUser.displayName ?? '',
      location: null,
      createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
      role: 0,
      registeredFrom: null,
      currentlyLogin: null,
    );
  }

  factory UserModel.fromSignup({
    required String uid,
    required String email,
    required String firstName,
    String? location,
    required DateTime createdAt,
    String? registeredFrom,
    String? currentlyLogin
  }) {
    return UserModel(
      uid: uid,
      email: email,
      firstName: firstName,
      location: location,
      createdAt: createdAt,
      role: 0,
      registeredFrom: registeredFrom,
      currentlyLogin: currentlyLogin,
    );
  }

  factory UserModel.fromFirestore(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      email: data['email'] ?? '',
      firstName: data['firstName'] ?? '',
      location: data['location'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      role: data['role'] ?? 0,
      registeredFrom: data['registeredFrom'],
      currentlyLogin: data['currentlyLogin'],
    );
  }
}

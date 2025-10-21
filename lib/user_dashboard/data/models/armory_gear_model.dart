// lib/user_dashboard/data/models/armory_gear_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/armory_gear.dart';

class ArmoryGearModel extends ArmoryGear {
  const ArmoryGearModel({
    super.id,
    required super.category,
    required super.model,
    super.serial,
    super.quantity = 1,
    super.notes,
    required super.dateAdded,
  });

  factory ArmoryGearModel.fromMap(Map<String, dynamic> map, String id) {
    return ArmoryGearModel(
      id: id,
      category: map['category'] ?? '',
      model: map['model'] ?? '',
      serial: map['serial'],
      quantity: map['quantity'] ?? 1,
      notes: map['notes'],
      dateAdded: (map['dateAdded'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'model': model,
      'serial': serial,
      'quantity': quantity,
      'notes': notes,
      'dateAdded': Timestamp.fromDate(dateAdded),
    };
  }
}
// lib/user_dashboard/data/models/armory_gear_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/armory_gear.dart';

class ArmoryGearModel extends ArmoryGear {
   ArmoryGearModel({
    super.id,
    required super.category,
    required super.model,
    super.serial,
    super.quantity = 1,
    super.notes,
    required super.dateAdded,
  });

  factory ArmoryGearModel.fromMap(Map<String, dynamic> map, String id) {
           DateTime? safeToDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    if (value is DateTime) return value;
    return null;
  }
    return ArmoryGearModel(
      id: id,
      category: map['category'] ?? '',
      model: map['model'] ?? '',
      serial: map['serial'],
      quantity: map['quantity'] ?? 1,
      notes: map['notes'],
      dateAdded: safeToDate(map['dateAdded']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'model': model,
      'serial': serial,
      'quantity': quantity,
      'notes': notes,
      'dateAdded': DateTime.now().millisecondsSinceEpoch,
    };
  }
}
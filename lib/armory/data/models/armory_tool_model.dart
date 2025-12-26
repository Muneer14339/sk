// lib/user_dashboard/data/models/armory_tool_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/armory_tool.dart';

class ArmoryToolModel extends ArmoryTool {
   ArmoryToolModel({
    super.id,
    required super.name,
    super.category,
    super.quantity = 1,
    super.status = 'available',
    super.notes,
    required super.dateAdded,
  });

  factory ArmoryToolModel.fromMap(Map<String, dynamic> map, String id) {
     DateTime? safeToDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      if (value is DateTime) return value;
      return null;
    }
    return ArmoryToolModel(
      id: id,
      name: map['name'] ?? '',
      category: map['category'],
      quantity: map['quantity'] ?? 1,
      status: map['status'] ?? 'available',
      notes: map['notes'],
      dateAdded: safeToDate(map['dateAdded']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'quantity': quantity,
      'status': status,
      'notes': notes,
      'dateAdded':dateAdded.millisecondsSinceEpoch,
    };
  }
}

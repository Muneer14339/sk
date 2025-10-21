// lib/user_dashboard/data/models/armory_tool_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/armory_tool.dart';

class ArmoryToolModel extends ArmoryTool {
  const ArmoryToolModel({
    super.id,
    required super.name,
    super.category,
    super.quantity = 1,
    super.status = 'available',
    super.notes,
    required super.dateAdded,
  });

  factory ArmoryToolModel.fromMap(Map<String, dynamic> map, String id) {
    return ArmoryToolModel(
      id: id,
      name: map['name'] ?? '',
      category: map['category'],
      quantity: map['quantity'] ?? 1,
      status: map['status'] ?? 'available',
      notes: map['notes'],
      dateAdded: (map['dateAdded'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'quantity': quantity,
      'status': status,
      'notes': notes,
      'dateAdded': Timestamp.fromDate(dateAdded),
    };
  }
}

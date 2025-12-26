import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/armory_loadout.dart';

class ArmoryLoadoutModel extends ArmoryLoadout {
  const ArmoryLoadoutModel({
    super.id,
    required super.name,
    super.firearmId,
    super.ammunitionId,
    super.gearIds = const [],
    super.toolIds = const [],
    super.maintenanceIds = const [],
    super.notes,
    required super.dateAdded,
  });

  factory ArmoryLoadoutModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime? safeToDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      if (value is DateTime) return value;
      return null;
    }

    // Helper to parse list from JSON string or existing list
    List<String> safeToList(dynamic value) {
      if (value == null) return [];
      if (value is List) return List<String>.from(value);
      if (value is String) {
        try {
          final list = jsonDecode(value) as List;
          return List<String>.from(list);
        } catch (e) {
          return [];
        }
      }
      return [];
    }

    return ArmoryLoadoutModel(
      id: id,
      name: map['name'] ?? '',
      firearmId: map['firearmId'],
      ammunitionId: map['ammunitionId'],
      gearIds: safeToList(map['gearIds']),
      toolIds: safeToList(map['toolIds']),
      maintenanceIds: safeToList(map['maintenanceIds']),
      notes: map['notes'],
      dateAdded: safeToDate(map['dateAdded']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'firearmId': firearmId,
      'ammunitionId': ammunitionId,
      'gearIds': jsonEncode(gearIds), // Convert list to JSON string
      'toolIds': jsonEncode(toolIds), // Convert list to JSON string
      'maintenanceIds': jsonEncode(maintenanceIds), // Convert list to JSON string
      'notes': notes,
      'dateAdded': dateAdded.millisecondsSinceEpoch,
    };
  }

  // Additional method for Firestore (if needed)
  Map<String, dynamic> toFirestoreMap() {
    return {
      'name': name,
      'firearmId': firearmId,
      'ammunitionId': ammunitionId,
      'gearIds': gearIds, // Firestore supports arrays directly
      'toolIds': toolIds,
      'maintenanceIds': maintenanceIds,
      'notes': notes,
      'dateAdded': Timestamp.fromDate(dateAdded),
    };
  }
}
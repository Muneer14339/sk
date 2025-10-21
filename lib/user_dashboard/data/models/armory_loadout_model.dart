import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/armory_loadout.dart';
// lib/user_dashboard/data/models/armory_loadout_model.dart
class ArmoryLoadoutModel extends ArmoryLoadout {
  const ArmoryLoadoutModel({
    super.id,
    required super.name,
    super.firearmId,
    super.ammunitionId,
    super.gearIds = const [],
    super.notes,
    required super.dateAdded,
  });

  factory ArmoryLoadoutModel.fromMap(Map<String, dynamic> map, String id) {
    return ArmoryLoadoutModel(
      id: id,
      name: map['name'] ?? '',
      firearmId: map['firearmId'],
      ammunitionId: map['ammunitionId'],
      gearIds: List<String>.from(map['gearIds'] ?? []),
      notes: map['notes'],
      dateAdded: (map['dateAdded'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'firearmId': firearmId,
      'ammunitionId': ammunitionId,
      'gearIds': gearIds,
      'notes': notes,
      'dateAdded': Timestamp.fromDate(dateAdded),
    };
  }
}
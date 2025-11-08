import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/armory_maintenance.dart';

class ArmoryMaintenanceModel extends ArmoryMaintenance {
  ArmoryMaintenanceModel({
    super.id,
    required super.assetType,
    required super.assetId,
    required super.maintenanceType,
    required super.date,
    super.roundsFired,
    super.notes,
    required super.dateAdded,
  });

  factory ArmoryMaintenanceModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime? safeToDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      if (value is String) return DateTime.tryParse(value);
      if (value is DateTime) return value;
      return null;
    }

    return ArmoryMaintenanceModel(
      id: id,
      assetType: map['assetType'] ?? '',
      assetId: map['assetId'] ?? '',
      maintenanceType: map['maintenanceType'] ?? '',
      date: safeToDate(map['date']) ?? DateTime.now(),
      roundsFired: map['roundsFired'],
      notes: map['notes'],
      dateAdded: safeToDate(map['dateAdded']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'assetType': assetType,
      'assetId': assetId,
      'maintenanceType': maintenanceType,
      'date': date.millisecondsSinceEpoch,
      'roundsFired': roundsFired,
      'notes': notes,
      'dateAdded': dateAdded.millisecondsSinceEpoch,
    };
  }
}
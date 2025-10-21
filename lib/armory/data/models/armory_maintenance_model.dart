// lib/user_dashboard/data/models/armory_maintenance_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/armory_maintenance.dart';

class ArmoryMaintenanceModel extends ArmoryMaintenance {
  const ArmoryMaintenanceModel({
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
    return ArmoryMaintenanceModel(
      id: id,
      assetType: map['assetType'] ?? '',
      assetId: map['assetId'] ?? '',
      maintenanceType: map['maintenanceType'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      roundsFired: map['roundsFired'],
      notes: map['notes'],
      dateAdded: (map['dateAdded'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'assetType': assetType,
      'assetId': assetId,
      'maintenanceType': maintenanceType,
      'date': Timestamp.fromDate(date),
      'roundsFired': roundsFired,
      'notes': notes,
      'dateAdded': Timestamp.fromDate(dateAdded),
    };
  }
}
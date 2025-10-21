// lib/user_dashboard/domain/entities/armory_maintenance.dart
import 'package:equatable/equatable.dart';

class ArmoryMaintenance extends Equatable {
  final String? id;
  final String assetType; // 'firearm' or 'gear'
  final String assetId;
  final String maintenanceType; // 'cleaning', 'lubrication', etc.
  final DateTime date;
  final int? roundsFired;
  final String? notes;
  final DateTime dateAdded;

  const ArmoryMaintenance({
    this.id,
    required this.assetType,
    required this.assetId,
    required this.maintenanceType,
    required this.date,
    this.roundsFired,
    this.notes,
    required this.dateAdded,
  });

  @override
  List<Object?> get props => [id, assetType, assetId, maintenanceType, date, roundsFired, notes, dateAdded];
}
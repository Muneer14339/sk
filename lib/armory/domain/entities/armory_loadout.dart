// lib/user_dashboard/domain/entities/armory_loadout.dart
import 'package:equatable/equatable.dart';

// lib/armory/domain/entities/armory_loadout.dart
class ArmoryLoadout extends Equatable {
  final String? id;
  final String name;
  final String? firearmId;
  final String? ammunitionId;
  final List<String> gearIds;
  final List<String> toolIds;        // ADD
  final List<String> maintenanceIds; // ADD
  final String? notes;
  final DateTime dateAdded;

  const ArmoryLoadout({
    this.id,
    required this.name,
    this.firearmId,
    this.ammunitionId,
    this.gearIds = const [],
    this.toolIds = const [],        // ADD
    this.maintenanceIds = const [], // ADD
    this.notes,
    required this.dateAdded,
  });

  @override
  List<Object?> get props => [id, name, firearmId, ammunitionId, gearIds, toolIds, maintenanceIds, notes, dateAdded];
}
// lib/user_dashboard/domain/entities/armory_loadout.dart
import 'package:equatable/equatable.dart';

class ArmoryLoadout extends Equatable {
  final String? id;
  final String name;
  final String? firearmId;
  final String? ammunitionId;
  final List<String> gearIds;
  final String? notes;
  final DateTime dateAdded;

  const ArmoryLoadout({
    this.id,
    required this.name,
    this.firearmId,
    this.ammunitionId,
    this.gearIds = const [],
    this.notes,
    required this.dateAdded,
  });

  @override
  List<Object?> get props => [id, name, firearmId, ammunitionId, gearIds, notes, dateAdded];
}
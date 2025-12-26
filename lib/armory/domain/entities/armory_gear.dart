// lib/user_dashboard/domain/entities/armory_gear.dart
import 'package:equatable/equatable.dart';

class ArmoryGear extends Equatable {
   String? id;
  final String category;
  final String model;
  final String? serial;
  final int quantity;
  final String? notes;
  final DateTime dateAdded;

   ArmoryGear({
    this.id,
    required this.category,
    required this.model,
    this.serial,
    this.quantity = 1,
    this.notes,
    required this.dateAdded,
  });

  @override
  List<Object?> get props => [id, category, model, serial, quantity, notes, dateAdded];
}
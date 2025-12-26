// lib/user_dashboard/domain/entities/armory_tool.dart
import 'package:equatable/equatable.dart';

class ArmoryTool extends Equatable {
   String? id;
  final String name;
  final String? category;
  final int quantity;
  final String status;
  final String? notes;
  final DateTime dateAdded;

   ArmoryTool({
    this.id,
    required this.name,
    this.category,
    this.quantity = 1,
    this.status = 'available',
    this.notes,
    required this.dateAdded,
  });

  @override
  List<Object?> get props => [id, name, category, quantity, status, notes, dateAdded];
}
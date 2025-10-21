// lib/user_dashboard/domain/entities/dropdown_option.dart
import 'package:equatable/equatable.dart';

class DropdownOption extends Equatable {
  final String value;
  final String label;

  const DropdownOption({
    required this.value,
    required this.label,
  });

  @override
  List<Object> get props => [value, label];
}
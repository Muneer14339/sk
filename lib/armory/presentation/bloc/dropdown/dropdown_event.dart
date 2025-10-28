// dropdown_event.dart
import 'package:equatable/equatable.dart';

import '../../../../core/usecases/usecase.dart';


abstract class DropdownEvent extends Equatable {
  const DropdownEvent();

  @override
  List<Object?> get props => [];
}

class LoadDropdownEvent extends DropdownEvent {
  final String key; // unique key for each dropdown
  final DropdownType type;
  final String? filterValue;

  const LoadDropdownEvent({
    required this.key,
    required this.type,
    this.filterValue,
  });

  @override
  List<Object?> get props => [key, type, filterValue];
}

class ClearDropdownEvent extends DropdownEvent {
  final String key;

  const ClearDropdownEvent({required this.key});

  @override
  List<Object?> get props => [key];
}

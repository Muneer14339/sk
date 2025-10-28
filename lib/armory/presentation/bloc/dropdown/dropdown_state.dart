// dropdown_state.dart
import 'package:equatable/equatable.dart';

import '../../../domain/entities/dropdown_option.dart';

abstract class DropdownState extends Equatable {
  const DropdownState();

  @override
  List<Object?> get props => [];
}

class DropdownInitial extends DropdownState {
  const DropdownInitial();
}

class DropdownLoading extends DropdownState {
  final String loadingKey; // To identify which dropdown is loading

  const DropdownLoading({required this.loadingKey});

  @override
  List<Object?> get props => [loadingKey];
}

class DropdownLoaded extends DropdownState {
  final String key; // Which dropdown (caliber, brand, etc.)
  final List<DropdownOption> options;

  const DropdownLoaded({
    required this.key,
    required this.options,
  });

  @override
  List<Object?> get props => [key, options];
}

class DropdownError extends DropdownState {
  final String message;
  final String key;

  const DropdownError({
    required this.message,
    required this.key,
  });

  @override
  List<Object?> get props => [message, key];
}

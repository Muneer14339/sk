// lib/features/training/presentation/bloc/sensitivity_settings/counter_sens_event.dart
part of 'counter_sens_bloc.dart';

abstract class CounterSensEvent {}

class SetInitialValues extends CounterSensEvent {
  final int pfi, ppf, pwd, spi, avt, avdt;
  final bool hapticEnabled;
  final bool useCustomHaptic;
  final Map<int, int> customHapticValues;
  final TraceDisplayMode traceDisplayMode; // ✅ CHANGED

  SetInitialValues(
      this.pfi,
      this.ppf,
      this.pwd,
      this.spi,
      this.avt,
      this.avdt,
      this.hapticEnabled,
      this.useCustomHaptic,
      this.customHapticValues,
      this.traceDisplayMode, // ✅ CHANGED
      );
}

class ToggleHaptic extends CounterSensEvent {}
class ToggleTraceDisplay extends CounterSensEvent {} // ✅ CHANGED: renamed
class ToggleCustomHaptic extends CounterSensEvent {}
class UpdateCustomHapticValue extends CounterSensEvent {
  final int ring;
  final int value;
  UpdateCustomHapticValue(this.ring, this.value);
}

// ... existing events remain same

class IncrementPfi extends CounterSensEvent {}

class DecrementPfi extends CounterSensEvent {}

class IncrementPpf extends CounterSensEvent {}

class DecrementPpf extends CounterSensEvent {}

class IncrementPwd extends CounterSensEvent {}

class DecrementPwd extends CounterSensEvent {}

class IncrementSpi extends CounterSensEvent {}

class DecrementSpi extends CounterSensEvent {}

class IncrementAvt extends CounterSensEvent {}

class DecrementAvt extends CounterSensEvent {}

class IncrementAvdt extends CounterSensEvent {}

class DecrementAvdt extends CounterSensEvent {}

class IncrementHaptic extends CounterSensEvent {}

class DecrementHaptic extends CounterSensEvent {}

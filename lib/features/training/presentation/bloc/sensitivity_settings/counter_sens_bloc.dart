// lib/features/training/presentation/bloc/sensitivity_settings/counter_sens_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';

part 'counter_sens_event.dart';
part 'counter_sens_state.dart';

class CounterSensBloc extends Bloc<CounterSensEvent, CounterSensState> {
  CounterSensBloc() : super(CounterSensState.initial()) {
    on<SetInitialValues>((event, emit) {
      emit(CounterSensState(
        pfi: event.pfi,
        ppf: event.ppf,
        pwd: event.pwd,
        spi: event.spi,
        avt: event.avt,
        avdt: event.avdt,
        hapticEnabled: event.hapticEnabled,
        useCustomHaptic: event.useCustomHaptic,
        customHapticValues: event.customHapticValues,
        traceDisplayMode: event.traceDisplayMode, // ✅ CHANGED
      ));
    });

    on<ToggleHaptic>((event, emit) {
      emit(state.copyWith(hapticEnabled: !state.hapticEnabled));
    });

    // ✅ CHANGED: Cycle through 3 modes
    on<ToggleTraceDisplay>((event, emit) {
      final currentIndex = state.traceDisplayMode.index;
      final nextIndex = (currentIndex + 1) % TraceDisplayMode.values.length;
      emit(state.copyWith(traceDisplayMode: TraceDisplayMode.values[nextIndex]));
    });

    on<ToggleCustomHaptic>((event, emit) {
      emit(state.copyWith(useCustomHaptic: !state.useCustomHaptic));
    });


    on<UpdateCustomHapticValue>((event, emit) {
      final updated = Map<int, int>.from(state.customHapticValues);
      updated[event.ring] = event.value.clamp(1, 10);
      emit(state.copyWith(customHapticValues: updated));
    });

    // ... existing event handlers remain same (IncrementPfi, DecrementPfi, etc.)
    on<IncrementPfi>((event, emit) {
      if (state.pfi < 5) emit(state.copyWith(pfi: state.pfi + 1));
    });
    on<DecrementPfi>((event, emit) {
      if (state.pfi > 1) emit(state.copyWith(pfi: state.pfi - 1));
    });
    on<IncrementPpf>((event, emit) {
      if (state.ppf < 6) emit(state.copyWith(ppf: state.ppf + 1));
    });
    on<DecrementPpf>((event, emit) {
      if (state.ppf > 1) emit(state.copyWith(ppf: state.ppf - 1));
    });
    on<IncrementPwd>((event, emit) {
      if (state.pwd < 6) emit(state.copyWith(pwd: state.pwd + 1));
    });
    on<DecrementPwd>((event, emit) {
      if (state.pwd > 1) emit(state.copyWith(pwd: state.pwd - 1));
    });
    on<IncrementSpi>((event, emit) {
      if (state.spi < 5) emit(state.copyWith(spi: state.spi + 1));
    });
    on<DecrementSpi>((event, emit) {
      if (state.spi > 1) emit(state.copyWith(spi: state.spi - 1));
    });
    on<IncrementAvt>((event, emit) {
      if (state.avt < 11) emit(state.copyWith(avt: state.avt + 1));
    });
    on<DecrementAvt>((event, emit) {
      if (state.avt > 1) emit(state.copyWith(avt: state.avt - 1));
    });
    on<IncrementAvdt>((event, emit) {
      if (state.avdt < 8) emit(state.copyWith(avdt: state.avdt + 1));
    });
    on<DecrementAvdt>((event, emit) {
      if (state.avdt > 0) emit(state.copyWith(avdt: state.avdt - 1));
    });
  }
}
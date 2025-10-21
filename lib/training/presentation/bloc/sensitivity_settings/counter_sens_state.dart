part of 'counter_sens_bloc.dart';

// ✅ NEW: 3 display modes
enum TraceDisplayMode {
  tracelineAndDot,  // 0 - Full display
  dotOnly,          // 1 - Just dot, no traceline
  hidden,           // 2 - Nothing visible
}

class CounterSensState {
  final int pfi, ppf, pwd, spi, avt, avdt;
  final bool hapticEnabled;
  final bool useCustomHaptic;
  final Map<int, int> customHapticValues;
  final TraceDisplayMode traceDisplayMode; // ✅ CHANGED: from bool to enum

  const CounterSensState({
    required this.pfi,
    required this.ppf,
    required this.pwd,
    required this.spi,
    required this.avt,
    required this.avdt,
    required this.hapticEnabled,
    required this.useCustomHaptic,
    required this.customHapticValues,
    required this.traceDisplayMode, // ✅ CHANGED
  });

  factory CounterSensState.initial() => CounterSensState(
    pfi: 5,
    ppf: 4,
    pwd: 1,
    spi: 1,
    avt: 1,
    avdt: 1,
    hapticEnabled: true,
    traceDisplayMode: TraceDisplayMode.tracelineAndDot, // ✅ Default
    useCustomHaptic: false,
    customHapticValues: {10: 0, 9: 0, 8: 1, 7: 1, 6: 1, 5: 1},
  );

  CounterSensState copyWith({
    int? pfi,
    int? ppf,
    int? pwd,
    int? spi,
    int? avt,
    int? avdt,
    bool? hapticEnabled,
    bool? useCustomHaptic,
    Map<int, int>? customHapticValues,
    TraceDisplayMode? traceDisplayMode, // ✅ CHANGED
  }) {
    return CounterSensState(
      pfi: pfi ?? this.pfi,
      ppf: ppf ?? this.ppf,
      pwd: pwd ?? this.pwd,
      spi: spi ?? this.spi,
      avt: avt ?? this.avt,
      avdt: avdt ?? this.avdt,
      hapticEnabled: hapticEnabled ?? this.hapticEnabled,
      useCustomHaptic: useCustomHaptic ?? this.useCustomHaptic,
      customHapticValues: customHapticValues ?? this.customHapticValues,
      traceDisplayMode: traceDisplayMode ?? this.traceDisplayMode, // ✅ CHANGED
    );
  }
}
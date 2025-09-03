part of 'counter_sens_bloc.dart';

class CounterSensState {
  final int pfi;
  final int ppf;
  final int pwd;
  final int spi;
  final int avt;
  final int avdt;

  const CounterSensState({
    required this.pfi,
    required this.ppf,
    required this.pwd,
    required this.spi,
    required this.avt,
    required this.avdt,
  });

  factory CounterSensState.initial() => const CounterSensState(
        pfi: 5,
        ppf: 4,
        pwd: 1,
        spi: 1,
        avt: 1,
        avdt: 1,
      );

  CounterSensState copyWith({
    int? pfi,
    int? ppf,
    int? pwd,
    int? spi,
    int? avt,
    int? avdt,
  }) {
    return CounterSensState(
      pfi: pfi ?? this.pfi,
      ppf: ppf ?? this.ppf,
      pwd: pwd ?? this.pwd,
      spi: spi ?? this.spi,
      avt: avt ?? this.avt,
      avdt: avdt ?? this.avdt,
    );
  }
}

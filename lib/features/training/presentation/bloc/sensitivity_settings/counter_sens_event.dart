part of 'counter_sens_bloc.dart';

abstract class CounterSensEvent {}

class SetInitialValues extends CounterSensEvent {
  final int pfi, ppf, pwd, spi, avt, avdt;

  SetInitialValues(this.pfi, this.ppf, this.pwd, this.spi, this.avt, this.avdt);
}

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

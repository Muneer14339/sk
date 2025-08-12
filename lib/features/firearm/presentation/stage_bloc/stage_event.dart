// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'stage_bloc.dart';

sealed class StageEvent {}

class StageUpdateEvent extends StageEvent {
  final StageEntity stageEntity;

  StageUpdateEvent({required this.stageEntity});
}

class StageRebuildEvent extends StageEvent {
  final StageEntity stageEntity;

  StageRebuildEvent({required this.stageEntity});
}

class FireArmDropDownChangedEvent extends StageEvent {
  FirearmEntity firearmEntity;
  FireArmDropDownChangedEvent({
    required this.firearmEntity,
  });
}

class FireArmDropDownChangedEventGen<T> extends StageEvent {
  T firearmEntity;
  List<T> allItems;
  FireArmDropDownChangedEventGen({
    required this.firearmEntity,
    required this.allItems,
  });
}

final class SelectModeChangedEvent extends StageEvent {
  final String selectedOption;

  SelectModeChangedEvent({required this.selectedOption});
}

final class DrillDropDownChangedEvent extends StageEvent {
  final int id;
  final String selectedVal;

  DrillDropDownChangedEvent({required this.id, required this.selectedVal});
}

class DrillDropDownChangedEventGen<T> extends StageEvent {
  final int id;
  final T selectedVal;

  DrillDropDownChangedEventGen({required this.id, required this.selectedVal});
}

class DistanceChanged extends StageEvent {
  final List<int> selectedDigits;
  final int value;
  final int index;

  DistanceChanged(this.selectedDigits, this.value, this.index);
}

class BeginToEndChangedEvent extends StageEvent {
  final int extractedSeconds;
  final int extracedMilliSeconds;

  BeginToEndChangedEvent(
      {required this.extractedSeconds, required this.extracedMilliSeconds});
}

class LoadFireArms extends StageEvent {}

class AmmoTypeChangedEvent extends StageEvent {
  final AmmoModel ammoModel;

  AmmoTypeChangedEvent({required this.ammoModel});
}

class ForEachShotChangedEvent extends StageEvent {
  final List<int> secondsFirst;
  final List<int> secondsSecond;
  final List<int> millisecondsFirst;
  final List<int> millisecondsSecond;

  ForEachShotChangedEvent(
      {required this.secondsFirst,
      required this.secondsSecond,
      required this.millisecondsFirst,
      required this.millisecondsSecond});
}

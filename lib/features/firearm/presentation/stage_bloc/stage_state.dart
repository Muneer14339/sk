part of 'stage_bloc.dart';

sealed class StageState {}

final class StageInitial extends StageState {}

class FireArmDropDownChangedStateGen extends StageState {
  final FirearmEntity firearmEntity;
  final List<FirearmEntity> brandsList;
  final List<FirearmEntity> modelsList;
  final List<FirearmEntity> generationList;
  final List<FirearmEntity> caliberList;
  final List<FirearmEntity> firingMacList;
  final List<FirearmEntity> ammoTypeList;

  //
  final List<String> brandsListString;
  final List<String> modelsListString;
  final List<String> generationListString;
  final List<String> caliberListString;
  final List<String> firingMacListString;
  final List<String> ammoTypeListString;

  FireArmDropDownChangedStateGen({
    required this.firearmEntity,
    required this.brandsList,
    required this.modelsList,
    required this.generationList,
    required this.caliberList,
    required this.firingMacList,
    required this.ammoTypeList,
    required this.brandsListString,
    required this.modelsListString,
    required this.generationListString,
    required this.caliberListString,
    required this.firingMacListString,
    required this.ammoTypeListString,
  });
}

final class StageUpdatedState extends StageState {
  final StageEntity stageEntity;

  StageUpdatedState({required this.stageEntity});
}

final class StageUpdatedStateGen<T> extends StageState {
  final T stageEntity;
  StageUpdatedStateGen({required this.stageEntity});
}

final class FireArmDropDownChangedState extends StageState {
  final FirearmEntity firearmEntity;

  FireArmDropDownChangedState({required this.firearmEntity});
}

// final class FireArmDropDownChangedStateGen<T> extends StageState {
//   final T firearmEntity;

//   FireArmDropDownChangedStateGen({required this.firearmEntity});
// }

final class SelectModeChangedState extends StageState {
  final String selectedOption;

  SelectModeChangedState({required this.selectedOption});
}

final class SelectModeChangedStateGen<T> extends StageState {
  final T selectedOption;

  SelectModeChangedStateGen({required this.selectedOption});
}

final class DrillDropdownChangedState extends StageState {
  final int id;
  final String selectedVal;

  DrillDropdownChangedState({required this.id, required this.selectedVal});
}

final class DrillDropdownChangedStateGen<T> extends StageState {
  final int id;
  final T selectedVal;

  DrillDropdownChangedStateGen({required this.id, required this.selectedVal});
}

final class DistanceUpdated extends StageState {
  final List<int> selectedDigits;

  DistanceUpdated(this.selectedDigits);
}

final class LoadFireArmsState extends StageState {
  final List<FirearmEntity> firearms;

  LoadFireArmsState({required this.firearms});
}

final class BeginToEndChangedState extends StageState {
  final int extractedSeconds;
  final int extractedMilliSeconds;

  BeginToEndChangedState(
      {required this.extractedSeconds, required this.extractedMilliSeconds});
}

final class ForEachShotChangedState extends StageState {
  final List<int> secondsFirst;
  final List<int> secondsSecond;
  final List<int> millisecondsFirst;
  final List<int> millisecondsSecond;

  ForEachShotChangedState(
      {required this.secondsFirst,
      required this.secondsSecond,
      required this.millisecondsFirst,
      required this.millisecondsSecond});
}

final class AmmoTypeChangedState extends StageState {
  final AmmoModel ammoModel;

  AmmoTypeChangedState({required this.ammoModel});
}

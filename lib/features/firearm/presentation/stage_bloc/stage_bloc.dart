import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pulse_skadi/features/firearm/data/model/ammo_model.dart';
import 'package:pulse_skadi/features/firearm/data/model/firearm_entity.dart';
import 'package:pulse_skadi/features/firearm/data/model/stage_entity.dart';
part 'stage_event.dart';
part 'stage_state.dart';

// @injectable
class StageBloc extends Bloc<StageEvent, StageState> {
  StageBloc() : super(StageInitial()) {
    on<DrillDropDownChangedEventGen>((event, emit) {
      emit(DrillDropdownChangedStateGen(
          id: event.id, selectedVal: event.selectedVal));
    });
    on<StageUpdateEvent>((event, emit) {
      emit(StageUpdatedState(stageEntity: event.stageEntity));
    });

    on<FireArmDropDownChangedEvent>((event, emit) {
      emit(FireArmDropDownChangedState(firearmEntity: event.firearmEntity));
    });

    on<FireArmDropDownChangedEventGen>((event, emit) {
      FirearmEntity firearm = event.firearmEntity;
      List<FirearmEntity> allFireArms = event.allItems as List<FirearmEntity>;

      List<FirearmEntity> brandsList = [];
      List<FirearmEntity> modelsList = [];
      List<FirearmEntity> generationList = [];
      List<FirearmEntity> caliberList = [];
      List<FirearmEntity> firingMacList = [];
      List<FirearmEntity> ammoTypeList = [];

      //
      List<String> brandsListString = [];
      List<String> modelsListString = [];
      List<String> generationListString = [];
      List<String> caliberListString = [];
      List<String> firingMacListString = [];
      List<String> ammoTypeListString = [];

      brandsList = allFireArms.where((e) => e.type == firearm.type).toList();

      brandsList = brandsList.fold<List<FirearmEntity>>([], (prev, element) {
        if (!prev.any((e) => e.brand == element.brand)) {
          prev.add(element);
        }
        return prev;
      });

      // --------------------------------------Values Null Check
      String? model = firearm.model == 'None' ? null : firearm.model;
      String? generation =
          firearm.generation == 'None' ? null : firearm.generation;
      String? caliber = firearm.caliber == 'None' ? null : firearm.caliber;
      String? firingMachanism =
          firearm.firingMachanism == 'None' ? null : firearm.firingMachanism;
      // --------------------------------------

      List<FirearmEntity> filterFireMac(
          List<FirearmEntity> allFireArms, FirearmEntity firearm) {
        List<FirearmEntity> list = [];

        print(
            'passed data - type=${firearm.type}-brand=${firearm.brand}-model=$model-generation=$generation-caliber=$caliber-firingMachanism=$firingMachanism-ammoType=${firearm.ammoType}');

        // Filtering based on conditions
        list = allFireArms
            .where(
              (e) =>
                  (e.type == firearm.type) &&
                  (firearm.brandIsCustom == true || e.brand == firearm.brand) &&
                  (firearm.modelIsCustom == true || e.model == model) &&
                  (firearm.generationIsCustom == true || generation == null
                      ? true
                      : e.generation == generation) &&
                  ((firearm.caliberIsCustom == true) || caliber == null
                      ? true
                      : e.caliber == caliber) &&
                  (firearm.firingMacIsCustom == true || firingMachanism == null
                      ? true
                      : e.firingMachanism == firingMachanism),
            )
            .toList();

        // Ensuring unique firing mechanisms
        return list;
      }

      //----------------------------------------- Models

      if (firearm.brand != null) {
        if (firearm.brandIsCustom == true) {
          modelsList =
              allFireArms.where((e) => (e.type == firearm.type)).toList();
        } else {
          modelsList = allFireArms
              .where(
                  (e) => (e.brand == firearm.brand) && (e.type == firearm.type))
              .toList();
        }
        modelsList = modelsList.fold<List<FirearmEntity>>([], (prev, element) {
          if (!prev.any((e) => e.model == element.model)) {
            prev.add(element);
          }
          return prev;
        });
        for (var element in modelsList) {
          if (element.model != null) {
            modelsListString.add(element.model ?? '');
          }
        }
        if (modelsListString.isEmpty) {
          firearm.model = 'None';
        }
      }

      //----------------------------------------- Generations

      if (firearm.model != null) {
        if (firearm.model == 'None') {
          generationList = allFireArms
              .where((e) =>
                  (e.brand == firearm.brand) &&
                  (e.type == firearm.type) &&
                  (e.model == null))
              .toList();
        } else if (firearm.brandIsCustom == true &&
            firearm.modelIsCustom == true) {
          print('--------------------- generations in both custom');
          generationList =
              allFireArms.where((e) => (e.type == firearm.type)).toList();
        } else if (firearm.brandIsCustom == true) {
          print('--------------------- generations in brand custom');
          generationList = allFireArms
              .where((e) => (e.type == firearm.type) && (e.model == model))
              .toList();
        } else if (firearm.modelIsCustom == true) {
          print('--------------------- generations in model custom');
          generationList = allFireArms
              .where(
                  (e) => (e.brand == firearm.brand) && (e.type == firearm.type))
              .toList();
        } else {
          print('--------------------- generations in else');
          generationList = allFireArms
              .where((e) =>
                  (e.brand == firearm.brand) &&
                  (e.type == firearm.type) &&
                  (e.model == model))
              .toList();
        }
        generationList =
            generationList.fold<List<FirearmEntity>>([], (prev, element) {
          if (!prev.any((e) => e.generation == element.generation)) {
            prev.add(element);
          }
          return prev;
        });
        for (var element in generationList) {
          if (element.generation != null) {
            generationListString.add(element.generation ?? '');
          }
        }
        if (generationListString.isEmpty) {
          firearm.generation = 'None';
        }
        firearm.addedByUser = 0;
      }

      //----------------------------------------- Caliber
      if (firearm.generation != null) {
        if (firearm.generation == 'None') {
          caliberList = allFireArms
              .where((e) => firearm.brandIsCustom == true
                  ? true
                  : (e.brand == firearm.brand) &&
                          (e.type == firearm.type) &&
                          firearm.modelIsCustom == true
                      ? true
                      : (e.model == model) && firearm.brandIsCustom == true
                          ? true
                          : (e.generation == null))
              .toList();
        } else {
          caliberList = filterFireMac(allFireArms, firearm);
        }
        caliberList =
            caliberList.fold<List<FirearmEntity>>([], (prev, element) {
          if (!prev.any((e) => e.caliber == element.caliber)) {
            prev.add(element);
          }
          return prev;
        });
        for (var element in caliberList) {
          if (element.caliber != null) {
            caliberListString.add(element.caliber ?? '');
          }
        }
        if (caliberListString.isEmpty) {
          firearm.caliber = 'None';
        }
      }

      //----------------------------------------- FireingMacanism
      if (firearm.caliber != null) {
        if (firearm.caliber == 'None') {
          firingMacList = allFireArms
              .where((e) =>
                  // (e.brand == firearm.brand) &&
                  // (e.type == firearm.type) &&
                  // (e.model == model) &&
                  // (e.generation == generation) &&
                  // (e.caliber == null))
                  //------------------------------
                  (e.type == firearm.type) &&
                  (firearm.brandIsCustom == true || e.brand == firearm.brand) &&
                  (firearm.modelIsCustom == true || e.model == model) &&
                  (firearm.generationIsCustom == true ||
                      e.generation == generation) &&
                  (firearm.caliberIsCustom == true || e.caliber == null))
              .toList();
        } else {
          firingMacList = filterFireMac(allFireArms, firearm);
        }

        firingMacList =
            firingMacList.fold<List<FirearmEntity>>([], (prev, element) {
          if (!prev.any((e) => e.firingMachanism == element.firingMachanism)) {
            prev.add(element);
          }
          return prev;
        });
        for (var element in firingMacList) {
          if (element.firingMachanism != null) {
            firingMacListString.add(element.firingMachanism ?? '');
          }
        }
        if (firingMacListString.isEmpty) {
          firearm.firingMachanism = 'None';
        }
      }

      //----------------------------------------- ammoType
      if (firearm.firingMachanism != null) {
        if (firearm.firingMachanism == 'None') {
          ammoTypeList = firingMacList
              .where((e) =>
                  (e.type == firearm.type) &&
                  (firearm.brandIsCustom == true || e.brand == firearm.brand) &&
                  (firearm.modelIsCustom == true || e.model == model) &&
                  (firearm.generationIsCustom == true ||
                      e.generation == generation) &&
                  (firearm.caliberIsCustom == true || e.caliber == caliber) &&
                  (firearm.firingMacIsCustom == true ||
                      e.firingMachanism == null))
              .toList();
        } else {
          ammoTypeList = filterFireMac(allFireArms, firearm);
        }

        ammoTypeList =
            ammoTypeList.fold<List<FirearmEntity>>([], (prev, element) {
          if (!prev.any((e) => e.ammoType == element.ammoType)) {
            prev.add(element);
          }
          return prev;
        });
        for (var element in ammoTypeList) {
          if (element.ammoType != null) {
            ammoTypeListString.add(element.ammoType ?? '');
          }
        }
        if (ammoTypeListString.isEmpty) {
          firearm.ammoType = 'None';
        }
      }

      // Emit the state with updated lists and firearm entity
      emit(FireArmDropDownChangedStateGen(
        firearmEntity: firearm,
        brandsList: brandsList,
        modelsList: modelsList,
        generationList: generationList,
        caliberList: caliberList,
        firingMacList: firingMacList,
        ammoTypeList: ammoTypeList,
        brandsListString: brandsListString,
        modelsListString: modelsListString,
        generationListString: generationListString,
        caliberListString: caliberListString,
        firingMacListString: firingMacListString,
        ammoTypeListString: ammoTypeListString,
      ));
    });

    on<SelectModeChangedEvent>((event, emit) {
      log('SelectModeChangedEvent ::');
      emit(SelectModeChangedState(selectedOption: event.selectedOption));
    });

    on<DrillDropDownChangedEvent>((event, emit) {
      log('DrillDropDownChangedEvent ::');
      emit(DrillDropdownChangedState(
          id: event.id, selectedVal: event.selectedVal));
    });

    on<DistanceChanged>((event, emit) {
      log('DistanceChanged ::');
      final selectedDigits = event.selectedDigits;

      selectedDigits[event.index] = event.value;

      if (selectedDigits[0] == 5) {
        // If the first digit is 5, reset the other digits to 0
        selectedDigits[1] = 0;
        selectedDigits[2] = 0;
        selectedDigits[3] = 0;
      }
      print(selectedDigits);
      emit(DistanceUpdated(selectedDigits));
    });

    on<BeginToEndChangedEvent>((event, emit) {
      emit(BeginToEndChangedState(
          extractedSeconds: event.extractedSeconds,
          extractedMilliSeconds: event.extracedMilliSeconds));
    });
    on<ForEachShotChangedEvent>((event, emit) {
      print("ClearParTimeEvent received");
      print(event.secondsFirst);
      emit(ForEachShotChangedState(
        secondsFirst: event.secondsFirst,
        secondsSecond: event.secondsSecond,
        millisecondsFirst: event.millisecondsFirst,
        millisecondsSecond: event.millisecondsSecond,
      ));
    });

    on<AmmoTypeChangedEvent>((event, emit) {
      emit(AmmoTypeChangedState(ammoModel: event.ammoModel));
    });
  }
}

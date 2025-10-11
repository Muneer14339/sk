import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:pulse_skadi/core/constants/app_constants.dart';
import 'package:pulse_skadi/features/firearm/data/local/service/firearm_db_helper.dart';
import 'package:pulse_skadi/features/firearm/data/model/ammo_model.dart';
import 'package:pulse_skadi/features/gear_setup/data/models/gear_setup_model.dart';
import 'package:pulse_skadi/features/firearm/data/model/firearm_entity.dart';
import 'package:pulse_skadi/features/firearm/data/remote/service/firebase_service.dart';

part 'gear_setup_event.dart';
part 'gear_setup_state.dart';

class GearSetupBloc extends Bloc<GearSetupEvent, GearSetupState> {
  GearSetupBloc()
      : super(GearSetupState(
            currentTab: 0,
            // selectedPreset: 'custom',
            selectedPresetIndex: null,
            selectedSights: const {},
            showCustomFirearm: false,
            equipmentProfileSaved: false,
            allFirearms: const [],
            gearSetup: defaultGearSetup ??
                GearSetupModel(
                  name: '',
                  firearm: FirearmEntity(),
                  ammoModel: AmmoModel(),
                ))) {
    on<GearSetupUpdate>((event, emit) {
      emit(state.copyWith(
        gearSetup: event.gearSetup,
      ));
    });
    on<GearSetupTabChanged>((event, emit) {
      emit(state.copyWith(currentTab: event.tabIndex));
    });
    on<GearSetupPresetSelected>((event, emit) {
      emit(state.copyWith(
        selectedPresetIndex: event.presetIndex,
        gearSetup: event.setup,
        showCustomFirearm: event.presetIndex == -2,
      ));
    });
    on<GearSetupSightsChanged>((event, emit) {
      emit(state.copyWith(
        selectedSights: event.sights,
        gearSetup: state.gearSetup.copyWith(sights: event.sights),
      ));
    });
    on<GearSetupFirearmChanged>((event, emit) {
      emit(state.copyWith(
        gearSetup: state.gearSetup.copyWith(firearm: event.setup.firearm),
      ));
    });
    on<GearSetupAmmoChanged>((event, emit) {
      emit(state.copyWith(
        gearSetup: state.gearSetup.copyWith(ammo: event.ammo),
      ));
    });
    on<GearSetupModeChanged>((event, emit) {
      emit(state.copyWith(
        gearSetup: state.gearSetup.copyWith(mode: event.mode),
      ));
    });
    on<GearSetupLocationChanged>((event, emit) {
      emit(state.copyWith(
        gearSetup: state.gearSetup.copyWith(location: event.location),
      ));
    });
    on<GearSetupReset>((event, emit) {
      emit(state.copyWith(
        // selectedPreset: null,
        selectedPresetIndex: null,
        selectedSights: {},
        showCustomFirearm: false,
        equipmentProfileSaved: false,
        isLoadingAllFirearms: false,
        allFirearms: const [],
        gearSetup: GearSetupModel(
          name: '',
          firearm: FirearmEntity(),
          ammo: '',
          mode: '',
          sights: {},
          location: '',
          ammoModel: AmmoModel(),
        ),
      ));
    });

    on<AddFirearmSetup>((event, emit) async {
      emit(state.copyWith(isLoadingSetups: true, setupsError: null));
      try {
        await FirebaseService().addFirearmSetup(gearSetup: event.setupModel);
        emit(state.copyWith(
          firearmSetups: [event.setupModel],
          isLoadingSetups: false,
          setupsError: null,
        ));
      } catch (e) {
        emit(state.copyWith(
          isLoadingSetups: false,
          setupsError: e.toString(),
        ));
      }
    });
    on<LoadFirearmSetups>((event, emit) async {
      emit(state.copyWith(isLoadingSetups: true, setupsError: null));
      try {
        final setups = await FirebaseService().getFirearmSetups();
        int? defaultIndex;
        if (setups.isNotEmpty) {
          for (int i = 0; i < setups.length; i++) {
            // log(setups[i].id.toString());
            // log(defaultGearSetup.firearm.id.toString());
            if (setups[i].id == defaultGearSetup?.id) {
              defaultIndex = i;
              break;
            }
          }
        }
        emit(state.copyWith(
            firearmSetups: setups,
            selectedPresetIndex: defaultIndex,
            isLoadingSetups: false,
            setupsError: null));
      } catch (e) {
        emit(state.copyWith(isLoadingSetups: false, setupsError: e.toString()));
      }
    });

    on<LoadAllFirearms>((event, emit) async {
      emit(state.copyWith(isLoadingAllFirearms: true, setupsError: null));
      try {
        final setups = await FirearmDbHelper().getFirearms('');
        emit(state.copyWith(
          allFirearms: setups,
          isLoadingAllFirearms: false,
          setupsError: null,
        ));
      } catch (e) {
        emit(state.copyWith(
          isLoadingAllFirearms: false,
          setupsError: e.toString(),
        ));
      }
    });

    on<AddEquipmentProfile>((event, emit) async {
      emit(state.copyWith(isSavingEquipmentProfile: true, profilesError: null));
      try {
        await FirebaseService().addEquipmentProfile(gearSetup: event.profile);
        emit(state.copyWith(
          equipmentProfiles: [event.profile],
          isSavingEquipmentProfile: false,
          profilesError: null,
          equipmentProfileSaved: true,
          gearSetup: event.profile,
        ));
      } catch (e) {
        emit(state.copyWith(
          isSavingEquipmentProfile: false,
          profilesError: e.toString(),
        ));
      }
    });

    on<UpdateEquipmentProfile>((event, emit) async {
      emit(state.copyWith(isSavingEquipmentProfile: true, profilesError: null));
      try {
        await FirebaseService()
            .updateEquipmentProfile(gearSetup: event.profile);
        emit(state.copyWith(
          equipmentProfiles: [event.profile],
          isSavingEquipmentProfile: false,
          profilesError: null,
          equipmentProfileSaved: true,
          gearSetup: event.profile,
        ));
      } catch (e) {
        emit(state.copyWith(
          isSavingEquipmentProfile: false,
          profilesError: e.toString(),
        ));
      }
    });

    on<LoadEquipmentProfiles>((event, emit) async {
      emit(state.copyWith(isLoadingProfiles: true, profilesError: null));
      try {
        final profiles = await FirebaseService().getEquipmentProfiles();
        emit(state.copyWith(
          equipmentProfiles: profiles,
          isLoadingProfiles: false,
          profilesError: null,
          gearSetup: profiles.isNotEmpty ? profiles.first : state.gearSetup,
          equipmentProfileSaved: false,
        ));
      } catch (e) {
        emit(state.copyWith(
          isLoadingProfiles: false,
          profilesError: e.toString(),
        ));
      }
    });
  }
}

part of 'gear_setup_bloc.dart';

abstract class GearSetupEvent extends Equatable {
  const GearSetupEvent();
  @override
  List<Object?> get props => [];
}

class GearSetupTabChanged extends GearSetupEvent {
  final int tabIndex;
  const GearSetupTabChanged(this.tabIndex);
  @override
  List<Object?> get props => [tabIndex];
}

class GearSetupPresetSelected extends GearSetupEvent {
  final int presetIndex;
  final GearSetupModel setup;
  const GearSetupPresetSelected(this.presetIndex, this.setup);
  @override
  List<Object?> get props => [presetIndex, setup];
}

class GearSetupSightsChanged extends GearSetupEvent {
  final Set<String> sights;
  const GearSetupSightsChanged(this.sights);
  @override
  List<Object?> get props => [sights];
}

class GearSetupFirearmChanged extends GearSetupEvent {
  final GearSetupModel setup;
  const GearSetupFirearmChanged(this.setup);
  @override
  List<Object?> get props => [setup];
}

class GearSetupAmmoChanged extends GearSetupEvent {
  final String ammo;
  const GearSetupAmmoChanged(this.ammo);
  @override
  List<Object?> get props => [ammo];
}

class GearSetupModeChanged extends GearSetupEvent {
  final String mode;
  const GearSetupModeChanged(this.mode);
  @override
  List<Object?> get props => [mode];
}

class GearSetupLocationChanged extends GearSetupEvent {
  final String location;
  const GearSetupLocationChanged(this.location);
  @override
  List<Object?> get props => [location];
}

class GearSetupReset extends GearSetupEvent {
  const GearSetupReset();
}

class LoadFirearmSetups extends GearSetupEvent {}

class LoadEquipmentProfiles extends GearSetupEvent {
  const LoadEquipmentProfiles();
}

class AddFirearmSetup extends GearSetupEvent {
  final GearSetupModel setupModel;
  const AddFirearmSetup(this.setupModel);
}

class LoadAllFirearms extends GearSetupEvent {
  const LoadAllFirearms();
}

class EquipmentProfilesLoaded extends GearSetupEvent {
  final List<GearSetupModel> profiles;
  const EquipmentProfilesLoaded(this.profiles);
  @override
  List<Object?> get props => [profiles];
}

class AddEquipmentProfile extends GearSetupEvent {
  final GearSetupModel profile;
  const AddEquipmentProfile(this.profile);
}

class UpdateEquipmentProfile extends GearSetupEvent {
  final GearSetupModel profile;
  const UpdateEquipmentProfile(this.profile);
}

class FirearmSetupsLoaded extends GearSetupEvent {
  final List<GearSetupModel> setups;
  const FirearmSetupsLoaded(this.setups);
  @override
  List<Object?> get props => [setups];
}

class FirearmSetupsLoadFailed extends GearSetupEvent {
  final String error;
  const FirearmSetupsLoadFailed(this.error);
  @override
  List<Object?> get props => [error];
}

class GearSetupUpdate extends GearSetupEvent {
  final GearSetupModel gearSetup;
  const GearSetupUpdate(this.gearSetup);
}

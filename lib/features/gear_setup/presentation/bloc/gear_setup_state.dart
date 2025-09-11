part of 'gear_setup_bloc.dart';

class GearSetupState extends Equatable {
  final int currentTab;
  // final String? selectedPreset;
  final int? selectedPresetIndex;
  final Set<String> selectedSights;
  final bool showCustomFirearm;
  final GearSetupModel gearSetup;
  final List<GearSetupModel>? firearmSetups;
  final List<FirearmEntity> allFirearms;
  final bool isLoadingSetups;
  final bool isLoadingAllFirearms;
  final String? setupsError;
  final List<GearSetupModel>? equipmentProfiles;
  final bool isLoadingProfiles;
  final String? profilesError;
  final bool isSavingEquipmentProfile;
  final bool equipmentProfileSaved;

  const GearSetupState({
    required this.currentTab,
    // required this.selectedPreset,
    this.selectedPresetIndex,
    required this.selectedSights,
    required this.showCustomFirearm,
    required this.gearSetup,
    this.firearmSetups,
    this.allFirearms = const [],
    this.isLoadingSetups = false,
    this.isLoadingAllFirearms = false,
    this.setupsError,
    this.equipmentProfiles,
    this.isLoadingProfiles = false,
    this.profilesError,
    this.isSavingEquipmentProfile = false,
    this.equipmentProfileSaved = false,
  });

  GearSetupState copyWith({
    int? currentTab,
    // String? selectedPreset,
    int? selectedPresetIndex,
    Set<String>? selectedSights,
    bool? showCustomFirearm,
    GearSetupModel? gearSetup,
    List<GearSetupModel>? firearmSetups,
    List<FirearmEntity>? allFirearms,
    bool? isLoadingSetups,
    bool? isLoadingAllFirearms,
    String? setupsError,
    List<GearSetupModel>? equipmentProfiles,
    bool? isLoadingProfiles,
    String? profilesError,
    bool? isSavingEquipmentProfile,
    bool? equipmentProfileSaved,
  }) {
    return GearSetupState(
      currentTab: currentTab ?? this.currentTab,
      // selectedPreset: selectedPreset ?? this.selectedPreset,
      selectedPresetIndex: selectedPresetIndex ?? this.selectedPresetIndex,
      selectedSights: selectedSights ?? this.selectedSights,
      showCustomFirearm: showCustomFirearm ?? this.showCustomFirearm,
      gearSetup: gearSetup ?? this.gearSetup,
      firearmSetups: firearmSetups ?? this.firearmSetups,
      allFirearms: allFirearms ?? this.allFirearms,
      isLoadingSetups: isLoadingSetups ?? this.isLoadingSetups,
      isLoadingAllFirearms: isLoadingAllFirearms ?? this.isLoadingAllFirearms,
      setupsError: setupsError ?? this.setupsError,
      equipmentProfiles: equipmentProfiles ?? this.equipmentProfiles,
      isLoadingProfiles: isLoadingProfiles ?? this.isLoadingProfiles,
      profilesError: profilesError ?? this.profilesError,
      isSavingEquipmentProfile:
          isSavingEquipmentProfile ?? this.isSavingEquipmentProfile,
      equipmentProfileSaved:
          equipmentProfileSaved ?? this.equipmentProfileSaved,
    );
  }

  @override
  List<Object?> get props => [
        currentTab,
        // selectedPreset,
        selectedPresetIndex,
        selectedSights,
        showCustomFirearm,
        gearSetup,
        firearmSetups,
        allFirearms,
        isLoadingSetups,
        isLoadingAllFirearms,
        setupsError,
        equipmentProfiles,
        isLoadingProfiles,
        profilesError,
        isSavingEquipmentProfile,
        equipmentProfileSaved,
      ];
}

import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pulse_skadi/core/constants/app_constants.dart';
import 'package:pulse_skadi/core/services/prefs.dart';
import 'package:pulse_skadi/core/theme/app_colors.dart';
import 'package:pulse_skadi/core/utils/dialog_utils.dart';
import 'package:pulse_skadi/core/utils/helper_methods.dart';
import 'package:pulse_skadi/core/utils/toast_utils.dart';
import 'package:pulse_skadi/core/widgets/bottom_sheet_.dart';
import 'package:pulse_skadi/core/widgets/custom_textfield.dart';
import 'package:pulse_skadi/core/widgets/label_widget.dart';
import 'package:pulse_skadi/core/widgets/pa_dropdown.dart';
import 'package:pulse_skadi/core/widgets/primary_button.dart';
import 'package:pulse_skadi/features/firearm/data/model/ammo_model.dart';
import 'package:pulse_skadi/features/firearm/data/model/firearm_entity.dart';
import 'package:pulse_skadi/features/firearm/data/remote/service/firebase_service.dart';
import 'package:pulse_skadi/features/firearm/presentation/stage_bloc/stage_bloc.dart';
import 'package:pulse_skadi/features/gear_setup/data/models/ammunition.dart';
import 'package:pulse_skadi/features/gear_setup/data/models/gear_setup_model.dart';
import 'package:pulse_skadi/features/bottom_nav/presentation/pages/bottom_nav_page.dart';
import 'package:pulse_skadi/features/gear_setup/presentation/bloc/gear_setup_bloc.dart';

class GearSetupPage extends StatefulWidget {
  const GearSetupPage({super.key});

  @override
  State<GearSetupPage> createState() => _GearSetupPageState();
}

class _GearSetupPageState extends State<GearSetupPage>
    with TickerProviderStateMixin {
  final TextEditingController _setupNameController =
      TextEditingController(text: '');
  final TextEditingController _customMakeController = TextEditingController();
  final TextEditingController _customCaliberController =
      TextEditingController();
  final TextEditingController _customBarrelController = TextEditingController();
  final TextEditingController _customAmmoCaliberController =
      TextEditingController();
  final TextEditingController _customAmmoWeightController =
      TextEditingController();
  final TextEditingController _customAmmoTypeController =
      TextEditingController();

  // late AnimationController _progressController;

  final List<String> _tabs = ['Firearm', 'Ammo', 'Mode', 'Sights'];

  List<Ammunition> _ammunitionList = [];

  @override
  void initState() {
    super.initState();
    // _progressController =
    //     AnimationController(duration: const Duration(seconds: 2), vsync: this)
    //       ..repeat();
    context.read<GearSetupBloc>().add(LoadFirearmSetups());
    context.read<GearSetupBloc>().add(LoadEquipmentProfiles());
    context.read<GearSetupBloc>().add(LoadAllFirearms());
    loadAmmunitionData();
  }

  @override
  void dispose() {
    // _progressController.dispose();
    _setupNameController.dispose();
    _customMakeController.dispose();
    _customCaliberController.dispose();
    _customBarrelController.dispose();
    _customAmmoCaliberController.dispose();
    _customAmmoWeightController.dispose();
    _customAmmoTypeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<GearSetupBloc, GearSetupState>(
          builder: (context, state) {
            if (state.gearSetup.name.isNotEmpty) {
              _setupNameController.text = state.gearSetup.name;
            }
            return Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildSetupProgress(state),
                        const SizedBox(height: 20),
                        _buildQuickPresets(state),
                        const SizedBox(height: 20),
                        if (state.selectedPresetIndex == -1) ...[
                          _buildSetupTabs(state),
                          const SizedBox(height: 8),
                          _buildTabContent(state),
                          const SizedBox(height: 20),
                        ],
                        if (state.selectedPresetIndex != -1 &&
                            state.selectedPresetIndex != null)
                          _buildProfileSave(state),
                        const SizedBox(height: 20),
                        _buildTrainingCTA(),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Theme.of(context).primaryColor,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 20),
          const Text(
            'Gear Setup',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          GestureDetector(
            onTap: _showGearHelp,
            child: Container(
              padding: const EdgeInsets.all(8),
              child: const Text(
                '❓',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetupProgress(GearSetupState state) {
    return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF28A745), Color(0xFF20C997)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(children: [
          const Text(
            'Configure Your Equipment',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Set up your gear for optimal AI training performance',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 15),
          Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: index <= state.currentTab
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.3))));
              }))
        ]));
  }

  Widget _buildQuickPresets(GearSetupState state) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              border: Border.all(
                  color: AppColors.borderOutline.withValues(alpha: 0.5)),
              borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('⚡', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text('Quick Setup',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white))
                ],
              ),
              const SizedBox(height: 8),
              Text('Choose a common configuration to get started quickly',
                  style: TextStyle(fontSize: 14, color: Colors.white)),
              const SizedBox(height: 15),
              if (state.isLoadingSetups) LinearProgressIndicator(),
              if (!state.isLoadingSetups)
                Wrap(
                    direction: Axis.horizontal,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      ...List.generate(
                          (state.firearmSetups ?? []).length,
                          (index) => _buildPresetCard(
                              state.firearmSetups![index].firearm.type ==
                                      'Pistol'
                                  ? '🔫'
                                  : state.firearmSetups![index].firearm.type ==
                                          'Rifles'
                                      ? '⌐╦ᡁ᠊╾━'
                                      : '🎯',
                              state.firearmSetups![index].name.isNotEmpty
                                  ? state.firearmSetups![index].name
                                  : state.firearmSetups![index].firearm.brand!,
                              '${state.firearmSetups![index].firearm.model!} + ${state.firearmSetups![index].firearm.caliber} + ${state.firearmSetups![index].firearm.generation ?? ''}',
                              // state.firearmSetups![index].firearm.type == 'Pistol'
                              //     ? 'glock19'
                              //     : state.firearmSetups![index].firearm.type ==
                              //             'Rifles'
                              //         ? 'ar15'
                              //         : 'ruger22',
                              state.firearmSetups![index],
                              state,
                              index)),
                      _buildPresetCard(
                          '⚙️',
                          'Custom',
                          'Build your own',
                          // 'custom',
                          GearSetupModel(
                              name: '',
                              firearm: FirearmEntity(),
                              ammoModel: AmmoModel()),
                          state,
                          -1)
                    ]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPresetCard(
      String icon,
      String name,
      String details,
      // String preset,
      GearSetupModel setup,
      GearSetupState state,
      int presetIndex) {
    final isSelected = state.selectedPresetIndex == presetIndex;

    return GestureDetector(
      onTap: () {
        if (state.currentTab != 0) {
          context.read<GearSetupBloc>().add(GearSetupTabChanged(0));
        }
        if (presetIndex != -1) {
          prefs?.setString(
              AppConstants.gearSetupKey, json.encode(setup.toJson()));
          defaultGearSetup = setup;
        }
        context
            .read<GearSetupBloc>()
            .add(GearSetupPresetSelected(presetIndex, setup));
      },
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            width: 141,
            height: 141,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.kSecondaryColor
                  : AppColors.kPrimaryColor,
              border: Border.all(
                  color: isSelected
                      ? AppColors.kQuaternaryColor
                      : AppColors.kTertiaryColor,
                  width: 2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(icon,
                    style: TextStyle(
                        fontSize: 28,
                        color: isSelected
                            ? AppColors.white
                            : AppColors.kQuaternaryColor)),
                const SizedBox(height: 8),
                Text(
                  name,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? AppColors.white
                          : AppColors.kQuaternaryColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(details,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12,
                        color: isSelected
                            ? AppColors.white
                            : AppColors.kQuaternaryColor),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
          if (name != 'Custom')
            Positioned(
                top: 5,
                left: 5,
                child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: AppColors.kTertiaryColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                        setup.mode == 'dryfire' ? 'Dry Fire' : 'Live Fire',
                        style: TextStyle(
                            fontSize: 12,
                            color: isSelected
                                ? AppColors.white
                                : AppColors.greenColor)))),
          if (name != 'Custom')
            Positioned(
              top: 3,
              right: 3,
              child: GestureDetector(
                onTap: () {
                  DialogUtils.showConfirmationDialog(
                    context: context,
                    title: 'Delete Setup',
                    message: 'Are you sure you want to delete this setup?',
                    confirmText: 'Delete',
                    cancelText: 'Cancel',
                    confirmColor: Colors.red,
                  ).then((value) {
                    if (value) {
                      FirebaseService()
                          .removeFirearmSetup(setupId: setup.id ?? '');
                      if (setup.id == defaultGearSetup?.id) {
                        defaultGearSetup = null;
                        prefs?.remove(AppConstants.gearSetupKey);
                      }
                      context.read<GearSetupBloc>().add(LoadFirearmSetups());
                    }
                  });
                },
                child: CircleAvatar(
                  radius: 10,
                  backgroundColor: Colors.red,
                  child: Icon(Icons.close, color: Colors.white, size: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSetupTabs(GearSetupState state) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: List.generate(_tabs.length, (index) {
          final isActive = state.currentTab == index;
          return Expanded(
              child: GestureDetector(
            onTap: () =>
                context.read<GearSetupBloc>().add(GearSetupTabChanged(index)),
            child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                decoration: BoxDecoration(
                  color: isActive
                      ? Theme.of(context).primaryColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(_tabs[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: isActive
                            ? Colors.white
                            : Theme.of(context).primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500))),
          ));
        }),
      ),
    );
  }

  Widget _buildTabContent(GearSetupState state) {
    switch (state.currentTab) {
      case 0:
        return state.selectedPresetIndex == -1
            ? BlocBuilder<GearSetupBloc, GearSetupState>(
                builder: (context, state) {
                return _buildFirearmCTA(gearSetupState: state);
              })
            : _buildFirearmTab(state);
      case 1:
        return _buildAmmoTab(state);
      case 2:
        return _buildTrainingTab(state);
      case 3:
        return _buildSightsTab(state);
      default:
        return Container();
    }
  }

  Widget _buildFirearmCTA({required GearSetupState gearSetupState}) {
    final firearm = gearSetupState.gearSetup.firearm;
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController notesController =
        TextEditingController(text: firearm.notes);
    final TextEditingController serialNumberController =
        TextEditingController(text: firearm.serialNumber);
    final TextEditingController barrelLengthController =
        TextEditingController(text: firearm.barrelLength);
    final TextEditingController overallLengthController =
        TextEditingController(text: firearm.overallLength);
    final TextEditingController weightController =
        TextEditingController(text: firearm.weight);
    final TextEditingController riflingTwistRateController =
        TextEditingController(text: firearm.riflingTwistRate);
    final TextEditingController capacityController =
        TextEditingController(text: firearm.capacity);
    final TextEditingController sightHeightOverBoreController =
        TextEditingController(text: firearm.sightHeightOverBore);
    final TextEditingController triggerPullWeightController =
        TextEditingController(text: firearm.triggerPullWeight);
    final TextEditingController purchaseDateController =
        TextEditingController(text: firearm.purchaseDate);
    final TextEditingController roundCountController =
        TextEditingController(text: firearm.roundCount);
    final TextEditingController modificationsAttachmentsController =
        TextEditingController(text: firearm.modificationsAttachments);
    List<FirearmEntity> allFireArms = [];
    allFireArms = (gearSetupState.allFirearms).fold<List<FirearmEntity>>([],
        (prev, element) {
      if (!prev.any((e) => e.type == element.type)) {
        prev.add(element);
      }
      return prev;
    });
    return BlocBuilder<StageBloc, StageState>(
      builder: (context, state) {
        return Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LabelWidget(label: 'Firearm Type'),
              PaDropdownGen<FirearmEntity>(
                hint: 'Gun Type',
                items: allFireArms,
                getLabel: (p0) => p0.type ?? '',
                initialValue: firearm,
                showDelIcon: false,
                onDelTap: (p0) {},
                showSearch: true,
                noPadding: true,
                selectItemCall: (value) {
                  firearm.type = value.type ?? 'None';
                  firearm.brand = null;
                  firearm.model = null;
                  firearm.generation = null;
                  firearm.caliber = null;
                  firearm.firingMachanism = null;
                  firearm.ammoType = null;
                  context.read<StageBloc>().add(FireArmDropDownChangedEventGen(
                      allItems: gearSetupState.allFirearms,
                      firearmEntity: firearm));
                },
                selectedValue: (state is FireArmDropDownChangedStateGen)
                    ? state.firearmEntity
                    : firearm,
              ),
              if (firearm.type != null) LabelWidget(label: 'Brand'),
              if (firearm.type != null)
                PaDropdownGen<FirearmEntity>(
                  key: UniqueKey(),
                  isPreviousSelected: firearm.type == null,
                  hint: 'Brand',
                  fieldName: 'brand',
                  items: (state is FireArmDropDownChangedStateGen)
                      ? state.brandsList
                      : [],
                  getLabel: (p0) => p0.brand ?? '',
                  initialValue: firearm,
                  showDelIcon: false,
                  allowCustomItem: true,
                  onDelTap: (p0) {},
                  noPadding: true,
                  itemTapped: (p0) {
                    if (p0) {
                      print('non custom brand');
                      firearm.brandIsCustom = false;
                    }
                  },
                  selectItemCall: (value) {
                    firearm.brand = value.brand ?? 'None';
                    firearm.model = null;
                    firearm.generation = null;
                    firearm.caliber = null;
                    firearm.firingMachanism = null;
                    firearm.ammoType = null;
                    context.read<StageBloc>().add(
                        FireArmDropDownChangedEventGen(
                            allItems: gearSetupState.allFirearms,
                            firearmEntity: firearm));
                  },
                  selectedValue: (state is FireArmDropDownChangedStateGen)
                      ? state.firearmEntity
                      : firearm,
                ),
              if (firearm.brand != null) LabelWidget(label: 'Model'),
              if (firearm.brand != null)
                PaDropdownGen<FirearmEntity>(
                    key: UniqueKey(),
                    isPreviousSelected: firearm.brand == null,
                    hint: 'Model',
                    fieldName: 'model',
                    allowCustomItem: true,
                    items: (state is FireArmDropDownChangedStateGen)
                        ? state.modelsListString.isEmpty
                            ? []
                            : state.modelsList
                        : [],
                    getLabel: (p0) => p0.model ?? '',
                    initialValue: firearm,
                    showDelIcon: false,
                    onDelTap: (p0) {},
                    noPadding: true,
                    itemTapped: (p0) {
                      if (p0) {
                        print('non custom model');
                        firearm.modelIsCustom = false;
                      }
                    },
                    selectItemCall: (value) {
                      firearm.model = value.model ?? 'None';
                      firearm.generation = null;
                      firearm.caliber = null;
                      firearm.firingMachanism = null;
                      firearm.ammoType = null;
                      context.read<StageBloc>().add(
                          FireArmDropDownChangedEventGen(
                              allItems: gearSetupState.allFirearms,
                              firearmEntity: firearm));
                    },
                    selectedValue: (state is FireArmDropDownChangedStateGen)
                        ? state.firearmEntity
                        : firearm),
              if (firearm.model != null) LabelWidget(label: 'Generation'),
              if (firearm.model != null)
                PaDropdownGen<FirearmEntity>(
                  key: UniqueKey(),
                  isPreviousSelected: firearm.model == null,
                  hint: 'Generation',
                  fieldName: 'generation',
                  allowCustomItem: true,
                  items: (state is FireArmDropDownChangedStateGen)
                      ? state.generationListString.isEmpty
                          ? []
                          : state.generationList
                      : [],
                  getLabel: (p0) => p0.generation ?? '',
                  initialValue: firearm,
                  showDelIcon: false,
                  onDelTap: (p0) {},
                  noPadding: true,
                  itemTapped: (p0) {
                    if (p0) {
                      print('non custom generation');
                      firearm.generationIsCustom = false;
                    }
                  },
                  selectItemCall: (value) {
                    firearm.generation = value.generation ?? 'None';
                    firearm.caliber = null;
                    firearm.firingMachanism = null;
                    firearm.ammoType = null;
                    context.read<StageBloc>().add(
                        FireArmDropDownChangedEventGen(
                            allItems: gearSetupState.allFirearms,
                            firearmEntity: firearm));
                  },
                  selectedValue: (state is FireArmDropDownChangedStateGen)
                      ? state.firearmEntity
                      : firearm,
                ),
              if (firearm.generation != null) LabelWidget(label: 'Caliber'),
              if (firearm.generation != null)
                // if (caliberList.isNotEmpty)
                PaDropdownGen<FirearmEntity>(
                  key: UniqueKey(),
                  isPreviousSelected: firearm.generation == null,
                  hint: 'Caliber',
                  fieldName: 'caliber',
                  allowCustomItem: true,
                  items: (state is FireArmDropDownChangedStateGen)
                      ? state.caliberListString.isEmpty
                          ? []
                          : state.caliberList
                      : [],
                  getLabel: (p0) => p0.caliber ?? '',
                  initialValue: firearm,
                  showDelIcon: false,
                  onDelTap: (p0) {},
                  noPadding: true,
                  itemTapped: (p0) {
                    if (p0) {
                      print('non custom caliber');
                      firearm.caliberIsCustom = false;
                    }
                  },
                  selectItemCall: (value) {
                    firearm.caliber = value.caliber ?? 'None';
                    firearm.firingMachanism = null;
                    firearm.ammoType = null;
                    context.read<StageBloc>().add(
                        FireArmDropDownChangedEventGen(
                            allItems: gearSetupState.allFirearms,
                            firearmEntity: firearm));
                  },
                  selectedValue: (state is FireArmDropDownChangedStateGen)
                      ? state.firearmEntity
                      : firearm,
                ),
              if (firearm.caliber != null) LabelWidget(label: 'Action Type'),
              if (firearm.caliber != null)
                // if (firingMacList.isNotEmpty)
                PaDropdownGen<FirearmEntity>(
                  key: UniqueKey(),
                  isPreviousSelected: firearm.caliber == null,
                  hint: 'Action Type',
                  fieldName: 'firing_machanism',
                  allowCustomItem: true,
                  items: (state is FireArmDropDownChangedStateGen)
                      ? state.firingMacListString.isEmpty
                          ? []
                          : state.firingMacList
                      : [],
                  getLabel: (p0) => p0.firingMachanism ?? '',
                  initialValue: firearm,
                  showDelIcon: false,
                  onDelTap: (p0) {},
                  noPadding: true,
                  itemTapped: (p0) {
                    if (p0) {
                      print('non custom Firing Mac');
                      firearm.firingMacIsCustom = false;
                    }
                  },
                  selectItemCall: (value) {
                    print(
                        'value.firingMachanism --------------------------- ${value.firingMachanism}');
                    firearm.firingMachanism = value.firingMachanism ?? 'None';
                    firearm.ammoType = null;
                    context.read<StageBloc>().add(
                        FireArmDropDownChangedEventGen(
                            allItems: gearSetupState.allFirearms,
                            firearmEntity: firearm));
                  },
                  selectedValue: (state is FireArmDropDownChangedStateGen)
                      ? state.firearmEntity
                      : firearm,
                ),
              if (firearm.firingMachanism != null) LabelWidget(label: 'Notes'),
              if (firearm.firingMachanism != null)
                CustomTextField(
                  controller: notesController,
                  maxLines: 3,
                  hintText: 'Enter general notes about this firearm...',
                ),
              if (firearm.firingMachanism != null) const SizedBox(height: 16),
              if (firearm.firingMachanism != null)
                PrimaryButton(
                    title:
                        'Advanced Info (Click to ${firearm.advancedInfoExpanded ?? false ? 'collapse' : 'expand'})',
                    buttonColor: AppColors.kGreenColor.withValues(alpha: 0.1),
                    textColor: AppColors.kGreenColor,
                    onTap: () {
                      firearm.advancedInfoExpanded =
                          !(firearm.advancedInfoExpanded ?? false);
                      context.read<StageBloc>().add(
                          FireArmDropDownChangedEventGen(
                              allItems: gearSetupState.allFirearms,
                              firearmEntity: firearm));
                    }),
              if (firearm.advancedInfoExpanded ?? false)
                LabelWidget(label: 'Serial Number'),
              if (firearm.advancedInfoExpanded ?? false)
                CustomTextField(
                    controller: serialNumberController,
                    hintText: 'Enter serial number',
                    keyboardType: TextInputType.number),
              if (firearm.advancedInfoExpanded ?? false)
                LabelWidget(label: 'Barrel Length (inches)'),
              if (firearm.advancedInfoExpanded ?? false)
                CustomTextField(
                  controller: barrelLengthController,
                  hintText: 'e.g., 4.5',
                  keyboardType: TextInputType.number,
                ),
              if (firearm.advancedInfoExpanded ?? false)
                LabelWidget(label: 'Overall Length (inches)'),
              if (firearm.advancedInfoExpanded ?? false)
                CustomTextField(
                  controller: overallLengthController,
                  hintText: 'e.g., 7.5',
                  keyboardType: TextInputType.number,
                ),
              if (firearm.advancedInfoExpanded ?? false)
                LabelWidget(label: 'Weight (oz)'),
              if (firearm.advancedInfoExpanded ?? false)
                CustomTextField(
                  controller: weightController,
                  hintText: 'e.g., 24.5',
                  keyboardType: TextInputType.number,
                ),
              if (firearm.advancedInfoExpanded ?? false)
                LabelWidget(label: 'Rifling Twist Rate'),
              if (firearm.advancedInfoExpanded ?? false)
                CustomTextField(
                  controller: riflingTwistRateController,
                  hintText: 'e.g., 1:10',
                ),
              if (firearm.advancedInfoExpanded ?? false)
                LabelWidget(label: 'Capacity'),
              if (firearm.advancedInfoExpanded ?? false)
                CustomTextField(
                  controller: capacityController,
                  hintText: 'Magazine/cylinder capacity',
                ),
              if (firearm.advancedInfoExpanded ?? false)
                LabelWidget(label: 'Finish/Color'),
              if (firearm.advancedInfoExpanded ?? false)
                PaDropdownGen<String>(
                  items: [
                    'Black',
                    'Stainless Steel',
                    'FDE (Flat Dark Earth)',
                    'OD Green',
                    'Cerakote',
                    'Blued',
                    'Nickel',
                    'Other',
                  ],
                  initialValue: firearm.finishColor ?? '',
                  selectedValue: firearm.finishColor,
                  getLabel: (String value) => value,
                  showSearch: true,
                  showDelIcon: false,
                  onDelTap: (p0) {},
                  allowCustomItem: true,
                  noPadding: true,
                  selectItemCall: (value) {
                    firearm.finishColor = value;
                    context.read<StageBloc>().add(
                        FireArmDropDownChangedEventGen(
                            allItems: gearSetupState.allFirearms,
                            firearmEntity: firearm));
                  },
                ),
              if (firearm.advancedInfoExpanded ?? false)
                LabelWidget(label: 'Sight Type'),
              if (firearm.advancedInfoExpanded ?? false)
                PaDropdownGen<String>(
                  items: [
                    'Iron Sights',
                    'Red Dot Sight',
                    'Magnified Scope',
                    'Laser Sight',
                    'Weapon Light'
                  ],
                  initialValue: firearm.sightType ?? '',
                  selectedValue: firearm.sightType,
                  getLabel: (String value) => value,
                  showSearch: true,
                  showDelIcon: false,
                  onDelTap: (p0) {},
                  allowCustomItem: true,
                  noPadding: true,
                  selectItemCall: (value) {
                    firearm.sightType = value;
                    context.read<StageBloc>().add(
                        FireArmDropDownChangedEventGen(
                            allItems: gearSetupState.allFirearms,
                            firearmEntity: firearm));
                  },
                ),
              if (firearm.advancedInfoExpanded ?? false)
                LabelWidget(label: 'Sight/Optic Model'),
              if (firearm.advancedInfoExpanded ?? false)
                PaDropdownGen<String>(
                    items: [
                      'Open Iron Sights',
                      'Peep Sights (Aperture)',
                      'Ghost Ring Sights',
                      'Low Power Variable Optic (LPVO)',
                      'Fixed Power Scope',
                      'Variable Power Scope',
                      'Red Dot Sight (RDS)',
                      'Holographic Sight',
                      'Prism Sight',
                      'Night Vision Scope',
                      'Thermal Scope',
                      'No Optic/Iron Sights Only'
                    ],
                    initialValue: firearm.sightModel ?? '',
                    selectedValue: firearm.sightModel,
                    getLabel: (String value) => value,
                    showSearch: true,
                    showDelIcon: false,
                    onDelTap: (p0) {},
                    allowCustomItem: true,
                    noPadding: true,
                    selectItemCall: (value) {
                      firearm.sightModel = value;
                      context.read<StageBloc>().add(
                          FireArmDropDownChangedEventGen(
                              allItems: gearSetupState.allFirearms,
                              firearmEntity: firearm));
                    }),
              if (firearm.advancedInfoExpanded ?? false)
                LabelWidget(label: 'Sight Height Over Bore (inches)'),
              if (firearm.advancedInfoExpanded ?? false)
                CustomTextField(
                  controller: sightHeightOverBoreController,
                  hintText: 'e.g., 1.5',
                  keyboardType: TextInputType.number,
                ),
              if (firearm.advancedInfoExpanded ?? false)
                LabelWidget(label: 'Trigger Pull Weight (lbs)'),
              if (firearm.advancedInfoExpanded ?? false)
                CustomTextField(
                  controller: triggerPullWeightController,
                  hintText: 'e.g., 5.5',
                  keyboardType: TextInputType.number,
                ),
              if (firearm.advancedInfoExpanded ?? false)
                LabelWidget(label: 'Purchase Date'),
              if (firearm.advancedInfoExpanded ?? false)
                CustomTextField(
                  controller: purchaseDateController,
                  hintText: 'Select purchase date',
                  isReadOnly: true,
                  onTap: () async {
                    DateTime? selectedDate = await selectDate(
                        context, purchaseDateController, DateTime.now());
                    if (selectedDate != null) {
                      firearm.purchaseDate = selectedDate.toString();
                      context.read<StageBloc>().add(
                          FireArmDropDownChangedEventGen(
                              allItems: gearSetupState.allFirearms,
                              firearmEntity: firearm));
                    }
                  },
                ),
              if (firearm.advancedInfoExpanded ?? false)
                LabelWidget(label: 'Round Count'),
              if (firearm.advancedInfoExpanded ?? false)
                CustomTextField(
                  controller: roundCountController,
                  hintText: 'Approximate rounds fired',
                  keyboardType: TextInputType.number,
                ),
              if (firearm.advancedInfoExpanded ?? false)
                LabelWidget(label: 'Modifications/Attachments'),
              if (firearm.advancedInfoExpanded ?? false)
                CustomTextField(
                  controller: modificationsAttachmentsController,
                  maxLines: 3,
                  hintText:
                      'List any modifications: suppressor, compensator, aftermarket trigger, etc.',
                ),
              if (firearm.firingMachanism != null) const SizedBox(height: 16),
              if (firearm.firingMachanism != null)
                PrimaryButton(
                    title: 'Next 1/4',
                    buttonColor: AppColors.kGreenColor,
                    onTap: () {
                      GearSetupModel gearSetupModel = GearSetupModel(
                        name: gearSetupState.gearSetup.name,
                        firearm: firearm.copyWith(
                          notes: notesController.text,
                          serialNumber: serialNumberController.text,
                          barrelLength: barrelLengthController.text,
                          overallLength: overallLengthController.text,
                          weight: weightController.text,
                          riflingTwistRate: riflingTwistRateController.text,
                          capacity: capacityController.text,
                          sightHeightOverBore:
                              sightHeightOverBoreController.text,
                          triggerPullWeight: triggerPullWeightController.text,
                          roundCount: roundCountController.text,
                          modificationsAttachments:
                              modificationsAttachmentsController.text,
                        ),
                        ammoModel: gearSetupState.gearSetup.ammoModel,
                        ammo: gearSetupState.gearSetup.ammo,
                        mode: gearSetupState.gearSetup.mode,
                        sights: gearSetupState.gearSetup.sights,
                        location: gearSetupState.gearSetup.location,
                        id: gearSetupState.gearSetup.id,
                      );
                      context
                          .read<GearSetupBloc>()
                          .add(GearSetupUpdate(gearSetupModel));
                      context.read<GearSetupBloc>().add(GearSetupTabChanged(1));
                    }),
            ],
          ),
        );
      },
    );
    //   }
    // });
  }

  Widget _buildFirearmTab(GearSetupState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text('🔫', style: TextStyle(fontSize: 16)),
          SizedBox(width: 8),
          Text('Select Your Firearm',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor))
        ]),
        // const SizedBox(height: 15),
        if (state.firearmSetups != null)
          ...state.firearmSetups!.map((firearm) => _buildFirearmSelector(
              firearm.firearm.type == 'Pistol' ? '🔫' : '🏹',
              firearm.firearm.brand!,
              '${firearm.firearm.model!} + ${firearm.firearm.caliber} + ${firearm.firearm.ammoType!}',
              firearm.firearm.type == 'Pistol'
                  ? 'glock19'
                  : firearm.firearm.type == 'Rifles'
                      ? 'ar15'
                      : 'ruger22',
              firearm.firearm.type == 'Pistol'
                  ? const Color(0xFF667EEA)
                  : const Color(0xFFF093FB),
              state,
              firearm,
              state.firearmSetups!.indexOf(firearm))),
      ],
    );
  }

  Widget _buildFirearmSelector(
      String icon,
      String name,
      String specs,
      String type,
      Color color,
      GearSetupState state,
      GearSetupModel firearm,
      int presetIndex) {
    final isSelected = state.selectedPresetIndex == presetIndex;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF8FFF9) : Colors.white,
          border: Border.all(
            color:
                isSelected ? const Color(0xFF28A745) : const Color(0xFFE9ECEF),
          ),
          borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => context
                .read<GearSetupBloc>()
                .add(GearSetupPresetSelected(presetIndex, firearm)),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                          gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [color, color.withValues(alpha: 0.7)]),
                          borderRadius: BorderRadius.circular(12)),
                      child: Center(
                          child: Text(icon,
                              style: const TextStyle(fontSize: 28)))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          specs,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6C757D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSightsTab(GearSetupState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text('👁️', style: TextStyle(fontSize: 16)),
          SizedBox(width: 8),
          Text(
            'Sights & Optics',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          )
        ]),
        const SizedBox(height: 15),
        _buildGearCard(
            '👁️',
            'Iron Sights',
            'Factory or aftermarket iron sights',
            'iron',
            const Color(0xFF43E97B),
            state),
        const SizedBox(height: 12),
        _buildGearCard('🔴', 'Red Dot Sight', 'Reflex or holographic sight',
            'reddot', const Color(0xFF43E97B), state),
        const SizedBox(height: 12),
        _buildGearCard(
            '🔭',
            'Magnified Scope',
            'Variable or fixed magnification',
            'scope',
            const Color(0xFF43E97B),
            state),
        const SizedBox(height: 25),
        Row(
          children: [
            Text('✨', style: TextStyle(fontSize: 16)),
            SizedBox(width: 8),
            Text('Accessories',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor)),
          ],
        ),
        const SizedBox(height: 15),
        _buildGearCard('🔺', 'Laser Sight', 'Red or green laser pointer',
            'laser', const Color(0xFFFA709A), state),
        const SizedBox(height: 12),
        _buildGearCard('💡', 'Weapon Light', 'Tactical flashlight', 'light',
            const Color(0xFFFA709A), state),
        const SizedBox(height: 15),
        PrimaryButton(
          title: 'View & Save',
          buttonColor: AppColors.kGreenColor,
          onTap: () {
            final GlobalKey<FormState> formKey = GlobalKey<FormState>();
            final TextEditingController controller = TextEditingController();
            showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) {
                  return AppBottomSheet(
                    hideInitials: true,
                    height: 0.9,
                    formKey: formKey,
                    children: [
                      // Firearm Section
                      SectionHeaderWidget(
                        title: 'Firearm',
                        icon: Icons.gps_fixed,
                      ),
                      LabelValueWidget(
                        label: 'Type',
                        value: state.gearSetup.firearm.type ?? '',
                        icon: Icons.category,
                        isImportant: true,
                      ),
                      LabelValueWidget(
                        label: 'Brand',
                        value: state.gearSetup.firearm.brand ?? '',
                        icon: Icons.business,
                      ),
                      LabelValueWidget(
                        label: 'Model',
                        value: state.gearSetup.firearm.model ?? '',
                        icon: Icons.model_training,
                      ),
                      LabelValueWidget(
                        label: 'Generation',
                        value: state.gearSetup.firearm.generation ?? '',
                        icon: Icons.timeline,
                      ),
                      LabelValueWidget(
                        label: 'Caliber',
                        value: state.gearSetup.firearm.caliber ?? '',
                        icon: Icons.straighten,
                        isImportant: true,
                      ),

                      // Advanced Info (if expanded)
                      if (state.gearSetup.firearm.advancedInfoExpanded ==
                          true) ...[
                        const ProfessionalDivider(),
                        LabelValueWidget(
                          label: 'Serial Number',
                          value: state.gearSetup.firearm.serialNumber ?? '',
                          icon: Icons.qr_code,
                        ),
                        LabelValueWidget(
                          label: 'Barrel Length',
                          value: state.gearSetup.firearm.barrelLength ?? '',
                          icon: Icons.straighten,
                        ),
                        LabelValueWidget(
                          label: 'Overall Length',
                          value: state.gearSetup.firearm.overallLength ?? '',
                          icon: Icons.straighten,
                        ),
                        LabelValueWidget(
                          label: 'Weight',
                          value: state.gearSetup.firearm.weight ?? '',
                          icon: Icons.scale,
                        ),
                        LabelValueWidget(
                          label: 'Rifling Twist Rate',
                          value: state.gearSetup.firearm.riflingTwistRate ?? '',
                          icon: Icons.rotate_right,
                        ),
                        LabelValueWidget(
                            label: 'Capacity',
                            value: state.gearSetup.firearm.capacity ?? '',
                            icon: Icons.storage),
                        LabelValueWidget(
                            label: 'Finish/Color',
                            value: state.gearSetup.firearm.finishColor ?? '',
                            icon: Icons.palette),
                        LabelValueWidget(
                          label: 'Sight Type',
                          value: state.gearSetup.firearm.sightType ?? '',
                          icon: Icons.visibility,
                        ),
                        LabelValueWidget(
                          label: 'Sight/Optic Model',
                          value: state.gearSetup.firearm.sightModel ?? '',
                          icon: Icons.center_focus_strong,
                        ),
                        LabelValueWidget(
                          label: 'Sight Height Over Bore',
                          value:
                              state.gearSetup.firearm.sightHeightOverBore ?? '',
                          icon: Icons.height,
                        ),
                        LabelValueWidget(
                          label: 'Trigger Pull Weight (lbs)',
                          value:
                              state.gearSetup.firearm.triggerPullWeight ?? '',
                          icon: Icons.touch_app,
                        ),
                        LabelValueWidget(
                          label: 'Purchase Date',
                          value: state.gearSetup.firearm.purchaseDate ?? '',
                          icon: Icons.calendar_today,
                        ),
                        LabelValueWidget(
                          label: 'Round Count',
                          value: state.gearSetup.firearm.roundCount ?? '',
                          icon: Icons.countertops,
                        ),
                        LabelValueWidget(
                            label: 'Modifications/Attachments',
                            value: state.gearSetup.firearm
                                    .modificationsAttachments ??
                                '',
                            icon: Icons.build),
                      ],
                      SectionHeaderWidget(
                        title: 'Ammunition',
                        icon: Icons.scatter_plot,
                      ),
                      LabelValueWidget(
                        label: 'Caliber',
                        value: state.gearSetup.ammoModel.caliber ?? '',
                        icon: Icons.straighten,
                        isImportant: true,
                      ),
                      LabelValueWidget(
                        label: 'Bullet Type',
                        value: state.gearSetup.ammoModel.bulletType ?? '',
                        icon: Icons.circle,
                      ),
                      LabelValueWidget(
                        label: 'Bullet Weight',
                        value:
                            '${state.gearSetup.ammoModel.bulletWeight ?? ''}',
                        icon: Icons.scale,
                      ),

                      // Advanced Ammo Info (if expanded)
                      if (state.gearSetup.ammoModel.advancedExpanded ==
                          true) ...[
                        const ProfessionalDivider(),
                        LabelValueWidget(
                          label: 'Notes',
                          value: state.gearSetup.ammoModel.notes ?? '',
                          icon: Icons.note,
                        ),
                        LabelValueWidget(
                          label: 'Cartridge Type',
                          value: state.gearSetup.ammoModel.cartridgeType ?? '',
                          icon: Icons.category,
                        ),
                        LabelValueWidget(
                          label: 'Case Material',
                          value: state.gearSetup.ammoModel.caseMaterial ?? '',
                          icon: Icons.circle,
                        ),
                        LabelValueWidget(
                          label: 'Primer Type',
                          value: state.gearSetup.ammoModel.primerType ?? '',
                          icon: Icons.flash_on,
                        ),
                        LabelValueWidget(
                          label: 'Pressure Class',
                          value: state.gearSetup.ammoModel.pressureClass ?? '',
                          icon: Icons.compress,
                        ),
                        LabelValueWidget(
                          label: 'Muzzle Velocity',
                          value: state.gearSetup.ammoModel.muzzleVelocity ?? '',
                          icon: Icons.speed,
                        ),
                        LabelValueWidget(
                          label: 'Ballistic Coefficient (G1)',
                          value:
                              state.gearSetup.ammoModel.ballisticCoefficient ??
                                  '',
                          icon: Icons.calculate,
                        ),
                        LabelValueWidget(
                          label: 'Sectional Density',
                          value:
                              state.gearSetup.ammoModel.sectionalDensity ?? '',
                          icon: Icons.density_medium,
                        ),
                        LabelValueWidget(
                          label: 'Recoil Energy',
                          value: state.gearSetup.ammoModel.recoilEnergy ?? '',
                          icon: Icons.bolt,
                        ),
                        LabelValueWidget(
                          label: 'Powder Charge',
                          value: state.gearSetup.ammoModel.powderCharge ?? '',
                          icon: Icons.grain,
                        ),
                        LabelValueWidget(
                          label: 'Powder Type',
                          value: state.gearSetup.ammoModel.powderType ?? '',
                          icon: Icons.scatter_plot,
                        ),
                        LabelValueWidget(
                          label: 'Lot Number',
                          value: state.gearSetup.ammoModel.lotNumber ?? '',
                          icon: Icons.numbers,
                        ),
                        LabelValueWidget(
                          label: 'Chronograph FPS',
                          value: state.gearSetup.ammoModel.chronographFPS ?? '',
                          icon: Icons.speed,
                        ),
                      ],

                      // Mode Section
                      SectionHeaderWidget(
                        title: 'Mode',
                        icon: Icons.settings,
                      ),
                      LabelValueWidget(
                        label: 'Mode',
                        value: state.gearSetup.mode ?? '',
                        icon: Icons.mode,
                      ),
                      LabelValueWidget(
                        label: 'Location',
                        value: state.gearSetup.location ?? '',
                        icon: Icons.location_on,
                      ),
                      SectionHeaderWidget(
                        title: 'Sights',
                        icon: Icons.visibility,
                      ),
                      LabelValueWidget(
                        label: 'Sights',
                        value: state.gearSetup.sights?.join(', ') ?? '',
                        icon: Icons.center_focus_strong,
                      ),
                      const Divider(),
                      const SizedBox(height: 15),
                      CustomTextField(
                          controller: controller,
                          hintText: 'Weapon Profile Name',
                          isRequired: true),
                      EnhancedPrimaryButton(
                        title: 'Save Setup',
                        icon: Icons.save,
                        buttonColor: AppColors.kGreenColor,
                        onTap: () {
                          if (!formKey.currentState!.validate()) return;
                          if (state.gearSetup.firearm.firingMachanism == null) {
                            ToastUtils.showError(context,
                                message: 'Complete Firearm Setup');
                            return;
                          } else if (state.gearSetup.ammoModel.bulletWeight ==
                              null) {
                            ToastUtils.showError(context,
                                message: 'Complete Ammunition Setup');
                            return;
                          } else if (state.gearSetup.sights == null) {
                            ToastUtils.showError(context,
                                message: 'Complete Sights Setup');
                            return;
                          }
                          context.read<GearSetupBloc>().add(AddFirearmSetup(
                              state.gearSetup.copyWith(name: controller.text)));
                          context.read<GearSetupBloc>().add(GearSetupReset());
                          context.read<GearSetupBloc>().add(
                              GearSetupPresetSelected(-2, state.gearSetup));
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  );
                });
          },
        ),
      ],
    );
  }

  Widget _buildAmmoTab(GearSetupState gearSetupState) {
    final ammoModel = gearSetupState.gearSetup.ammoModel;
    final bulletWeightController =
        TextEditingController(text: '${ammoModel.bulletWeight ?? ''}');
    final notesController = TextEditingController(text: ammoModel.notes ?? '');
    final muzzleVelocityController =
        TextEditingController(text: ammoModel.muzzleVelocity ?? '');
    final sectionalDensityController =
        TextEditingController(text: ammoModel.sectionalDensity ?? '');
    final recoilEnergyController =
        TextEditingController(text: ammoModel.recoilEnergy ?? '');
    final powderChargeController =
        TextEditingController(text: ammoModel.powderCharge ?? '');
    final powderTypeController =
        TextEditingController(text: ammoModel.powderType ?? '');
    final lotNumberController =
        TextEditingController(text: ammoModel.lotNumber ?? '');
    final chronographFpsController =
        TextEditingController(text: ammoModel.chronographFPS ?? '');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('🎯', style: TextStyle(fontSize: 16)),
            SizedBox(width: 8),
            Text(
              'Ammunition Selection',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
        BlocBuilder<StageBloc, StageState>(
          builder: (context, state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LabelWidget(label: 'Caliber'),
                PaDropdownGen<String>(
                  key: UniqueKey(),
                  hint: 'Caliber',
                  allowCustomItem: true,
                  noPadding: true,
                  items: _ammunitionList
                      .map((e) => e.caliber)
                      .toList()
                      .toSet()
                      .toList(),
                  getLabel: (p0) => p0,
                  initialValue: ammoModel.caliber ?? '',
                  showDelIcon: false,
                  onDelTap: (p0) {},
                  selectItemCall: (value) {
                    ammoModel.caliber = value;
                    context.read<StageBloc>().add(
                        FireArmDropDownChangedEventGen(
                            allItems: gearSetupState.allFirearms,
                            firearmEntity: gearSetupState.gearSetup.firearm));
                  },
                  selectedValue: ammoModel.caliber,
                ),
                LabelWidget(label: 'Bullet Type'),
                PaDropdownGen<String>(
                  key: UniqueKey(),
                  hint: 'Bullet Type',
                  allowCustomItem: true,
                  noPadding: true,
                  items: _ammunitionList
                      .map((e) => e.bulletType)
                      .toList()
                      .toSet()
                      .toList(),
                  getLabel: (p0) => p0,
                  initialValue: ammoModel.bulletType ?? '',
                  showDelIcon: false,
                  onDelTap: (p0) {},
                  selectItemCall: (value) {
                    ammoModel.bulletType = value;
                    context.read<StageBloc>().add(
                        FireArmDropDownChangedEventGen(
                            allItems: gearSetupState.allFirearms,
                            firearmEntity: gearSetupState.gearSetup.firearm));
                  },
                  selectedValue: ammoModel.bulletType,
                ),
                LabelWidget(label: 'Bullet Weight (grains)'),
                CustomTextField(
                  controller: bulletWeightController,
                  hintText: 'Bullet Weight (grains)',
                  keyboardType: TextInputType.number,
                ),
                LabelWidget(label: 'Manufacturer'),
                PaDropdownGen<String>(
                  key: UniqueKey(),
                  hint: 'Manufacturer',
                  allowCustomItem: true,
                  noPadding: true,
                  items: _ammunitionList
                      .map((e) => e.manufacturer)
                      .toList()
                      .toSet()
                      .toList(),
                  getLabel: (p0) => p0,
                  initialValue: ammoModel.manufacturer ?? '',
                  showDelIcon: false,
                  onDelTap: (p0) {},
                  itemTapped: (p0) {},
                  selectItemCall: (value) {
                    ammoModel.manufacturer = value;
                    context.read<StageBloc>().add(AmmoTypeChangedEvent(
                        ammoModel: gearSetupState.gearSetup.ammoModel));
                    context.read<StageBloc>().add(
                        FireArmDropDownChangedEventGen(
                            allItems: gearSetupState.allFirearms,
                            firearmEntity: gearSetupState.gearSetup.firearm));
                  },
                  selectedValue: ammoModel.manufacturer,
                ),
                LabelWidget(label: 'Notes'),
                CustomTextField(
                  controller: notesController,
                  hintText: 'Notes',
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                    title:
                        'Advanced Info (Click to ${ammoModel.advancedExpanded ?? false ? 'collapse' : 'expand'})',
                    buttonColor: AppColors.kGreenColor.withValues(alpha: 0.1),
                    textColor: AppColors.kGreenColor,
                    onTap: () {
                      ammoModel.advancedExpanded =
                          !(ammoModel.advancedExpanded ?? false);
                      context.read<StageBloc>().add(AmmoTypeChangedEvent(
                          ammoModel: ammoModel.copyWith(
                              advancedExpanded: ammoModel.advancedExpanded)));
                    }),
                const SizedBox(height: 16),
                if (ammoModel.advancedExpanded == true) ...[
                  LabelWidget(label: 'Cartridge Type'),
                  PaDropdownGen<String>(
                    key: UniqueKey(),
                    hint: 'Cartridge Type',
                    allowCustomItem: true,
                    noPadding: true,
                    items: ['Factory', 'Reload', 'Mil-Surp'],
                    getLabel: (p0) => p0,
                    initialValue: ammoModel.cartridgeType ?? '',
                    showDelIcon: false,
                    onDelTap: (p0) {},
                    itemTapped: (p0) {},
                    selectItemCall: (value) {
                      ammoModel.cartridgeType = value;
                      context.read<StageBloc>().add(AmmoTypeChangedEvent(
                          ammoModel: gearSetupState.gearSetup.ammoModel));
                      context.read<StageBloc>().add(
                          FireArmDropDownChangedEventGen(
                              allItems: gearSetupState.allFirearms,
                              firearmEntity: gearSetupState.gearSetup.firearm));
                    },
                    selectedValue: ammoModel.cartridgeType,
                  ),
                  LabelWidget(label: 'Case Material'),
                  PaDropdownGen<String>(
                    key: UniqueKey(),
                    hint: 'Case Material',
                    allowCustomItem: true,
                    noPadding: true,
                    items: ['Steel', 'Brass', 'Copper'],
                    getLabel: (p0) => p0,
                    initialValue: ammoModel.caseMaterial ?? '',
                    showDelIcon: false,
                    onDelTap: (p0) {},
                    itemTapped: (p0) {},
                    selectItemCall: (value) {
                      ammoModel.caseMaterial = value;
                      context.read<StageBloc>().add(AmmoTypeChangedEvent(
                          ammoModel: ammoModel.copyWith(
                              caseMaterial: ammoModel.caseMaterial)));
                      context.read<StageBloc>().add(
                          FireArmDropDownChangedEventGen(
                              allItems: gearSetupState.allFirearms,
                              firearmEntity: gearSetupState.gearSetup.firearm));
                    },
                    selectedValue: ammoModel.caseMaterial,
                  ),
                  LabelWidget(label: 'Primer Type'),
                  PaDropdownGen<String>(
                    key: UniqueKey(),
                    hint: 'Primer Type',
                    allowCustomItem: true,
                    noPadding: true,
                    items: ['Boxer', 'Berdan', 'Match'],
                    getLabel: (p0) => p0,
                    initialValue: ammoModel.primerType ?? '',
                    showDelIcon: false,
                    onDelTap: (p0) {},
                    itemTapped: (p0) {},
                    selectItemCall: (value) {
                      ammoModel.primerType = value;
                      context.read<StageBloc>().add(AmmoTypeChangedEvent(
                          ammoModel: ammoModel.copyWith(
                              primerType: ammoModel.primerType)));
                      context.read<StageBloc>().add(
                          FireArmDropDownChangedEventGen(
                              allItems: gearSetupState.allFirearms,
                              firearmEntity: gearSetupState.gearSetup.firearm));
                    },
                    selectedValue: ammoModel.primerType,
                  ),
                  LabelWidget(label: 'Pressure Class'),
                  PaDropdownGen<String>(
                    key: UniqueKey(),
                    hint: 'Pressure Class',
                    allowCustomItem: true,
                    noPadding: true,
                    items: ['NATO', 'SAAMI', '+P'],
                    getLabel: (p0) => p0,
                    initialValue: ammoModel.pressureClass ?? '',
                    showDelIcon: false,
                    onDelTap: (p0) {},
                    itemTapped: (p0) {},
                    selectItemCall: (value) {
                      ammoModel.pressureClass = value;
                      context.read<StageBloc>().add(AmmoTypeChangedEvent(
                          ammoModel: ammoModel.copyWith(
                              pressureClass: ammoModel.pressureClass)));
                      context.read<StageBloc>().add(
                          FireArmDropDownChangedEventGen(
                              allItems: gearSetupState.allFirearms,
                              firearmEntity: gearSetupState.gearSetup.firearm));
                    },
                    selectedValue: ammoModel.pressureClass,
                  ),
                  LabelWidget(label: 'Muzzle Velocity (fps)'),
                  CustomTextField(
                    controller: muzzleVelocityController,
                    hintText: 'Muzzle Velocity (fps)',
                    keyboardType: TextInputType.number,
                  ),
                  LabelWidget(label: 'Sectional Density'),
                  CustomTextField(
                    controller: sectionalDensityController,
                    hintText: 'Sectional Density',
                    keyboardType: TextInputType.number,
                  ),
                  LabelWidget(label: 'Recoil Energy (ft-lbs)'),
                  CustomTextField(
                    controller: recoilEnergyController,
                    hintText: 'Recoil Energy (ft-lbs)',
                    keyboardType: TextInputType.number,
                  ),
                  LabelWidget(label: 'Powder Charge (grains)'),
                  CustomTextField(
                    controller: powderChargeController,
                    hintText: 'Powder Charge (grains)',
                    keyboardType: TextInputType.number,
                  ),
                  LabelWidget(label: 'Powder Type'),
                  CustomTextField(
                    controller: powderTypeController,
                    hintText: 'Powder Type',
                  ),
                  LabelWidget(label: 'Lot Number'),
                  CustomTextField(
                    controller: lotNumberController,
                    hintText: 'Lot Number',
                  ),
                  LabelWidget(label: 'Chronograph FPS (optional)'),
                  CustomTextField(
                    controller: chronographFpsController,
                    hintText: 'Chronograph FPS (optional)',
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 16),
                ],
                PrimaryButton(
                  title: 'Next 2/4',
                  buttonColor: AppColors.kGreenColor,
                  onTap: () {
                    if (bulletWeightController.text.isEmpty) {
                      ToastUtils.showError(context,
                          message: 'Bullet Weight is required');
                      return;
                    }
                    AmmoModel ammoModel2 = ammoModel.copyWith(
                        bulletWeight: int.parse(bulletWeightController.text),
                        notes: notesController.text,
                        muzzleVelocity: muzzleVelocityController.text,
                        sectionalDensity: sectionalDensityController.text,
                        recoilEnergy: recoilEnergyController.text,
                        powderCharge: powderChargeController.text,
                        powderType: powderTypeController.text,
                        lotNumber: lotNumberController.text,
                        advancedExpanded: ammoModel.advancedExpanded,
                        chronographFPS: chronographFpsController.text);
                    context.read<GearSetupBloc>().add(GearSetupUpdate(
                        gearSetupState.gearSetup
                            .copyWith(ammoModel: ammoModel2)));
                    context.read<GearSetupBloc>().add(GearSetupTabChanged(2));
                  },
                ),
              ],
            );
          },
        ),
        // ..._getAmmoOptions(state).map((ammo) => Padding(
        //       padding: const EdgeInsets.only(bottom: 12),
        //       child: _buildAmmoCard(
        //           ammo['name']!, ammo['description']!, ammo['id']!, state),
        //     )),
        // const SizedBox(height: 15),
        // _buildCustomAmmoInput(),
      ],
    );
    // });
  }

  Widget _buildTrainingTab(GearSetupState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('🎯', style: TextStyle(fontSize: 16)),
            SizedBox(width: 8),
            Text(
              'Training Mode',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        _buildModeCard('🏠', 'Dry Fire Practice',
            'No ammunition, trigger practice', 'dryfire', state),
        const SizedBox(height: 12),
        _buildModeCard('💥', 'Live Fire Training', 'Range with ammunition',
            'livefire', state),
        const SizedBox(height: 25),
        Row(
          children: [
            Text('📍', style: TextStyle(fontSize: 16)),
            SizedBox(width: 8),
            Text(
              'Training Location',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        _buildLocationCard(
            '🏠', 'Home Practice', 'Indoor safe training area', 'home', state),
        const SizedBox(height: 12),
        _buildLocationCard(
            '🏢', 'Indoor Range', 'Controlled environment', 'indoor', state),
        const SizedBox(height: 12),
        _buildLocationCard(
            '🌲', 'Outdoor Range', 'Natural conditions', 'outdoor', state),
        const SizedBox(height: 15),
        PrimaryButton(
          title: 'Next 3/4',
          buttonColor: AppColors.kGreenColor,
          onTap: () {
            context.read<GearSetupBloc>().add(GearSetupTabChanged(3));
          },
        ),
      ],
    );
  }

  Widget _buildGearCard(String icon, String name, String description, String id,
      Color color, GearSetupState state) {
    final isSelected = state.gearSetup.sights?.contains(id) ?? false;

    return GestureDetector(
      onTap: () {
        final newSights = Set<String>.from(state.gearSetup.sights ?? []);
        if (isSelected) {
          newSights.remove(id);
        } else {
          newSights.add(id);
        }
        context.read<GearSetupBloc>().add(GearSetupSightsChanged(newSights));
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF8FFF9) : Colors.white,
          border: Border.all(
            color:
                isSelected ? const Color(0xFF28A745) : const Color(0xFFE9ECEF),
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color, color.withValues(alpha: 0.7)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  icon,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedOpacity(
              opacity: isSelected ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Color(0xFF28A745),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    '✓',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> loadAmmunitionData() async {
    final String response =
        await rootBundle.loadString('assets/database/ammo_data.json');
    final List<dynamic> data = await json.decode(response);
    _ammunitionList = data.map((json) => Ammunition.fromJson(json)).toList();
  }

  Widget _buildModeCard(String icon, String name, String description, String id,
      GearSetupState state) {
    final isSelected = state.gearSetup.mode == id;

    return GestureDetector(
      onTap: () => context.read<GearSetupBloc>().add(GearSetupModeChanged(id)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF8FFF9) : Colors.white,
          border: Border.all(
            color:
                isSelected ? const Color(0xFF28A745) : const Color(0xFFE9ECEF),
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF43E97B), Color(0xFF38F9D7)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  icon,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedOpacity(
              opacity: isSelected ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Color(0xFF28A745),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    '✓',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard(String icon, String name, String description,
      String id, GearSetupState state) {
    final isSelected = state.gearSetup.location == id;

    return GestureDetector(
      onTap: () =>
          context.read<GearSetupBloc>().add(GearSetupLocationChanged(id)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF8FFF9) : Colors.white,
          border: Border.all(
            color:
                isSelected ? const Color(0xFF28A745) : const Color(0xFFE9ECEF),
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF43E97B), Color(0xFF38F9D7)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  icon,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6C757D),
                    ),
                  ),
                ],
              ),
            ),
            AnimatedOpacity(
              opacity: isSelected ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Color(0xFF28A745),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    '✓',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSave(GearSetupState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF28A745), Color(0xFF20C997)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('📋', style: TextStyle(fontSize: 16)),
              SizedBox(width: 8),
              Text(
                'Setup Summary',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryRow('Firearm:', _getFirearmSummary(state)),
                _buildSummaryRow('Sights:', _getSightsSummary(state)),
                _buildSummaryRow('Ammo:', _getAmmoSummary(state)),
                _buildSummaryRow('Mode:', _getModeSummary(state)),
                _buildSummaryRow('Location:', _getLocationSummary(state)),
              ],
            ),
          ),
          const SizedBox(height: 15),
          // TextField(
          //     controller: _setupNameController,
          //     style: const TextStyle(
          //       color: Color(0xFF2C3E50),
          //       fontWeight: FontWeight.bold,
          //     ),
          //     decoration: InputDecoration(
          //       filled: true,
          //       fillColor: Colors.white.withValues(alpha: 0.9),
          //       border: OutlineInputBorder(
          //         borderRadius: BorderRadius.circular(8),
          //         borderSide: BorderSide.none,
          //       ),
          //       contentPadding: const EdgeInsets.all(12),
          //       hintText: 'Setup Name (e.g., Indoor Drill, Glock Practice)',
          //     ),
          //     textAlign: TextAlign.center),
          // const SizedBox(height: 15),
          // BlocConsumer<GearSetupBloc, GearSetupState>(
          //   listener: (context, state) {
          //     if (state.profilesError != null) {
          //       ToastUtils.showError(context, message: state.profilesError!);
          //     } else if (state.equipmentProfileSaved) {
          //       ToastUtils.showSuccess(context,
          //           message: 'Equipment profile saved successfully');
          //       Navigator.pushAndRemoveUntil(
          //           context,
          //           MaterialPageRoute(
          //               builder: (context) =>
          //                   const BottomNavPage(initialIndex: 2)),
          //           (route) => false);
          //     }
          //   },
          //   builder: (context, builderState) {
          //     if (builderState.isSavingEquipmentProfile) {
          //       return const LinearProgressIndicator();
          //     }
          //     return ElevatedButton(
          //       onPressed: () {
          //         if (_setupNameController.text.isEmpty) {
          //           ToastUtils.showError(context,
          //               message: 'Setup name is required');
          //         } else if (state.gearSetup.firearm.model == null) {
          //           ToastUtils.showError(context,
          //               message: 'Please select a firearm');
          //         } else if (state.gearSetup.ammo!.isEmpty) {
          //           ToastUtils.showError(context,
          //               message: 'Please select ammo');
          //         } else {
          //           if (state.gearSetup.id == null) {
          //             GearSetupModel gearSetupModel = GearSetupModel(
          //               name: _setupNameController.text,
          //               firearm: state.gearSetup.firearm,
          //               ammo: state.gearSetup.ammo,
          //               mode: state.gearSetup.mode,
          //               sights: state.gearSetup.sights,
          //               location: state.gearSetup.location,
          //               ammoModel: state.gearSetup.ammoModel,
          //             );
          //             context
          //                 .read<GearSetupBloc>()
          //                 .add(AddEquipmentProfile(gearSetupModel));
          //           } else {
          //             GearSetupModel gearSetupModel = GearSetupModel(
          //               id: state.gearSetup.id,
          //               name: _setupNameController.text,
          //               firearm: state.gearSetup.firearm,
          //               ammo: state.gearSetup.ammo,
          //               mode: state.gearSetup.mode,
          //               sights: state.gearSetup.sights,
          //               location: state.gearSetup.location,
          //               ammoModel: state.gearSetup.ammoModel,
          //             );
          //             context
          //                 .read<GearSetupBloc>()
          //                 .add(UpdateEquipmentProfile(gearSetupModel));
          //           }
          //         }
          //       },
          //       style: ElevatedButton.styleFrom(
          //         backgroundColor: Colors.white,
          //         foregroundColor: const Color(0xFF28A745),
          //         padding:
          //             const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
          //         shape: RoundedRectangleBorder(
          //           borderRadius: BorderRadius.circular(8),
          //         ),
          //       ),
          //       child: Row(
          //         mainAxisSize: MainAxisSize.min,
          //         children: [
          //           Text('💾', style: TextStyle(fontSize: 16)),
          //           SizedBox(width: 8),
          //           Text(
          //             state.gearSetup.id == null
          //                 ? 'Save Equipment Profile'
          //                 : 'Update Equipment Profile',
          //             style: TextStyle(fontWeight: FontWeight.bold),
          //           ),
          //         ],
          //       ),
          //     );
          //   },
          // ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrainingCTA() {
    return PrimaryButton(
        title: 'Back to Programs',
        onTap: () {
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  builder: (context) => BottomNavPage(initialIndex: 2)),
              (route) => false);
        });
    // return Row(
    //   children: [
    //     Expanded(
    //       child: ElevatedButton(
    //         onPressed: () {
    //           Navigator.pushAndRemoveUntil(
    //               context,
    //               MaterialPageRoute(
    //                   builder: (context) => BottomNavPage(initialIndex: 2)),
    //               (route) => false);
    //         },
    //         style: ElevatedButton.styleFrom(
    //           backgroundColor: const Color(0xFF6C757D),
    //           foregroundColor: Colors.white,
    //           padding: const EdgeInsets.all(15),
    //           shape: RoundedRectangleBorder(
    //             borderRadius: BorderRadius.circular(10),
    //           ),
    //         ),
    //         child: const Row(
    //           mainAxisAlignment: MainAxisAlignment.center,
    //           children: [
    //             Text('🔄', style: TextStyle(fontSize: 16)),
    //             SizedBox(width: 8),
    //             Flexible(
    //               child: Text(
    //                 'Back to Programs',
    //                 style: TextStyle(fontWeight: FontWeight.w600),
    //               ),
    //             ),
    //           ],
    //         ),
    //       ),
    //     ),
    //     const SizedBox(width: 12),
    //     Expanded(
    //       child: ElevatedButton(
    //         onPressed: () {
    //           // Navigator.pushAndRemoveUntil(
    //           //     context,
    //           //     MaterialPageRoute(
    //           //         builder: (context) =>
    //           //             const BottomNavPage(initialIndex: 2)),
    //           //     (route) => false);
    //         },
    //         style: ElevatedButton.styleFrom(
    //           backgroundColor: const Color(0xFFE74C3C),
    //           foregroundColor: Colors.white,
    //           padding: const EdgeInsets.all(15),
    //           shape: RoundedRectangleBorder(
    //             borderRadius: BorderRadius.circular(10),
    //           ),
    //         ),
    //         child: const Row(
    //           mainAxisAlignment: MainAxisAlignment.center,
    //           children: [
    //             Text('🎯', style: TextStyle(fontSize: 16)),
    //             SizedBox(width: 8),
    //             Text(
    //               'Start Training',
    //               style: TextStyle(fontWeight: FontWeight.bold),
    //             ),
    //           ],
    //         ),
    //       ),
    //     ),
    //   ],
    // );
  }

  String _getFirearmSummary(GearSetupState state) {
    log('------ _getFirearmSummary ${state.gearSetup.ammoModel.bulletType}------');

    return '${state.gearSetup.firearm.brand ?? ''}, ${state.gearSetup.firearm.model ?? ''}';
  }

  String _getSightsSummary(GearSetupState state) {
    if (state.gearSetup.sights?.isEmpty ?? true) return 'None selected';

    final sightNames = {
      'iron': 'Iron Sights',
      'reddot': 'Red Dot Sight',
      'scope': 'Magnified Scope',
      'laser': 'Laser Sight',
      'light': 'Weapon Light'
    };

    return state.gearSetup.sights
            ?.map((sight) => sightNames[sight] ?? sight)
            .join(' + ') ??
        'None selected';
  }

  String _getAmmoSummary(GearSetupState state) {
    // if (state.gearSetup.ammo != null) {
    //   final ammoNames = {
    //     '115gr-9mm': '115gr 9mm FMJ',
    //     '124gr-9mm': '124gr 9mm',
    //     '147gr-9mm': '147gr 9mm Subsonic',
    //     '40gr-22lr': '40gr .22 LR',
    //     '55gr-223': '55gr .223 Rem'
    //   };
    //   return ammoNames[state.gearSetup.ammo] ??
    //       state.gearSetup.ammoModel.bulletType ??
    //       'Custom';
    // }

    // // Check custom ammo
    // final caliber = _customAmmoCaliberController.text;
    // final weight = _customAmmoWeightController.text;
    // final type = _customAmmoTypeController.text;
    // if (caliber.isNotEmpty || weight.isNotEmpty || type.isNotEmpty) {
    //   return '$weight $caliber $type'.trim();
    // }

    return '${state.gearSetup.ammoModel.bulletType ?? ''}, ${state.gearSetup.ammoModel.caseMaterial ?? ''}, ${state.gearSetup.ammoModel.manufacturer ?? ''}';
  }

  String _getModeSummary(GearSetupState state) {
    final modeNames = {
      'dryfire': 'Dry Fire Practice',
      'livefire': 'Live Fire Training',
    };
    return modeNames[state.gearSetup.mode] ?? 'None selected';
  }

  String _getLocationSummary(GearSetupState state) {
    final locationNames = {
      'home': 'Home Practice',
      'indoor': 'Indoor Range',
      'outdoor': 'Outdoor Range',
    };
    return locationNames[state.gearSetup.location] ?? 'None selected';
  }

  void _showGearHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gear Setup Help'),
        content: const Text('Gear Setup Help:\n\n'
            '• Choose your firearm type and model\n'
            '• Select your sighting system\n'
            '• Pick appropriate ammunition\n'
            '• Set training mode and location\n'
            '• Save your setup for future use\n\n'
            'Use presets for quick setup or build custom configurations!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pulse_skadi/core/widgets/pa_dropdown.dart';
import 'package:pulse_skadi/features/firearm/data/model/firearm_entity.dart';
import 'package:pulse_skadi/features/firearm/data/local/service/firearm_db_helper.dart';
import 'package:pulse_skadi/features/firearm/data/model/stage_entity.dart';
import 'package:pulse_skadi/features/firearm/presentation/stage_bloc/stage_bloc.dart';

class SelectFirearmScreen extends StatefulWidget {
  final StageEntity stageEntity;
  const SelectFirearmScreen({super.key, required this.stageEntity});

  @override
  State<SelectFirearmScreen> createState() => _SelectFirearmScreenState();
}

class _SelectFirearmScreenState extends State<SelectFirearmScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late FirearmEntity firearm;
  bool loadedArms = false;
  @override
  void initState() {
    super.initState();
    firearm = FirearmEntity(
        type: widget.stageEntity.firearm?.type ?? '',
        brand: widget.stageEntity.firearm?.brand ?? '',
        model: widget.stageEntity.firearm?.model,
        generation: widget.stageEntity.firearm?.generation,
        caliber: widget.stageEntity.firearm?.caliber,
        firingMachanism: widget.stageEntity.firearm?.firingMachanism,
        ammoType: widget.stageEntity.firearm?.ammoType);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Weapon'),
      ),
      body: FutureBuilder<List<FirearmEntity>>(
          future: loadedArms ? null : FirearmDbHelper().getFirearms(''),
          builder: (context, snap) {
            if (!snap.hasData ||
                snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator.adaptive());
            } else {
              loadedArms = true;
              List<FirearmEntity> allFireArms = [];
              allFireArms = (snap.data ?? []).fold<List<FirearmEntity>>([],
                  (prev, element) {
                if (!prev.any((e) => e.type == element.type)) {
                  prev.add(element);
                }
                return prev;
              });
              return BlocBuilder<StageBloc, StageState>(
                builder: (context, state) {
                  return Form(
                    key: _formKey,
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(left: 24),
                          child: Text(
                            'Select Weapon',
                            style: TextStyle(
                              fontSize: 18,
                              // color: AppColors.blackTextColor,
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        PaDropdownGen<FirearmEntity>(
                          // key: UniqueKey(),
                          hint: 'Gun Type',
                          items: allFireArms,
                          getLabel: (p0) => p0.type ?? '',
                          initialValue: firearm,
                          showDelIcon: false,
                          onDelTap: (p0) {},
                          showSearch: true,
                          selectItemCall: (value) {
                            firearm.type = value.type ?? 'None';
                            firearm.brand = null;
                            firearm.model = null;
                            firearm.generation = null;
                            firearm.caliber = null;
                            firearm.firingMachanism = null;
                            firearm.ammoType = null;
                            context.read<StageBloc>().add(
                                FireArmDropDownChangedEventGen(
                                    allItems: snap.data ?? [],
                                    firearmEntity: firearm));
                          },
                          selectedValue:
                              (state is FireArmDropDownChangedStateGen)
                                  ? state.firearmEntity
                                  : firearm,
                        ),
                        const SizedBox(height: 16),
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
                                    allItems: snap.data ?? [],
                                    firearmEntity: firearm));
                          },
                          selectedValue:
                              (state is FireArmDropDownChangedStateGen)
                                  ? state.firearmEntity
                                  : firearm,
                        ),
                        const SizedBox(height: 16),
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
                                      allItems: snap.data ?? [],
                                      firearmEntity: firearm));
                            },
                            selectedValue:
                                (state is FireArmDropDownChangedStateGen)
                                    ? state.firearmEntity
                                    : firearm),
                        const SizedBox(height: 16),
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
                                    allItems: snap.data ?? [],
                                    firearmEntity: firearm));
                          },
                          selectedValue:
                              (state is FireArmDropDownChangedStateGen)
                                  ? state.firearmEntity
                                  : firearm,
                        ),
                        const SizedBox(height: 16),
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
                                    allItems: snap.data ?? [],
                                    firearmEntity: firearm));
                          },
                          selectedValue:
                              (state is FireArmDropDownChangedStateGen)
                                  ? state.firearmEntity
                                  : firearm,
                        ),
                        const SizedBox(height: 16),
                        // if (firingMacList.isNotEmpty)
                        PaDropdownGen<FirearmEntity>(
                          key: UniqueKey(),
                          isPreviousSelected: firearm.caliber == null,
                          hint: 'Firing Mechanism',
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
                          itemTapped: (p0) {
                            if (p0) {
                              print('non custom Firing Mac');
                              firearm.firingMacIsCustom = false;
                            }
                          },
                          selectItemCall: (value) {
                            print(
                                'value.firingMachanism --------------------------- ${value.firingMachanism}');
                            firearm.firingMachanism =
                                value.firingMachanism ?? 'None';
                            firearm.ammoType = null;
                            context.read<StageBloc>().add(
                                FireArmDropDownChangedEventGen(
                                    allItems: snap.data ?? [],
                                    firearmEntity: firearm));
                          },
                          selectedValue:
                              (state is FireArmDropDownChangedStateGen)
                                  ? state.firearmEntity
                                  : firearm,
                        ),
                        const SizedBox(height: 16),
                        // if (ammoTypeList.isNotEmpty)
                        PaDropdownGen<FirearmEntity>(
                          key: UniqueKey(),
                          isPreviousSelected: firearm.firingMachanism == null,
                          hint: 'Ammo Type',
                          fieldName: 'ammo_type',
                          allowCustomItem: true,
                          items: (state is FireArmDropDownChangedStateGen)
                              ? state.ammoTypeListString.isEmpty
                                  ? []
                                  : state.ammoTypeList
                              : [],
                          getLabel: (p0) => p0.ammoType ?? '',
                          initialValue: firearm,
                          showDelIcon: false,
                          onDelTap: (p0) {},
                          itemTapped: (p0) {
                            if (p0) {
                              print('non custom Ammo Type');
                              firearm.ammoTypeMacIsCustom = false;
                            }
                          },
                          selectItemCall: (value) {
                            firearm.ammoType = value.ammoType ?? 'None';
                            context.read<StageBloc>().add(
                                FireArmDropDownChangedEventGen(
                                    allItems: snap.data ?? [],
                                    firearmEntity: firearm));
                          },
                          selectedValue:
                              (state is FireArmDropDownChangedStateGen)
                                  ? state.firearmEntity
                                  : firearm,
                        ),
                      ],
                    ),
                  );
                },
              );
            }
          }),
    );
  }
}

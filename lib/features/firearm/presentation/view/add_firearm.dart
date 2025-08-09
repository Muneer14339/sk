import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pulse_skadi/core/widgets/custom_textfield.dart';
import 'package:pulse_skadi/features/firearm/data/local/service/firearm_db_helper.dart';
import 'package:pulse_skadi/features/firearm/data/model/firearm_entity.dart';
import 'package:pulse_skadi/features/firearm/data/model/stage_entity.dart';
import 'package:pulse_skadi/features/firearm/presentation/stage_bloc/stage_bloc.dart';
import 'package:pulse_skadi/features/firearm/presentation/cubit/satge_cubit.dart';

class AddFireArmScreen extends StatefulWidget {
  const AddFireArmScreen({required this.stageEntity, super.key});
  final StageEntity stageEntity;

  @override
  State<AddFireArmScreen> createState() => _AddFireArmScreenState();
}

class _AddFireArmScreenState extends State<AddFireArmScreen> {
  TextEditingController gunTypeController = TextEditingController();
  TextEditingController brandController = TextEditingController();
  TextEditingController modelController = TextEditingController();
  TextEditingController generationController = TextEditingController();
  TextEditingController caliberController = TextEditingController();
  TextEditingController firingMechController = TextEditingController();
  TextEditingController ammoTypeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool isAutoValidate = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Firearm')),
      body: BlocProvider(
        create: (context) => AutoValidationCubit(),
        child: BlocBuilder<AutoValidationCubit, bool>(
          builder: (context, state) {
            isAutoValidate = state;
            return Form(
              autovalidateMode:
                  state ? AutovalidateMode.always : AutovalidateMode.disabled,
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ListView(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Add new weapon',
                          style: TextStyle(
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 16,
                    ),
                    CustomTextField(
                      labelText: 'Gun Type',
                      isRequired: true,
                      controller: gunTypeController,
                    ),
                    SizedBox(
                      height: 16,
                    ),
                    CustomTextField(
                      isRequired: true,
                      labelText: 'Brand',
                      controller: brandController,
                    ),
                    SizedBox(
                      height: 16,
                    ),
                    CustomTextField(
                      labelText: 'Model',
                      controller: modelController,
                    ),
                    SizedBox(
                      height: 16,
                    ),
                    CustomTextField(
                      labelText: 'Generation/variant',
                      controller: generationController,
                    ),
                    SizedBox(
                      height: 16,
                    ),
                    CustomTextField(
                      labelText: 'Caliber',
                      controller: caliberController,
                    ),
                    SizedBox(
                      height: 16,
                    ),
                    CustomTextField(
                      labelText: 'Firing Mechanism',
                      controller: firingMechController,
                    ),
                    SizedBox(height: 16),
                    CustomTextField(
                        labelText: 'Ammo Type', controller: ammoTypeController),
                    SizedBox(height: 16),
                    // ExitSaveButton(
                    //   firstButton: 'Exit',
                    //   onTapFirstButton: () => Navigator.pop(context),
                    //   secondButton: 'Save',
                    //   onTapSecondButton: () async {
                    //     if (_formKey.currentState!.validate()) {
                    //       FirearmEntity firearmEntity = FirearmEntity(
                    //           type: gunTypeController.text,
                    //           brand: brandController.text,
                    //           model: modelController.text,
                    //           generation: generationController.text,
                    //           caliber: caliberController.text,
                    //           firingMachanism: firingMechController.text,
                    //           ammoType: ammoTypeController.text);
                    //       // BotToast.showLoading();
                    //       FirearmEntity? entity = await FirearmDbHelper()
                    //           .addNewFirearm('user', firearmEntity);
                    //       // BotToast.closeAllLoading();
                    //       widget.stageEntity.firearm = entity;
                    //       if (context.mounted) {
                    //         context.read<StageBloc>().add(StageUpdateEvent(
                    //             stageEntity: widget.stageEntity
                    //                 .copyWith(firearm: entity)));
                    //         Navigator.pop(context);
                    //         Navigator.pop(context);
                    //       }
                    //     } else {
                    //       !isAutoValidate
                    //           ? context.read<AutoValidationCubit>().enableAuto()
                    //           : '';
                    //     }
                    //   },
                    // ),
                    SizedBox(
                      height: 20,
                    )
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

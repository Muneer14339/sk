// lib/armory/presentation/widgets/add_forms/add_firearm_form.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/validators/caliber_validator.dart';
import '../../../domain/entities/armory_firearm.dart';
import '../../../domain/entities/dropdown_option.dart';
import '../../bloc/armory_bloc.dart';
import '../../bloc/armory_event.dart';
import '../../bloc/armory_state.dart';
import '../../bloc/dropdown/dropdown_bloc.dart';
import '../../bloc/dropdown/dropdown_event.dart';
import '../../bloc/dropdown/dropdown_state.dart';
import '../common/armory_constants.dart';
import '../common/common_widgets.dart';
import '../common/dialog_widgets.dart';

class AddFirearmForm extends StatefulWidget {
  final String userId;

  const AddFirearmForm({super.key, required this.userId});

  @override
  State<AddFirearmForm> createState() => _AddFirearmFormState();
}

class _AddFirearmFormState extends State<AddFirearmForm> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{};
  final _dropdownValues = <String, String?>{};
  final _errors = <String, String>{};

  List<DropdownOption> _firearmBrands = [];
  List<DropdownOption> _firearmModels = [];
  List<DropdownOption> _firearmGenerations = [];
  List<DropdownOption> _firearmMakes = [];
  List<DropdownOption> _firearmMechanisms = [];
  List<DropdownOption> _calibers = [];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  bool get _shouldUseGridLayout {
    final orientation = MediaQuery.of(context).orientation;
    return orientation == Orientation.landscape;
  }

  void _loadBrandsForType(String type) {
    setState(() {
      _clearAllDependentDropdowns();
    });
    context.read<DropdownBloc>().add(
      LoadDropdownEvent(
        key: 'firearm_brands',
        type: DropdownType.firearmBrands,
        filterValue: type,
      ),
    );
  }

  void _loadModelsForBrand(String brand) {
    setState(() {
      _firearmModels.clear();
      _clearDependentDropdowns(['model', 'generation', 'caliber', 'firingMechanism', 'make']);
    });

    final filterBrand = DialogWidgets.isCustomValue(brand) ? '' : brand;
    context.read<DropdownBloc>().add(
      LoadDropdownEvent(
        key: 'firearm_models',
        type: DropdownType.firearmModels,
        filterValue: filterBrand,
      ),
    );
  }

  void _loadGenerationsForModel(String model) {
    setState(() {
      _firearmGenerations.clear();
      _clearDependentDropdowns(['generation', 'caliber', 'firingMechanism', 'make']);
    });

    final filterModel = DialogWidgets.isCustomValue(model) ? '' : model;
    context.read<DropdownBloc>().add(
      LoadDropdownEvent(
        key: 'firearm_generations',
        type: DropdownType.firearmGenerations,
        filterValue: filterModel,
      ),
    );
  }

  void _loadCalibersForSelection(String generation) {
    setState(() {
      _calibers.clear();
      _clearDependentDropdowns(['caliber', 'firingMechanism', 'make']);
    });

    final filterGeneration = DialogWidgets.isCustomValue(generation) ? '' : generation;
    context.read<DropdownBloc>().add(
      LoadDropdownEvent(
        key: 'firearm_calibers',
        type: DropdownType.calibers,
        filterValue: filterGeneration,
      ),
    );
  }

  void _loadFiringMechanismsForSelection(String caliber) {
    setState(() {
      _firearmMechanisms.clear();
      _clearDependentDropdowns(['firingMechanism', 'make']);
    });

    final filterCaliber = DialogWidgets.isCustomValue(caliber) ? '' : caliber;
    context.read<DropdownBloc>().add(
      LoadDropdownEvent(
        key: 'firearm_mechanisms',
        type: DropdownType.firearmFiringMechanisms,
        filterValue: filterCaliber,
      ),
    );
  }

  void _loadMakesForSelection(String firingMechanism) {
    setState(() {
      _firearmMakes.clear();
      _dropdownValues['make'] = null;
    });

    final filterMechanism = DialogWidgets.isCustomValue(firingMechanism) ? '' : firingMechanism;
    context.read<DropdownBloc>().add(
      LoadDropdownEvent(
        key: 'firearm_makes',
        type: DropdownType.firearmMakes,
        filterValue: filterMechanism,
      ),
    );
  }

  void _clearAllDependentDropdowns() {
    _firearmBrands.clear();
    _firearmModels.clear();
    _firearmGenerations.clear();
    _firearmMakes.clear();
    _firearmMechanisms.clear();
    _calibers.clear();
    _dropdownValues['brand'] = null;
    _dropdownValues['model'] = null;
    _dropdownValues['generation'] = null;
    _dropdownValues['make'] = null;
    _dropdownValues['firingMechanism'] = null;
    _dropdownValues['caliber'] = null;
  }

  void _clearDependentDropdowns(List<String> fields) {
    for (final field in fields) {
      _dropdownValues[field] = null;
      switch (field) {
        case 'model':
          _firearmModels.clear();
          break;
        case 'generation':
          _firearmGenerations.clear();
          break;
        case 'caliber':
          _calibers.clear();
          break;
        case 'firingMechanism':
          _firearmMechanisms.clear();
          break;
        case 'make':
          _firearmMakes.clear();
          break;
      }
    }
  }

  void _onBrandChanged(String? value) {
    setState(() => _dropdownValues['brand'] = value);
    if (value != null) {
      _loadModelsForBrand(value);
    }
  }

  void _onModelChanged(String? value) {
    setState(() => _dropdownValues['model'] = value);
    if (value != null && _dropdownValues['brand'] != null) {
      _loadGenerationsForModel(value);
    }
  }

  void _onGenerationChanged(String? value) {
    setState(() => _dropdownValues['generation'] = value);
    if (value != null) {
      _loadCalibersForSelection(value);
    }
  }

  void _onCaliberChanged(String? value) {
    setState(() => _dropdownValues['caliber'] = value);
    if (value != null) {
      _loadFiringMechanismsForSelection(value);
    }
  }

  void _onFiringMechanismChanged(String? value) {
    setState(() => _dropdownValues['firingMechanism'] = value);
    if (value != null) {
      _loadMakesForSelection(value);
    }
  }

  void _initializeControllers() {
    final fields = ['make', 'model', 'nickname', 'serial', 'notes'];
    for (final field in fields) {
      _controllers[field] = TextEditingController();
    }

    _dropdownValues['status'] = 'available';
    _dropdownValues['condition'] = 'good';
  }

  void _handleDropdownOptionsLoaded(String key, List<DropdownOption> options) {
    setState(() {
      switch (key) {
        case 'firearm_brands':
          _firearmBrands = options;
          break;
        case 'firearm_models':
          _firearmModels = options;
          break;
        case 'firearm_generations':
          _firearmGenerations = options;
          break;
        case 'firearm_calibers':
          _calibers = options;
          break;
        case 'firearm_mechanisms':
          _firearmMechanisms = options;
          break;
        case 'firearm_makes':
          _firearmMakes = options;
          break;
      }
    });
  }

  @override
  void dispose() {
    _controllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<DropdownBloc, DropdownState>(
          listener: (context, state) {
            if (state is DropdownLoaded) {
              _handleDropdownOptionsLoaded(state.key, state.options);
            }
          },
        ),
        BlocListener<ArmoryBloc, ArmoryState>(
          listener: (context, state) {
            if (state is ArmoryActionSuccess) {
              context.read<ArmoryBloc>().add(const HideFormEvent());
            }
          },
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: _buildForm()),
          BlocBuilder<ArmoryBloc, ArmoryState>(
            builder: (context, state) {
              return _buildActions(state);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActions(ArmoryState state) {
    return Container(
      padding: const EdgeInsets.all(ArmoryConstants.dialogPadding),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.border(context))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => context.read<ArmoryBloc>().add(const HideFormEvent()),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: state is ArmoryLoadingAction ? null : _saveFirearm,
            child: state is ArmoryLoadingAction
                ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.textPrimary(context),
              ),
            )
                : const Text('Save Firearm'),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(ArmoryConstants.dialogPadding),
      child: Form(
        key: _formKey,
        child: CommonWidgets.buildResponsiveLayout(context, [
          DialogWidgets.buildDropdownField(
            context: context,
            label: 'Firearm Type *',
            value: _dropdownValues['type'],
            options: const [
              DropdownOption(value: 'Rifle', label: 'Rifle'),
              DropdownOption(value: 'Pistol', label: 'Pistol'),
              DropdownOption(value: 'Revolver', label: 'Revolver'),
              DropdownOption(value: 'Shotgun', label: 'Shotgun'),
            ],
            onChanged: (value) {
              setState(() => _dropdownValues['type'] = value);
              if (value != null) _loadBrandsForType(value);
            },
            isRequired: true,
          ),
          BlocBuilder<DropdownBloc, DropdownState>(
            builder: (context, dropdownState) {
              final isLoading = dropdownState is DropdownLoading &&
                  dropdownState.loadingKey == 'firearm_brands';
              return DialogWidgets.buildDropdownFieldWithCustom(
                context: context,
                label: 'Brand *',
                value: _dropdownValues['brand'],
                options: _firearmBrands,
                onChanged: _onBrandChanged,
                customFieldLabel: 'Brand',
                customHintText: 'e.g., Custom Manufacturer',
                isRequired: true,
                isLoading: isLoading,
                enabled: _dropdownValues['type'] != null,
              );
            },
          ),
          BlocBuilder<DropdownBloc, DropdownState>(
            builder: (context, dropdownState) {
              final isLoading = dropdownState is DropdownLoading &&
                  dropdownState.loadingKey == 'firearm_models';
              return DialogWidgets.buildDropdownFieldWithCustom(
                context: context,
                label: 'Model *',
                value: _dropdownValues['model'],
                options: _firearmModels,
                onChanged: _onModelChanged,
                customFieldLabel: 'Model',
                customHintText: 'e.g., Custom Model Name',
                isRequired: true,
                isLoading: isLoading,
                enabled: _dropdownValues['brand'] != null,
              );
            },
          ),
          BlocBuilder<DropdownBloc, DropdownState>(
            builder: (context, dropdownState) {
              final isLoading = dropdownState is DropdownLoading &&
                  dropdownState.loadingKey == 'firearm_generations';
              return DialogWidgets.buildDropdownFieldWithCustom(
                context: context,
                label: 'Generation *',
                value: _dropdownValues['generation'],
                options: _firearmGenerations,
                onChanged: _onGenerationChanged,
                customFieldLabel: 'Generation',
                customHintText: 'e.g., Gen 5, Mk II',
                isLoading: isLoading,
                enabled: _dropdownValues['model'] != null,
                isRequired: true,
              );
            },
          ),
          BlocBuilder<DropdownBloc, DropdownState>(
            builder: (context, dropdownState) {
              final isLoading = dropdownState is DropdownLoading &&
                  dropdownState.loadingKey == 'firearm_calibers';
              return DialogWidgets.buildDropdownFieldWithCustom(
                context: context,
                label: 'Caliber *',
                value: _dropdownValues['caliber'],
                options: _calibers,
                onChanged: _onCaliberChanged,
                customFieldLabel: 'Caliber',
                customHintText: 'e.g., .300 WinMag',
                isRequired: true,
                isLoading: isLoading,
                enabled: _dropdownValues['brand'] != null,
                customValueFormatter: (customValue) {
                  final firearmType = _dropdownValues['type'];
                  if (firearmType != null && firearmType.isNotEmpty) {
                    return '$customValue ($firearmType)';
                  }
                  return customValue;
                },
                validator: (value) => CaliberValidator.validate(value),
              );
            },
          ),
          BlocBuilder<DropdownBloc, DropdownState>(
            builder: (context, dropdownState) {
              final isLoading = dropdownState is DropdownLoading &&
                  dropdownState.loadingKey == 'firearm_mechanisms';
              return DialogWidgets.buildDropdownFieldWithCustom(
                context: context,
                label: 'Firing Mechanism *',
                value: _dropdownValues['firingMechanism'],
                options: _firearmMechanisms,
                onChanged: _onFiringMechanismChanged,
                customFieldLabel: 'Firing Mechanism',
                customHintText: 'e.g., Custom Action',
                isLoading: isLoading,
                enabled: _dropdownValues['type'] != null,
                isRequired: true,
              );
            },
          ),
          BlocBuilder<DropdownBloc, DropdownState>(
            builder: (context, dropdownState) {
              final isLoading = dropdownState is DropdownLoading &&
                  dropdownState.loadingKey == 'firearm_makes';
              return DialogWidgets.buildDropdownFieldWithCustom(
                context: context,
                label: 'Make *',
                value: _dropdownValues['make'],
                options: _firearmMakes,
                onChanged: (value) => setState(() => _dropdownValues['make'] = value),
                customFieldLabel: 'Make',
                customHintText: 'e.g., Custom Make',
                isRequired: true,
                isLoading: isLoading,
                enabled: _dropdownValues['type'] != null,
              );
            },
          ),
          DialogWidgets.buildTextField(
            context: context,
            label: 'Nickname/Identifier *',
            controller: _controllers['nickname']!,
            isRequired: true,
            maxLength: 20,
          ),
          DialogWidgets.buildDropdownField(
            context: context,
            label: 'Status *',
            value: _dropdownValues['status'],
            options: const [
              DropdownOption(value: 'available', label: 'Available'),
              DropdownOption(value: 'in-use', label: 'In Use'),
              DropdownOption(value: 'maintenance', label: 'Maintenance'),
            ],
            onChanged: (value) => setState(() => _dropdownValues['status'] = value),
            isRequired: true,
          ),
          DialogWidgets.buildTextField(
            context: context,
            label: 'Serial Number',
            controller: _controllers['serial']!,
            maxLength: 20,
          ),
          _shouldUseGridLayout
              ? SizedBox(
            width: double.infinity,
            child: DialogWidgets.buildTextField(
              context: context,
              label: 'Notes',
              controller: _controllers['notes']!,
              maxLines: 3,
              maxLength: 200,
              hintText: 'Purpose, setup, special considerations, etc.',
            ),
          )
              : DialogWidgets.buildTextField(
            context: context,
            label: 'Notes',
            controller: _controllers['notes']!,
            maxLines: 3,
            maxLength: 200,
            hintText: 'Purpose, setup, special considerations, etc.',
          ),
        ], _shouldUseGridLayout),
      ),
    );
  }

  void _saveFirearm() {
    if (!_formKey.currentState!.validate()) return;

    bool hasErrors = false;
    final requiredDropdowns = {
      'type': 'Firearm type is required',
      'brand': 'Brand is required',
      'model': 'Model is required',
      'make': 'Make is required',
      'caliber': 'Caliber is required',
      'status': 'Status is required',
    };

    requiredDropdowns.forEach((field, errorMessage) {
      if (_dropdownValues[field] == null) {
        setState(() => _errors[field] = errorMessage);
        hasErrors = true;
      }
    });

    final nickname = _controllers['nickname']?.text.trim() ?? '';
    if (nickname.isEmpty) {
      setState(() => _errors['nickname'] = 'Nickname is required and must be unique');
      hasErrors = true;
    }

    if (hasErrors) return;

    final firearm = ArmoryFirearm(
      type: _dropdownValues['type']!,
      make: DialogWidgets.getDisplayValue(_dropdownValues['make']),
      model: DialogWidgets.getDisplayValue(_dropdownValues['model']),
      caliber: DialogWidgets.getDisplayValue(_dropdownValues['caliber']),
      nickname: nickname,
      status: _dropdownValues['status']!,
      serial: _controllers['serial']?.text.trim(),
      notes: _controllers['notes']?.text.trim(),
      brand: DialogWidgets.getDisplayValue(_dropdownValues['brand']),
      generation: DialogWidgets.getDisplayValue(_dropdownValues['generation']),
      firingMechanism: DialogWidgets.getDisplayValue(_dropdownValues['firingMechanism']),
      dateAdded: DateTime.now(),
    );

    context.read<ArmoryBloc>().add(
      AddFirearmEvent(userId: widget.userId, firearm: firearm),
    );
  }
}

// lib/training/presentation/pages/training_program_builder.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:pa_sreens/training/presentation/widgets/common/training_dropdown.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_appbar.dart';
import '../../data/model/programs_model.dart';
import '../../../armory/presentation/bloc/armory_bloc.dart';
import '../../../armory/presentation/bloc/armory_event.dart';
import '../../../armory/presentation/bloc/armory_state.dart';
import '../../../armory/domain/entities/armory_firearm.dart';
import '../../../armory/domain/entities/armory_ammunition.dart';
import '../widgets/common/training_button.dart';
import '../widgets/common/training_card.dart';
import '../widgets/common/training_text_field.dart';
import 'steadiness_trainer_page.dart';

class SessionPreviewPage extends StatefulWidget {
  final ProgramsModel program;
  final BluetoothDevice connectedDevice;
  final String alertsInfo;
  final String drillInfo;
  final String audioType;

  const SessionPreviewPage({
    super.key,
    required this.program,
    required this.connectedDevice,
    required this.alertsInfo,
    required this.drillInfo,
    required this.audioType,
  });

  @override
  State<SessionPreviewPage> createState() => _SessionPreviewPageState();
}

class _SessionPreviewPageState extends State<SessionPreviewPage> {
  final _sessionNameController = TextEditingController();
  final _rangeNameController = TextEditingController();
  final _notesController = TextEditingController();

  ArmoryFirearm? _firearm;
  ArmoryAmmunition? _ammunition;

  final List<String> _rangeOptions = [
    'Thunder Range — Indoor • Bradenton, FL',
    'Manatee Gun & Archery — Outdoor • Myakka City, FL',
    'Shooter\'s World — Indoor • Tampa, FL',
    'Knight Trail Park — Outdoor • Nokomis, FL',
  ];


  @override
  void initState() {
    super.initState();
    if (widget.program.loadout != null) {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        context.read<ArmoryBloc>().add(LoadFirearmsEvent(userId: userId));
        context.read<ArmoryBloc>().add(LoadAmmunitionEvent(userId: userId));
      }
    }
  }

  @override
  void dispose() {
    _sessionNameController.dispose();
    _rangeNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background(context),
      appBar: customAppBar(
        title: 'Preview & Configure',
        context: context,
        showBackButton: false,
      ),
      body: BlocListener<ArmoryBloc, ArmoryState>(
        listener: (context, state) {
          if (state is FirearmsLoaded) {
            final firearmId = widget.program.loadout?.firearmId;
            if (firearmId != null) {
              setState(() {
                _firearm = state.firearms.firstWhere((f) => f.id == firearmId, orElse: () => state.firearms.first);
              });
            }
          } else if (state is AmmunitionLoaded) {
            final ammoId = widget.program.loadout?.ammunitionId;
            if (ammoId != null) {
              setState(() {
                _ammunition = state.ammunition.firstWhere((a) => a.id == ammoId, orElse: () => state.ammunition.first);
              });
            }
          }
        },
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: AppTheme.paddingLarge,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TrainingCard(
                      title: 'Session Information',
                      child: Column(
                        children: [
                          TrainingTextField(
                            controller: _sessionNameController,
                            label: 'Session Name',
                            hint: 'e.g., Morning Practice - Bill Drill',
                            isRequired: true,
                          ),
                          const SizedBox(height: AppTheme.spacingLarge),
                          TrainingDropdown(
                            label: 'Range Name',
                            value: _rangeNameController.text.isNotEmpty
                                ? _rangeNameController.text
                                : _rangeOptions.first,
                            items: _rangeOptions,
                            onChanged: (newValue) {
                              setState(() {
                                _rangeNameController.text = newValue!;
                              });
                            },
                          ),
                          const SizedBox(height: AppTheme.spacingLarge),
                          TrainingTextField(
                            controller: _notesController,
                            label: 'Session Notes (Optional)',
                            hint: 'Add any notes about this session...',
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXXLarge),
                    TrainingCard(
                      title: 'Loadout Summary',
                      child: Row(
                        children: [
                          Expanded(child: _buildLoadoutInfo(isFirearm: true)),
                          const SizedBox(width: AppTheme.spacingLarge),
                          Expanded(child: _buildLoadoutInfo(isFirearm: false)),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXXLarge),
                    TrainingCard(
                      title: 'Drill Summary',
                      child: Text(
                        widget.drillInfo,
                        style: AppTheme.bodyMedium(context).copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: AppTheme.paddingLarge,
              decoration: AppTheme.cardDecoration(context),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: TrainingButton(
                        label: 'Back',
                        type: ButtonType.outlined,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingLarge),
                    Expanded(
                      child: TrainingButton(
                        label: 'Start Session',
                        onPressed: _startSession,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadoutInfo({required bool isFirearm}) {
    return Container(
      padding: AppTheme.paddingLarge,
      decoration: AppTheme.inputDecoration(context),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  isFirearm ? 'FIREARM' : 'AMMUNITION',
                  style: AppTheme.labelSmall(context).copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  isFirearm
                      ? (_firearm != null ? '${_firearm!.make} ${_firearm!.model}' : widget.program.loadout?.name ?? 'N/A')
                      : (_ammunition != null ? '${_ammunition!.brand} ${_ammunition!.line ?? ''}'.trim() : 'N/A'),
                  style: AppTheme.bodyMedium(context).copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  isFirearm
                      ? (_firearm != null ? '${_firearm!.caliber} ${_firearm!.type}' : 'Loading...')
                      : (_ammunition != null ? '${_ammunition!.bullet}' : 'Loading...'),
                  style: AppTheme.labelMedium(context),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _startSession() {
    if (_sessionNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please enter a Session Name', style: AppTheme.bodyMedium(context)),
        backgroundColor: AppTheme.error(context),
      ));
      return;
    }
    if (_rangeNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please select a Range Name', style: AppTheme.bodyMedium(context)),
        backgroundColor: AppTheme.error(context),
      ));
      return;
    }

    final updatedProgram = widget.program.copyWith(
      programName: _sessionNameController.text,
      programDescription: _notesController.text,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => SteadinessTrainerPage(program: updatedProgram),
      ),
    );
  }
}
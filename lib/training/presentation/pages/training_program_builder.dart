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
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCompactCard(
                      title: 'Session Information',
                      child: Column(
                        children: [
                          TrainingTextField(
                            controller: _sessionNameController,
                            label: 'Session Name',
                            hint: 'e.g., Morning Practice - Bill Drill',
                            isRequired: true,
                          ),
                          const SizedBox(height: 12),
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
                          const SizedBox(height: 12),
                          TrainingTextField(
                            controller: _notesController,
                            label: 'Session Notes (Optional)',
                            hint: 'Add any notes about this session...',
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildCompactCard(
                      title: 'Loadout Summary',
                      child: Row(
                        children: [
                          Expanded(child: _buildLoadoutInfo(isFirearm: true)),
                          const SizedBox(width: 10),
                          Expanded(child: _buildLoadoutInfo(isFirearm: false)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildCompactCard(
                      title: 'Drill Summary',
                      child: Text(
                        widget.drillInfo,
                        style: AppTheme.bodyMedium(context).copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
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
                    const SizedBox(width: 12),
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

  Widget _buildCompactCard({required String title, required Widget child}) {
    return Container(
      width: double.maxFinite,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: AppTheme.border(context).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.titleMedium(context).copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildLoadoutInfo({required bool isFirearm}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: AppTheme.inputDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isFirearm ? 'FIREARM' : 'AMMUNITION',
            style: AppTheme.labelSmall(context).copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              fontSize: 9,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isFirearm
                ? (_firearm != null ? '${_firearm!.make} ${_firearm!.model}' : widget.program.loadout?.name ?? 'N/A')
                : (_ammunition != null ? '${_ammunition!.brand} ${_ammunition!.line ?? ''}'.trim() : 'N/A'),
            style: AppTheme.bodyMedium(context).copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            isFirearm
                ? (_firearm != null ? '${_firearm!.caliber} ${_firearm!.type}' : 'Loading...')
                : (_ammunition != null ? '${_ammunition!.bullet}' : 'Loading...'),
            style: AppTheme.labelMedium(context).copyWith(fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
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

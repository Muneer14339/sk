import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_appbar.dart';
import '../../data/model/programs_model.dart';
import '../../../armory/presentation/bloc/armory_bloc.dart';
import '../../../armory/presentation/bloc/armory_event.dart';
import '../../../armory/presentation/bloc/armory_state.dart';
import '../../../armory/domain/entities/armory_firearm.dart';
import '../../../armory/domain/entities/armory_ammunition.dart';
import '../bloc/training_session/training_session_bloc.dart';
import '../bloc/training_session/training_session_event.dart';
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

  @override
  void initState() {
    super.initState();
    if (widget.program.loadout != null) {
      final userId = FirebaseAuth.instance.currentUser?.uid; // Replace with actual user ID
      context.read<ArmoryBloc>().add(LoadFirearmsEvent(userId: userId!));
      context.read<ArmoryBloc>().add(LoadAmmunitionEvent(userId: userId));
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
                _firearm = state.firearms.firstWhere(
                      (f) => f.id == firearmId,
                  orElse: () => state.firearms.first,
                );
              });
            }
          } else if (state is AmmunitionLoaded) {
            final ammoId = widget.program.loadout?.ammunitionId;
            if (ammoId != null) {
              setState(() {
                _ammunition = state.ammunition.firstWhere(
                      (a) => a.id == ammoId,
                  orElse: () => state.ammunition.first,
                );
              });
            }
          }
        },
        child: SingleChildScrollView(
          padding: AppTheme.paddingLarge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                'Session Information',
                Column(
                  children: [
                    _buildTextField(
                      controller: _sessionNameController,
                      label: 'Session Name',
                      hint: 'e.g., Morning Practice - Bill Drill',
                      isRequired: true,
                    ),
                    const SizedBox(height: AppTheme.spacingLarge),
                    _buildTextField(
                      controller: _rangeNameController,
                      label: 'Range Name',
                      hint: 'Select range',
                      isRequired: true,
                      readOnly: true,
                      onTap: _showRangeDialog,
                    ),
                    const SizedBox(height: AppTheme.spacingLarge),
                    _buildTextField(
                      controller: _notesController,
                      label: 'Session Notes (Optional)',
                      hint: 'Add any notes about this session...',
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingXXLarge),
              _buildSection(
                'Loadout Summary',
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: AppTheme.paddingLarge,
                          decoration: AppTheme.inputDecoration(context),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              double width = constraints.maxWidth;
                              double titleSize = width * 0.06; // responsive title
                              double mainTextSize = width * 0.07; // main info text
                              double subTextSize = width * 0.05; // secondary text

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'FIREARM',
                                      style: AppTheme.labelSmall(context).copyWith(
                                        color: AppTheme.textSecondary(context),
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                        fontSize: titleSize,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      _firearm != null
                                          ? '${_firearm!.make} ${_firearm!.model}'
                                          : widget.program.loadout?.name ?? 'N/A',
                                      style: AppTheme.bodyMedium(context).copyWith(
                                        fontWeight: FontWeight.w700,
                                        fontSize: mainTextSize,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      _firearm != null
                                          ? '${_firearm!.caliber} ${_firearm!.type}'
                                          : 'Loading...',
                                      style: AppTheme.labelMedium(context).copyWith(
                                        color: AppTheme.textSecondary(context),
                                        fontSize: subTextSize,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: AppTheme.paddingLarge,
                          decoration: AppTheme.inputDecoration(context),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              double width = constraints.maxWidth;
                              double titleSize = width * 0.06;
                              double mainTextSize = width * 0.07;
                              double subTextSize = width * 0.05;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'AMMUNITION',
                                      style: AppTheme.labelSmall(context).copyWith(
                                        color: AppTheme.textSecondary(context),
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                        fontSize: titleSize,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      _ammunition != null
                                          ? '${_ammunition!.brand} ${_ammunition!.line ?? ''}'.trim()
                                          : 'N/A',
                                      style: AppTheme.bodyMedium(context).copyWith(
                                        fontWeight: FontWeight.w700,
                                        fontSize: mainTextSize,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      _ammunition != null
                                          ? '${_ammunition!.bullet}'
                                          : 'Loading...',
                                      style: AppTheme.labelMedium(context).copyWith(
                                        color: AppTheme.textSecondary(context),
                                        fontSize: subTextSize,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  )

              ),
              const SizedBox(height: AppTheme.spacingXXLarge),
              _buildSection(
                'Drill Summary',
                Container(
                  width: double.maxFinite,
                  padding: AppTheme.paddingLarge,
                  decoration: AppTheme.inputDecoration(context),
                  child: Text(
                    widget.drillInfo,
                    style: AppTheme.bodyMedium(context)
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
      bottomSheet: Container(
        padding: AppTheme.paddingLarge,
        decoration: AppTheme.cardDecoration(context),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: AppTheme.spacingLarge),
              Expanded(
                child: ElevatedButton(
                  onPressed: _startSession,
                  child: const Text('Start Session'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, Widget child) {
    return Container(
      decoration: AppTheme.cardDecoration(context),
      padding: AppTheme.paddingXLarge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTheme.headingSmall(context)),
          const SizedBox(height: AppTheme.spacingLarge),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool isRequired = false,
    bool readOnly = false,
    VoidCallback? onTap,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isRequired ? '$label *' : label,
          style: AppTheme.labelLarge(context),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: AppTheme.bodyMedium(context),
          decoration: const InputDecoration(),
        ),
      ],
    );
  }

  void _showRangeDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.surface(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        ),
        child: Padding(
          padding: AppTheme.paddingLarge,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Select Range', style: AppTheme.headingMedium(context)),
              const SizedBox(height: AppTheme.spacingLarge),
              Divider(color: AppTheme.border(context)),
              const SizedBox(height: AppTheme.spacingLarge),
              _buildRangeOption('Thunder Range', 'Indoor • Bradenton, FL'),
              _buildRangeOption('Manatee Gun & Archery', 'Outdoor • Myakka City, FL'),
              _buildRangeOption('Shooter\'s World', 'Indoor • Tampa, FL'),
              _buildRangeOption('Knight Trail Park', 'Outdoor • Nokomis, FL'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRangeOption(String title, String location) {
    return GestureDetector(
      onTap: () {
        _rangeNameController.text = title;
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: AppTheme.paddingLarge,
        decoration: AppTheme.inputDecoration(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTheme.titleMedium(context)),
            const SizedBox(height: 4),
            Text(location, style: AppTheme.labelMedium(context)),
          ],
        ),
      ),
    );
  }

  void _startSession() {
    if (_sessionNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Please enter a Session Name'),
        backgroundColor: AppTheme.error(context),
      ));
      return;
    }
    if (_rangeNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Please select a Range Name'),
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
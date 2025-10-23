// lib/training/presentation/pages/session_preview_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../../data/model/programs_model.dart';
import '../bloc/training_session/training_session_bloc.dart';
import '../bloc/training_session/training_session_event.dart';
import 'steadiness_trainer_page.dart';

class SessionPreviewPage extends StatefulWidget {
  final ProgramsModel program;
  final BluetoothDevice connectedDevice;
  final String loadoutInfo;
  final String alertsInfo;
  final String drillInfo;

  const SessionPreviewPage({
    super.key,
    required this.program,
    required this.connectedDevice,
    required this.loadoutInfo,
    required this.alertsInfo,
    required this.drillInfo,
  });

  @override
  State<SessionPreviewPage> createState() => _SessionPreviewPageState();
}

class _SessionPreviewPageState extends State<SessionPreviewPage> {
  final _sessionNameController = TextEditingController();
  final _rangeNameController = TextEditingController();
  final _notesController = TextEditingController();
  final _shotCountController = TextEditingController(text: '10');

  @override
  void dispose() {
    _sessionNameController.dispose();
    _rangeNameController.dispose();
    _notesController.dispose();
    _shotCountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Preview & Configure',
                style: AppTheme.headingLarge(context),
              ),
              const SizedBox(height: 8),
              Text(
                'Review your setup and complete session details',
                style: AppTheme.bodyMedium(context).copyWith(
                  color: AppTheme.textSecondary(context),
                ),
              ),
              const SizedBox(height: 24),
              _buildSection(
                title: 'Session Information',
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _sessionNameController,
                      label: 'Session Name',
                      hint: 'e.g., Morning Practice - Bill Drill',
                      isRequired: true,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _rangeNameController,
                      label: 'Range Name',
                      hint: 'Select range',
                      isRequired: true,
                      readOnly: true,
                      onTap: _showRangeDialog,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _notesController,
                      label: 'Session Notes (Optional)',
                      hint: 'Add any notes about this session...',
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildSection(
                title: 'Loadout Summary',
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant(context),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.loadoutInfo,
                    style: AppTheme.bodyMedium(context).copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildSection(
                title: 'Drill Configuration',
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariant(context),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.drillInfo,
                            style: AppTheme.bodyMedium(context).copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _shotCountController,
                            label: 'Number of Shots',
                            hint: 'Enter shot count',
                            keyboardType: TextInputType.number,
                            isRequired: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppTheme.surfaceVariant(context),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: AppTheme.border(context).withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  child: Text(
                    'Back',
                    style: AppTheme.button(context),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _startSession,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppTheme.primary(context),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Start Session',
                    style: AppTheme.button(context).copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.border(context).withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.titleLarge(context).copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
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
        Row(
          children: [
            Text(
              label,
              style: AppTheme.labelLarge(context).copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary(context),
              ),
            ),
            if (isRequired)
              Text(
                ' *',
                style: AppTheme.labelLarge(context).copyWith(
                  color: AppTheme.error(context),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: AppTheme.bodyMedium(context),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTheme.bodyMedium(context).copyWith(
              color: AppTheme.textSecondary(context),
            ),
            filled: true,
            fillColor: AppTheme.surfaceVariant(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: AppTheme.border(context),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: AppTheme.border(context),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: AppTheme.primary(context),
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
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
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppTheme.border(context).withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Select Range',
                      style: AppTheme.headingMedium(context),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      color: AppTheme.textPrimary(context),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              constraints: const BoxConstraints(maxHeight: 400),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildRangeItem('Thunder Range', 'Indoor • Bradenton, FL'),
                  _buildRangeItem('Manatee Gun & Archery', 'Outdoor • Myakka City, FL'),
                  _buildRangeItem('Shooter\'s World', 'Indoor • Tampa, FL'),
                  _buildRangeItem('Knight Trail Park', 'Outdoor • Nokomis, FL'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRangeItem(String name, String location) {
    return GestureDetector(
      onTap: () {
        _rangeNameController.text = name;
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.border(context).withValues(alpha: 0.1),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: AppTheme.titleMedium(context).copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              location,
              style: AppTheme.bodySmall(context).copyWith(
                color: AppTheme.textSecondary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startSession() {
    if (_sessionNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a Session Name'),
          backgroundColor: AppTheme.error(context),
        ),
      );
      return;
    }

    if (_rangeNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a Range Name'),
          backgroundColor: AppTheme.error(context),
        ),
      );
      return;
    }

    final shotCount = int.tryParse(_shotCountController.text) ?? 10;
    final updatedProgram = widget.program.copyWith(
      programName: _sessionNameController.text,
      noOfShots: shotCount,
    );

    context.read<TrainingSessionBloc>().add(
      EnableSensors(device: widget.connectedDevice),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => SteadinessTrainerPage(
          program: updatedProgram,
        ),
      ),
    );
  }
}
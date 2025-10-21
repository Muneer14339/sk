// lib/features/training/presentation/widgets/calibration_wizard_dialog.dart
import 'package:flutter/material.dart';

import '../../../core/services/prefs.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/primary_button.dart';
import '../pages/calibration_page.dart';
import '../pages/sensitity_settings_page.dart';

class CalibrationWizardDialog extends StatefulWidget {
  const CalibrationWizardDialog({super.key});

  @override
  State<CalibrationWizardDialog> createState() =>
      _CalibrationWizardDialogState();
}

class _CalibrationWizardDialogState extends State<CalibrationWizardDialog> {
  String selectedCalibrationType = 'live';
  final TextEditingController _shotCountController = TextEditingController(text: '10'); // NEW
  final _formKey = GlobalKey<FormState>(); // NEW

  @override
  void dispose() {
    _shotCountController.dispose(); // NEW
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.kSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Form( // NEW: Wrap in Form
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header (existing)
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(Icons.arrow_back, color: AppColors.kTextSecondary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'CALIBRATION WIZARD',
                        style: TextStyle(
                          color: AppColors.kTextPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _openSettings(context),
                      icon: Icon(Icons.settings, color: AppColors.kTextSecondary),
                      tooltip: 'Settings',
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Description (existing)
                Text(
                  'We\'ll analyze your shooting to find optimal detection settings',
                  style: TextStyle(
                    color: AppColors.kTextSecondary,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // NEW: Shot Count Input
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Number of Shots',
                      style: TextStyle(
                        color: AppColors.kTextPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _shotCountController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: AppColors.kTextPrimary),
                      decoration: InputDecoration(
                        hintText: 'Enter shot count',
                        hintStyle: TextStyle(color: AppColors.kTextSecondary),
                        filled: true,
                        fillColor: AppColors.kBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.kTextSecondary.withOpacity(0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.kTextSecondary.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.kPrimaryTeal),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.kError),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter shot count';
                        }
                        final number = int.tryParse(value);
                        if (number == null) {
                          return 'Please enter a valid number';
                        }
                        if (number <= 0) {
                          return 'Shot count must be greater than 0';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Action Buttons (existing)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.kTextSecondary,
                          side: BorderSide(
                              color: AppColors.kTextSecondary.withOpacity(0.5)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: PrimaryButton(
                        title: 'Continue',
                        onTap: () => _startCalibration(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRadioOption(String value, String label) {
    return GestureDetector(
      onTap: () => setState(() => selectedCalibrationType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selectedCalibrationType == value
              ? AppColors.kPrimaryTeal.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selectedCalibrationType == value
                ? AppColors.kPrimaryTeal
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: selectedCalibrationType,
              onChanged: (val) =>
                  setState(() => selectedCalibrationType = val ?? 'live'),
              activeColor: AppColors.kPrimaryTeal,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: selectedCalibrationType == value
                      ? AppColors.kPrimaryTeal
                      : AppColors.kTextPrimary,
                  fontSize: 14,
                  fontWeight: selectedCalibrationType == value
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startCalibration(BuildContext context) {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final shotCount = int.parse(_shotCountController.text);

    Navigator.pop(context); // Close dialog
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CalibrationPage(
          calibrationType: selectedCalibrationType,
          targetShots: shotCount, // NEW: Pass shot count
        ),
      ),
    );
  }

  // Existing methods remain unchanged
  void _openSettings(BuildContext context) {
    String? sensPerms = prefs?.getString(sensitivityKey);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingViewPage(
            sensPerms: sensPerms?.split('/') ?? ['5', '3', '3', '3', '3', '3']),
      ),
    );
  }
}

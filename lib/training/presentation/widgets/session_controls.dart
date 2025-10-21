import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
class SessionControls extends StatelessWidget {
  const SessionControls({
    super.key,
    required this.isTraining,
    required this.isSensorEnabled,
    required this.isPaused,
    required this.startTraining,
    required this.stopTraining,
    required this.resetTrace,
    required this.finishSession,
    this.onRecalibrate, // NEW
  });

  final bool isTraining;
  final bool isSensorEnabled;
  final bool isPaused;
  final VoidCallback startTraining;
  final VoidCallback stopTraining;
  final VoidCallback resetTrace;
  final VoidCallback finishSession;
  final VoidCallback? onRecalibrate; // NEW

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Main controls row
        Row(
          children: [
            Expanded(child: _buildMainButton()),
            const SizedBox(width: 8),
            isPaused
                ? ElevatedButton.icon(
              onPressed: finishSession,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Finish Session'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.kSuccess,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            )
                : ElevatedButton.icon(
              onPressed: resetTrace,
              icon: const Icon(Icons.refresh),
              label: const Text('Reset'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.kPrimaryTeal.withValues(alpha: .12),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),

        // NEW: Recalibrate button (only show when sensors enabled)
        if (onRecalibrate != null && isSensorEnabled) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onRecalibrate,
              icon: Icon(Icons.tune, size: 18),
              label: const Text('Recalibrate Sensor'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.kPrimaryTeal,
                side: BorderSide(color: AppColors.kPrimaryTeal.withOpacity(0.5)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMainButton() {
    if (isPaused) {
      return ElevatedButton.icon(
        onPressed: startTraining,
        icon: const Icon(Icons.play_arrow),
        label: const Text('Resume'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.kSuccess,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }

    if (isTraining && isSensorEnabled) {
      return ElevatedButton.icon(
        onPressed: stopTraining,
        icon: const Icon(Icons.pause),
        label: const Text('Pause'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.kError,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: startTraining,
      icon: const Icon(Icons.play_arrow),
      label: const Text('Start Training'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.kPrimaryTeal,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
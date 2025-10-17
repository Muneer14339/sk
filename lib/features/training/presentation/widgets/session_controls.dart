import 'package:flutter/material.dart';
import 'package:pulse_skadi/core/theme/app_colors.dart';

class SessionControls extends StatelessWidget {
  const SessionControls({
    super.key,
    required this.isTraining,
    required this.isSensorEnabled,
    required this.isPaused, // NEW
    required this.startTraining,
    required this.stopTraining,
    required this.resetTrace,
    required this.finishSession, // NEW
  });

  final bool isTraining;
  final bool isSensorEnabled;
  final bool isPaused; // NEW
  final VoidCallback startTraining;
  final VoidCallback stopTraining;
  final VoidCallback resetTrace;
  final VoidCallback finishSession; // NEW

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildMainButton()),
        const SizedBox(width: 8),
        // UPDATED: Show "Finish Session" when paused, else "Reset"
        isPaused
            ? ElevatedButton.icon(
                onPressed: finishSession,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Finish Session'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.kSuccess,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              )
            : ElevatedButton.icon(
                onPressed: resetTrace,
                icon: const Icon(Icons.refresh),
                label: const Text('Reset'),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      AppColors.kPrimaryTeal.withValues(alpha: .12),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
      ],
    );
  }

  Widget _buildMainButton() {
    // Processing state (sensor enabling/disabling)
    if ((!isTraining && isSensorEnabled) || (isTraining && !isSensorEnabled)) {
      return ElevatedButton.icon(
        onPressed: null,
        icon: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        ),
        label: const Text('Processing...'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.kPrimaryTeal,
          disabledBackgroundColor: AppColors.kPrimaryTeal.withOpacity(0.6),
          disabledForegroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }

    // Paused state - Show Resume
    if (isPaused) {
      return ElevatedButton.icon(
        onPressed: startTraining,
        icon: const Icon(Icons.play_arrow),
        label: const Text('Resume'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.kSuccess,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }

    // Running state - Show Pause
    if (isTraining && isSensorEnabled) {
      return ElevatedButton.icon(
        onPressed: stopTraining,
        icon: const Icon(Icons.pause),
        label: const Text('Pause'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.kError,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }

    // Initial state - Show Start
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

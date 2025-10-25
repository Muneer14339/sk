// lib/training/presentation/widgets/session_controls.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'common/training_button.dart';

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
    this.onRecalibrate,
  });

  final bool isTraining;
  final bool isSensorEnabled;
  final bool isPaused;
  final VoidCallback startTraining;
  final VoidCallback stopTraining;
  final VoidCallback resetTrace;
  final VoidCallback finishSession;
  final VoidCallback? onRecalibrate;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(child: _buildMainButton(context)),
            const SizedBox(width: 8),
            isPaused
                ? Expanded(
              child: TrainingButton(
                label: 'Finish Session',
                icon: Icons.check_circle_outline,
                type: ButtonType.success,
                onPressed: finishSession,
              ),
            )
                : Expanded(
              child: TrainingButton(
                label: 'Reset',
                icon: Icons.refresh,
                type: ButtonType.secondary,
                onPressed: resetTrace,
              ),
            ),
          ],
        ),
        if (onRecalibrate != null && isSensorEnabled) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TrainingButton(
              label: 'Recalibrate Sensor',
              icon: Icons.tune,
              type: ButtonType.outlined,
              onPressed: onRecalibrate,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMainButton(BuildContext context) {
    if (isPaused) {
      return TrainingButton(label: 'Resume', icon: Icons.play_arrow, type: ButtonType.success, onPressed: startTraining);
    }
    if (isTraining && isSensorEnabled) {
      return TrainingButton(label: 'Pause', icon: Icons.pause, type: ButtonType.error, onPressed: stopTraining);
    }
    return TrainingButton(label: 'Start Training', icon: Icons.play_arrow, onPressed: startTraining);
  }
}
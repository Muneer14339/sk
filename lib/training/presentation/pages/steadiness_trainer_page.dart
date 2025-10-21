// lib/features/training/presentation/pages/steadiness_trainer_page.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/services/prefs.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../core/widgets/custom_appbar.dart';
import '../../data/model/programs_model.dart';
import '../bloc/ble_scan/ble_scan_bloc.dart';
import '../bloc/ble_scan/ble_scan_state.dart';
import '../bloc/sensitivity_settings/counter_sens_bloc.dart';
import '../bloc/training_session/training_session_bloc.dart';
import '../bloc/training_session/training_session_event.dart';
import '../bloc/training_session/training_session_state.dart';
import '../widgets/calibration_wizard_dialog.dart';
import '../widgets/device_calibration_dialog.dart';
import '../widgets/session_controls.dart';
import '../widgets/target_display.dart';
import 'sensitity_settings_page.dart';
import 'session_summary_page.dart';

class SteadinessTrainerPage extends StatefulWidget {
  const SteadinessTrainerPage({super.key, required this.program});
  final ProgramsModel program;

  @override
  State<SteadinessTrainerPage> createState() => _SteadinessTrainerPageState();
}

class _SteadinessTrainerPageState extends State<SteadinessTrainerPage> {
  int _shotCount = 0;

  @override
  void initState() {
    super.initState();
    final bloc = context.read<TrainingSessionBloc>();
    final device = bloc.state.device;

    context.read<TrainingSessionBloc>().add(ClearLastSession(device: device!));
    context.read<TrainingSessionBloc>().add(const InitializeRingSystem());
    context.read<TrainingSessionBloc>().add(const RecomputeScoreRadii('nov'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBackground,
      appBar: customAppBar(
        title: 'Steadiness Trainer',
        context: context,
        actions: [
          Spacer(),
          IconButton(
            icon: Icon(Icons.settings, color: AppColors.kTextPrimary),
            onPressed: () {
              String? sensPerms = prefs?.getString(sensitivityKey);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingViewPage(
                    sensPerms:
                        sensPerms?.split('/') ?? ['5', '3', '3', '3', '3', '3'],
                  ),
                ),
              );
            },
          ),
          // // NEW: Calibration wizard button
          IconButton(
            icon: Icon(Icons.tune, color: AppColors.kTextPrimary),
            tooltip: 'Calibration Wizard',
            onPressed: () => _showCalibrationWizard(context),
          ),
        ],
      ),
      body: BlocConsumer<BleScanBloc, BleScanState>(
        listener: (_, bleState) {
          if (!bleState.isConnected) {
            if (_shotCount > 0) {
              _navigateToAnalysisPage(context);
            } else {
              if (!kDebugMode) {
                Navigator.pop(context);
              }
            }
            ToastUtils.showError(context, message: 'Sensor Disconnected');
          }
        },
        builder: (_, bleState) {
          return BlocConsumer<TrainingSessionBloc, TrainingSessionState>(
            listener: (_, sessionState) {
              _shotCount = sessionState.shotCount;

              // ✅ Show sensor errors to user
              if (sessionState.sensorError != null) {
                _handleSensorError(context, sessionState.sensorError!);
              }

              if (sessionState.hasNavigatedToSessionDetail &&
                  sessionState.sessionCompleted) {
                _navigateToAnalysisPage(context);
              }
            },
            builder: (_, sessionState) {
              // ✅ Read mode from bloc state (loaded at app start)
              final traceModeInt = prefs?.getInt(traceDisplayModeKey) ?? 0;
              final traceMode = TraceDisplayMode.values[traceModeInt.clamp(0, 2)];

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildProgramHeader(
                      widget.program.programName ?? '',
                      widget.program.programDescription ?? '',
                    ),
                    const SizedBox(height: 12),
                    _buildStatusCard(sessionState, widget.program),
                    const SizedBox(height: 12),
                    TargetDisplay(
                      selectedDistance: sessionState.selectedDistance,
                      tracePoints: sessionState.tracePoints,
                      visGate: sessionState.visGate,
                      thetaInstDeg: sessionState.thetaInstDeg,
                      hideOverDeg: sessionState.hideOverDeg,
                      isInPostShotMode: sessionState.isInPostShotMode,
                      postShotStartIndex: sessionState.postShotStartIndex,
                      shotMarkers: sessionState.shotMarkers,
                      lastDrawX: sessionState.lastDrawX,
                      lastDrawY: sessionState.lastDrawY,
                      isResetting: false,
                      traceDisplayMode: traceMode, // ✅ NEW parameter
                    ),
                    const SizedBox(height: 16),
                    SessionControls(
                      isSensorEnabled: sessionState.isSensorsEnabled,
                      isTraining: sessionState.isTraining,
                      isPaused: sessionState.isPaused,
                      startTraining: _startTraining,
                      stopTraining: () => _pauseTraining(sessionState),
                      resetTrace: _resetTrace,
                      finishSession: _finishSession,
                      onRecalibrate: sessionState.isSensorsEnabled ? _showRecalibrationDialog : null, // NEW
                    ),
                    const SizedBox(height: 16),
                    _buildDropdownSection(
                      title: 'Training Distance',
                      value: sessionState.selectedDistance,
                      items: sessionState.distancePresets.entries
                          .map(
                            (entry) => DropdownMenuItem(
                              value: entry.key,
                              child: Text(
                                '${entry.value['name']}${entry.value['description']}',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          context.read<TrainingSessionBloc>().add(
                                UpdateDistancePreset(val),
                              );
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildDropdownSection(
                      title: 'Angle Range to Outer Ring',
                      value: sessionState.selectedAngleRange,
                      items: sessionState.angleRangePresets.entries
                          .map(
                            (entry) => DropdownMenuItem(
                              value: entry.key,
                              child: Text(
                                '${entry.value['name']} - ${entry.value['description']}',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          context.read<TrainingSessionBloc>().add(
                                UpdateAngleRange(val),
                              );
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildShotLog(sessionState),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showRecalibrationDialog() {
    final bleState = context.read<BleScanBloc>().state;
    if (!bleState.isConnected || bleState.connectedDevice == null) {
      ToastUtils.showError(context, message: 'Device not connected');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: true, // Can dismiss (not forceful)
      builder: (_) => DeviceCalibrationDialog(
        onStartCalibration: () async {
          final device = bleState.connectedDevice!;

          // 1. Disable sensors
          context.read<TrainingSessionBloc>().add(DisableSensors(device: device));
          await Future.delayed(Duration(seconds: 1));

          // 2. Enable sensors (triggers calibration)
          context.read<TrainingSessionBloc>().add(
            EnableSensors( device: device),
          );
          await Future.delayed(Duration(seconds: 6));

          Navigator.of(context).pop();
          ToastUtils.showSuccess(context, message: 'Recalibration complete');
        },
        onFactoryReset: () async {
          await context.read<TrainingSessionBloc>().bleRepository.factoryReset(
            bleState.connectedDevice!,
          );
          ToastUtils.showSuccess(context, message: 'Factory reset completed');
        },
      ),
    );
  }

  // Add this new method:
  void _handleSensorError(BuildContext context, String error) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.kSurface,
        title: Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.kError),
            const SizedBox(width: 8),
            Text(
              'Sensor Error',
              style: TextStyle(color: AppColors.kTextPrimary),
            ),
          ],
        ),
        content: Text(error, style: TextStyle(color: AppColors.kTextSecondary)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext); // Close dialog
              Navigator.pop(context); // Navigate back to previous page
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.kPrimaryTeal,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // NEW: Show calibration wizard dialog
  void _showCalibrationWizard(BuildContext context) {
    final bleState = context.read<BleScanBloc>().state;
    if (!bleState.isConnected) {
      ToastUtils.showError(context, message: 'Please connect to sensor first');
      return;
    }

    showDialog(
      context: context,
      builder: (_) => const CalibrationWizardDialog(),
    );
  }

  void _startTraining() {
    final hapticEnabled = prefs?.getBool(hapticEnabledKey) ?? true;
    final traceModeInt = prefs?.getInt(traceDisplayModeKey) ?? 0;
    final traceMode = TraceDisplayMode.values[traceModeInt.clamp(0, 2)];

    // ✅ CHANGED: Allow training if haptic OR any visible mode
    if (!hapticEnabled && traceMode == TraceDisplayMode.hidden) {
      ToastUtils.showError(context,
          message: 'Enable Haptic or Display Mode from settings to start training');
      return;
    }

    final sessionState = context.read<TrainingSessionBloc>().state;

    if (sessionState.isPaused) {
      context.read<TrainingSessionBloc>().add(const ResumeTrainingSession());
    } else {
      context.read<TrainingSessionBloc>().add(StartTrainingSession(program: widget.program));
    }

    // final bleState = context.read<BleScanBloc>().state;
    // if (bleState.connectedDevice != null) {
    //   context.read<TrainingSessionBloc>().add(
    //     EnableSensors(
    //       program: widget.program,
    //       device: bleState.connectedDevice!,
    //     ),
    //   );
    // }
  }

  // MODIFY: _stopTraining -> rename to _pauseTraining
  void _pauseTraining(TrainingSessionState sessionState) {
    // final bleState = context.read<BleScanBloc>().state;
    // if (bleState.connectedDevice != null) {
    //   context.read<TrainingSessionBloc>().add(
    //         DisableSensors(device: bleState.connectedDevice!),
    //       );
    // }
    if (sessionState.shotCount > 0) {
      context.read<TrainingSessionBloc>().add(
            const PauseTrainingSession(),
          ); // NEW
    } else {
      context.read<TrainingSessionBloc>().add(
            const StopTrainingSession(),
          ); // NEW
    }
  }

  // NEW: Finish session method
  void _finishSession() {
    // final bleState = context.read<BleScanBloc>().state;
    // if (bleState.connectedDevice != null) {
    //   context.read<TrainingSessionBloc>().add(
    //         DisableSensors(device: bleState.connectedDevice!),
    //       );
    // }
    context.read<TrainingSessionBloc>().add(const StopTrainingSession());
    _navigateToAnalysisPage(context);
  }

  void _stopTraining() {
    final bleState = context.read<BleScanBloc>().state;
    if (bleState.connectedDevice != null) {
      context.read<TrainingSessionBloc>().add(
            DisableSensors(device: bleState.connectedDevice!),
          );
    }
    context.read<TrainingSessionBloc>().add(const StopTrainingSession());
  }

  void _resetTrace() {
    context.read<TrainingSessionBloc>().add(const ResetTrace());
  }

  void _navigateToAnalysisPage(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const SessionSummaryPage(), // Changed from ManticXAnalysisPage
      ),
    );
  }

  Widget _buildProgramHeader(String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.kPrimaryTeal,
            AppColors.kPrimaryTeal.withValues(alpha: .6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppColors.kTextPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: TextStyle(color: AppColors.kTextPrimary, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Update _buildStatusCard method in steadiness_trainer_page.dart

  Widget _buildStatusCard(TrainingSessionState s, ProgramsModel p) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.kBackground.withOpacity(0.8)),
      ),
      child: Column(
        children: [
          // First row - existing metrics
          Row(
            children: [
              _buildMetric(
                "Shots",
                "${s.shotCount}/${p.noOfShots}",
                Icons.gps_fixed,
              ),
              const SizedBox(width: 8),
              _buildMetric(
                "Time",
                _formatDuration(
                  DateTime.now().difference(
                    s.sessionStartTime ?? DateTime.now(),
                  ),
                ),
                Icons.timer,
                color: s.isTraining ? AppColors.kPrimaryTeal : null,
              ),
              const SizedBox(width: 8),
              _buildMetric(
                "Distance",
                "${s.selectedDistance} m",
                Icons.straighten,
                color: s.isTraining ? AppColors.kPrimaryTeal : null,
              ),
            ],
          ),

          const SizedBox(height: 8),

          if(s.isTraining && s.sensorStream!=null)
          // ✅ NEW: Pitch, Yaw, Tilt live metrics
            Row(
              children: [
                _buildMetric(
                  "Pitch",
                  "${s.sensorStream!.pitch.toStringAsFixed(1)}°",
                  Icons.height,
                  color: AppColors.kTextPrimary,
                ),
                const SizedBox(width: 8),
                _buildMetric(
                  "Yaw",
                  "${s.sensorStream!.yaw.toStringAsFixed(1)}°",
                  Icons.explore,
                  color: AppColors.kTextPrimary,
                ),
                const SizedBox(width: 8),
                _buildMetric(
                  "Roll",
                  "${s.sensorStream!.roll.toStringAsFixed(1)}°",
                  Icons.rotate_90_degrees_ccw,
                  color: AppColors.kTextPrimary,
                ),
              ],
            ),

          // NEW: Missed shots section
          if (s.missedShotCount > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.appYellow.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.appYellow.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.appYellow,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Missed Shots: ${s.missedShotCount}",
                    style: TextStyle(
                      color: AppColors.appYellow,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Tooltip(
                    message:
                    "Shots detected by sensor but not counted (out of range or visibility issues)",
                    child: Icon(
                      Icons.info_outline,
                      color: AppColors.appYellow,
                      size: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }


  Widget _buildMetric(
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.kPrimaryTeal.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // Icon(icon, color: AppColors.kPrimaryTeal, size: 16),
            // const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(color: AppColors.kTextSecondary, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color ?? AppColors.kTextPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownSection({
    required String title,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(color: AppColors.kTextSecondary, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.kBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.kSurface.withOpacity(0.8)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: AppColors.kSurface,
              style: TextStyle(color: AppColors.kTextPrimary),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShotLog(TrainingSessionState s) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.kBackground.withOpacity(0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Shot Log",
            style: TextStyle(
              color: AppColors.kTextPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (s.shotLog.isEmpty)
            Text(
              "No shots recorded yet",
              style: TextStyle(color: AppColors.kTextSecondary),
            )
          else
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        "Time",
                        style: TextStyle(
                          color: AppColors.kTextSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        "θ (deg)",
                        style: TextStyle(
                          color: AppColors.kTextSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        "Score",
                        style: TextStyle(
                          color: AppColors.kTextSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...s.shotLog.take(10).map((shot) {
                  final time = shot['time'] as DateTime;
                  final theta = shot['theta'] as double;
                  final score = shot['score'] as int;
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: AppColors.kBackground.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}",
                            style: TextStyle(
                              color: AppColors.kTextPrimary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Expanded(
                            flex: 2,
                            child: Text(
                                theta.isNaN
                                    ? '—'
                                    : "${theta.toStringAsFixed(2)}°",
                                style: TextStyle(
                                    color: AppColors.kTextPrimary,
                                    fontSize: 13))),
                        Expanded(
                          flex: 1,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getScoreColor(score).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              score.toString(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _getScoreColor(score),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) =>
      "${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}";

  Color _getScoreColor(int score) {
    if (score >= 9) return AppColors.kSuccess;
    if (score >= 7) return const Color(0xFFF59E0B);
    if (score >= 5) return AppColors.kError;
    return AppColors.kTextSecondary;
  }
}

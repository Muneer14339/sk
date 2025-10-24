// lib/features/training/presentation/pages/steadiness_trainer_page.dart
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/services/prefs.dart';
import '../../../core/theme/app_theme.dart';
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
    context.read<TrainingSessionBloc>().add(
      UpdateDistancePreset(widget.program.recommenedDistance!),
    );
    context.read<TrainingSessionBloc>().add(
      UpdateAngleRange(widget.program.difficultyLevel!),
    );

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background(context),
      appBar: customAppBar(
        title: 'Steadiness Trainer',
        context: context,
        actions: [
          Spacer(),
          IconButton(
            icon: Icon(Icons.settings, color: AppTheme.textPrimary(context)),
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
            icon: Icon(Icons.tune, color: AppTheme.textPrimary(context)),
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

                    buildRealtimeStability(sessionState, context),

                    // const SizedBox(height: 16),
                    // _buildDropdownSection(
                    //   title: 'Training Distance',
                    //   value: sessionState.selectedDistance,
                    //   items: sessionState.distancePresets.entries
                    //       .map(
                    //         (entry) => DropdownMenuItem(
                    //           value: entry.key,
                    //           child: Text(
                    //             '${entry.value['name']}${entry.value['description']}',
                    //           ),
                    //         ),
                    //       )
                    //       .toList(),
                    //   onChanged: (val) {
                    //     if (val != null) {
                    //       context.read<TrainingSessionBloc>().add(
                    //             UpdateDistancePreset(val),
                    //           );
                    //     }
                    //   },
                    // ),
                    // const SizedBox(height: 16),
                    // _buildDropdownSection(
                    //   title: 'Angle Range to Outer Ring',
                    //   value: sessionState.selectedAngleRange,
                    //   items: sessionState.angleRangePresets.entries
                    //       .map(
                    //         (entry) => DropdownMenuItem(
                    //           value: entry.key,
                    //           child: Text(
                    //             '${entry.value['name']} - ${entry.value['description']}',
                    //           ),
                    //         ),
                    //       )
                    //       .toList(),
                    //   onChanged: (val) {
                    //     if (val != null) {
                    //       context.read<TrainingSessionBloc>().add(
                    //             UpdateAngleRange(val),
                    //           );
                    //     }
                    //   },
                    // ),
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
        backgroundColor: AppTheme.surface(context),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: AppTheme.error(context)),
            const SizedBox(width: 8),
            Text(
              'Sensor Error',
              style: TextStyle(color: AppTheme.textPrimary(context)),
            ),
          ],
        ),
        content: Text(error, style: TextStyle(color: AppTheme.textSecondary(context))),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext); // Close dialog
              Navigator.pop(context); // Navigate back to previous page
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primary(context),
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
      width: double.maxFinite,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary(context),
            AppTheme.primary(context).withValues(alpha: .6),
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
              color: AppTheme.textPrimary(context),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: TextStyle(color: AppTheme.textPrimary(context), fontSize: 14),
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
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.background(context).withOpacity(0.8)),
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
                color: s.isTraining ? AppTheme.primary(context) : null,
              ),
              const SizedBox(width: 8),
              _buildMetric(
                "Distance",
                "${s.selectedDistance} m",
                Icons.straighten,
                color: s.isTraining ? AppTheme.primary(context) : null,
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
                  color: AppTheme.textPrimary(context),
                ),
                const SizedBox(width: 8),
                _buildMetric(
                  "Yaw",
                  "${s.sensorStream!.yaw.toStringAsFixed(1)}°",
                  Icons.explore,
                  color: AppTheme.textPrimary(context),
                ),
                const SizedBox(width: 8),
                _buildMetric(
                  "Roll",
                  "${s.sensorStream!.roll.toStringAsFixed(1)}°",
                  Icons.rotate_90_degrees_ccw,
                  color: AppTheme.textPrimary(context),
                ),
              ],
            ),

          // NEW: Missed shots section
          if (s.missedShotCount > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.warning(context).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.warning(context).withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: AppTheme.warning(context),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Missed Shots: ${s.missedShotCount}",
                    style: TextStyle(
                      color: AppTheme.warning(context),
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
                      color: AppTheme.warning(context),
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
          color: AppTheme.primary(context).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // Icon(icon, color: AppTheme.primary(context), size: 16),
            // const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color ?? AppTheme.textPrimary(context),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ UPDATED: buildRealtimeStability - Professional Distance-Based Calculation
  Widget buildRealtimeStability(TrainingSessionState sessionState, BuildContext context) {
    // Calculate distance from center (200, 200)
    final double centerX = 200.0;
    final double centerY = 200.0;
    final double currentX = sessionState.lastDrawX;
    final double currentY = sessionState.lastDrawY;

    final double distanceFromCenter = math.sqrt(
        math.pow(currentX - centerX, 2) + math.pow(currentY - centerY, 2)
    );

    // Get ring 10 (innermost/center) radius
    final double ring10Radius = sessionState.ringRadii[10] ?? 0.0;

    // Get ring 5 (outermost visible) radius
    final double ring5Radius = sessionState.ringRadii[5] ?? 190.0;

    // ✅ PROFESSIONAL CALCULATION: Stability based on distance from center
    int stabilityPercent;
    Color stabColor;

    if (distanceFromCenter <= ring10Radius) {
      // ✅ Inside ring 10 (center) = 100% stability
      stabilityPercent = 100;
      stabColor = AppTheme.success(context);
    } else if (distanceFromCenter > ring5Radius) {
      // ✅ Outside ring 5 (outer boundary) = 0% stability
      stabilityPercent = 0;
      stabColor = AppTheme.error(context);
    } else {
      // ✅ Between ring 10 and ring 5: Linear interpolation
      // Formula: stability = 100 - (distance_ratio * 100)
      // where distance_ratio = (current_distance - ring10_radius) / (ring5_radius - ring10_radius)

      final double distanceRatio = (distanceFromCenter - ring10Radius) / (ring5Radius - ring10Radius);
      stabilityPercent = (100 - (distanceRatio * 100)).round().clamp(0, 100);

      // Dynamic color based on stability
      if (stabilityPercent >= 80) {
        stabColor = AppTheme.success(context);
      } else if (stabilityPercent >= 50) {
        stabColor = const Color(0xFFFF9800); // Orange
      } else {
        stabColor = AppTheme.error(context);
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface(context).withOpacity(0.22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: stabColor.withOpacity(0.4), width: 2),
      ),
      child: Row(
        children: [
          Text(
              "Stability",
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary(context),
                  fontSize: 16
              )
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Container(
              height: 13,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.09),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: stabilityPercent / 100.0,
                  child: Container(
                    height: 13,
                    decoration: BoxDecoration(
                      color: stabColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Text(
              "$stabilityPercent%",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: stabColor,
                  fontSize: 17
              )
          ),
        ],
      ),
    );
  }


  double calculateCurrentLinearWobble(TrainingSessionState state) {
    final preset = state.currentDistancePreset;
    final distance = preset['distance'] as double;
    return distance * state.thetaInstDeg * math.pi / 180;
  }


  // Widget _buildDropdownSection({
  //   required String title,
  //   required String value,
  //   required List<DropdownMenuItem<String>> items,
  //   required Function(String?) onChanged,
  // }) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(
  //         title,
  //         style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 12),
  //       ),
  //       const SizedBox(height: 8),
  //       Container(
  //         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  //         decoration: BoxDecoration(
  //           color: AppTheme.background(context),
  //           borderRadius: BorderRadius.circular(8),
  //           border: Border.all(color: AppTheme.surface(context).withOpacity(0.8)),
  //         ),
  //         child: DropdownButtonHideUnderline(
  //           child: DropdownButton<String>(
  //             value: value,
  //             isExpanded: true,
  //             dropdownColor: AppTheme.surface(context),
  //             style: TextStyle(color: AppTheme.textPrimary(context)),
  //             items: items,
  //             onChanged: onChanged,
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }
  Widget _buildShotLog(TrainingSessionState s) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.background(context).withOpacity(0.8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Shot Log",
            style: TextStyle(
              color: AppTheme.textPrimary(context),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (s.shotLog.isEmpty)
            Text(
              "No shots recorded yet",
              style: TextStyle(color: AppTheme.textSecondary(context)),
            )
          else
            Column(
              children: [
                // ===== Table Header =====
                LayoutBuilder(
                  builder: (context, constraints) {
                    final headerFontSize = constraints.maxWidth * 0.035;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildHeaderCell(context, "Time", flex: 2, fontSize: headerFontSize),
                        _buildHeaderCell(context, "θ (deg)", flex: 2, fontSize: headerFontSize),
                        _buildHeaderCell(context, "Score", flex: 1, fontSize: headerFontSize),
                        _buildHeaderCell(context, "Stability", flex: 1, fontSize: headerFontSize),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 8),

                // ===== Table Data Rows =====
                ...s.shotLog.take(10).map((shot) {
                  final time = shot['time'] as DateTime;
                  final theta = shot['theta'] as double;
                  final score = shot['score'] as int;
                  final stability = shot['stability'] as int? ?? 0;

                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: AppTheme.background(context).withOpacity(0.8),
                        ),
                      ),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final fontSize = constraints.maxWidth * 0.035;

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildDataCell(
                              context,
                              "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}",
                              flex: 2,
                              fontSize: fontSize,
                              textColor: AppTheme.textPrimary(context),
                            ),
                            _buildDataCell(
                              context,
                              theta.isNaN ? '—' : "${theta.toStringAsFixed(2)}°",
                              flex: 2,
                              fontSize: fontSize,
                              textColor: AppTheme.textPrimary(context),
                            ),
                            _buildBadgeCell(
                              context,
                              score.toString(),
                              _getScoreColor(score),
                              fontSize,
                            ),
                            _buildBadgeCell(
                              context,
                              "$stability%",
                              stability >= 80
                                  ? AppTheme.success(context)
                                  : stability >= 50
                                  ? const Color(0xFFFFA726)
                                  : AppTheme.error(context),
                              fontSize,
                            ),
                          ],
                        );
                      },
                    ),
                  );
                }),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(BuildContext context, String text,
      {int flex = 1, double fontSize = 14}) {
    return Expanded(
      flex: flex,
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textSecondary(context),
              fontWeight: FontWeight.w600,
              fontSize: fontSize,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDataCell(BuildContext context, String text,
      {int flex = 1, required double fontSize, required Color textColor}) {
    return Expanded(
      flex: flex,
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontSize: fontSize,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadgeCell(BuildContext context, String text, Color color, double fontSize) {
    return Expanded(
      flex: 1,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: fontSize,
              ),
            ),
          ),
        ),
      ),
    );
  }


  String _formatDuration(Duration d) =>
      "${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}";

  Color _getScoreColor(int score) {
    if (score >= 9) return AppTheme.success(context);
    if (score >= 7) return const Color(0xFFF59E0B);
    if (score >= 5) return AppTheme.error(context);
    return AppTheme.textSecondary(context);
  }
}
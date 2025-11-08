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
  bool _toastShown = false; // NEW: Track if toast already shown

  @override
  void initState() {
    super.initState();
    final bloc = context.read<TrainingSessionBloc>();
    final device = bloc.state.device;

    context.read<TrainingSessionBloc>().add(ClearLastSession(device: device!));
    context.read<TrainingSessionBloc>().add(const InitializeRingSystem());
    context.read<TrainingSessionBloc>().add(const RecomputeScoreRadii('nov'));
    context.read<TrainingSessionBloc>().add(
      UpdateDistancePreset(widget.program.drill!.distanceYards),
    );
    context.read<TrainingSessionBloc>().add(
      UpdateAngleRange(widget.program.drill!.sensitivity),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background(context),
      appBar: customAppBar(
        title: 'PulseSkadi Session\nSession Name: ${widget.program.programName ?? 'Training'}',
        context: context,
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: AppTheme.textPrimary(context)),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
            onPressed: () {
              String? sensPerms = prefs?.getString(sensitivityKey);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingViewPage(
                    sensPerms: sensPerms?.split('/') ?? ['2', '1', '1', '1', '1', '1'],
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.tune, color: AppTheme.textPrimary(context)),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
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
            // lib/training/presentation/pages/steadiness_trainer_page.dart
// Update listener in BlocConsumer (around line 115):
            // Update listener in BlocConsumer (around line 115):
            listener: (_, sessionState) {
              _shotCount = sessionState.shotCount;

              if (sessionState.sensorError != null) {
                _handleSensorError(context, sessionState.sensorError!);
              }

              // NEW: Show toast only once when session completes
              if (sessionState.sessionJustCompleted && !_toastShown) {
                _toastShown = true; // Mark as shown
                final sessionName = widget.program.programName ?? 'Training Session';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Session Complete: $sessionName',
                      style: AppTheme.bodyMedium(context).copyWith(color: Colors.white),
                    ),
                    backgroundColor: AppTheme.success(context),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    margin: EdgeInsets.only(
                      bottom: MediaQuery.of(context).size.height - 150,
                      left: 10,
                      right: 10,
                    ),
                  ),
                );
                context.read<TrainingSessionBloc>().add(const ClearSessionCompletionFlag());
              }

              if (sessionState.hasNavigatedToSessionDetail && sessionState.sessionCompleted) {
                _navigateToAnalysisPage(context);
              }
            },
            builder: (_, sessionState) {
              final traceModeInt = prefs?.getInt(traceDisplayModeKey) ?? 0;
              final traceMode = TraceDisplayMode.values[traceModeInt.clamp(0, 2)];

              return SingleChildScrollView(
                physics: ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  children: [

                    _buildStatusCard(sessionState, widget.program),
                    const SizedBox(height: 8),
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
                      traceDisplayMode: traceMode,
                    ),
                    const SizedBox(height: 10),
                    SessionControls(
                      isSensorEnabled: sessionState.isSensorsEnabled,
                      isTraining: sessionState.isTraining,
                      isPaused: sessionState.isPaused,
                      startTraining: _startTraining,
                      stopTraining: () => _pauseTraining(sessionState),
                      resetTrace: _resetTrace,
                      finishSession: _finishSession,
                      onRecalibrate: sessionState.isSensorsEnabled ? _showRecalibrationDialog : null,
                    ),
                    const SizedBox(height: 10),
                    buildRealtimeStability(sessionState, context),
                    const SizedBox(height: 10),
                    _buildShotLog(sessionState),
                    const SizedBox(height: 8),
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
      barrierDismissible: true,
      builder: (_) => DeviceCalibrationDialog(
        onStartCalibration: () async {
          final device = bleState.connectedDevice!;
          context.read<TrainingSessionBloc>().add(DisableSensors(device: device));
          await Future.delayed(Duration(seconds: 1));
          context.read<TrainingSessionBloc>().add(EnableSensors(device: device));
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

  void _handleSensorError(BuildContext context, String error) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surface(context),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: AppTheme.error(context), size: 20),
            const SizedBox(width: 6),
            Text('Sensor Error', style: TextStyle(color: AppTheme.textPrimary(context), fontSize: 15)),
          ],
        ),
        content: Text(error, style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.primary(context)),
            child: const Text('OK', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

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

    if (!hapticEnabled && traceMode == TraceDisplayMode.hidden) {
      ToastUtils.showError(context, message: 'Enable Haptic or Display Mode from settings to start training');
      return;
    }

    final sessionState = context.read<TrainingSessionBloc>().state;

    if (sessionState.isPaused) {
      context.read<TrainingSessionBloc>().add(const ResumeTrainingSession());
    } else {
      context.read<TrainingSessionBloc>().add(StartTrainingSession(program: widget.program));
    }
  }

  void _pauseTraining(TrainingSessionState sessionState) {
    if (sessionState.shotCount > 0) {
      context.read<TrainingSessionBloc>().add(const PauseTrainingSession());
    } else {
      context.read<TrainingSessionBloc>().add(const StopTrainingSession());
    }
  }

  void _finishSession() {
    context.read<TrainingSessionBloc>().add(const StopTrainingSession());
    _navigateToAnalysisPage(context);
  }

  void _resetTrace() {
    context.read<TrainingSessionBloc>().add(const ResetTrace());
  }

  void _navigateToAnalysisPage(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SessionSummaryPage()),
    );
  }

  Widget _buildStatusCard(TrainingSessionState s, ProgramsModel p) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.background(context).withOpacity(0.8)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildMetric("Shots", "${s.shotCount}/${p.drill!.plannedRounds}", Icons.gps_fixed),
              const SizedBox(width: 6),
              _buildMetric(
                "Time",
                _formatDuration(DateTime.now().difference(s.sessionStartTime ?? DateTime.now())),
                Icons.timer,
                color: s.isTraining ? AppTheme.primary(context) : null,
              ),
              const SizedBox(width: 6),
              _buildMetric(
                "Distance",
                "${s.selectedDistance} m",
                Icons.straighten,
                color: s.isTraining ? AppTheme.primary(context) : null,
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (s.isTraining && s.sensorStream != null)
            Row(
              children: [
                _buildMetric(
                  "Pitch",
                  "${s.sensorStream!.pitch.toStringAsFixed(1)}°",
                  Icons.height,
                  color: AppTheme.textPrimary(context),
                ),
                const SizedBox(width: 6),
                _buildMetric(
                  "Yaw",
                  "${s.sensorStream!.yaw.toStringAsFixed(1)}°",
                  Icons.explore,
                  color: AppTheme.textPrimary(context),
                ),
                const SizedBox(width: 6),
                _buildMetric(
                  "Roll",
                  "${s.sensorStream!.roll.toStringAsFixed(1)}°",
                  Icons.rotate_90_degrees_ccw,
                  color: AppTheme.textPrimary(context),
                ),
              ],
            ),
          if (s.missedShotCount > 0) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.warning(context).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.warning(context).withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppTheme.warning(context), size: 14),
                  const SizedBox(width: 6),
                  Text(
                    "Missed Shots: ${s.missedShotCount}",
                    style: TextStyle(
                      color: AppTheme.warning(context),
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Tooltip(
                    message: "Shots detected by sensor but not counted (out of range or visibility issues)",
                    child: Icon(Icons.info_outline, color: AppTheme.warning(context), size: 12),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, IconData icon, {Color? color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.primary(context).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 10),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                color: color ?? AppTheme.textPrimary(context),
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildRealtimeStability(TrainingSessionState sessionState, BuildContext context) {
    final double centerX = 200.0;
    final double centerY = 200.0;
    final double currentX = sessionState.lastDrawX;
    final double currentY = sessionState.lastDrawY;

    final double distanceFromCenter = math.sqrt(
      math.pow(currentX - centerX, 2) + math.pow(currentY - centerY, 2),
    );

    final double ring10Radius = sessionState.ringRadii[10] ?? 0.0;
    final double ring5Radius = sessionState.ringRadii[5] ?? 190.0;

    int stabilityPercent;
    Color stabColor;

    if (distanceFromCenter <= ring10Radius) {
      stabilityPercent = 100;
      stabColor = AppTheme.success(context);
    } else if (distanceFromCenter > ring5Radius) {
      stabilityPercent = 0;
      stabColor = AppTheme.error(context);
    } else {
      final double distanceRatio = (distanceFromCenter - ring10Radius) / (ring5Radius - ring10Radius);
      stabilityPercent = (100 - (distanceRatio * 100)).round().clamp(0, 100);

      if (stabilityPercent >= 80) {
        stabColor = AppTheme.success(context);
      } else if (stabilityPercent >= 50) {
        stabColor = const Color(0xFFFF9800);
      } else {
        stabColor = AppTheme.error(context);
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface(context).withOpacity(0.22),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: stabColor.withOpacity(0.4), width: 1.5),
      ),
      child: Row(
        children: [
          Text(
            "Stability",
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppTheme.primary(context),
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 10,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.09),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: stabilityPercent / 100.0,
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: stabColor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            "$stabilityPercent%",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: stabColor,
              fontSize: 14,
            ),
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

  Widget _buildShotLog(TrainingSessionState s) {
    return Container(
      padding: const EdgeInsets.all(10),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.background(context).withOpacity(0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Shot Log",
            style: TextStyle(
              color: AppTheme.textPrimary(context),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (s.shotLog.isEmpty)
            Text(
              "No shots recorded yet",
              style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 11),
            )
          else
            Column(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final headerFontSize = 10.0;
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
                const SizedBox(height: 6),
                ...s.shotLog.take(10).map((shot) {
                  final time = shot['time'] as DateTime;
                  final theta = shot['theta'] as double;
                  final score = shot['score'] as int;
                  final stability = shot['stability'] as int? ?? 0;

                  // ✅ NEW: Check if missed shot
                  final isMissedShot = score == 0 && stability == 0;

                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppTheme.background(context).withOpacity(0.8)),
                      ),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final fontSize = 10.0;

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
                            // ✅ MODIFIED: Show "MISS" for missed shots
                            isMissedShot
                                ? _buildMissedShotBadge(context, fontSize)
                                : _buildBadgeCell(context, score.toString(), _getScoreColor(score), fontSize),
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

  // ✅ NEW: Add this method after _buildBadgeCell (around line 580)
  Widget _buildMissedShotBadge(BuildContext context, double fontSize) {
    return Expanded(
      flex: 1,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: AppTheme.error(context).withOpacity(0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'MISS',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.error(context),
                fontWeight: FontWeight.bold,
                fontSize: fontSize,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCell(BuildContext context, String text, {int flex = 1, double fontSize = 10}) {
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

  Widget _buildDataCell(BuildContext context, String text, {int flex = 1, required double fontSize, required Color textColor}) {
    return Expanded(
      flex: flex,
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: textColor, fontSize: fontSize),
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
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(6),
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

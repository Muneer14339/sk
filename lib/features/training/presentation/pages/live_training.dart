import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pulse_skadi/core/services/prefs.dart';
import 'package:pulse_skadi/core/theme/app_colors.dart';
import 'package:pulse_skadi/core/utils/dialog_utils.dart';
import 'package:pulse_skadi/features/training/data/model/programs_model.dart';
import 'package:pulse_skadi/features/training/presentation/bloc/ble_scan/ble_scan_bloc.dart';
import 'package:pulse_skadi/features/training/presentation/bloc/ble_scan/ble_scan_state.dart';
import 'package:pulse_skadi/features/training/presentation/bloc/training_session/training_session_bloc.dart';
import 'package:pulse_skadi/features/training/presentation/bloc/training_session/training_session_event.dart';
import 'package:pulse_skadi/features/training/presentation/bloc/training_session/training_session_state.dart';
import 'package:pulse_skadi/features/training/presentation/pages/sensitity_settings_page.dart';
import 'package:pulse_skadi/features/training/presentation/pages/session_details_page.dart';
import 'package:pulse_skadi/features/training/presentation/widgets/trace_painter.dart';

// --- Main Page Widget ---
class LiveTrainingPage extends StatefulWidget {
  const LiveTrainingPage({super.key, required this.program});
  final ProgramsModel program;

  @override
  State<LiveTrainingPage> createState() => _LiveTrainingPageState();
}

class _LiveTrainingPageState extends State<LiveTrainingPage>
    with SingleTickerProviderStateMixin {
  late ProgramsModel _currentProgram;
  bool isClearing = false;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    _currentProgram = widget.program;
    // Har 250ms me ek clear cycle start hoga
    timer = Timer.periodic(const Duration(milliseconds: 500), (t) async {
      setState(() => isClearing = true);

      // 20ms ke baad wapas normal trace show karo
      await Future.delayed(const Duration(milliseconds: 250));
      if (mounted) {
        setState(() => isClearing = false);
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }


  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    // return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  // Helper method to get movement status
  String _getMovementStatus(TrainingSessionState sessionState) {
    if (sessionState.sensorStream?.points.isEmpty ?? true) {
      return "Waiting";
    }

    final latestPoint = sessionState.sensorStream!.points.last;
    final x = latestPoint.point.x;
    final y = latestPoint.point.y;

    // Check if values are zero (resetting)
    if (x == 0 && y == 0) {
      return "Resetting";
    }

    // Check if values are outside range (hide)
    if (x < -4.5 || x > 4.5 || y < -4.5 || y > 4.5) {
      return "Hide";
    }

    // Normal movement
    return "Moving";
  }

  // Helper method to get status color
  Color _getStatusColor(String status) {
    switch (status) {
      case "Moving":
        return const Color(0xff28a745); // Green
      case "Waiting":
        return const Color(0xff6c757d); // Gray
      case "Resetting":
        return const Color(0xffffc107); // Yellow
      case "Hide":
        return const Color(0xffdc3545); // Red
      default:
        return const Color(0xff6c757d);
    }
  }

  DateTime? lastShotTime;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xfff8f9fa),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: AppBar(
              backgroundColor: const Color(0xff2c3e50),
              foregroundColor: Colors.white,
              title: const Text('Live Training'),
              centerTitle: true,
              leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: IconButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white)),
              elevation: 0,
              actions: [
                IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () {
                      String? sensPerms = prefs?.getString(sensitivityKey);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SettingViewPage(
                                  sensPerms: sensPerms?.split('/') ??
                                      ['5', '3', '3', '3', '3', '3'])));
                    }),
              ]),
        ),
        body:
        BlocConsumer<BleScanBloc, BleScanState>(listener: (context, state) {
          if (!state.isConnected) {
            DialogUtils.showConfirmationDialog(
                context: context,
                title: 'Sensor Connection',
                message: 'RT Sensor Disconnected',
                confirmText: 'Continue',
                cancelText: 'Back',
                confirmColor: Colors.red)
                .then((value) {
              if (value) {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            SessionDetailPage(sessionId: '')));
              } else {
                Navigator.pop(context);
              }
            });
          }
        }, builder: (context, bleState) {
          return BlocConsumer<TrainingSessionBloc, TrainingSessionState>(
              listener: (context, sessionState) async {
                if (sessionState.sessionCompleted) {
                  final now = DateTime.now();
                  if (lastShotTime == null ||
                      now.difference(lastShotTime!) >
                          const Duration(milliseconds: 200)) {
                    lastShotTime = now;
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                SessionDetailPage(sessionId: '')));
                  }
                }
              }, builder: (context, sessionState) {
            final isConnected = bleState.isConnected;
            final connectionStatus =
            isConnected ? "RT Sensor Connected" : "RT Sensor Not Connected";
            return Column(children: [
              Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // --- Training Header ---
                        Container(
                          padding: const EdgeInsets.all(20.0),
                          decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xffe74c3c), Color(0xffc0392b)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12.0),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5))
                              ]),
                          child: Column(children: [
                            Text(_currentProgram.programName ?? '',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center),
                            const SizedBox(height: 8),
                            Text(_currentProgram.programDescription ?? '',
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 14),
                                textAlign: TextAlign.center)
                          ]),
                          //   ],
                          // ),
                        ),
                        const SizedBox(height: 20),
                        // --- Connection Status ---
                        Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isConnected
                                    ? [
                                  const Color(0xff28a745),
                                  const Color(0xff218838)
                                ]
                                    : [
                                  const Color(0xffdc3545),
                                  const Color(0xffc82333)
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: Text(connectionStatus,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500),
                                textAlign: TextAlign.center)),
                        const SizedBox(height: 20),
                        // --- Program-Specific Metrics ---
                        Container(
                          padding: const EdgeInsets.all(15.0),
                          decoration: BoxDecoration(
                            color: const Color(0xffe8f4f8),
                            border: Border.all(
                                color: const Color(0xff17a2b8), width: 2),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.bar_chart,
                                      color: Color(0xff0c5460), size: 20),
                                  SizedBox(width: 8),
                                  Text('Live Metrics',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xff0c5460)))
                                ],
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: Wrap(spacing: 12, runSpacing: 12, children: [
                                  ...List.generate(
                                      _currentProgram.performanceMetrics?.length ??
                                          0, (index) {
                                    final metric =
                                    _currentProgram.performanceMetrics?[index];
                                    return _buildMetricDisplay(
                                        metric?.stability ?? '',
                                        '--',
                                        metric?.unit ?? '');
                                  })
                                ]),
                              )
                            ],
                          ),
                        ),
                        const SizedBox(height: 25),
                        // --- Session Info ---
                        Row(
                          children: [
                            _buildInfoItem(
                              'Session Time',
                              sessionState.sessionStartTime == null
                                  ? '0:00'
                                  : _formatDuration(DateTime.now()
                                  .difference(sessionState.sessionStartTime!)),
                            ),
                            _buildInfoItem(
                              _currentProgram.noOfShots != null
                                  ? 'Shots (${_currentProgram.noOfShots})'
                                  : 'Shots Fired',
                              sessionState.shotCount.toString(),
                            ),
                            _buildInfoItem('Success Rate', '--'),
                          ],
                        ),
                        const SizedBox(height: 25),
                        // --- Target Display ---
                        AspectRatio(
                          aspectRatio: 1,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 0),
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const RadialGradient(
                                  colors: [Color(0xfff8f9fa), Color(0xffe9ecef)],
                                  stops: [0.0, 1.0],
                                ),
                                // border: Border.all(
                                //     color: const Color(0xff343a40), width: 3),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4))
                                ]),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Target Rings
                                _buildTargetRing(0.1, AppColors.kRedColor,
                                    AppColors.kRedColor), // Ring 10
                                _buildTargetRing(
                                    0.3, AppColors.kRedColor), // Ring 9
                                _buildTargetRing(
                                    0.48, AppColors.kRedColor), // Ring 8
                                _buildTargetRing(
                                    0.65, AppColors.kRedColor), // Ring 7
                                _buildTargetRing(0.83, AppColors.kRedColor),
                                _buildTargetRing(1, AppColors.kRedColor), // Ring 6
                                Positioned.fill(
                                    child:
                                    CustomPaint(painter: CrosshairPainter())),
                            Positioned.fill(
                              child: (sessionState.sensorStream != null &&
                                  sessionState.sensorStream!.points.isNotEmpty &&
                                  sessionState.sensorStream?.points.last.point.x != 0 &&
                                  sessionState.sensorStream!.points.last.point.x <= 4.5 &&
                                  sessionState.sensorStream!.points.last.point.x >= -4.5 &&
                                  sessionState.sensorStream?.points.last.point.y != 0 &&
                                  sessionState.sensorStream!.points.last.point.y <= 4.5 &&
                                  sessionState.sensorStream!.points.last.point.y >= -4.5)
                                  ? CustomPaint(
                                painter: isClearing
                                    ? TracePainter([]) // ⬅️ 20ms ke liye empty trace
                                    : TracePainter(
                                  sessionState.sensorStream?.points.toList() ?? [],
                                  smoothingFactor: 0.3,
                                  enableInterpolation: true,
                                  interpolationPoints: 2,
                                  enableVelocityBasedSmoothing: true,
                                  enableAdaptiveThickness: true,
                                  movementDampening: 0.2,
                                  responseDelay: 0.3,
                                  targetRadius: 1.0,
                                  showCurrentPositionMarker: true,
                                  animateCurrentMarker: true,
                                  currentMarkerSize: 8.0,
                                ),
                              )
                                  : CustomPaint(painter: TracePainter([])),
                            )
                            ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        // --- Trace Legend ---
                        // ✅ UPDATED: Trace Legend with correct colors as per user requirements
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // ✅ Pre-shot: Blue lines (as requested)
                            _LegendItem(
                                color: Color(0xff17a2b8), // Blue for pre-shot
                                label: 'Pre-shot'),
                            SizedBox(width: 15),

                            // ✅ Shot break: Red lines (as requested)
                            _LegendItem(
                                color: Color(0xffdc3545), // Red for shot detection
                                label: 'Shot break'),
                            SizedBox(width: 15),

                            // ✅ Post-shot: Red lines (as requested)
                            _LegendItem(
                                color:
                                Color(0xffdc3545), // Red for post-shot/recovery
                                label: 'Recovery'),
                            SizedBox(width: 15),

                            // ✅ NEW: Previous shots: Yellow lines (as requested)
                            _LegendItem(
                                color:
                                Color(0xffffc107), // Yellow for previous shots
                                label: 'Previous'),
                          ],
                        ),
                        const SizedBox(height: 25),

                        // --- NEW: Movement Logs Card ---
                        Visibility(
                          visible: sessionState.isTraining,
                          child: Container(
                            padding: const EdgeInsets.all(15.0),
                            decoration: BoxDecoration(
                              color: const Color(0xff17a2b8).withValues(alpha: 0.1),
                              border: Border.all(
                                  color: const Color(0xff17a2b8), width: 2),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.timeline,
                                        color: Color(0xff0c5460), size: 20),
                                    SizedBox(width: 8),
                                    Text('Movement Logs',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xff0c5460)))
                                  ],
                                ),
                                const SizedBox(height: 15),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildMovementLogItem(
                                        'X-Movement',
                                        sessionState.sensorStream?.points.isNotEmpty ?? false
                                            ? sessionState.sensorStream!.points.last.point.x.toStringAsFixed(3)
                                            : '0.000',
                                        Icons.swap_horiz,
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: _buildMovementLogItem(
                                        'Y-Movement',
                                        sessionState.sensorStream?.points.isNotEmpty ?? false
                                            ? sessionState.sensorStream!.points.last.point.y.toStringAsFixed(3)
                                            : '0.000',
                                        Icons.swap_vert,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),

                        // --- NEW: Status Card ---
                        Visibility(
                          visible: sessionState.isTraining,
                          child: Container(
                            padding: const EdgeInsets.all(15.0),
                            decoration: BoxDecoration(
                              color: _getStatusColor(_getMovementStatus(sessionState)).withValues(alpha: 0.1),
                              border: Border.all(
                                  color: _getStatusColor(_getMovementStatus(sessionState)), width: 2),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.info_outline,
                                        color: _getStatusColor(_getMovementStatus(sessionState)), size: 20),
                                    const SizedBox(width: 8),
                                    const Text('Movement Status',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold))
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Status:',
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(_getMovementStatus(sessionState)),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        _getMovementStatus(sessionState),
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _getStatusDescription(_getMovementStatus(sessionState)),
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.black.withValues(alpha: 0.7)),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // --- Training Controls ---
                        Row(children: [
                          if (!sessionState.isTraining)
                            Expanded(
                              child: _ControlButton(
                                label: 'Start Training',
                                icon: Icons.play_arrow,
                                color: const Color(0xff28a745),
                                onPressed: bleState.connectedDevice != null
                                    ? () {
                                  // First start the session in the Bloc, then enable sensors
                                  context
                                      .read<TrainingSessionBloc>()
                                      .add(StartTrainingSession());
                                  context.read<TrainingSessionBloc>().add(
                                      EnableSensors(
                                          program: _currentProgram,
                                          device: bleState.connectedDevice!));
                                }
                                    : null,
                              ),
                            ),
                          if (sessionState.isTraining)
                            Expanded(
                                child: _ControlButton(
                                    label: 'Stop Training',
                                    icon: Icons.pause,
                                    color: const Color(0xffdc3545),
                                    onPressed: bleState.connectedDevice != null
                                        ? () {
                                      context.read<TrainingSessionBloc>().add(
                                          DisableSensors(
                                              device:
                                              bleState.connectedDevice!));
                                      context
                                          .read<TrainingSessionBloc>()
                                          .add(StopTrainingSession());
                                    }
                                        : null)),
                          if (sessionState.isTraining) const SizedBox(width: 6),
                          if (sessionState.isTraining)
                            Expanded(
                              child: _ControlButton(
                                  label: 'Calibrate',
                                  icon: Icons.refresh,
                                  color: const Color(0xff6c757d),
                                  onPressed: () => context
                                      .read<TrainingSessionBloc>()
                                      .add(Recalibrate())),
                            ),
                        ]),
                        const SizedBox(height: 20),
                        // --- AI Feedback ---
                        Container(
                          padding: const EdgeInsets.all(18.0),
                          decoration: BoxDecoration(
                            color: const Color(0xff343a40).withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(12.0),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4))
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(children: [
                                Text('🤖', style: TextStyle(fontSize: 20)),
                                SizedBox(width: 10),
                                Text('ShoQ AI Coach',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold))
                              ]),
                              const SizedBox(height: 12),
                              Text(sessionState.aiFeedbackText,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 14)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ))
            ]);
          });
        }));
  }

  // Helper method to get status description
  String _getStatusDescription(String status) {
    switch (status) {
      case "Moving":
        return "Gun movement detected within valid range";
      case "Waiting":
        return "Waiting for sensor data...";
      case "Resetting":
        return "Sensor values resetting to zero";
      case "Hide":
        return "Movement outside target range (±4.5)";
      default:
        return "Unknown status";
    }
  }

  // Helper widget for movement log items
  Widget _buildMovementLogItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: const Color(0xffb3d7e6), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xff0c5460), size: 20),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
                color: Color(0xff6c757d),
                fontSize: 12,
                fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xff0c5460)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets and Painters ---

  Widget _buildMetricDisplay(String label, String value, String target) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: const Color(0xffb3d7e6), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xff6c757d), fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 5),
          Text(value,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff0c5460)),
              textAlign: TextAlign.center),
          const SizedBox(height: 2),
          Text('Target: $target',
              style: const TextStyle(color: Color(0xff28a745), fontSize: 11),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xffe9ecef), width: 1),
          borderRadius: BorderRadius.circular(10.0),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                  color: Color(0xff6c757d),
                  fontSize: 10,
                  fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xff2c3e50),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetRing(double sizePercentage, Color borderColor,
      [Color? fillColor]) {
    return FractionallySizedBox(
      widthFactor: sizePercentage,
      heightFactor: sizePercentage,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: fillColor,
          border: Border.all(color: borderColor, width: 2),
        ),
      ),
    );
  }

  Widget _buildStabilityBar(String label, double fillPercentage) {
    return Column(
      children: [
        Row(
          children: [
            SizedBox(
              width: 70,
              child: Text(
                label,
                style:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
            Expanded(
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xffe9ecef),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: fillPercentage.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xffdc3545),
                          Color(0xffffc107),
                          Color(0xff28a745)
                        ],
                        stops: [0.0, 0.5, 1.0],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// --- Custom Painters for advanced drawing ---

class PulseEffectPainter extends CustomPainter {
  final Animation<double> animation;

  PulseEffectPainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width *
        (0.5 + 0.5 * animation.value); // Scale from 0.5 to 1.0 of width
    final opacity = (1 - animation.value).clamp(0.0, 1.0) * 0.3; // Fades out

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: opacity),
          Colors.transparent,
        ],
        stops: const [0.0, 0.7],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class CrosshairPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..strokeWidth = 1.0;

    // Horizontal line
    canvas.drawLine(
        Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);
    // Vertical line
    canvas.drawLine(
        Offset(size.width / 2, 0), Offset(size.width / 2, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

// --- Shot Marker Widget ---
enum ShotAccuracy { excellent, good, fair, poor }

class ShotData {
  final double normalizedX; // -1.0 to 1.0
  final double normalizedY; // -1.0 to 1.0
  final ShotAccuracy accuracy;

  ShotData(this.normalizedX, this.normalizedY, this.accuracy);
}

class _ShotMarker extends StatefulWidget {
  final ShotAccuracy accuracy;

  const _ShotMarker({required this.accuracy});

  @override
  State<_ShotMarker> createState() => _ShotMarkerState();
}

class _ShotMarkerState extends State<_ShotMarker>
    with SingleTickerProviderStateMixin {
  // late AnimationController _controller;
  // late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // _controller = AnimationController(
    //   vsync: this,
    //   duration: const Duration(milliseconds: 500),
    // );
    // _animation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
    //   parent: _controller,
    //   curve: Curves.easeOut,
    // ));
    // _controller.forward();
  }

  @override
  void dispose() {
    // _controller.dispose();
    super.dispose();
  }

  Color _getMarkerColor(ShotAccuracy accuracy) {
    switch (accuracy) {
      case ShotAccuracy.excellent:
        return const Color(0xff28a745);
      case ShotAccuracy.good:
        return const Color(0xffffc107);
      case ShotAccuracy.fair:
        return const Color(0xfffd7e14);
      case ShotAccuracy.poor:
        return const Color(0xffdc3545);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: _getMarkerColor(widget.accuracy),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}

// --- Control Button Widget ---
class _ControlButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color textColor;
  final VoidCallback? onPressed;

  const _ControlButton({
    required this.label,
    required this.icon,
    required this.color,
    this.textColor = Colors.white,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: textColor),
      label: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: textColor,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 2,
        disabledBackgroundColor: color.withValues(alpha: 0.6),
        disabledForegroundColor: textColor.withValues(alpha: 0.6),
      ),
    );
  }
}

// --- Legend Item Widget ---
class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 13),
        ),
      ],
    );
  }
}
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:pulse_skadi/core/theme/app_colors.dart';
// import 'dart:math' as math;
// import 'package:pulse_skadi/features/training/data/model/programs_model.dart';
// import 'package:pulse_skadi/features/training/presentation/bloc/ble_scan/ble_scan_bloc.dart';
// import 'package:pulse_skadi/features/training/presentation/bloc/ble_scan/ble_scan_state.dart';
// import 'package:pulse_skadi/features/training/presentation/bloc/training_session/training_session_bloc.dart';
// import 'package:pulse_skadi/features/training/presentation/bloc/training_session/training_session_event.dart';
// import 'package:pulse_skadi/features/training/presentation/bloc/training_session/training_session_state.dart';
// import 'package:pulse_skadi/features/training/data/model/streaming_model.dart';

// class SteadinessTrainerPage extends StatefulWidget {
//   const SteadinessTrainerPage({super.key, required this.program});
//   final ProgramsModel program;

//   @override
//   State<SteadinessTrainerPage> createState() => _SteadinessTrainerPageState();
// }

// class _SteadinessTrainerPageState extends State<SteadinessTrainerPage>
//     with TickerProviderStateMixin {
//   late ProgramsModel _currentProgram;

//   // Animation controllers
//   late AnimationController _dotAnimationController;
//   late AnimationController _glowAnimationController;

//   // Training state
//   bool _isTraining = false;
//   final bool _isResetting = false;
//   int _shotCount = 0;
//   final List<Map<String, dynamic>> _shotLog = [];

//   // Sensor data processing (matching HTML exactly)
//   double _thetaInstDeg = 0.0;
//   double _lastAngle = 0.0;
//   double _rViz = 0.0;
//   double _lastDrawX = 200.0;
//   double _lastDrawY = 200.0;

//   // ✅ NEW: Current cant value for display
//   double _currentCant = 0.0;

//   // Visibility and hysteresis
//   bool _visGate = false;
//   DateTime? _visGateTS;

//   // Steady hold detection
//   DateTime? _holdStart;

//   // Settings
//   final double _easing = 0.15;
//   final String _difficulty = 'nov'; // Default to Novice (Easy)
//   final double _gateValue = 2.5; // ✅ NEW: Gate value for dynamic angle control

//   // Constants (matching HTML exactly)
//   static const double TABLE_REST_DEG = 0.0015;
//   static const double HOLD_STABLE_DEG = 0.10;
//   static const int HOLD_TIME_MS = 250;
//   // ✅ REMOVED: These are now dynamic based on _gateValue
//   // static const double VISUAL_RING5_DEG = 0.10;
//   // static const double HIDE_OVER_DEG = 0.105;
//   // static const double SHOW_UNDER_DEG = 0.095;
//   static const int HYSTERESIS_DWELL_MS = 60;
//   static const double ANG_SMOOTH_TAU = 0.12;
//   static const double RAD_SMOOTH_TAU = 0.10;

//   // Ring configuration
//   final Map<int, double> _ringRadii = {};
//   final Map<int, Offset> _ringLabels = {};

//   // Scoring radii (can be more lenient than visual rings depending on Difficulty)
//   final Map<int, double> _scoreRadii = {};

//   // Traceline points (matching HTML)
//   final List<Offset> _tracePoints = [];

//   // Sensor readings buffer (matching HTML)
//   final List<Map<String, dynamic>> _readings = [];

//   // ✅ CORRECTED: Linear-based training system
//   String _selectedDistance = '7'; // Default to 7m
//   final Map<String, Map<String, dynamic>> _distancePresets = {
//     '7': {
//       'name': '7m',
//       'distance': 7.0,
//       'linearTolerance': 10.0,
//       'description': 'Beginner - 7m',
//     },
//     '10': {
//       'name': '10m',
//       'distance': 10.0,
//       'linearTolerance': 10.0,
//       'description': 'Intermediate - 10m',
//     },
//     '15': {
//       'name': '15m',
//       'distance': 15.0,
//       'linearTolerance': 10.0,
//       'description': 'Advanced - 15m',
//     },
//     '25': {
//       'name': '25m',
//       'distance': 25.0,
//       'linearTolerance': 10.0,
//       'description': 'Expert - 25m',
//     },
//   };

//   // ✅ NEW: Adaptive scaling system
//   double _scaleAbs = 0.0; // Fixed truth scale (edge_px / edge_deg)
//   double _currentScale = 1.0; // Current adaptive scale
//   double _gainBadge = 1.0; // Current gain multiplier
//   DateTime? _lastScaleUpdate; // For 300-500ms updates
//   final List<double> _recentSway = []; // 4-second buffer for P95 calculation

//   // ✅ CORRECTED: Fixed linear rings (same visual size for all distances)
//   final List<double> _fixedLinearRings = [5.0, 10.0, 20.0]; // mm
//   final Map<double, double> _fixedRingRadii = {}; // mm -> radius in pixels

//   // ✅ NEW: Goal achievement tracking
//   int _goalHoldsAchieved = 0;
//   DateTime? _goalHoldStart;
//   bool _showingGoalBadge = false;

//   @override
//   void initState() {
//     super.initState();
//     _currentProgram = widget.program;

//     _dotAnimationController = AnimationController(
//       duration: const Duration(milliseconds: 200),
//       vsync: this,
//     );

//     _glowAnimationController = AnimationController(
//       duration: const Duration(milliseconds: 300),
//       vsync: this,
//     );

//     _initializeRingSystem();
//     _recomputeScoreRadii(); // Initialize scoring radii based on difficulty
//     _updateDistancePreset(
//       _selectedDistance,
//     ); // ✅ NEW: Initialize distance preset
//   }

//   void _initializeRingSystem() {
//     // Calculate ring radii (matching HTML logic exactly)
//     const double ring5Radius = 190.0;
//     const double bandWidth = ring5Radius / 5.5;
//     const double r10 = bandWidth / 2;

//     _ringRadii[10] = r10;
//     _ringRadii[9] = r10 + 1 * bandWidth;
//     _ringRadii[8] = r10 + 2 * bandWidth;
//     _ringRadii[7] = r10 + 3 * bandWidth;
//     _ringRadii[6] = r10 + 4 * bandWidth;
//     _ringRadii[5] = r10 + 5 * bandWidth;

//     // Calculate label positions
//     const center = Offset(200, 200);
//     const labelInset = 12.0;

//     for (int i = 10; i >= 5; i--) {
//       _ringLabels[i] = Offset(
//         center.dx,
//         center.dy - math.max(0, _ringRadii[i]! - labelInset),
//       );
//     }
//   }

//   // ✅ NEW: Update distance preset and recalculate scales
//   void _updateDistancePreset(String distance) {
//     setState(() {
//       _selectedDistance = distance;
//     });

//     final preset = _distancePresets[distance] ?? _distancePresets['7']!;
//     print('edgeDeg --: $preset ');
//     final edgeDeg = preset['distance'] as double;

//     // Calculate fixed truth scale: edge_px / distance
//     _scaleAbs = 190.0 / edgeDeg; // 190px is the outer ring radius

//     // Initialize current scale to truth scale
//     _currentScale = _scaleAbs;
//     _gainBadge = 1.0;

//     // Calculate fixed linear ring radii (same visual size for all distances)
//     _fixedRingRadii.clear();
//     for (final mm in _fixedLinearRings) {
//       // Convert mm to pixels: 190px = 20mm ring (outer ring)
//       _fixedRingRadii[mm] = (mm / 20.0) * 190.0;
//     }

//     // Reset adaptive scaling
//     _lastScaleUpdate = null;
//     _recentSway.clear();

//     // Reset goal tracking
//     _goalHoldsAchieved = 0;
//     _goalHoldStart = null;
//     _showingGoalBadge = false;
//   }

//   void _recomputeScoreRadii() {
//     // Base visual thresholds from center→outer: r10 < r9 < r8 < r7 < r6 < r5
//     final base = [
//       _ringRadii[10]!,
//       _ringRadii[9]!,
//       _ringRadii[8]!,
//       _ringRadii[7]!,
//       _ringRadii[6]!,
//       _ringRadii[5]!,
//     ];
//     final scores = [10, 9, 8, 7, 6, 5];

//     // Map difficulty to an outward step in the base array (can be fractional)
//     // pro = 0 (exact geometry)
//     // adv = 0.5 (very difficult)
//     // int = 1 (not easy) → 10 at visual 9
//     // nov = 2 (easy)     → 10 at visual 8
//     // beg = 3 (very easy)→ 10 at visual 7
//     final step = _difficulty == 'pro'
//         ? 0.0
//         : _difficulty == 'adv'
//             ? 0.5
//             : _difficulty == 'int'
//                 ? 1.0
//                 : _difficulty == 'nov'
//                     ? 2.0
//                     : 3.0; // beg

//     // Interpolate thresholds with the given step; clamp to r5 so they never exceed outer ring
//     for (int i = 0; i < scores.length; i++) {
//       double pos = i + step;
//       if (pos >= base.length - 1) {
//         _scoreRadii[scores[i]] = base[base.length - 1]; // r5
//         continue;
//       }
//       final lo = pos.floor();
//       final hi = pos.ceil();
//       final t = pos - lo;
//       final r = base[lo] + (base[hi] - base[lo]) * t;
//       _scoreRadii[scores[i]] = math.min(r, base[base.length - 1]);
//     }
//   }

//   @override
//   void dispose() {
//     _dotAnimationController.dispose();
//     _glowAnimationController.dispose();
//     super.dispose();
//   }

//   void _startTraining() {
//     setState(() {
//       _isTraining = true;
//       _shotCount = 0;
//       _shotLog.clear();
//       _tracePoints.clear();
//       _readings.clear();
//       _visGate = false;
//       _holdStart = null;
//       _rViz = 0.0;
//       _lastDrawX = 200.0;
//       _lastDrawY = 200.0;
//       _currentCant = 0.0; // ✅ Reset cant display

//       // ✅ NEW: Reset goal tracking
//       _goalHoldsAchieved = 0;
//       _goalHoldStart = null;
//       _showingGoalBadge = false;

//       // ✅ NEW: Reset adaptive scaling
//       _currentScale = _scaleAbs;
//       _gainBadge = 1.0;
//       _recentSway.clear();

//       _lastTraceX = 200.0; // ✅ ADD THIS
//       _lastTraceY = 200.0;
//     });

//     // Start the training session in BLoC
//     context.read<TrainingSessionBloc>().add(StartTrainingSession());

//     // Enable sensors if device is connected
//     final bleState = context.read<BleScanBloc>().state;
//     if (bleState.connectedDevice != null) {
//       context.read<TrainingSessionBloc>().add(
//             EnableSensors(
//               program: _currentProgram,
//               device: bleState.connectedDevice!,
//             ),
//           );
//     }
//   }

//   void _stopTraining() {
//     setState(() {
//       _isTraining = false;
//     });

//     // Stop the training session
//     context.read<TrainingSessionBloc>().add(StopTrainingSession());

//     // Disable sensors if device is connected
//     final bleState = context.read<BleScanBloc>().state;
//     if (bleState.connectedDevice != null) {
//       context.read<TrainingSessionBloc>().add(
//             DisableSensors(device: bleState.connectedDevice!),
//           );
//     }
//   }

//   // ✅ NEW: Show distance preset toast
//   void _showDistanceToast(String distance) {
//     final preset = _distancePresets[distance]!;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(
//           '${preset['name']}: Distance ${preset['distance']}m • Linear Tolerance ${preset['linearTolerance']}mm',
//         ),
//         duration: const Duration(seconds: 2),
//         backgroundColor: const Color(0xFF5EA1FF),
//       ),
//     );
//   }

//   void _resetTrace() {
//     setState(() {
//       _shotLog.clear();
//       _shotCount = 0;
//       _tracePoints.clear();
//       _readings.clear();
//       _rViz = 0.0;
//       _lastDrawX = 200.0;
//       _lastDrawY = 200.0;
//       _visGate = false;
//       _holdStart = null;
//       _currentCant = 0.0; // ✅ Reset cant display

//       // ✅ NEW: Reset goal tracking
//       _goalHoldsAchieved = 0;
//       _goalHoldStart = null;
//       _showingGoalBadge = false;

//       // ✅ NEW: Reset adaptive scaling
//       _currentScale = _scaleAbs;
//       _gainBadge = 1.0;
//       _recentSway.clear();
//     });
//     _recomputeScoreRadii(); // Recalculate scoring radii after reset
//   }

//   // ✅ CORRECTED: Update adaptive scaling for distance-aware linear system
//   void _updateAdaptiveScaling() {
//     final now = DateTime.now();
//     if (_lastScaleUpdate != null &&
//         now.difference(_lastScaleUpdate!).inMilliseconds < 400) {
//       return; // Update every ~400ms
//     }

//     if (_recentSway.length < 10) return; // Need enough data

//     // Calculate P95 of recent sway (4-second window)
//     final sortedSway = List<double>.from(_recentSway);
//     sortedSway.sort();
//     final p95Index = (sortedSway.length * 0.95).floor();
//     final sway = sortedSway[p95Index];

//     // Calculate effective sway (minimum 0.15° to prevent division by zero)
//     final swayEff = math.max(sway, 0.15);

//     // ✅ CORRECTED: Distance-aware scaling - same angular motion = larger trace at longer distance
//     final preset = _getDistancePreset();
//     final distance = preset['distance'] as double;

//     // Convert angular motion to linear trace: W(t) = D * θ(t)
//     // At 25m, same θ produces 3.6x larger trace than at 7m
//     final linearTrace =
//         distance * swayEff * (math.pi / 180); // Convert to radians

//     // Target scale: keep trace visible but don't exceed safe limits
//     final target = math.min(0.92 * 190.0 / linearTrace, 1.25 * _scaleAbs);

//     // Smooth interpolation with limits
//     final alpha = 0.08; // Slow adaptation
//     _currentScale = _currentScale + (target - _currentScale) * alpha;

//     // Clamp to safe limits: 0.85× to 1.25× of truth scale
//     _currentScale = _currentScale.clamp(0.85 * _scaleAbs, 1.25 * _scaleAbs);

//     // Calculate gain badge
//     _gainBadge = _currentScale / _scaleAbs;

//     _lastScaleUpdate = now;
//   }

//   // ✅ NEW: Get current distance preset
//   Map<String, dynamic> _getDistancePreset() {
//     return _distancePresets[_selectedDistance]!;
//   }

//   // ✅ CORRECTED: Balanced gate values - not too restrictive
//   double get _visualRing5Deg {
//     // ✅ FIX: Keep gate values reasonable across all distances
//     // Only slight adjustment, not drastic inverse scaling
//     final preset = _getDistancePreset();
//     final distance = preset['distance'] as double;

//     // Gentle adjustment: 7m = 1.0x, 10m = 0.9x, 15m = 0.8x, 25m = 0.7x
//     final distanceAdjustment = math.max(0.7, 1.0 - ((distance - 7.0) * 0.05));
//     final adjustedGateValue = _gateValue * distanceAdjustment;

//     return adjustedGateValue * math.pi / 180;
//   }

//   double get _hideOverDeg {
//     // ✅ BALANCED: Only slight increase in hiding threshold
//     return _visualRing5Deg * 1.05;
//   }

//   double get _showUnderDeg {
//     // ✅ BALANCED: Only slight decrease in showing threshold
//     return _visualRing5Deg * 0.95;
//   }

// // ✅ ENHANCED: Better distance-aware positioning with proper sensitivity
//   Offset _calculateDistanceAwarePosition(double thetaInstDeg, double angle) {
//     final preset = _getDistancePreset();
//     final distance = preset['distance'] as double;

//     // ✅ IMPROVED: More responsive scaling for visual feedback
//     final normalizedTheta = (thetaInstDeg / _visualRing5Deg).clamp(0.0, 1.0);
//     final baseRadius = normalizedTheta * _ringRadii[5]!;

//     // ✅ KEY FIX: Enhanced exponential scaling for better visual response
//     // 7m = 1.0x, 10m = 1.5x, 15m = 2.2x, 25m = 3.8x
//     final distanceMultiplier =
//         math.pow(distance / 7.0, 1.4); // More aggressive scaling
//     final scaledRadius = baseRadius * distanceMultiplier;

//     final newX = 200 + scaledRadius * math.cos(angle);
//     final newY = 200 + scaledRadius * math.sin(angle);

//     return Offset(newX, newY);
//   }

// // ✅ NEW: Traceline movement threshold to reduce excessive drawing - Add this in class variables section
//   double _lastTraceX = 200.0;
//   double _lastTraceY = 200.0;

//   // ✅ CORRECTED: Get linear ring color based on millimeters
//   Color _getLinearRingColor(double millimeters) {
//     if (millimeters <= 5.0)
//       return const Color(0xFF34D399); // Green for 5mm (easy)
//     if (millimeters <= 10.0)
//       return const Color(0xFFF59E0B); // Orange for 10mm (medium)
//     if (millimeters <= 20.0)
//       return const Color(0xFFEF4444); // Red for 20mm (hard)
//     return const Color(0xFF6B7280); // Gray for beyond 20mm
//   }

//   // ✅ NEW: Build gain badge
//   Widget _buildGainBadge() {
//     return Positioned(
//       top: 16,
//       left: 16,
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//         decoration: BoxDecoration(
//           color: const Color(0xFF1A2332).withOpacity(0.9),
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(
//             color: _gainBadge > 1.0
//                 ? const Color(0xFF34D399)
//                 : const Color(0xFFF59E0B),
//             width: 1.5,
//           ),
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(
//               _gainBadge > 1.0 ? Icons.zoom_in : Icons.zoom_out,
//               color: _gainBadge > 1.0
//                   ? const Color(0xFF34D399)
//                   : const Color(0xFFF59E0B),
//               size: 14,
//             ),
//             const SizedBox(width: 4),
//             Text(
//               '×${_gainBadge.toStringAsFixed(1)}',
//               style: TextStyle(
//                 color: _gainBadge > 1.0
//                     ? const Color(0xFF34D399)
//                     : const Color(0xFFF59E0B),
//                 fontSize: 12,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ✅ CORRECTED: Check goal achievement based on linear tolerance
//   void _checkGoalAchievement(DateTime now) {
//     final preset = _getDistancePreset();
//     final linearTolerance = preset['linearTolerance'] as double;
//     final distance = preset['distance'] as double;

//     // Convert current angular sway to linear wobble: W = D * θ
//     final currentLinearWobble = distance * _thetaInstDeg * (math.pi / 180);

//     // Check if current linear wobble is within tolerance
//     if (currentLinearWobble <= linearTolerance) {
//       if (_goalHoldStart == null) {
//         _goalHoldStart = now;
//       } else {
//         final held = now.difference(_goalHoldStart!).inMilliseconds;
//         if (held >= 1000) {
//           // 1 second hold required
//           // Goal achieved!
//           _goalHoldsAchieved++;
//           _goalHoldStart = null;

//           // Show achievement badge
//           // if (_goalHoldsAchieved >= _goalHoldsRequired) {
//           //   _showGoalAchievementBadge();
//           // } else {
//           //   _showGoalHoldToast();
//           // }
//         }
//       }
//     } else {
//       _goalHoldStart = null;
//     }
//   }

//   // ✅ NEW: Build goal achievement badge
//   Widget _buildGoalAchievementBadge() {
//     return Positioned(
//       top: 80,
//       left: 16,
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//         decoration: BoxDecoration(
//           color: const Color(0xFF34D399).withOpacity(0.95),
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(color: const Color(0xFF10B981), width: 2),
//           boxShadow: [
//             BoxShadow(
//               color: const Color(0xFF34D399).withOpacity(0.3),
//               blurRadius: 20,
//               spreadRadius: 0,
//             ),
//           ],
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Icon(Icons.emoji_events, color: Colors.white, size: 20),
//             const SizedBox(width: 8),
//             Text(
//               'GOAL ACHIEVED!',
//               style: const TextStyle(
//                 color: Color(0xFF10B981),
//                 fontSize: 14,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ✅ NEW: Build program information header
//   Widget _buildProgramHeader() {
//     return Container(
//       padding: const EdgeInsets.all(20.0),
//       decoration: BoxDecoration(
//         gradient: const LinearGradient(
//           colors: [Color(0xFFE74C3C), Color(0xFFC0392B)],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(12.0),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.2),
//             blurRadius: 10,
//             offset: const Offset(0, 5),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           Text(
//             _currentProgram.programName ?? 'Steadiness Training',
//             style: const TextStyle(
//               color: Colors.white,
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//             ),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 8),
//           Text(
//             _currentProgram.programDescription ?? 'Improve your shooting steadiness',
//             style: TextStyle(
//               color: Colors.white.withOpacity(0.9),
//               fontSize: 14,
//             ),
//             textAlign: TextAlign.center,
//           ),
//         ],
//       ),
//     );
//   }

//   // ✅ NEW: Build connection status
//   Widget _buildConnectionStatus(bool isConnected) {
//     return Container(
//       padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: isConnected
//               ? [const Color(0xFF28A745), const Color(0xFF218838)]
//               : [const Color(0xFFDC3545), const Color(0xFFC82333)],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(10.0),
//       ),
//       child: Text(
//         isConnected ? "RT Sensor Connected" : "RT Sensor Not Connected",
//         style: const TextStyle(
//           color: Colors.white,
//           fontSize: 14,
//           fontWeight: FontWeight.w500,
//         ),
//         textAlign: TextAlign.center,
//       ),
//     );
//   }

//   // ✅ NEW: Build program information header
//   Widget _buildProgramHeader() {
//     return Container(
//       padding: const EdgeInsets.all(20.0),
//       decoration: BoxDecoration(
//         gradient: const LinearGradient(
//           colors: [Color(0xFFE74C3C), Color(0xFFC0392B)],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(12.0),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.2),
//             blurRadius: 10,
//             offset: const Offset(0, 5),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           Text(
//             _currentProgram.programName ?? 'Steadiness Training',
//             style: const TextStyle(
//               color: Colors.white,
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//             ),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 8),
//           Text(
//             _currentProgram.programDescription ?? 'Improve your shooting steadiness',
//             style: TextStyle(
//               color: Colors.white.withOpacity(0.9),
//               fontSize: 14,
//             ),
//             textAlign: TextAlign.center,
//           ),
//         ],
//       ),
//     );
//   }

//   // ✅ NEW: Build connection status
//   Widget _buildConnectionStatus(bool isConnected) {
//     return Container(
//       padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: isConnected
//               ? [const Color(0xFF28A745), const Color(0xFF218838)]
//               : [const Color(0xFFDC3545), const Color(0xFFC82333)],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(10.0),
//       ),
//       child: Text(
//         isConnected ? "RT Sensor Connected" : "RT Sensor Not Connected",
//         style: const TextStyle(
//           color: Colors.white,
//           fontSize: 14,
//           fontWeight: FontWeight.w500,
//         ),
//         textAlign: TextAlign.center,
//       ),
//     );
//   }

//   // ✅ NEW: Build controls with session time
//   Widget _buildControlsWithSessionTime(TrainingSessionState sessionState) {
//     return Column(
//       children: [
//         // Session time display
//         if (sessionState.sessionStartTime != null)
//           Container(
//             margin: const EdgeInsets.only(bottom: 12),
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             decoration: BoxDecoration(
//               color: const Color(0xFF1A2332),
//               borderRadius: BorderRadius.circular(8),
//               border: Border.all(color: const Color(0xFF2A3A64), width: 1),
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 const Icon(
//                   Icons.timer,
//                   color: Color(0xFF5EA1FF),
//                   size: 16,
//                 ),
//                 const SizedBox(width: 8),
//                 Text(
//                   'Session Time: ${_formatDuration(DateTime.now().difference(sessionState.sessionStartTime!))}',
//                   style: const TextStyle(
//                     color: Color(0xFFE6EEFC),
//                     fontSize: 14,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ],
//             ),
//           ),

//         // Original controls
//         Row(
//           children: [
//             if (!_isTraining)
//               Expanded(
//                 child: ElevatedButton.icon(
//                   onPressed: _startTraining,
//                   icon: const Icon(Icons.play_arrow),
//                   label: const Text('Start Training'),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xFF34D399),
//                     foregroundColor: Colors.white,
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                 ),
//               ),
//             if (_isTraining) ...[
//               Expanded(
//                 child: ElevatedButton.icon(
//                   onPressed: _stopTraining,
//                   icon: const Icon(Icons.stop),
//                   label: const Text('Stop'),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xFFEF4444),
//                     foregroundColor: Colors.white,
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//             const SizedBox(width: 8),
//             ElevatedButton.icon(
//               onPressed: _resetTrace,
//               icon: const Icon(Icons.refresh),
//               label: const Text('Reset'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.transparent,
//                 foregroundColor: const Color(0xFFE6EEFC),
//                 side: const BorderSide(color: Color(0xFF2A3A64)),
//                 padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   // ✅ NEW: Build enhanced status card
//   Widget _buildEnhancedStatusCard(TrainingSessionState sessionState) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: const Color(0xFF111A2B),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: const Color(0xFF1A2440), width: 1),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               const Icon(
//                 Icons.analytics,
//                 color: Color(0xFF5EA1FF),
//                 size: 20,
//               ),
//               const SizedBox(width: 8),
//               Text(
//                 'Training Metrics',
//                 style: const TextStyle(
//                   color: Color(0xFFE6EEFC),
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           Row(
//             children: [
//               Expanded(
//                 child: _buildMetricItem(
//                   'Shots',
//                   _shotCount.toString(),
//                   Icons.gps_fixed,
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: _buildMetricItem(
//                   'Session Time',
//                   sessionState.sessionStartTime != null
//                       ? _formatDuration(DateTime.now().difference(sessionState.sessionStartTime!))
//                       : '0:00',
//                   Icons.timer,
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: _buildMetricItem(
//                   'Status',
//                   _isTraining ? 'Active' : 'Idle',
//                   Icons.circle,
//                   valueColor: _isTraining ? const Color(0xFF34D399) : const Color(0xFF6B7280),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   // ✅ NEW: Format duration helper method
//   String _formatDuration(Duration duration) {
//     String twoDigits(int n) => n.toString().padLeft(2, "0");
//     String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
//     String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
//     return "$twoDigitMinutes:$twoDigitSeconds";
//   }

//   // ✅ NEW: Build distance and angle info cards above Start Training button
//   Widget _buildDistanceAngleInfoCards() {
//     final preset = _getDistancePreset();
//     return Row(
//       children: [
//         Expanded(
//           child: Container(
//             padding: const EdgeInsets.all(8),
//             decoration: BoxDecoration(
//               color: const Color(0xFF111A2B),
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(color: const Color(0xFF1A2440), width: 1),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     const Icon(
//                       Icons.straighten,
//                       color: Color(0xFF5EA1FF),
//                       size: 15,
//                     ),
//                     const SizedBox(width: 8),
//                     Text(
//                       'Training Distance',
//                       style: const TextStyle(
//                         color: Color(0xFFE6EEFC),
//                         fontSize: 12,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   preset['name'] as String,
//                   style: const TextStyle(
//                     color: Color(0xFF5EA1FF),
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   preset['description'] as String,
//                   style: const TextStyle(
//                     color: Color(0xFFA8B3C7),
//                     fontSize: 12,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFF0B1220),
//       appBar: AppBar(
//         backgroundColor: const Color(0xFF111A2B),
//         foregroundColor: const Color(0xFFE6EEFC),
//         title: const Text('Steadiness Trainer'),
//         centerTitle: true,
//         elevation: 0,
//       ),
//       body: BlocConsumer<BleScanBloc, BleScanState>(
//         listener: (context, bleState) {
//           if (!bleState.isConnected) {
//             _showConnectionDialog();
//           }
//         },
//         builder: (context, bleState) {
//           return BlocConsumer<TrainingSessionBloc, TrainingSessionState>(
//             listener: (context, sessionState) {
//               // Process sensor data for steadiness training
//               if (sessionState.sensorStream?.points.isNotEmpty == true) {
//                 _processSensorData(sessionState.sensorStream!);
//               }
//             },
//             builder: (context, sessionState) {
//               return SingleChildScrollView(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   children: [
//                     // ✅ NEW: Program Information Header
//                     _buildProgramHeader(),
//                     const SizedBox(height: 16),

//                     // ✅ NEW: Connection Status
//                     _buildConnectionStatus(bleState.isConnected),
//                     const SizedBox(height: 16),

//                     // Target Display
//                     _buildTargetDisplay(),
//                     const SizedBox(height: 8),

//                     const SizedBox(height: 16),

//                     _buildDistanceAngleInfoCards(),
//                     const SizedBox(height: 16),

//                     // ✅ ENHANCED: Controls with session time
//                     _buildControlsWithSessionTime(sessionState),
//                     const SizedBox(height: 16),

//                     // ✅ ENHANCED: Status and Metrics
//                     _buildEnhancedStatusCard(sessionState),
//                     const SizedBox(height: 16),

//                     // Settings
//                     // ✅ NEW: Distance Preset Selector
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'Training Distance',
//                           style: const TextStyle(
//                               color: Color(0xFFA8B3C7), fontSize: 12),
//                         ),
//                         const SizedBox(height: 8),
//                         Container(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 12,
//                             vertical: 8,
//                           ),
//                           decoration: BoxDecoration(
//                             color: const Color(0xFF0F1830),
//                             borderRadius: BorderRadius.circular(8),
//                             border: Border.all(
//                                 color: const Color(0xFF1A2440), width: 1),
//                           ),
//                           child: DropdownButtonHideUnderline(
//                             child: DropdownButton<String>(
//                               value: _selectedDistance,
//                               isExpanded: true,
//                               dropdownColor: const Color(0xFF0F1830),
//                               style: const TextStyle(
//                                 color: Color(0xFFE6EEFC),
//                                 fontSize: 14,
//                               ),
//                               items: _distancePresets.entries.map((entry) {
//                                 final key = entry.key;
//                                 final preset = entry.value;
//                                 return DropdownMenuItem(
//                                   value: key,
//                                   child: Text(
//                                     '${preset['name']} - ${preset['description']}',
//                                   ),
//                                 );
//                               }).toList(),
//                               onChanged: (String? newValue) {
//                                 if (newValue != null) {
//                                   _updateDistancePreset(newValue);
//                                   _showDistanceToast(newValue);
//                                 }
//                               },
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 16),

//                     // Shot Log
//                     _buildShotLog(),

//                     // Help Section
//                     const SizedBox(height: 20),
//                   ],
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }

//   // ✅ FIXED: _buildTargetDisplay method with proper clipping
//   Widget _buildTargetDisplay() {
//     return Container(
//       width: double.infinity,
//       height: MediaQuery.of(context).size.height * 0.44,
//       decoration: BoxDecoration(
//         color: const Color(0xFF0E1629),
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: const Color(0xFF1E2A44), width: 2),
//       ),
//       child: LayoutBuilder(
//         builder: (context, constraints) {
//           // ✅ FIX: Use the actual container size consistently
//           final containerWidth = constraints.maxWidth;
//           final containerHeight = constraints.maxHeight;
//           final actualCenterX = containerWidth / 2;
//           final actualCenterY = containerHeight / 2;

//           return Stack(
//             alignment: Alignment.center,
//             children: [
//               // ✅ REMOVED: alignment: Alignment.center - this was causing issues
//               // Crosshair - ✅ FIX: Use actual container size
//               CustomPaint(
//                 painter: CrosshairPainter(),
//                 size:
//                     Size(containerWidth, containerHeight), // ✅ Use actual size
//               ),

//               // ✅ NEW: Center reference ring (0.0° - perfect center)
//               Positioned(
//                 left: actualCenterX - 4,
//                 top: actualCenterY - 4,
//                 child: Container(
//                   width: 8,
//                   height: 8,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     color: const Color(0xFF34D399),
//                     border:
//                         Border.all(color: const Color(0xFF10B981), width: 2),
//                   ),
//                 ),
//               ),
//               _buildTargetRing(
//                   0.1, AppColors.kRedColor, AppColors.kRedColor), // Ring 10
//               _buildTargetRing(0.3, AppColors.kRedColor), // Ring 9
//               _buildTargetRing(0.48, AppColors.kRedColor), // Ring 8
//               _buildTargetRing(0.65, AppColors.kRedColor), // Ring 7
//               _buildTargetRing(0.83, AppColors.kRedColor),
//               _buildTargetRing(1, AppColors.kRedColor),
//               // ✅ CORRECTED: Fixed linear rings with proper scaling
//               // ..._fixedRingRadii.entries.map((entry) {
//               //   final mm = entry.key;
//               //   final radius = entry.value;
//               //   // ✅ FIX: Scale radius to actual container size
//               //   final scaledRadius = radius * (math.min(containerWidth, containerHeight) / 400.0);

//               //   return _buildFixedLinearRingPositioned(
//               //     actualCenterX,
//               //     actualCenterY,
//               //     scaledRadius,
//               //     mm,
//               //   );
//               // }),

//               // ✅ NEW: Gain badge (shows when scaling is active)
//               if (_gainBadge != 1.0 && _gainBadge != 0.0) _buildGainBadge(),

//               // ✅ NEW: Goal achievement badge
//               if (_showingGoalBadge) _buildGoalAchievementBadge(),

//               // ✅ NEW: Current linear wobble display
//               // Positioned(
//               //   bottom: 16,
//               //   left: 16,
//               //   child: Container(
//               //     padding:
//               //         const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//               //     decoration: BoxDecoration(
//               //       color: const Color(0xFF0B1220).withOpacity(0.95),
//               //       borderRadius: BorderRadius.circular(12),
//               //       border: Border.all(
//               //         color: _getMovementStatus() == "Resting"
//               //             ? const Color(0xFF34D399)
//               //             : _getMovementStatus() == "Moving"
//               //                 ? const Color(0xFF5EA1FF)
//               //                 : const Color(0xFFEF4444),
//               //         width: 2,
//               //       ),
//               //       boxShadow: [
//               //         BoxShadow(
//               //           color: Colors.black.withOpacity(0.3),
//               //           blurRadius: 8,
//               //           spreadRadius: 0,
//               //         ),
//               //       ],
//               //     ),
//               //     child: Column(
//               //       mainAxisSize: MainAxisSize.min,
//               //       children: [
//               //         Text(
//               //           'Current Wobble',
//               //           style: const TextStyle(
//               //             color: Color(0xFF9FB0D4),
//               //             fontSize: 10,
//               //             fontWeight: FontWeight.w600,
//               //           ),
//               //         ),
//               //         const SizedBox(height: 4),
//               //         Text(
//               //           '${_calculateCurrentLinearWobble().toStringAsFixed(1)}mm',
//               //           style: TextStyle(
//               //             color: _getMovementStatus() == "Resting"
//               //                 ? const Color(0xFF34D399)
//               //                 : _getMovementStatus() == "Moving"
//               //                     ? const Color(0xFF5EA1FF)
//               //                     : const Color(0xFFEF4444),
//               //             fontSize: 18,
//               //             fontWeight: FontWeight.bold,
//               //           ),
//               //         ),
//               //         Text(
//               //           'at ${_getDistancePreset()['name']}',
//               //           style: const TextStyle(
//               //             color: Color(0xFF8EA6D6),
//               //             fontSize: 10,
//               //           ),
//               //         ),
//               //       ],
//               //     ),
//               //   ),
//               // ),

//               // ✅ FIX: Traceline path - use consistent coordinate system
//               if (_tracePoints.isNotEmpty &&
//                   _visGate &&
//                   _thetaInstDeg < _hideOverDeg)
//                 CustomPaint(
//                   painter: TracelinePainter(
//                     _tracePoints,
//                     containerWidth,
//                     containerHeight,
//                   ),
//                   size: Size(
//                       containerWidth, containerHeight), // ✅ Use actual size
//                 ),

//               // ✅ FIX: Moving dot - use consistent coordinate system
//               if (_visGate && !_isResetting)
//                 Positioned(
//                   left: _convertToDisplayX(_lastDrawX, containerWidth) - 4.5,
//                   top: _convertToDisplayY(_lastDrawY, containerHeight) - 4.5,
//                   child: Container(
//                     width: 9,
//                     height: 9,
//                     decoration: BoxDecoration(
//                       color: const Color(0xFF9BC1FF),
//                       shape: BoxShape.circle,
//                       border: Border.all(
//                         color: const Color(0xFFCFE0FF),
//                         width: 1,
//                       ),
//                       boxShadow: [
//                         BoxShadow(
//                           color:
//                               const Color(0xFF79A9FF).withValues(alpha: 0.35),
//                           blurRadius: 14,
//                           spreadRadius: 0,
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//             ],
//           );
//         },
//       ),
//     );
//   }

// // ✅ NEW: Coordinate conversion functions
//   double _convertToDisplayX(double internalX, double containerWidth) {
//     // Convert from internal 400x400 system to actual container size
//     return (internalX / 400.0) * containerWidth;
//   }

//   double _convertToDisplayY(double internalY, double containerHeight) {
//     // Convert from internal 400x400 system to actual container size
//     return (internalY / 400.0) * containerHeight;
//   }

//   Widget _buildTargetRing(
//     double sizePercentage,
//     Color borderColor, [
//     Color? fillColor,
//   ]) {
//     return FractionallySizedBox(
//       widthFactor: sizePercentage,
//       heightFactor: sizePercentage,
//       child: Container(
//         decoration: BoxDecoration(
//           shape: BoxShape.circle,
//           color: fillColor,
//           border: Border.all(color: borderColor, width: 2),
//         ),
//       ),
//     );
//   }

//   Widget _buildControls() {
//     return Row(
//       children: [
//         if (!_isTraining)
//           Expanded(
//             child: ElevatedButton.icon(
//               onPressed: _startTraining,
//               icon: const Icon(Icons.play_arrow),
//               label: const Text('Start Training'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFF34D399),
//                 foregroundColor: Colors.white,
//                 padding: const EdgeInsets.symmetric(vertical: 16),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//             ),
//           ),
//         if (_isTraining) ...[
//           Expanded(
//             child: ElevatedButton.icon(
//               onPressed: _stopTraining,
//               icon: const Icon(Icons.stop),
//               label: const Text('Stop'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFFEF4444),
//                 foregroundColor: Colors.white,
//                 padding: const EdgeInsets.symmetric(vertical: 16),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//             ),
//           ),
//         ],
//         const SizedBox(width: 8),
//         ElevatedButton.icon(
//           onPressed: _resetTrace,
//           icon: const Icon(Icons.refresh),
//           label: const Text('Reset'),
//           style: ElevatedButton.styleFrom(
//             backgroundColor: Colors.transparent,
//             foregroundColor: const Color(0xFFE6EEFC),
//             side: const BorderSide(color: Color(0xFF2A3A64)),
//             padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(12),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildStatusCard() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: const Color(0xFF111A2B),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: const Color(0xFF1A2440), width: 1),
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: _buildMetricItem(
//               'Shots',
//               _shotCount.toString(),
//               Icons.gps_fixed,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMetricItem(
//     String label,
//     String value,
//     IconData icon, {
//     Color? valueColor,
//   }) {
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: const Color(0xFF0F1830),
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: const Color(0xFF1A2440), width: 1),
//       ),
//       child: Column(
//         children: [
//           Icon(icon, color: const Color(0xFF93A4C7), size: 20),
//           const SizedBox(height: 8),
//           Text(
//             label,
//             style: const TextStyle(color: Color(0xFF93A4C7), fontSize: 12),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 4),
//           Text(
//             value,
//             style: TextStyle(
//               color: valueColor ?? const Color(0xFFE6EEFC),
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//             ),
//             textAlign: TextAlign.center,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildShotLog() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: const Color(0xFF111A2B),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: const Color(0xFF1A2440), width: 1),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Shot Log',
//             style: TextStyle(
//               color: const Color(0xFFE6EEFC),
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 16),
//           if (_shotLog.isEmpty)
//             Text(
//               'No shots recorded yet',
//               style: TextStyle(color: const Color(0xFFA8B3C7), fontSize: 14),
//             )
//           else
//             Column(
//               children: [
//                 // Header
//                 Row(
//                   children: [
//                     Expanded(
//                       flex: 2,
//                       child: Text(
//                         'Time',
//                         style: TextStyle(
//                           color: const Color(0xFF9FB0D4),
//                           fontSize: 14,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ),
//                     Expanded(
//                       flex: 2,
//                       child: Text(
//                         'θ (deg)',
//                         style: TextStyle(
//                           color: const Color(0xFF9FB0D4),
//                           fontSize: 14,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ),
//                     Expanded(
//                       flex: 1,
//                       child: Text(
//                         'Score',
//                         style: TextStyle(
//                           color: const Color(0xFF9FB0D4),
//                           fontSize: 14,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 8),
//                 // Shot entries
//                 ..._shotLog.take(10).map((shot) {
//                   final time = shot['time'] as DateTime;
//                   final theta = shot['theta'] as double;
//                   final score = shot['score'] as int;

//                   return Container(
//                     padding: const EdgeInsets.symmetric(
//                       vertical: 8,
//                       horizontal: 0,
//                     ),
//                     decoration: BoxDecoration(
//                       border: Border(
//                         bottom: BorderSide(
//                           color: const Color(0xFF1A2440),
//                           width: 1,
//                         ),
//                       ),
//                     ),
//                     child: Row(
//                       children: [
//                         Expanded(
//                           flex: 2,
//                           child: Text(
//                             '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}',
//                             style: const TextStyle(
//                               color: Color(0xFFE6EEFC),
//                               fontSize: 14,
//                             ),
//                           ),
//                         ),
//                         Expanded(
//                           flex: 2,
//                           child: Text(
//                             theta.isNaN ? '—' : '${theta.toStringAsFixed(2)}°',
//                             style: const TextStyle(
//                               color: Color(0xFFE6EEFC),
//                               fontSize: 14,
//                             ),
//                           ),
//                         ),
//                         Expanded(
//                           flex: 1,
//                           child: Container(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 8,
//                               vertical: 4,
//                             ),
//                             decoration: BoxDecoration(
//                               color: _getScoreColor(score).withOpacity(0.15),
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             child: Text(
//                               score.toString(),
//                               style: TextStyle(
//                                 color: _getScoreColor(score),
//                                 fontSize: 14,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                               textAlign: TextAlign.center,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   );
//                 }),
//               ],
//             ),
//         ],
//       ),
//     );
//   }

//   Color _getScoreColor(int score) {
//     if (score >= 9) return const Color(0xFF34D399);
//     if (score >= 7) return const Color(0xFFF59E0B);
//     if (score >= 5) return const Color(0xFFEF4444);
//     return const Color(0xFF6B7280);
//   }

//   // ✅ FIXED: Enhanced sensor processing with better traceline control
//   void _processSensorData(StreamingModel streamingModel) {
//     if (!_isTraining) return;

//     final now = DateTime.now();
//     final dt = 0.016;

//     final yaw = streamingModel.yaw;
//     final pitch = streamingModel.pitch;
//     final roll = streamingModel.roll;

//     final w = math.sqrt(yaw * yaw + pitch * pitch + roll * roll);
//     final dtheta = w * dt;
//     _thetaInstDeg = dtheta;

//     _recentSway.add(_thetaInstDeg);
//     final cutoffTime = now.millisecondsSinceEpoch - 4000;
//     _recentSway.removeWhere((r) => r < cutoffTime);

//     _updateAdaptiveScaling();
//     _checkGoalAchievement(now);

//     final yawRate = yaw;
//     final pitchRate = pitch;
//     final angleTarget = math.atan2(-pitchRate, yawRate);

//     final easeSlider = _easing;
//     final angAlpha = 1 -
//         math.exp(-dt /
//             math.max(0.01, ANG_SMOOTH_TAU * (1 + (0.5 - easeSlider) * 1.5)));
//     _lastAngle = _emaAngle(_lastAngle, angleTarget, angAlpha);

//     _readings.add({'ts': now.millisecondsSinceEpoch, 'theta': _thetaInstDeg});
//     final cutoff = now.millisecondsSinceEpoch - 500;
//     _readings.removeWhere((r) => r['ts'] < cutoff);

//     final tableRest = (_thetaInstDeg < TABLE_REST_DEG) && !_isResetting;
//     final steadyNow = (_thetaInstDeg <= HOLD_STABLE_DEG) && !_isResetting;

//     final wasVisible = _visGate;

//     // ✅ ENHANCED: Distance-aware visibility logic
//     if (!_visGate) {
//       if (!tableRest && _thetaInstDeg <= _showUnderDeg) {
//         if (_visGateTS == null ||
//             now.difference(_visGateTS!).inMilliseconds > HYSTERESIS_DWELL_MS) {
//           setState(() {
//             _visGate = true;
//           });
//         }
//       } else {
//         _visGateTS = now;
//       }
//     } else {
//       if (tableRest || _thetaInstDeg >= _hideOverDeg) {
//         if (_visGateTS == null ||
//             now.difference(_visGateTS!).inMilliseconds > HYSTERESIS_DWELL_MS) {
//           setState(() {
//             _visGate = false;
//           });
//         }
//       } else {
//         _visGateTS = now;
//       }
//     }

//     if (!_visGate || _isResetting) {
//       _tracePoints.clear();
//       _readings.clear();
//       setState(() {});
//     } else {
//       if (!wasVisible && _visGate) {
//         _lastDrawX = 200.0;
//         _lastDrawY = 200.0;
//         _rViz = 0.0;
//         _tracePoints.clear();
//         _lastAngle = angleTarget;
//         _tracePoints.add(const Offset(200.0, 200.0));

//         // ✅ NEW: Reset trace tracking
//         _lastTraceX = 200.0;
//         _lastTraceY = 200.0;

//         setState(() {});
//         return;
//       }

//       final newPosition =
//           _calculateDistanceAwarePosition(_thetaInstDeg, _lastAngle);

//       final radAlpha = 1 - math.exp(-dt / math.max(0.01, RAD_SMOOTH_TAU));
//       _lastDrawX = _lastDrawX + (newPosition.dx - _lastDrawX) * radAlpha;
//       _lastDrawY = _lastDrawY + (newPosition.dy - _lastDrawY) * radAlpha;

//       // ✅ KEY FIX: Only add traceline points when significant movement occurs
//       final preset = _getDistancePreset();
//       final distance = preset['distance'] as double;

//       // ✅ CORRECTED: Better movement threshold for cleaner tracelines
//       // At 7m: 2px threshold, at 25m: 3px threshold (prevents excessive drawing)
//       final movementThreshold = 2.0 + (distance - 7.0) * 0.1;

//       final moveDistance = math.sqrt(math.pow(_lastDrawX - _lastTraceX, 2) +
//           math.pow(_lastDrawY - _lastTraceY, 2));

//       if (moveDistance >= movementThreshold) {
//         _tracePoints.add(Offset(_lastDrawX, _lastDrawY));

//         // ✅ ENHANCED: Better traceline management
//         // if (_tracePoints.length > maxPts) {
//         //   _tracePoints.removeAt(0);
//         // }

//         // Update last trace position
//         _lastTraceX = _lastDrawX;
//         _lastTraceY = _lastDrawY;
//       }

//       setState(() {});
//     }

//     _updateSteadyHold(steadyNow, now);
//   }

//   void _updateSteadyHold(bool steady, DateTime now) {
//     if (steady) {
//       _holdStart ??= now;
//       final held = now.difference(_holdStart!).inMilliseconds;
//       if (held >= HOLD_TIME_MS) {
//         //_startCenterReset();
//         _holdStart = null;
//       }
//     } else {
//       _holdStart = null;
//     }
//   }

//   double _emaAngle(double prev, double next, double alpha) {
//     // Normalize to avoid wrap jumps (matching HTML exactly)
//     const twoPi = math.pi * 2;
//     double d = next - prev;
//     if (d > math.pi)
//       next -= twoPi;
//     else if (d < -math.pi) next += twoPi;
//     return prev + alpha * (next - prev);
//   }

//   void _showConnectionDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Sensor Connection'),
//         content: const Text('RT Sensor Disconnected'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Back'),
//           ),
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//               Navigator.pop(context);
//             },
//             child: const Text('Continue'),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class TracelinePainter extends CustomPainter {
//   final List<Offset> points;
//   final double containerWidth;
//   final double containerHeight;

//   TracelinePainter(this.points, this.containerWidth, this.containerHeight);

//   @override
//   void paint(Canvas canvas, Size size) {
//     if (points.length < 2) return;

//     // Line paint
//     final linePaint = Paint()
//       ..color = const Color(0xFF7AA2FF)
//       ..strokeWidth = 2.5
//       ..style = PaintingStyle.stroke
//       ..strokeCap = StrokeCap.round
//       ..strokeJoin = StrokeJoin.round;

//     // Head paint (last point)
//     final headPaint = Paint()
//       ..color = const Color(0xFF7AA2FF)
//       ..style = PaintingStyle.fill;

//     // ✅ FIX: Convert internal coordinates to display coordinates
//     final path = Path();
//     final offsetPoints = points
//         .map(
//           (point) => Offset(
//             _convertInternalToDisplayX(point.dx, containerWidth),
//             _convertInternalToDisplayY(point.dy, containerHeight),
//           ),
//         )
//         .toList();

//     if (offsetPoints.isNotEmpty) {
//       path.moveTo(offsetPoints[0].dx, offsetPoints[0].dy);

//       for (int i = 1; i < offsetPoints.length; i++) {
//         path.lineTo(offsetPoints[i].dx, offsetPoints[i].dy);
//       }

//       // Draw line
//       canvas.drawPath(path, linePaint);
//     }
//   }

//   // ✅ Helper function to convert coordinates
//   double _convertInternalToDisplayX(double internalX, double containerWidth) {
//     return (internalX / 400.0) * containerWidth;
//   }

//   double _convertInternalToDisplayY(double internalY, double containerHeight) {
//     return (internalY / 400.0) * containerHeight;
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
// }

// // ✅ UPDATED: CrosshairPainter with dynamic sizing
// class CrosshairPainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = const Color(0xFF1E2A44)
//       ..strokeWidth = 1.0;

//     final center = Offset(size.width / 2, size.height / 2);

//     // Horizontal line
//     canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), paint);

//     // Vertical line
//     canvas.drawLine(
//       Offset(center.dx, 0),
//       Offset(center.dx, size.height),
//       paint,
//     );
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
// }
// // // ✅ NEW: Small crosshair painter for cant display
// // class SmallCrosshairPainter extends CustomPainter {
// //   @override
// //   void paint(Canvas canvas, Size size) {
// //     final paint = Paint()
// //       ..color = const Color(0xFF5EA1FF)
// //       ..strokeWidth = 1.0;
// //
// //     final center = Offset(size.width / 2, size.height / 2);
// //
// //     // Horizontal line
// //     canvas.drawLine(
// //       Offset(2, center.dy),
// //       Offset(size.width - 2, center.dy),
// //       paint,
// //     );
// //
// //     // Vertical line
// //     canvas.drawLine(
// //       Offset(center.dx, 2),
// //       Offset(center.dx, size.height - 2),
// //       paint,
// //     );
// //   }
// //
// //   @override
// //   bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
// // }
// //
// // // ✅ UPDATED: Cant indicator painter with bigger circle + angle inside
// // class CantIndicatorPainter extends CustomPainter {
// //   final double cantAngle;
// //
// //   CantIndicatorPainter(this.cantAngle);
// //
// //   @override
// //   void paint(Canvas canvas, Size size) {
// //     final center = Offset(size.width / 2, size.height / 2);
// //
// //     // Background circle
// //     final bgPaint = Paint()
// //       ..color = const Color(0xFF0F1830)
// //       ..style = PaintingStyle.fill;
// //     canvas.drawCircle(center, 28, bgPaint);
// //
// //     // Border circle
// //     final borderPaint = Paint()
// //       ..color = const Color(0xFF2A3A64)
// //       ..strokeWidth = 2.0
// //       ..style = PaintingStyle.stroke;
// //     canvas.drawCircle(center, 28, borderPaint);
// //
// //     // Cant line (rotates with angle) - bigger now
// //     final linePaint = Paint()
// //       ..color = const Color(0xFF5EA1FF)
// //       ..strokeWidth = 3.0
// //       ..strokeCap = StrokeCap.round;
// //
// //     final angleRad = (cantAngle * math.pi / 180);
// //     final lineLength = 22.0; // 🔥 made bigger
// //     final startX = center.dx - lineLength * math.cos(angleRad);
// //     final startY = center.dy - lineLength * math.sin(angleRad);
// //     final endX = center.dx + lineLength * math.cos(angleRad);
// //     final endY = center.dy + lineLength * math.sin(angleRad);
// //
// //     canvas.drawLine(Offset(startX, startY), Offset(endX, endY), linePaint);
// //
// //     // Reference horizontal line
// //     final refPaint = Paint()
// //       ..color = const Color(0xFF3A4A64).withOpacity(0.5)
// //       ..strokeWidth = 1.5;
// //     canvas.drawLine(
// //       Offset(center.dx - 18, center.dy),
// //       Offset(center.dx + 18, center.dy),
// //       refPaint,
// //     );
// //
// //     // Center dot
// //     final dotPaint = Paint()
// //       ..color = const Color(0xFF7AA2FF)
// //       ..style = PaintingStyle.fill;
// //     canvas.drawCircle(center, 2.5, dotPaint);
// //
// //     // Angle text inside circle
// //     final textPainter = TextPainter(
// //       text: TextSpan(
// //         text: '${cantAngle.toStringAsFixed(1)}°',
// //         style: const TextStyle(
// //           color: Color(0xFF7A8BA3),
// //           fontSize: 10,
// //           fontWeight: FontWeight.w500,
// //         ),
// //       ),
// //       textDirection: TextDirection.ltr,
// //     );
// //     textPainter.layout();
// //     textPainter.paint(
// //       canvas,
// //       Offset(center.dx - textPainter.width / 2, center.dy + 12),
// //     );
// //   }
// //
// //   @override
// //   bool shouldRepaint(covariant CustomPainter oldDelegate) {
// //     return oldDelegate is CantIndicatorPainter &&
// //         oldDelegate.cantAngle != cantAngle;
// //   }
// // }

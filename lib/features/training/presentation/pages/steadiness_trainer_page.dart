// Fixed version - Remove duplicate shot cycle management
import 'dart:collection';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:pulse_skadi/core/services/prefs.dart';
import 'package:pulse_skadi/core/theme/app_colors.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:pulse_skadi/features/training/data/model/programs_model.dart';
import 'package:pulse_skadi/features/training/presentation/bloc/ble_scan/ble_scan_bloc.dart';
import 'package:pulse_skadi/features/training/presentation/bloc/ble_scan/ble_scan_state.dart';
import 'package:pulse_skadi/features/training/presentation/bloc/training_session/training_session_bloc.dart';
import 'package:pulse_skadi/features/training/presentation/bloc/training_session/training_session_event.dart';
import 'package:pulse_skadi/features/training/presentation/bloc/training_session/training_session_state.dart';
import 'package:pulse_skadi/features/training/data/model/steadiness_shot_data.dart';
import 'package:pulse_skadi/features/training/data/model/streaming_model.dart';
import 'package:pulse_skadi/features/training/presentation/pages/sensitity_settings_page.dart';
import 'package:pulse_skadi/features/training/presentation/pages/manticx_analysis_page.dart';

import '../../data/model/shot_trace_model.dart';

class SteadinessTrainerPage extends StatefulWidget {
  const SteadinessTrainerPage({super.key, required this.program});
  final ProgramsModel program;

  @override
  State<SteadinessTrainerPage> createState() => _SteadinessTrainerPageState();
}

class _SteadinessTrainerPageState extends State<SteadinessTrainerPage>
    with TickerProviderStateMixin {
  late ProgramsModel _currentProgram;

  // Animation controllers
  late AnimationController _dotAnimationController;
  late AnimationController _glowAnimationController;

  // Timer for continuous session time updates
  Timer? _sessionTimer;

  // Training state
  bool _isTraining = false;
  bool _isResetting = false;
  DateTime? _lastShotTime;
  int _shotCount = 0;
  final List<Map<String, dynamic>> _shotLog = [];

  // Sensor data processing (matching HTML exactly)
  double _thetaInstDeg = 0.0;
  double _lastAngle = 0.0;
  double _rViz = 0.0;
  double _lastDrawX = 200.0;
  double _lastDrawY = 200.0;

  // Current cant value for display
  double _currentCant = 0.0;

  // Visibility and hysteresis
  bool _visGate = false;
  DateTime? _visGateTS;

  // Steady hold detection
  DateTime? _holdStart;

  // Settings
  double _traceLength = 160.0;
  double _easing = 0.15;
  String _difficulty = 'nov'; // Default to Novice (Easy)
  double _gateValue = 2.5; // Gate value for dynamic angle control

  // Constants (matching HTML exactly)
  static const double TABLE_REST_DEG = 0.0015;
  static const double HOLD_STABLE_DEG = 0.10;
  static const int HOLD_TIME_MS = 250;
  static const int HYSTERESIS_DWELL_MS = 60;
  static const double RATE_LIMIT_PX = 28.0;
  static const double ANG_SMOOTH_TAU = 0.12;
  static const double RAD_SMOOTH_TAU = 0.10;

  // Ring configuration
  final Map<int, double> _ringRadii = {};
  final Map<int, Offset> _ringLabels = {};

  // Scoring radii (can be more lenient than visual rings depending on Difficulty)
  final Map<int, double> _scoreRadii = {};

  // Traceline points (matching HTML)
  final List<Offset> _tracePoints = [];

  // Sensor readings buffer (matching HTML)
  final List<Map<String, dynamic>> _readings = [];

  // Linear-based training system
  String _selectedDistance = '7'; // Default to 7m
  final Map<String, Map<String, dynamic>> _distancePresets = {
    '7': {
      'name': '7m',
      'distance': 7.0,
      'linearTolerance': 10.0,
      'description': 'Beginner - 7m',
    },
    '10': {
      'name': '10m',
      'distance': 10.0,
      'linearTolerance': 10.0,
      'description': 'Intermediate - 10m',
    },
    '15': {
      'name': '15m',
      'distance': 15.0,
      'linearTolerance': 10.0,
      'description': 'Advanced - 15m',
    },
    '25': {
      'name': '25m',
      'distance': 25.0,
      'linearTolerance': 10.0,
      'description': 'Expert - 25m',
    },
    '50': {
      'name': '50m',
      'distance': 50.0,
      'linearTolerance': 10.0,
      'description': 'Expert - 50m',
    },
    '100': {
      'name': '100m',
      'distance': 100.0,
      'linearTolerance': 10.0,
      'description': 'Expert - 100m',
    },
    '200': {
      'name': '200m',
      'distance': 200.0,
      'linearTolerance': 10.0,
      'description': 'Expert - 200m',
    },
    '500': {
      'name': '500m',
      'distance': 500.0,
      'linearTolerance': 10.0,
      'description': 'Expert - 500m',
    },
  };

  // Adaptive scaling system
  double _scaleAbs = 0.0; // Fixed truth scale (edge_px / edge_deg)
  double _currentScale = 1.0; // Current adaptive scale
  double _gainBadge = 1.0; // Current gain multiplier
  DateTime? _lastScaleUpdate; // For 300-500ms updates
  final List<double> _recentSway = []; // 4-second buffer for P95 calculation

  // Fixed linear rings (same visual size for all distances)
  final List<double> _fixedLinearRings = [5.0, 10.0, 20.0]; // mm
  final Map<double, double> _fixedRingRadii = {}; // mm -> radius in pixels

  // Goal achievement tracking
  int _goalHoldsAchieved = 0;
  final int _goalHoldsRequired = 10; // Show badge after 10 successful holds
  DateTime? _goalHoldStart;
  bool _showingGoalBadge = false;

  // ✅ REMOVED: All shot cycle tracking variables (handled by repository)
  // ShotCycleState _shotCycleState = ShotCycleState.preShot;
  // int _preShotPointsCount = 0;
  // int _postShotPointsCount = 0;
  // int _targetPostShotPoints = 0;
  // final Queue<TracePoint> _currentShotTrace = Queue();
  // final List<Queue<TracePoint>> _allShotTraces = [];
  // bool _hasShotOccurred = false;
  // DateTime? _shotDetectedTime;
  // int _currentShotNumber = 0;

  // ✅ REMOVED: All shot cycle management methods
  // void _maintainTracelinePacketLimit() { ... }
  // void _addPointToTrace(TracePoint tracePoint) { ... }
  // void _manageShotCycleWithTraceStorage(...) { ... }
  // void _processCompleteShot() { ... }
  // void _resetForNextShot(...) { ... }

  // Traceline movement threshold to reduce excessive drawing
  double _lastTraceX = 200.0;
  double _lastTraceY = 200.0;

  // Shot markers for detected shots on traceline
  final List<ShotMarker> _shotMarkers = [];

  // Store the exact traceline position when shot is detected
  Offset? _lastShotPosition;

  // Traceline capture system for complete shot analysis - Packet-based approach
  final List<TracePoint> _tracelineBuffer = [];
  static const int PRE_SHOT_PACKETS = 250; // Increased to accommodate 30 point lookback
  static const int POST_SHOT_PACKETS = 100; // Packets after shot
  static const int SHOT_PACKETS = 1; // Shot packet itself
  static const int SHOT_LOOKBACK_POINTS = 50; // Points to go back for shot position

  // Post-shot tracking for visual traceline coloring
  bool _isInPostShotMode = false;
  int _postShotStartIndex = 0; // Index in _tracePoints where post-shot started

  // Calculate current linear wobble in mm for display
  double _calculateCurrentLinearWobble() {
    final preset = _getDistancePreset();
    final distance = preset['distance'] as double;

    // Convert current angular movement to linear wobble at target
    // W = D * θ * (π/180) where D is distance in meters, θ is angle in degrees
    return distance * _thetaInstDeg * (math.pi / 180);
  }

  // Calculate average wobble over recent readings
  double _calculateAverageWobble() {
    if (_readings.isEmpty) return 0.0;

    final preset = _getDistancePreset();
    final distance = preset['distance'] as double;

    // Calculate average angular movement
    double totalTheta = 0.0;
    for (final reading in _readings) {
      totalTheta += reading['theta'] as double;
    }
    final avgTheta = totalTheta / _readings.length;

    // Convert to linear wobble at current distance
    return distance * avgTheta * (math.pi / 180);
  }

  @override
  void initState() {
    super.initState();
    _currentProgram = widget.program;

    _dotAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _glowAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _initializeRingSystem();
    _recomputeScoreRadii();
    _updateDistancePreset(_selectedDistance);
  }

  void _initializeRingSystem() {
    // Calculate ring radii (matching HTML logic exactly)
    const double ring5Radius = 190.0;
    const double bandWidth = ring5Radius / 5.5;
    const double r10 = bandWidth / 2;

    _ringRadii[10] = r10;
    _ringRadii[9] = r10 + 1 * bandWidth;
    _ringRadii[8] = r10 + 2 * bandWidth;
    _ringRadii[7] = r10 + 3 * bandWidth;
    _ringRadii[6] = r10 + 4 * bandWidth;
    _ringRadii[5] = r10 + 5 * bandWidth;

    // Calculate label positions
    const center = Offset(200, 200);
    const labelInset = 12.0;

    for (int i = 10; i >= 5; i--) {
      _ringLabels[i] = Offset(
        center.dx,
        center.dy - math.max(0, _ringRadii[i]! - labelInset),
      );
    }
  }

  // Update distance preset and recalculate scales
  void _updateDistancePreset(String distance) {
    setState(() {
      _selectedDistance = distance;
    });

    final preset = _distancePresets[distance] ?? _distancePresets['7']!;
    print('edgeDeg --: $preset ');
    final edgeDeg = preset['distance'] as double;

    // Calculate fixed truth scale: edge_px / distance
    _scaleAbs = 190.0 / edgeDeg; // 190px is the outer ring radius

    // Initialize current scale to truth scale
    _currentScale = _scaleAbs;
    _gainBadge = 1.0;

    // Calculate fixed linear ring radii (same visual size for all distances)
    _fixedRingRadii.clear();
    for (final mm in _fixedLinearRings) {
      // Convert mm to pixels: 190px = 20mm ring (outer ring)
      _fixedRingRadii[mm] = (mm / 20.0) * 190.0;
    }

    // Reset adaptive scaling
    _lastScaleUpdate = null;
    _recentSway.clear();

    // Reset goal tracking
    _goalHoldsAchieved = 0;
    _goalHoldStart = null;
    _showingGoalBadge = false;
  }

  void _recomputeScoreRadii() {
    // Base visual thresholds from center→outer: r10 < r9 < r8 < r7 < r6 < r5
    final base = [
      _ringRadii[10]!,
      _ringRadii[9]!,
      _ringRadii[8]!,
      _ringRadii[7]!,
      _ringRadii[6]!,
      _ringRadii[5]!,
    ];
    final scores = [10, 9, 8, 7, 6, 5];

    // Map difficulty to an outward step in the base array (can be fractional)
    final step = _difficulty == 'pro'
        ? 0.0
        : _difficulty == 'adv'
            ? 0.5
            : _difficulty == 'int'
                ? 1.0
                : _difficulty == 'nov'
                    ? 2.0
                    : 3.0; // beg

    // Interpolate thresholds with the given step; clamp to r5 so they never exceed outer ring
    for (int i = 0; i < scores.length; i++) {
      double pos = i + step;
      if (pos >= base.length - 1) {
        _scoreRadii[scores[i]] = base[base.length - 1]; // r5
        continue;
      }
      final lo = pos.floor();
      final hi = pos.ceil();
      final t = pos - lo;
      final r = base[lo] + (base[hi] - base[lo]) * t;
      _scoreRadii[scores[i]] = math.min(r, base[base.length - 1]);
    }
  }

  @override
  void dispose() {
    _dotAnimationController.dispose();
    _glowAnimationController.dispose();
    _stopSessionTimer(); // Clean up timer
    super.dispose();
  }

  // ✅ SIMPLIFIED: Start training without shot cycle management
  void _startTraining() {
    setState(() {
      _isTraining = true;
      _shotCount = 0;
      _shotLog.clear();
      _tracePoints.clear();
      _readings.clear();
      _visGate = false;
      _holdStart = null;
      _rViz = 0.0;
      _lastDrawX = 200.0;
      _lastDrawY = 200.0;
      _currentCant = 0.0;

      // ✅ ONLY UI STATE RESET
      _goalHoldsAchieved = 0;
      _goalHoldStart = null;
      _showingGoalBadge = false;
      _currentScale = _scaleAbs;
      _gainBadge = 1.0;
      _recentSway.clear();
      _lastTraceX = 200.0;
      _lastTraceY = 200.0;
      _shotMarkers.clear();
      _hasNavigatedToSessionDetail = false;
      _lastShotPosition = null;
      _tracelineBuffer.clear();
      _lastShotDetectedUI = false;
      _waitingForLastShotTrace = false;// ✅ NEW: Reset post-shot mode
      _isInPostShotMode = false;
      _postShotStartIndex = 0;
    });

    // Start the training session in BLoC
    context.read<TrainingSessionBloc>().add(StartTrainingSession());

    // Enable sensors if device is connected
    final bleState = context.read<BleScanBloc>().state;
    if (bleState.connectedDevice != null) {
      context.read<TrainingSessionBloc>().add(
            EnableSensors(
              program: _currentProgram,
              device: bleState.connectedDevice!,
            ),
          );
    }

    _startSessionTimer();
  }

  void _stopTraining() {
    setState(() {
      _isTraining = false;
      _waitingForLastShotTrace = false;
    });

    // Stop the training session
    context.read<TrainingSessionBloc>().add(StopTrainingSession());

    // Disable sensors if device is connected
    final bleState = context.read<BleScanBloc>().state;
    if (bleState.connectedDevice != null) {
      context.read<TrainingSessionBloc>().add(
            DisableSensors(device: bleState.connectedDevice!),
          );
    }

    // Stop continuous timer updates
    _stopSessionTimer();
    _lastShotDetectedUI = false;
    _isInPostShotMode = false;
    _postShotStartIndex = 0;
  }

  void _takeShot() {
    if (!_isTraining) return;

    setState(() {
      _shotCount++;
    });

    // Calculate score based on current dot position
    final score = _calculateScore();
    final thetaDot = _calculateThetaDot();

    // Add to log
    _shotLog.insert(0, {
      'time': DateTime.now(),
      'theta': thetaDot,
      'score': score,
    });

    // Haptic feedback
    HapticFeedback.mediumImpact();

    // Show score toast
    _showScoreToast(score, thetaDot);
  }

  int _calculateScore() {
    if (_thetaInstDeg < TABLE_REST_DEG) return 10; // Resting = perfect

    final rPx = math.sqrt(_lastDrawX * _lastDrawX + _lastDrawY * _lastDrawY);

    // Score by difficulty-adjusted ring bands (matching HTML exactly)
    if (rPx <= _scoreRadii[10]!) return 10;
    if (rPx <= _scoreRadii[9]!) return 9;
    if (rPx <= _scoreRadii[8]!) return 8;
    if (rPx <= _scoreRadii[7]!) return 7;
    if (rPx <= _scoreRadii[6]!) return 6;
    if (rPx <= _scoreRadii[5]!) return 5;
    return 0; // Off the board
  }

  // Calculate score at a specific position
  int _calculateScoreAtPosition(Offset position) {
    final rPx = math
        .sqrt(math.pow(position.dx - 200, 2) + math.pow(position.dy - 200, 2));

    // Score by difficulty-adjusted ring bands (matching HTML exactly)
    if (rPx <= _scoreRadii[10]!) return 10;
    if (rPx <= _scoreRadii[9]!) return 9;
    if (rPx <= _scoreRadii[8]!) return 8;
    if (rPx <= _scoreRadii[7]!) return 7;
    if (rPx <= _scoreRadii[6]!) return 6;
    if (rPx <= _scoreRadii[5]!) return 5;
    return 0; // Off the board
  }

  double _calculateThetaDot() {
    final rPx = math.sqrt(_lastDrawX * _lastDrawX + _lastDrawY * _lastDrawY);
    final f = (rPx / _ringRadii[5]!).clamp(0.0, 1.0);
    return f * _visualRing5Deg; // NOW USING DYNAMIC VALUE
  }

  // Calculate theta dot at a specific position
  double _calculateThetaDotAtPosition(Offset position) {
    final rPx = math
        .sqrt(math.pow(position.dx - 200, 2) + math.pow(position.dy - 200, 2));
    final f = (rPx / _ringRadii[5]!).clamp(0.0, 1.0);
    return f * _visualRing5Deg;
  }

  // ✅ FIXED: Continuous traceline capture methods - Replace these methods in SteadinessTrainerPage



// Start post-shot capture for a specific shot - Ensures continuity from shot position
  void _startPostShotCapture(
      List<TracePoint> shotTracelineBuffer, Offset shotPosition)
  {
    int postShotCount = 0;
    int timeoutCount = 0;
    const maxTimeout = 2000; // 2 seconds timeout

    // ✅ FIX: Start from shot position to ensure continuity
    Offset lastCapturedPosition = shotPosition;

    // Create a timer to collect post-shot packets
    Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      timeoutCount++;

      // ✅ FIX: Create smooth transition from shot position to current position
      Offset currentPosition = Offset(_lastDrawX, _lastDrawY);

      // For the first few post-shot points, interpolate from shot position to current position
      if (postShotCount < 5) {
        final t = postShotCount / 4.0; // 0.0 to 1.0 over first 5 points
        currentPosition = Offset(
          lastCapturedPosition.dx +
              (currentPosition.dx - lastCapturedPosition.dx) * t,
          lastCapturedPosition.dy +
              (currentPosition.dy - lastCapturedPosition.dy) * t,
        );
      }

      // Add current position as post-shot packet
      final postShotPoint = TracePoint(
        Point3D(currentPosition.dx, currentPosition.dy, 0.0),
        TracePhase.postShot,
      );
      shotTracelineBuffer.add(postShotPoint);
      postShotCount++;

      // Update last captured position
      lastCapturedPosition = currentPosition;

      // Check if we have enough post-shot packets OR timeout reached
      if (postShotCount >= POST_SHOT_PACKETS || timeoutCount >= maxTimeout) {
        timer.cancel();
        // print(
        //     '🎯 Post-shot capture completed: $postShotCount packets (timeout: ${timeoutCount >= maxTimeout})');
        _completeShotCapture(shotTracelineBuffer);
      }
    });
  }



// Modified shot detection methods - Replace these in your SteadinessTrainerPage



// Modified _addShotMarker method
  void _addShotMarker() {
    final now = DateTime.now();

    // Calculate shot position by going back 30 points in the traceline buffer
    Offset shotPosition;
    int actualLookback = 0;

    if (_tracelineBuffer.length >= SHOT_LOOKBACK_POINTS) {
      // Go back 30 points from current position
      final lookbackIndex = _tracelineBuffer.length - SHOT_LOOKBACK_POINTS;
      final lookbackPoint = _tracelineBuffer[lookbackIndex];
      shotPosition = Offset(lookbackPoint.point.x, lookbackPoint.point.y);
      actualLookback = SHOT_LOOKBACK_POINTS;
      print('🎯 Shot detected: Using position from $actualLookback points back');
    } else {
      // Not enough points in buffer, use earliest available point
      if (_tracelineBuffer.isNotEmpty) {
        final earliestPoint = _tracelineBuffer.first;
        shotPosition = Offset(earliestPoint.point.x, earliestPoint.point.y);
        actualLookback = _tracelineBuffer.length;
        print('⚠️ Only ${_tracelineBuffer.length} points available, using earliest point');
      } else {
        // Fallback to current position
        shotPosition = Offset(_lastDrawX, _lastDrawY);
        print('⚠️ Empty traceline buffer, using current position as fallback');
      }
    }

    // Validate shot position
    if (shotPosition.dx.isNaN || shotPosition.dy.isNaN) {
      print('⚠️ Invalid shot position detected, using center as fallback');
      shotPosition = Offset(200.0, 200.0);
    }

    // Set post-shot mode and mark the index (accounting for the lookback)
    setState(() {
      _isInPostShotMode = true;
      // Post-shot starts from the lookback position in the visual traceline
      _postShotStartIndex = math.max(0, _tracePoints.length - actualLookback);
    });

    _processShotAtPosition(shotPosition, now, actualLookback);
  }

// Modified _processShotAtPosition method
  void _processShotAtPosition(Offset shotPosition, DateTime timestamp, [int lookbackPoints = 0]) {
    // Calculate accuracy based on distance from center
    final distanceFromCenter = math.sqrt(
        math.pow(shotPosition.dx - 200, 2) + math.pow(shotPosition.dy - 200, 2)
    );
    final maxRadius = 190.0;
    final accuracy = (distanceFromCenter / maxRadius).clamp(0.0, 1.0);

    // Calculate score and theta for shot log based on shot position
    final score = _calculateScoreAtPosition(shotPosition);
    final thetaDot = _calculateThetaDotAtPosition(shotPosition);

    // Create shot marker
    final shotMarker = ShotMarker(
      position: shotPosition,
      timestamp: timestamp,
      accuracy: accuracy,
    );

    // Add to shot markers list
    _shotMarkers.add(shotMarker);

    // Add entry to shot log
    _shotLog.insert(0, {
      'time': timestamp,
      'theta': thetaDot,
      'score': score,
    });

    // Increment shot count
    setState(() {
      _shotCount++;
    });

    // Store shot data immediately for session details page
    _storeImmediateShotData(shotPosition, score, thetaDot, accuracy, timestamp);

    // Start traceline capture for complete shot analysis (with lookback info)
    _startShotCapture(shotPosition, lookbackPoints);

    // Limit the number of shot markers to prevent memory issues
    if (_shotMarkers.length > 20) {
      _shotMarkers.removeAt(0);
    }

    // Show score toast for detected shots
    _showScoreToast(score, thetaDot);

    // Haptic feedback for detected shots
    HapticFeedback.mediumImpact();

    // Trigger UI update
    setState(() {});
  }

// Modified _startShotCapture method
  void _startShotCapture(Offset shotPosition, [int lookbackPoints = 0]) {
    // Create a copy of the current traceline buffer
    final shotTracelineBuffer = List<TracePoint>.from(_tracelineBuffer);

    print('🎯 Starting shot capture with ${shotTracelineBuffer.length} buffer points, lookback: $lookbackPoints');

    if (shotTracelineBuffer.isEmpty) {
      print('⚠️ Empty traceline buffer, adding pre-shot data at shot position');
      for (int i = 0; i < 10; i++) {
        final preShotPoint = TracePoint(
          Point3D(shotPosition.dx, shotPosition.dy, 0.0),
          TracePhase.preShot,
        );
        shotTracelineBuffer.add(preShotPoint);
      }
    }

    // Mark the phases correctly based on lookback
    if (lookbackPoints > 0 && shotTracelineBuffer.length >= lookbackPoints) {
      // Find the shot index (lookback points from the end)
      final shotIndex = shotTracelineBuffer.length - lookbackPoints;

      // Update phases: everything before shotIndex remains preShot
      // Points from shotIndex to end become early postShot
      for (int i = shotIndex; i < shotTracelineBuffer.length; i++) {
        shotTracelineBuffer[i] = TracePoint(
          shotTracelineBuffer[i].point,
          i == shotIndex ? TracePhase.shot : TracePhase.postShot,
        );
      }

      print('📊 Updated phases: pre-shot: $shotIndex, shot: 1, early post-shot: ${lookbackPoints - 1}');
    } else {
      // Fallback: add shot packet at the end
      final shotPoint = TracePoint(
        Point3D(shotPosition.dx, shotPosition.dy, 0.0),
        TracePhase.shot,
      );
      shotTracelineBuffer.add(shotPoint);
    }

    // Continue capturing remaining post-shot packets
    _continuePostShotCapture(shotTracelineBuffer, shotPosition, lookbackPoints);
  }

// Modified _continuePostShotCapture method
  void _continuePostShotCapture(List<TracePoint> shotTracelineBuffer, Offset shotPosition, int existingPostShotPoints) {
    int additionalPostShotCount = 0;
    int timeoutCount = 0;
    const maxTimeout = 2000; // 2 seconds timeout

    // Calculate how many more post-shot points we need
    final targetPostShotPoints = POST_SHOT_PACKETS;
    final remainingPostShotPoints = math.max(0, targetPostShotPoints - existingPostShotPoints);

    print('🎯 Continuing post-shot capture: need $remainingPostShotPoints more points (already have $existingPostShotPoints)');

    if (remainingPostShotPoints <= 0) {
      // We already have enough post-shot points from the lookback
      print('✅ Already have sufficient post-shot points from lookback');
      _completeShotCapture(shotTracelineBuffer);
      return;
    }

    Offset lastCapturedPosition = shotPosition;

    // Create a timer to collect remaining post-shot packets
    Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      timeoutCount++;
      Offset currentPosition = Offset(_lastDrawX, _lastDrawY);

      // Smooth transition for the first few additional points
      if (additionalPostShotCount < 5) {
        final t = additionalPostShotCount / 4.0;
        currentPosition = Offset(
          lastCapturedPosition.dx + (currentPosition.dx - lastCapturedPosition.dx) * t,
          lastCapturedPosition.dy + (currentPosition.dy - lastCapturedPosition.dy) * t,
        );
      }

      // Add current position as post-shot packet
      final postShotPoint = TracePoint(
        Point3D(currentPosition.dx, currentPosition.dy, 0.0),
        TracePhase.postShot,
      );
      shotTracelineBuffer.add(postShotPoint);
      additionalPostShotCount++;
      lastCapturedPosition = currentPosition;

      // Check if we have enough additional post-shot packets OR timeout reached
      if (additionalPostShotCount >= remainingPostShotPoints || timeoutCount >= maxTimeout) {
        timer.cancel();

        final totalPostShot = existingPostShotPoints + additionalPostShotCount;
        print('🎯 Post-shot capture completed: $totalPostShot total post-shot packets');
        print('   - From lookback: $existingPostShotPoints');
        print('   - Additional captured: $additionalPostShotCount');

        _completeShotCapture(shotTracelineBuffer);
      }
    });
  }

// Modified _addToTracelineBuffer method to handle larger buffer
  void _addToTracelineBuffer(Offset position, TracePhase phase) {
    // Validate position to avoid NaN or extreme values
    if (position.dx.isNaN ||
        position.dy.isNaN ||
        position.dx.isInfinite ||
        position.dy.isInfinite) {
      print('⚠️ Invalid position detected, skipping: ${position.dx}, ${position.dy}');
      return;
    }

    final tracePoint = TracePoint(
      Point3D(position.dx, position.dy, 0.0),
      phase,
    );

    // Maintain circular buffer of pre-shot packets (now larger to accommodate lookback)
    _tracelineBuffer.add(tracePoint);
    if (_tracelineBuffer.length > PRE_SHOT_PACKETS) {
      _tracelineBuffer.removeAt(0);
    }

    // Debug: Log buffer size periodically
    if (_tracelineBuffer.length % 50 == 0 && _tracelineBuffer.isNotEmpty) {
      //print('📊 Traceline buffer size: ${_tracelineBuffer.length}');
    }
  }



  // Store shot data immediately when shot is detected
  void _storeImmediateShotData(Offset shotPosition, int score, double thetaDot,
      double accuracy, DateTime timestamp)
  {
    // Create initial steadiness shot data with current traceline points
    final initialTracelinePoints = _tracePoints
        .map((point) => TracePoint(
              Point3D(point.dx, point.dy, 0.0),
              TracePhase.preShot, // All current points are pre-shot
            ))
        .toList();

    final steadinessShotData = SteadinessShotData(
      shotNumber: _shotCount,
      timestamp: timestamp,
      position: shotPosition,
      score: score,
      thetaDot: thetaDot,
      accuracy: accuracy,
      tracelinePoints: initialTracelinePoints,
      metrics: {
        'distance': _getDistancePreset()['distance'],
        'difficulty': _difficulty,
        'gateValue': _gateValue,
        'linearWobble': _calculateCurrentLinearWobble(),
        'status': 'capturing', // Indicate that traceline is being captured
        'preShotPackets': initialTracelinePoints.length,
        'shotPackets': 0,
        'postShotPackets': 0,
        'totalTracelinePackets': initialTracelinePoints.length,
      },
      analysisNotes:
          'Shot detected - capturing complete traceline (100 pre + 1 shot + 100 post packets)...',
    );

    // Store in TrainingSessionBloc immediately
    context
        .read<TrainingSessionBloc>()
        .add(AddSteadinessShot(steadinessShotData));

    print(
        '🎯 Stored immediate shot data for shot $_shotCount with ${initialTracelinePoints.length} initial points');
  }

  bool _hasNavigatedToSessionDetail = false;
  bool _lastShotDetectedUI = false;
  bool _waitingForLastShotTrace = false;

  // Complete shot capture and store the complete traceline - Packet-based approach
  void _completeShotCapture(List<TracePoint> completeTraceline) {
    final preShotCount =
        completeTraceline.where((p) => p.phase == TracePhase.preShot).length;
    final shotCount =
        completeTraceline.where((p) => p.phase == TracePhase.shot).length;
    final postShotCount =
        completeTraceline.where((p) => p.phase == TracePhase.postShot).length;

    // print(
    //     '🎯 Completed shot capture with ${completeTraceline.length} total packets');
    // print('   - Pre-shot packets: $preShotCount');
    // print('   - Shot packets: $shotCount');
    // print('   - Post-shot packets: $postShotCount');

    // Store the complete shot data
    _storeCompleteShotData(completeTraceline);
  }

  // Store complete shot data with full traceline
  void _storeCompleteShotData(List<TracePoint> completeTraceline) {
    final shotPosition = _lastShotPosition ?? Offset(_lastDrawX, _lastDrawY);
    final now = DateTime.now();

    // Calculate accuracy based on distance from center
    final distanceFromCenter = math.sqrt(math.pow(shotPosition.dx - 200, 2) +
        math.pow(shotPosition.dy - 200, 2));
    final maxRadius = 190.0;
    final accuracy = (distanceFromCenter / maxRadius).clamp(0.0, 1.0);

    // Calculate score and theta
    final score = _calculateScoreAtPosition(shotPosition);
    final thetaDot = _calculateThetaDotAtPosition(shotPosition);

    // Calculate packet counts from traceline data
    final preShotCount =
        completeTraceline.where((p) => p.phase == TracePhase.preShot).length;
    final shotCount =
        completeTraceline.where((p) => p.phase == TracePhase.shot).length;
    final postShotCount =
        completeTraceline.where((p) => p.phase == TracePhase.postShot).length;

    // Create complete steadiness shot data
    final steadinessShotData = SteadinessShotData(
      shotNumber: _shotCount,
      timestamp: now,
      position: shotPosition,
      score: score,
      thetaDot: thetaDot,
      accuracy: accuracy,
      tracelinePoints: completeTraceline,
      metrics: {
        'distance': _getDistancePreset()['distance'],
        'difficulty': _difficulty,
        'gateValue': _gateValue,
        'linearWobble': _calculateCurrentLinearWobble(),
        'status': 'complete',
        'preShotPackets': preShotCount,
        'shotPackets': shotCount,
        'postShotPackets': postShotCount,
        'totalTracelinePackets': completeTraceline.length,
      },
      analysisNotes:
          'Complete traceline: $preShotCount pre-shot + $shotCount shot + $postShotCount post-shot packets',
    );

    // Store in TrainingSessionBloc (update existing shot data)
    context
        .read<TrainingSessionBloc>()
        .add(AddSteadinessShot(steadinessShotData));

    print(
        '🎯 Updated shot data for shot $_shotCount with complete traceline (${completeTraceline.length} points)');

    // ✅ NEW: Check if this was the last shot
    if (_shotCount >= _currentProgram.noOfShots!.toInt()) {
      setState(() {
        _waitingForLastShotTrace = true;
      });
      print("✅ Waiting for last shot trace is now TRUE");
    }
  }
// ✅ New variable to track shotDetectedTime
  static DateTime? shotDetectedTime;
  static bool wasShotDetected = false;
  // ✅ SIMPLIFIED: Process sensor data without shot cycle management

  void _resetPostShotMode() {
    _isInPostShotMode = false;
    _postShotStartIndex = 0;
  }
  void _processSensorData(StreamingModel streamingModel) {
    if (!_isTraining) return;

    final now = DateTime.now();
    final dt = 0.016;

    final yaw = streamingModel.yaw;
    final pitch = streamingModel.pitch;
    final roll = streamingModel.roll;

    final w = math.sqrt(yaw * yaw + pitch * pitch + roll * roll);
    final dtheta = w * dt;
    _thetaInstDeg = dtheta;

    _recentSway.add(_thetaInstDeg);
    final cutoffTime = now.millisecondsSinceEpoch - 4000;
    _recentSway.removeWhere((r) => r < cutoffTime);

    _updateAdaptiveScaling();
    _checkGoalAchievement(now);

    final yawRate = yaw;
    final pitchRate = pitch;
    final angleTarget = math.atan2(-pitchRate, yawRate);

    final easeSlider = _easing;
    final angAlpha = 1 -
        math.exp(-dt /
            math.max(0.01, ANG_SMOOTH_TAU * (1 + (0.5 - easeSlider) * 1.5)));
    _lastAngle = _emaAngle(_lastAngle, angleTarget, angAlpha);

    _readings.add({'ts': now.millisecondsSinceEpoch, 'theta': _thetaInstDeg});
    final cutoff = now.millisecondsSinceEpoch - 500;
    _readings.removeWhere((r) => r['ts'] < cutoff);

    final tableRest = (_thetaInstDeg < TABLE_REST_DEG) && !_isResetting;
    final steadyNow = (_thetaInstDeg <= HOLD_STABLE_DEG) && !_isResetting;

    final wasVisible = _visGate;

    // Visibility logic
    if (!_visGate) {
      if (!tableRest && _thetaInstDeg <= _showUnderDeg) {
        if (_visGateTS == null ||
            now.difference(_visGateTS!).inMilliseconds > HYSTERESIS_DWELL_MS) {
          setState(() {
            _visGate = true;
          });
        }
      } else {
        _visGateTS = now;
      }
    } else {
      if (tableRest || _thetaInstDeg >= _hideOverDeg) {
        if (_visGateTS == null ||
            now.difference(_visGateTS!).inMilliseconds > HYSTERESIS_DWELL_MS) {
          setState(() {
            _visGate = false;
          });
        }
      } else {
        _visGateTS = now;
      }
    }

    if (streamingModel.shotDetected) {
      // Shot detected: record the first time
      if (!wasShotDetected) {
        shotDetectedTime = now;
        wasShotDetected = true;
        print("working");
      }
      // While shotDetected == true => skip clearing/resetting code
    }
    else if (shotDetectedTime!=null &&(now.millisecondsSinceEpoch - shotDetectedTime!.millisecondsSinceEpoch <= 1000) ){
    }
    else {
      if (wasShotDetected) {
        // Shot just turned FALSE for the first time
        wasShotDetected = false;
        print("working 2");

        // Run the skipped reset/clear code here
        if (!_visGate || _isResetting) {
          _tracePoints.clear();
          _readings.clear();
          _lastShotPosition = null;
          _tracelineBuffer.clear();

          // ✅ NEW: Reset post-shot mode when traceline clears
          _resetPostShotMode();

          setState(() {});
        }
        else {
          if (!wasVisible && _visGate) {
            _lastDrawX = 200.0;
            _lastDrawY = 200.0;
            _rViz = 0.0;
            _tracePoints.clear();
            _lastAngle = angleTarget;
            _tracePoints.add(const Offset(200.0, 200.0));
            _lastTraceX = 200.0;
            _lastTraceY = 200.0;

            // ✅ NEW: Reset post-shot mode when traceline clears (recenter case)
            _resetPostShotMode();

            setState(() {});
            return;
          }
        }
      }
      else {
        // ✅ Normal case: no shot detected, original logic works
        if (!_visGate || _isResetting) {
          _tracePoints.clear();
          _readings.clear();
          _lastShotPosition = null;
          _tracelineBuffer.clear();

          // ✅ NEW: Reset post-shot mode when traceline clears
          _resetPostShotMode();

          setState(() {});
        } else {
          if (!wasVisible && _visGate) {
            _lastDrawX = 200.0;
            _lastDrawY = 200.0;
            _rViz = 0.0;
            _tracePoints.clear();
            _lastAngle = angleTarget;
            _tracePoints.add(const Offset(200.0, 200.0));
            _lastTraceX = 200.0;
            _lastTraceY = 200.0;

            // ✅ NEW: Reset post-shot mode when traceline clears (recenter case)
            _resetPostShotMode();

            setState(() {});
            return;
          }
        }
      }
    }

    // ✅ Continue with normal position/traceline update logic
    final newPosition =
    _calculateDistanceAwarePosition(_thetaInstDeg, _lastAngle);
    final radAlpha = 1 - math.exp(-dt / math.max(0.01, RAD_SMOOTH_TAU));
    _lastDrawX = _lastDrawX + (newPosition.dx - _lastDrawX) * radAlpha;
    _lastDrawY = _lastDrawY + (newPosition.dy - _lastDrawY) * radAlpha;

    // ✅ SIMPLIFIED: Just update visual traceline and position tracking
    final preset = _getDistancePreset();
    final distance = preset['distance'] as double;
    final movementThreshold = 2.0 + (distance - 7.0) * 0.1;
    final moveDistance = math.sqrt(math.pow(_lastDrawX - _lastTraceX, 2) +
        math.pow(_lastDrawY - _lastTraceY, 2));

    _lastShotPosition = Offset(_lastDrawX, _lastDrawY);

    if (moveDistance >= movementThreshold) {
      final maxPts = _traceLength.toInt();
      _tracePoints.add(Offset(_lastDrawX, _lastDrawY));
      _lastTraceX = _lastDrawX;
      _lastTraceY = _lastDrawY;

      // ✅ SIMPLIFIED: Add to traceline buffer for shot capture
      _addToTracelineBuffer(
          Offset(_lastDrawX, _lastDrawY), TracePhase.preShot);
    }

    setState(() {});

    _updateSteadyHold(steadyNow, now);
  }


  void _showScoreToast(int score, double thetaDot) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Score: $score • θ: ${thetaDot.toStringAsFixed(2)}°'),
        duration: const Duration(seconds: 2),
        backgroundColor: score >= 8
            ? Colors.green
            : score >= 6
                ? Colors.orange
                : Colors.red,
      ),
    );
  }

  void _showDifficultyToast(String difficulty) {
    final difficultyMap = {
      'pro': 'Pro',
      'adv': 'Advanced',
      'int': 'Intermediate',
      'nov': 'Novice',
      'beg': 'Beginner',
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Difficulty: ${difficultyMap[difficulty] ?? 'Pro'}'),
        duration: const Duration(seconds: 1),
        backgroundColor: const Color(0xFF5EA1FF),
      ),
    );
  }

  void _showGateValueToast(double gateValue) {
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(
    //     content: Text('Gate Value: ${gateValue.toStringAsFixed(1)}°'),
    //     duration: const Duration(seconds: 1),
    //     backgroundColor: const Color(0xFF34D399),
    //   ),
    // );
  }

  // Show distance preset toast
  void _showDistanceToast(String distance) {
    final preset = _distancePresets[distance]!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${preset['name']}: Distance ${preset['distance']}m • Linear Tolerance ${preset['linearTolerance']}mm',
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF5EA1FF),
      ),
    );
  }

  // ✅ SIMPLIFIED: Reset method without shot cycle state
  void _resetTrace() {
    setState(() {
      _shotLog.clear();
      _shotCount = 0;
      _tracePoints.clear();
      _readings.clear();
      _rViz = 0.0;
      _lastDrawX = 200.0;
      _lastDrawY = 200.0;
      _visGate = false;
      _holdStart = null;
      _currentCant = 0.0;

      // ✅ ONLY UI STATE RESET
      _goalHoldsAchieved = 0;
      _goalHoldStart = null;
      _showingGoalBadge = false;
      _currentScale = _scaleAbs;
      _gainBadge = 1.0;
      _recentSway.clear();
      _shotMarkers.clear();
      _lastShotPosition = null;
      _tracelineBuffer.clear();
      _lastTraceX = 200.0;
      _lastTraceY = 200.0;
    });
    _recomputeScoreRadii();
  }

  String _getMovementStatus() {
    if (_thetaInstDeg < TABLE_REST_DEG) return "Resting";
    if (_thetaInstDeg >= _hideOverDeg) return "Too Wobbly"; // NOW DYNAMIC
    if (!_visGate) return "Hidden";
    return "Moving";
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "Moving":
        return Colors.green;
      case "Resting":
        return Colors.blue;
      case "Hidden":
        return Colors.grey;
      case "Too Wobbly":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getSteadyHoldText() {
    if (_holdStart == null) return "0 ms";
    final held = DateTime.now().difference(_holdStart!).inMilliseconds;
    return "$held ms";
  }

  // Update adaptive scaling for distance-aware linear system
  void _updateAdaptiveScaling() {
    final now = DateTime.now();
    if (_lastScaleUpdate != null &&
        now.difference(_lastScaleUpdate!).inMilliseconds < 400) {
      return; // Update every ~400ms
    }

    if (_recentSway.length < 10) return; // Need enough data

    // Calculate P95 of recent sway (4-second window)
    final sortedSway = List<double>.from(_recentSway);
    sortedSway.sort();
    final p95Index = (sortedSway.length * 0.95).floor();
    final sway = sortedSway[p95Index];

    // Calculate effective sway (minimum 0.15° to prevent division by zero)
    final swayEff = math.max(sway, 0.15);

    // Distance-aware scaling - same angular motion = larger trace at longer distance
    final preset = _getDistancePreset();
    final distance = preset['distance'] as double;

    // Convert angular motion to linear trace: W(t) = D * θ(t)
    // At 25m, same θ produces 3.6x larger trace than at 7m
    final linearTrace =
        distance * swayEff * (math.pi / 180); // Convert to radians

    // Target scale: keep trace visible but don't exceed safe limits
    final target = math.min(0.92 * 190.0 / linearTrace, 1.25 * _scaleAbs);

    // Smooth interpolation with limits
    final alpha = 0.08; // Slow adaptation
    _currentScale = _currentScale + (target - _currentScale) * alpha;

    // Clamp to safe limits: 0.85× to 1.25× of truth scale
    _currentScale = _currentScale.clamp(0.85 * _scaleAbs, 1.25 * _scaleAbs);

    // Calculate gain badge
    _gainBadge = _currentScale / _scaleAbs;

    _lastScaleUpdate = now;
  }

  // Get current distance preset
  Map<String, dynamic> _getDistancePreset() {
    return _distancePresets[_selectedDistance]!;
  }

  String _selectedAngleRange = 'default'; // Default angle range
  final Map<String, Map<String, dynamic>> _angleRangePresets = {
    'default': {
      'name': 'Default',
      'multiplier': 1.0,
      'description': 'Current sensitivity',
    },
    '10deg': {
      'name': '10 Degrees',
      'multiplier': 4.0, // 10/4.5 = 2.22
      'description': 'Less sensitive',
    },
    '20deg': {
      'name': '20 Degrees',
      'multiplier': 8.0, // 20/4.5 = 4.44
      'description': 'Low sensitivity',
    },
    '45deg': {
      'name': '45 Degrees',
      'multiplier': 18.0, // 45/4.5 = 10
      'description': 'Much less sensitive',
    },
    '90deg': {
      'name': '90 Degrees',
      'multiplier': 36.0, // 90/4.5 = 20
      'description': 'Least sensitive',
    },
    '100deg': {
      'name': '100 Degrees',
      'multiplier': 40.0, // 90/4.5 = 20
      'description': 'Least sensitive',
    },
    '200deg': {
      'name': '200 Degrees',
      'multiplier': 80.0, // 90/4.5 = 20
      'description': 'Least sensitive',
    },
    '300deg': {
      'name': '300 Degrees',
      'multiplier': 120.0, // 90/4.5 = 20
      'description': 'Least sensitive',
    },
  };
  // Balanced gate values - not too restrictive
  double get _visualRing5Deg {
    // Keep gate values reasonable across all distances
    // Only slight adjustment, not drastic inverse scaling
    final preset = _getDistancePreset();
    final distance = preset['distance'] as double;

    // Gentle adjustment: 7m = 1.0x, 10m = 0.9x, 15m = 0.8x, 25m = 0.7x
    final distanceAdjustment = math.max(0.7, 1.0 - ((distance - 7.0) * 0.05));
    final adjustedGateValue = _gateValue * distanceAdjustment;

    // Apply angle range multiplier
    final anglePreset = _angleRangePresets[_selectedAngleRange]!;
    final multiplier = anglePreset['multiplier'] as double;

    return (adjustedGateValue * math.pi / 180) * multiplier;
  }

  double get _hideOverDeg {
    // Only slight increase in hiding threshold
    return _visualRing5Deg * 1.05;
  }

  double get _showUnderDeg {
    // Only slight decrease in showing threshold
    return _visualRing5Deg * 0.95;
  }

// Better distance-aware positioning with proper sensitivity
  Offset _calculateDistanceAwarePosition(double thetaInstDeg, double angle) {
    final preset = _getDistancePreset();
    final distance = preset['distance'] as double;

    // More responsive scaling for visual feedback
    final normalizedTheta = (thetaInstDeg / _visualRing5Deg).clamp(0.0, 1.0);
    final baseRadius = normalizedTheta * _ringRadii[5]!;

    // Enhanced exponential scaling for better visual response
    // 7m = 1.0x, 10m = 1.5x, 15m = 2.2x, 25m = 3.8x
    final distanceMultiplier =
        math.pow(distance / 7.0, 1.4); // More aggressive scaling
    final scaledRadius = baseRadius * distanceMultiplier;

    final newX = 200 + scaledRadius * math.cos(angle);
    final newY = 200 + scaledRadius * math.sin(angle);

    return Offset(newX, newY);
  }

  // Build fixed linear ring with label - same visual size for all distances
  Widget _buildFixedLinearRing(double sizePercentage, double millimeters) {
    // Show all linear rings regardless of distance (they stay the same size)

    return Stack(
      children: [
        // More prominent ring with thicker border
        FractionallySizedBox(
          widthFactor: sizePercentage,
          heightFactor: sizePercentage,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _getLinearRingColor(millimeters),
                width: 2.5, // Increased from 1.5 to 2.5
              ),
            ),
          ),
        ),
        // Linear label with better positioning and visibility
        Positioned(
          left: 200 + (sizePercentage * 190 * 0.85) - 20,
          top: 200 - (sizePercentage * 190 * 0.85) - 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF0B1220).withOpacity(0.95),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _getLinearRingColor(millimeters),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Text(
              '${millimeters.toStringAsFixed(0)}mm',
              style: TextStyle(
                color: _getLinearRingColor(millimeters),
                fontSize: 11, // Increased from 9 to 11
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Get linear ring color based on millimeters
  Color _getLinearRingColor(double millimeters) {
    if (millimeters <= 5.0)
      return const Color(0xFF34D399); // Green for 5mm (easy)
    if (millimeters <= 10.0)
      return const Color(0xFFF59E0B); // Orange for 10mm (medium)
    if (millimeters <= 20.0)
      return const Color(0xFFEF4444); // Red for 20mm (hard)
    return const Color(0xFF6B7280); // Gray for beyond 20mm
  }

  // Build gain badge
  Widget _buildGainBadge() {
    return Positioned(
      top: 16,
      left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2332).withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _gainBadge > 1.0
                ? const Color(0xFF34D399)
                : const Color(0xFFF59E0B),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _gainBadge > 1.0 ? Icons.zoom_in : Icons.zoom_out,
              color: _gainBadge > 1.0
                  ? const Color(0xFF34D399)
                  : const Color(0xFFF59E0B),
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              '×${_gainBadge.toStringAsFixed(1)}',
              style: TextStyle(
                color: _gainBadge > 1.0
                    ? const Color(0xFF34D399)
                    : const Color(0xFFF59E0B),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Check goal achievement based on linear tolerance
  void _checkGoalAchievement(DateTime now) {
    final preset = _getDistancePreset();
    final linearTolerance = preset['linearTolerance'] as double;
    final distance = preset['distance'] as double;

    // Convert current angular sway to linear wobble: W = D * θ
    final currentLinearWobble = distance * _thetaInstDeg * (math.pi / 180);

    // Check if current linear wobble is within tolerance
    if (currentLinearWobble <= linearTolerance) {
      if (_goalHoldStart == null) {
        _goalHoldStart = now;
      } else {
        final held = now.difference(_goalHoldStart!).inMilliseconds;
        if (held >= 1000) {
          // 1 second hold required
          // Goal achieved!
          _goalHoldsAchieved++;
          _goalHoldStart = null;

          // Show achievement badge
          // if (_goalHoldsAchieved >= _goalHoldsRequired) {
          //   _showGoalAchievementBadge();
          // } else {
          //   _showGoalHoldToast();
          // }
        }
      }
    } else {
      _goalHoldStart = null;
    }
  }

  // Show goal hold toast based on linear tolerance
  void _showGoalHoldToast() {
    final preset = _getDistancePreset();
    final linearTolerance = preset['linearTolerance'] as double;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Goal Hold! ≤${linearTolerance}mm for 1s • $_goalHoldsAchieved/$_goalHoldsRequired',
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF34D399),
      ),
    );
  }

  // Show goal achievement badge
  void _showGoalAchievementBadge() {
    setState(() {
      _showingGoalBadge = true;
    });

    // Auto-hide after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showingGoalBadge = false;
        });
      }
    });
  }

  // Build goal achievement badge
  Widget _buildGoalAchievementBadge() {
    return Positioned(
      top: 80,
      left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF34D399).withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF10B981), width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF34D399).withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              'GOAL ACHIEVED!',
              style: const TextStyle(
                color: Color(0xFF10B981),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build current degree display overlay
  Widget _buildCurrentDegreeDisplay() {
    return Positioned(
      bottom: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2332).withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2A3A64), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Current θ',
              style: const TextStyle(
                color: Color(0xFF9FB0D4),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_thetaInstDeg.toStringAsFixed(3)}°',
              style: TextStyle(
                color: _getMovementStatus() == "Resting"
                    ? const Color(0xFF34D399)
                    : _getMovementStatus() == "Moving"
                        ? const Color(0xFF5EA1FF)
                        : const Color(0xFFEF4444),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Linear: ${((_getDistancePreset()['distance'] as double) * _thetaInstDeg * (math.pi / 180)).toStringAsFixed(1)}mm',
              style: const TextStyle(color: Color(0xFF8EA6D6), fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  // Build distance and angle info cards above Start Training button
  Widget _buildDistanceAngleInfoCards() {
    final preset = _getDistancePreset();
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF111A2B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1A2440), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.straighten,
                      color: Color(0xFF5EA1FF),
                      size: 15,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Training Distance',
                      style: const TextStyle(
                        color: Color(0xFFE6EEFC),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  preset['name'] as String,
                  style: const TextStyle(
                    color: Color(0xFF5EA1FF),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  preset['description'] as String,
                  style: const TextStyle(
                    color: Color(0xFFA8B3C7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Build program information header
  Widget _buildProgramInfoHeader() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(255, 76, 57, 54),
            Color.fromARGB(255, 56, 16, 12)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            _currentProgram.programName ?? 'Steadiness Training',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _currentProgram.programDescription ??
                'Improve your shooting steadiness',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Build connection status
  Widget _buildConnectionStatus(bool isConnected) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isConnected
              ? [const Color(0xFF28A745), const Color(0xFF218838)]
              : [const Color(0xFFDC3545), const Color(0xFFC82333)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Text(
        isConnected ? "RT Sensor Connected" : "RT Sensor Not Connected",
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // Build enhanced controls (without session time - moved to status card)
  Widget _buildEnhancedControls(TrainingSessionState sessionState) {
    return Row(
      children: [
        if (!_isTraining)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _startTraining,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Training'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF34D399),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        if (_isTraining) ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _stopTraining,
              icon: const Icon(Icons.stop),
              label: const Text('Stop'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: _resetTrace,
          icon: const Icon(Icons.refresh),
          label: const Text('Reset'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: const Color(0xFFE6EEFC),
            side: const BorderSide(color: Color(0xFF2A3A64)),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  // Build enhanced status card
  Widget _buildEnhancedStatusCard(TrainingSessionState sessionState) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111A2B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1A2440), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  'Shots',
                  '$_shotCount/${_currentProgram.noOfShots}',
                  Icons.gps_fixed,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricItem(
                  'Time',
                  _formatDuration(DateTime.now().difference(
                      sessionState.sessionStartTime ?? DateTime.now())),
                  Icons.timer,
                  valueColor: _isTraining
                      ? const Color(0xFF5EA1FF)
                      : const Color(0xFFA8B3C7),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricItem(
                  'Distance',
                  '$_selectedDistance m',
                  Icons.straighten,
                  valueColor: _isTraining
                      ? const Color(0xFF5EA1FF)
                      : const Color(0xFFA8B3C7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Format duration helper method
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  // Build session timer widget (always visible and continuously updating)
  Widget _buildSessionTimer(TrainingSessionState sessionState) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A2332), Color(0xFF0F1830)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A3A64), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF5EA1FF).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.timer,
              color: Color(0xFF5EA1FF),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            children: [
              Text(
                'Session Time',
                style: const TextStyle(
                  color: Color(0xFFA8B3C7),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDuration(
                    DateTime.now().difference(sessionState.sessionStartTime!)),
                style: const TextStyle(
                  color: Color(0xFFE6EEFC),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Start continuous session timer updates
  void _startSessionTimer() {
    _stopSessionTimer(); // Stop any existing timer
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _isTraining) {
        setState(() {
          // This will trigger a rebuild and update the timer display
        });
      } else {
        _stopSessionTimer();
      }
    });
  }

  // Stop session timer updates
  void _stopSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111A2B),
        foregroundColor: const Color(0xFFE6EEFC),
        title: const Text('Steadiness Trainer'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              String? sensPerms = prefs?.getString(sensitivityKey);

              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => SettingViewPage(
                          sensPerms: sensPerms?.split('/') ??
                              ['5', '3', '3', '3', '3', '3'])));
            },
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: BlocConsumer<BleScanBloc, BleScanState>(
        listener: (context, bleState) {
          if (!bleState.isConnected) {
            _showConnectionDialog();
          }
        },
        builder: (context, bleState) {
          return BlocConsumer<TrainingSessionBloc, TrainingSessionState>(
            listener: (context, sessionState) {
              // Navigate to session detail page only once when session is completed
              if (!_hasNavigatedToSessionDetail && _waitingForLastShotTrace) {
                _waitingForLastShotTrace = false;
                _hasNavigatedToSessionDetail = true;
                context
                    .read<TrainingSessionBloc>()
                    .add(DisableSensors(device: sessionState.device!));
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ManticXAnalysisPage()));
              }

              // ✅ SIMPLIFIED: Only process sensor data without shot cycle management
              if (sessionState.sensorStream != null) {
                _processSensorData(sessionState.sensorStream!);
              }

              // UI level shot edge detection
              final currentShotDetected =
                  sessionState.sensorStream?.shotDetected == true;
              final shotEdgeUI = !_lastShotDetectedUI && currentShotDetected;
              _lastShotDetectedUI = currentShotDetected;

              // ✅ ADD CONDITION: Only detect shot if traceline is visible AND enough pre-shot data
              if (shotEdgeUI && _visGate && _tracelineBuffer.length > 50) {
                print(
                    'Shot edge detected in UI! Buffer: ${_tracelineBuffer.length}, Visible: $_visGate');
                _addShotMarker();
              }
            },
            builder: (context, sessionState) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Program Information Header
                    _buildProgramInfoHeader(),
                    const SizedBox(height: 16),

                    // Connection Status
                    if (!bleState.isConnected)
                      _buildConnectionStatus(bleState.isConnected),
                    if (!bleState.isConnected) const SizedBox(height: 16),

                    // Session Timer (always visible when training)
                    _buildEnhancedStatusCard(sessionState),
                    const SizedBox(height: 16),
                    // Target Display
                    _buildTargetDisplay(),

                    const SizedBox(height: 16),

                    // Controls with session time
                    _buildEnhancedControls(sessionState),
                    const SizedBox(height: 16),

                    // Distance Preset Selector
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Training Distance',
                          style: const TextStyle(
                              color: Color(0xFFA8B3C7), fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F1830),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: const Color(0xFF1A2440), width: 1),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedDistance,
                              isExpanded: true,
                              dropdownColor: const Color(0xFF0F1830),
                              style: const TextStyle(
                                color: Color(0xFFE6EEFC),
                                fontSize: 14,
                              ),
                              items: _distancePresets.entries.map((entry) {
                                final key = entry.key;
                                final preset = entry.value;
                                return DropdownMenuItem(
                                  value: key,
                                  child: Text(
                                    '${preset['name']} - ${preset['description']}',
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  _updateDistancePreset(newValue);
                                  _showDistanceToast(newValue);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
// Angle Range Selector
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Angle Range to Outer Ring',
                          style: const TextStyle(
                              color: Color(0xFFA8B3C7), fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F1830),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: const Color(0xFF1A2440), width: 1),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedAngleRange,
                              isExpanded: true,
                              dropdownColor: const Color(0xFF0F1830),
                              style: const TextStyle(
                                  color: Color(0xFFE6EEFC), fontSize: 14),
                              items: _angleRangePresets.entries.map((entry) {
                                final key = entry.key;
                                final preset = entry.value;
                                return DropdownMenuItem(
                                  value: key,
                                  child: Text(
                                      '${preset['name']} - ${preset['description']}'),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _selectedAngleRange = newValue;
                                  });
                                  // _showAngleRangeToast(newValue);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Shot Log
                    _buildShotLog(),

                    // Help Section
                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ✅ FIXED: _buildTargetDisplay method with shot markers separate render
  Widget _buildTargetDisplay() {
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.44,
      decoration: BoxDecoration(
        color: const Color(0xFF0E1629),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E2A44), width: 2),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final containerWidth = constraints.maxWidth;
          final containerHeight = constraints.maxHeight;
          final actualCenterX = containerWidth / 2;
          final actualCenterY = containerHeight / 2;

          return Stack(
            alignment: Alignment.center,
            children: [
              // Crosshair
              CustomPaint(
                painter: CrosshairPainter(),
                size: Size(containerWidth, containerHeight),
              ),

              // Center reference ring (0.0° - perfect center)
              Positioned(
                left: actualCenterX - 4,
                top: actualCenterY - 4,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF34D399),
                    border:
                        Border.all(color: const Color(0xFF10B981), width: 2),
                  ),
                ),
              ),

              // Target Rings
              _buildTargetRing(
                  0.1, AppColors.kRedColor, AppColors.kRedColor), // Ring 10
              _buildTargetRing(0.3, AppColors.kRedColor), // Ring 9
              _buildTargetRing(0.48, AppColors.kRedColor), // Ring 8
              _buildTargetRing(0.65, AppColors.kRedColor), // Ring 7
              _buildTargetRing(0.83, AppColors.kRedColor),
              _buildTargetRing(1, AppColors.kRedColor), // Ring 6

              if (_gainBadge != 1.0 && _gainBadge != 0.0) _buildGainBadge(),

              if (_showingGoalBadge) _buildGoalAchievementBadge(),

              // Traceline path - only show when conditions are met
              if (_tracePoints.isNotEmpty &&
                  _visGate &&
                  _thetaInstDeg < _hideOverDeg)
                CustomPaint(
                  painter: TracelinePainter(
                    _tracePoints,
                    containerWidth,
                    containerHeight,
                    [], // EMPTY shot markers for traceline (rendered separately)
                    _isInPostShotMode, // Pass post-shot mode flag
                    _postShotStartIndex, // Pass post-shot start index
                  ),
                  size: Size(containerWidth, containerHeight),
                ),

              // Shot markers rendered separately (always visible)
              if (_shotMarkers.isNotEmpty)
                CustomPaint(
                  painter: ShotMarkersPainter(
                    _shotMarkers,
                    containerWidth,
                    containerHeight,
                  ),
                  size: Size(containerWidth, containerHeight),
                ),

              // Moving dot
              if (_visGate && !_isResetting)
                Positioned(
                  left: _convertToDisplayX(_lastDrawX, containerWidth) - 4.5,
                  top: _convertToDisplayY(_lastDrawY, containerHeight) - 4.5,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: const Color(0xFF9BC1FF),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFCFE0FF),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFF79A9FF).withValues(alpha: 0.35),
                          blurRadius: 14,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

// Coordinate conversion functions
  double _convertToDisplayX(double internalX, double containerWidth) {
    // Convert from internal 400x400 system to actual container size
    return (internalX / 400.0) * containerWidth;
  }

  double _convertToDisplayY(double internalY, double containerHeight) {
    // Convert from internal 400x400 system to actual container size
    return (internalY / 400.0) * containerHeight;
  }

// Fixed linear ring with proper positioning
  Widget _buildFixedLinearRingPositioned(
    double centerX,
    double centerY,
    double radius,
    double millimeters,
  ) {
    return Positioned(
      left: centerX - radius,
      top: centerY - radius,
      child: Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: _getLinearRingColor(millimeters),
            width: 2.5,
          ),
        ),
      ),
    );
  }

  Widget _buildTargetRing(
    double sizePercentage,
    Color borderColor, [
    Color? fillColor,
  ]) {
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

  Widget _buildControls() {
    return Row(
      children: [
        if (!_isTraining)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _startTraining,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Training'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF34D399),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        if (_isTraining) ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _takeShot,
              icon: const Icon(Icons.gps_fixed),
              label: const Text('Shot'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5EA1FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _stopTraining,
              icon: const Icon(Icons.stop),
              label: const Text('Stop'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: _resetTrace,
          icon: const Icon(Icons.refresh),
          label: const Text('Reset'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: const Color(0xFFE6EEFC),
            side: const BorderSide(color: Color(0xFF2A3A64)),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricItem(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1830),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF1A2440), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF93A4C7), size: 20),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF93A4C7), fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? const Color(0xFFE6EEFC),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildShotLog() {
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF111A2B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1A2440), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Shot Log',
            style: TextStyle(
              color: const Color(0xFFE6EEFC),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (_shotLog.isEmpty)
            Text('No shots recorded yet',
                style: TextStyle(color: const Color(0xFFA8B3C7), fontSize: 14))
          else
            Column(
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Time',
                        style: TextStyle(
                          color: const Color(0xFF9FB0D4),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'θ (deg)',
                        style: TextStyle(
                          color: const Color(0xFF9FB0D4),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        'Score',
                        style: TextStyle(
                          color: const Color(0xFF9FB0D4),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Shot entries
                ..._shotLog.take(10).map((shot) {
                  final time = shot['time'] as DateTime;
                  final theta = shot['theta'] as double;
                  final score = shot['score'] as int;

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 0,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: const Color(0xFF1A2440),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              color: Color(0xFFE6EEFC),
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            theta.isNaN ? '—' : '${theta.toStringAsFixed(2)}°',
                            style: const TextStyle(
                              color: Color(0xFFE6EEFC),
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getScoreColor(score).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              score.toString(),
                              style: TextStyle(
                                color: _getScoreColor(score),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
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

  Color _getScoreColor(int score) {
    if (score >= 9) return const Color(0xFF34D399);
    if (score >= 7) return const Color(0xFFF59E0B);
    if (score >= 5) return const Color(0xFFEF4444);
    return const Color(0xFF6B7280);
  }

  Widget _buildSettingsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111A2B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1A2440), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: TextStyle(
              color: const Color(0xFFE6EEFC),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trace Length: ${_traceLength.toInt()}',
                      style: const TextStyle(
                        color: Color(0xFFA8B3C7),
                        fontSize: 12,
                      ),
                    ),
                    Slider(
                      value: _traceLength,
                      min: 20,
                      max: 400,
                      divisions: 38,
                      onChanged: (value) {
                        setState(() {
                          _traceLength = value;
                        });
                      },
                      activeColor: const Color(0xFF5EA1FF),
                      inactiveColor: const Color(0xFF1A2440),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dot Easing: ${_easing.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Color(0xFFA8B3C7),
                        fontSize: 12,
                      ),
                    ),
                    Slider(
                      value: _easing,
                      min: 0.0,
                      max: 0.5,
                      divisions: 50,
                      onChanged: (value) {
                        setState(() {
                          _easing = value;
                        });
                      },
                      activeColor: const Color(0xFF5EA1FF),
                      inactiveColor: const Color(0xFF1A2440),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Difficulty Selector
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Difficulty',
                style: const TextStyle(color: Color(0xFFA8B3C7), fontSize: 12),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1830),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF1A2440), width: 1),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _difficulty,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF0F1830),
                    style: const TextStyle(
                      color: Color(0xFFE6EEFC),
                      fontSize: 14,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'pro',
                        child: Text('Pro (Extreme)'),
                      ),
                      DropdownMenuItem(
                        value: 'adv',
                        child: Text('Advanced (Very Hard)'),
                      ),
                      DropdownMenuItem(
                        value: 'int',
                        child: Text('Intermediate (Not Easy)'),
                      ),
                      DropdownMenuItem(
                        value: 'nov',
                        child: Text('Novice (Easy)'),
                      ),
                      DropdownMenuItem(
                        value: 'beg',
                        child: Text('Beginner (Very Easy)'),
                      ),
                    ],
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _difficulty = newValue;
                        });
                        _recomputeScoreRadii();
                        _showDifficultyToast(newValue);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B2A48),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '10-ring leniency scales up with level',
                  style: const TextStyle(
                    color: Color(0xFF8EA6D6),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          const SizedBox(height: 16),
          // Gate Value Selector
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gate Value: ${_gateValue.toStringAsFixed(1)}°',
                style: const TextStyle(color: Color(0xFFA8B3C7), fontSize: 12),
              ),
              const SizedBox(height: 8),
              Slider(
                value: _gateValue,
                min: 0.5,
                max: 90.0,
                divisions: 179, // 0.5 step increments
                onChanged: (value) {
                  setState(() {
                    _gateValue = value;
                  });
                  _showGateValueToast(value);
                },
                activeColor: const Color(0xFF34D399),
                inactiveColor: const Color(0xFF1A2440),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B4832),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Maximum angle for traceline visibility',
                  style: const TextStyle(
                    color: Color(0xFF8ED6B2),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _updateSteadyHold(bool steady, DateTime now) {
    if (steady) {
      _holdStart ??= now;
      final held = now.difference(_holdStart!).inMilliseconds;
      if (held >= HOLD_TIME_MS) {
        //_startCenterReset();
        _holdStart = null;
      }
    } else {
      _holdStart = null;
    }
  }

  void _startCenterReset() {
    if (_isResetting) return;

    setState(() {
      _isResetting = true;
    });

    // Quick glide to center WITHOUT drawing path (matching HTML exactly)
    final startX = _lastDrawX;
    final startY = _lastDrawY;
    const dur = 200; // ms
    final t0 = DateTime.now().millisecondsSinceEpoch;

    void step() {
      final now = DateTime.now().millisecondsSinceEpoch;
      final u = ((now - t0) / dur).clamp(0.0, 1.0);
      final e = 1 - math.pow(1 - u, 3.0); // ease-out cubic

      setState(() {
        _lastDrawX = startX + (200 - startX) * e;
        _lastDrawY = startY + (200 - startY) * e;
      });

      if (u < 1) {
        Future.delayed(const Duration(milliseconds: 16), step);
      } else {
        setState(() {
          _isResetting = false;
          // Leave dot at center but hidden; it will reappear when moving again
        });
      }
    }

    step();
  }

  double _emaAngle(double prev, double next, double alpha) {
    // Normalize to avoid wrap jumps (matching HTML exactly)
    const twoPi = math.pi * 2;
    double d = next - prev;
    if (d > math.pi)
      next -= twoPi;
    else if (d < -math.pi) next += twoPi;
    return prev + alpha * (next - prev);
  }

  void _showConnectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sensor Connection'),
        content: const Text('RT Sensor Disconnected'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}

// Shot marker data class for traceline
class ShotMarker {
  final Offset position;
  final DateTime timestamp;
  final double accuracy; // 0.0 to 1.0 (0.0 = perfect center, 1.0 = edge)

  ShotMarker({
    required this.position,
    required this.timestamp,
    required this.accuracy,
  });
}

// Modified TracelinePainter class - Replace this class in your code

class TracelinePainter extends CustomPainter {
  final List<Offset> points;
  final double containerWidth;
  final double containerHeight;
  final List<ShotMarker> shotMarkers;
  final bool isInPostShotMode; // Changed parameter
  final int postShotStartIndex; // Changed parameter

  TracelinePainter(
      this.points,
      this.containerWidth,
      this.containerHeight,
      this.shotMarkers,
      this.isInPostShotMode, // Changed parameter
      this.postShotStartIndex, // Changed parameter
      );

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    // Convert internal coordinates to display coordinates
    final offsetPoints = points
        .map(
          (point) => Offset(
        _convertInternalToDisplayX(point.dx, containerWidth),
        _convertInternalToDisplayY(point.dy, containerHeight),
      ),
    )
        .toList();

    // Draw line segments with appropriate colors
    for (int i = 0; i < offsetPoints.length - 1; i++) {
      final currentPoint = offsetPoints[i];
      final nextPoint = offsetPoints[i + 1];

      // Determine if this segment is post-shot based on index
      bool isPostShot = isInPostShotMode && i >= postShotStartIndex;

      // Choose paint color based on phase
      final linePaint = Paint()
        ..color = isPostShot ? const Color(0xFFEF4444) : const Color(0xFF7AA2FF) // Red for post-shot, blue for others
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      // Draw line segment
      canvas.drawLine(currentPoint, nextPoint, linePaint);
    }

    // Draw shot markers on traceline
    _drawShotMarkers(canvas, size);
  }

  // Draw shot markers on the traceline
  void _drawShotMarkers(Canvas canvas, Size size) {
    for (final marker in shotMarkers) {
      // Convert internal coordinates to display coordinates
      final displayX =
      _convertInternalToDisplayX(marker.position.dx, containerWidth);
      final displayY =
      _convertInternalToDisplayY(marker.position.dy, containerHeight);
      final displayPos = Offset(displayX, displayY);

      // Draw shot marker circle
      final markerPaint = Paint()
        ..color = _getShotMarkerColor(marker.accuracy)
        ..style = PaintingStyle.fill;

      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      // Draw marker (larger than traceline points)
      canvas.drawCircle(displayPos, 8, markerPaint);
      canvas.drawCircle(displayPos, 8, borderPaint);

      // Draw shot indicator (small cross or dot)
      final indicatorPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill
        ..strokeWidth = 1.0;

      // Draw small cross in center
      canvas.drawLine(
        Offset(displayPos.dx - 3, displayPos.dy),
        Offset(displayPos.dx + 3, displayPos.dy),
        indicatorPaint,
      );
      canvas.drawLine(
        Offset(displayPos.dx, displayPos.dy - 3),
        Offset(displayPos.dx, displayPos.dy + 3),
        indicatorPaint,
      );
    }
  }

  // Get shot marker color based on accuracy
  Color _getShotMarkerColor(double accuracy) {
    if (accuracy <= 0.2) return const Color(0xFF34D399); // Green - excellent
    if (accuracy <= 0.4) return const Color(0xFFF59E0B); // Orange - good
    if (accuracy <= 0.6) return const Color(0xFFEF4444); // Red - fair
    return const Color(0xFF6B7280); // Gray - poor
  }

  // Helper function to convert coordinates
  double _convertInternalToDisplayX(double internalX, double containerWidth) {
    return (internalX / 400.0) * containerWidth;
  }

  double _convertInternalToDisplayY(double internalY, double containerHeight) {
    return (internalY / 400.0) * containerHeight;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
// CrosshairPainter with dynamic sizing
class CrosshairPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E2A44)
      ..strokeWidth = 1.0;

    final center = Offset(size.width / 2, size.height / 2);

    // Horizontal line
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), paint);

    // Vertical line
    canvas.drawLine(
      Offset(center.dx, 0),
      Offset(center.dx, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Separate painter for shot markers only
class ShotMarkersPainter extends CustomPainter {
  final List<ShotMarker> shotMarkers;
  final double containerWidth;
  final double containerHeight;

  ShotMarkersPainter(
    this.shotMarkers,
    this.containerWidth,
    this.containerHeight,
  );

  @override
  void paint(Canvas canvas, Size size) {
    for (final marker in shotMarkers) {
      // Convert internal coordinates to display coordinates
      final displayX =
          _convertInternalToDisplayX(marker.position.dx, containerWidth);
      final displayY =
          _convertInternalToDisplayY(marker.position.dy, containerHeight);
      final displayPos = Offset(displayX, displayY);

      // Draw shot marker circle
      final markerPaint = Paint()
        ..color = _getShotMarkerColor(marker.accuracy)
        ..style = PaintingStyle.fill;

      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      // Draw marker (larger than traceline points)
      canvas.drawCircle(displayPos, 8, markerPaint);
      canvas.drawCircle(displayPos, 8, borderPaint);

      // Draw shot indicator (small cross or dot)
      final indicatorPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      // Draw small cross in center
      canvas.drawLine(
        Offset(displayPos.dx - 3, displayPos.dy),
        Offset(displayPos.dx + 3, displayPos.dy),
        indicatorPaint,
      );
      canvas.drawLine(
        Offset(displayPos.dx, displayPos.dy - 3),
        Offset(displayPos.dx, displayPos.dy + 3),
        indicatorPaint,
      );
    }
  }

  // Get shot marker color based on accuracy
  Color _getShotMarkerColor(double accuracy) {
    if (accuracy <= 0.2) return const Color(0xFF34D399); // Green - excellent
    if (accuracy <= 0.4) return const Color(0xFFF59E0B); // Orange - good
    if (accuracy <= 0.6) return const Color(0xFFEF4444); // Red - fair
    return const Color(0xFF6B7280); // Gray - poor
  }

  // Helper function to convert coordinates
  double _convertInternalToDisplayX(double internalX, double containerWidth) {
    return (internalX / 400.0) * containerWidth;
  }

  double _convertInternalToDisplayY(double internalY, double containerHeight) {
    return (internalY / 400.0) * containerHeight;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

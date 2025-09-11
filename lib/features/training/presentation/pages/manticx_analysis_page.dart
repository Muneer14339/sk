import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pulse_skadi/core/theme/app_colors.dart';
import 'package:pulse_skadi/features/training/presentation/bloc/training_session/training_session_bloc.dart';
import 'package:pulse_skadi/features/training/presentation/bloc/training_session/training_session_state.dart';
// import 'package:pulse_skadi/features/training/presentation/widgets/trace_painter.dart'; // Not needed - using custom AdvancedTracePainter
import 'package:pulse_skadi/features/training/data/model/streaming_model.dart'
    as streaming;
import 'dart:async';
import 'dart:math';

import '../widgets/trace_painter.dart';

/// ManticX-style Post-Session Analysis Page
/// Clean, focused implementation for shot analysis and traceline replay
class ManticXAnalysisPage extends StatefulWidget {
  const ManticXAnalysisPage({super.key});

  @override
  State<ManticXAnalysisPage> createState() => _ManticXAnalysisPageState();
}

class _ManticXAnalysisPageState extends State<ManticXAnalysisPage> {
  // Animation and playback controls
  Timer? _animationTimer;
  int _currentAnimatedPoints = 0;
  int _selectedShotNumber = -1;
  bool _isPlaying = false;
  bool _isPaused = false;

  // ✅ NEW: Advanced playback controls
  double _playbackSpeed = 1.0; // 0.5x, 1x, 2x, 4x
  // String _viewMode = 'standard'; // standard, zoomed, comparison
  // final int _selectedComparisonShot = -1; // Removed - not used

  // ✅ NEW: Traceline analysis data
  final Map<int, Map<String, dynamic>> _shotAnalysisData = {};
  List<streaming.TracePoint> _stabilityZonePoints = [];

  @override
  void dispose() {
    _animationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111A2B),
        foregroundColor: const Color(0xFFE6EEFC),
        title: const Text('Shot Analysis'),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocBuilder<TrainingSessionBloc, TrainingSessionState>(
        builder: (context, trainingState) {
          // Use sessionShotTraces (from BLE repository) if available, otherwise fallback to steadinessShots
          final shotTraces = trainingState.sessionShotTraces;
          final steadinessShots = trainingState.steadinessShots;

          // Debug print to see what data we have
          print(
              '🔍 ManticX Analysis: sessionShotTraces: ${shotTraces.length}, steadinessShots: ${steadinessShots.length}');

          if (shotTraces.isEmpty && steadinessShots.isEmpty) {
            return _buildNoShotsView();
          }

          // Use sessionShotTraces if available, otherwise convert steadinessShots
          final dataToUse = shotTraces.isNotEmpty
              ? shotTraces
              : _convertSteadinessShotsToShotTraces(steadinessShots);

          return ListView(
            children: [
              // Shot selection row
              _buildShotSelectionRow(dataToUse),
              const SizedBox(height: 20),
              _buildTargetDisplay(dataToUse),

              _buildShotDetailsPanel(dataToUse),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNoShotsView() {
    return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(
        Icons.track_changes,
        size: 80,
        color: Color(0xFFA8B3C7),
      ),
      const SizedBox(height: 20),
      const Text('No Shots Recorded',
          style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE6EEFC))),
      const SizedBox(height: 10),
      const Text('Complete a training session to view shot analysis',
          style: TextStyle(fontSize: 16, color: Color(0xFFA8B3C7)))
    ]));
  }

  Widget _buildShotSelectionRow(List<dynamic> shotTraces) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2332).withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A3A64), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Shot Analysis (${shotTraces.length} shots)',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE6EEFC),
                ),
              ),
              const Spacer(),
              // ✅ NEW: View mode selector
              // _buildViewModeSelector(),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            height: 60, // Increased height for better shot cards
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: shotTraces.length,
              itemBuilder: (context, index) {
                final shotTrace = shotTraces[index];
                final shotNumber = shotTrace is Map
                    ? shotTrace['shotNumber']
                    : shotTrace.shotNumber;
                final isSelected = _selectedShotNumber == shotNumber;
                final maxMagnitude = shotTrace is Map
                    ? shotTrace['maxMagnitude']
                    : shotTrace.maxMagnitude;
                final tracePoints = shotTrace is Map
                    ? shotTrace['tracePoints']
                    : shotTrace.tracePoints;

                // ✅ NEW: Calculate shot quality score
                final shotScore =
                    _calculateShotScore(tracePoints, maxMagnitude);
                final shotColor = _getShotColorFromScore(shotScore);

                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedShotNumber = shotNumber;
                        _currentAnimatedPoints = 0;
                        _isPlaying = false;
                        _isPaused = false;
                      });
                      _startTraceAnimation(shotTrace);
                      _analyzeShotData(shotTrace);
                    },
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: shotColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF5EA1FF)
                              : Colors.transparent,
                          width: isSelected ? 3 : 0,
                        ),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                                color: Colors.white.withValues(alpha: 0.8),
                                blurRadius: 12,
                                spreadRadius: 1),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Shot number
                          Text(
                            '$shotNumber',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          // ✅ NEW: Quality indicator
                          // Positioned(
                          //   top: 4,
                          //   right: 4,
                          //   child: Container(
                          //     width: 12,
                          //     height: 12,
                          //     decoration: BoxDecoration(
                          //       color: _getQualityIndicatorColor(shotScore),
                          //       shape: BoxShape.circle,
                          //       border:
                          //           Border.all(color: Colors.white, width: 1),
                          //     ),
                          //   ),
                          // ),

                          // ✅ NEW: Score display
                          // Positioned(
                          //   bottom: 2,
                          //   left: 2,
                          //   child: Text(
                          //     shotScore.toStringAsFixed(0),
                          //     style: const TextStyle(
                          //       color: Colors.white,
                          //       fontSize: 10,
                          //       fontWeight: FontWeight.bold,
                          //     ),
                          //   ),
                          // ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetDisplay(List<dynamic> shotTraces) {
    final selectedShot = shotTraces
        .where((shot) =>
            (shot is Map ? shot['shotNumber'] : shot.shotNumber) ==
            _selectedShotNumber)
        .firstOrNull;

    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: const Color(0xFF1A2332).withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2A3A64), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 5))
          ]),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(15),
            decoration: const BoxDecoration(
                color: Color(0xFF5EA1FF),
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12))),
            child: Row(
              children: [
                Text(
                    selectedShot != null
                        ? 'Shot #${selectedShot is Map ? selectedShot['shotNumber'] : selectedShot.shotNumber}'
                        : 'Select a shot to view traceline',
                    style: const TextStyle(
                        color: Color(0xFFE6EEFC),
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                const Spacer(),
                if (selectedShot != null) ...[
                  _buildPlaybackControls(selectedShot),
                ],
              ],
            ),
          ),

          // Target display
          Container(
            padding: const EdgeInsets.all(8),
            child: selectedShot != null
                ? _buildTargetWithTraceline(selectedShot)
                : _buildEmptyTarget(),
          ),

          // Traceline legend
          if (selectedShot != null)
            Container(
              padding: const EdgeInsets.all(12),
              child: _buildTracelineLegend(),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaybackControls(dynamic selectedShot) {
    final tracePoints = selectedShot is Map
        ? selectedShot['tracePoints']
        : selectedShot.tracePoints;
    final totalPoints = tracePoints?.length ?? 0;
    final progress =
        totalPoints > 0 ? _currentAnimatedPoints / totalPoints : 0.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ✅ NEW: Progress bar
        Container(
          width: 200,
          height: 4,
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),

        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ✅ NEW: Speed control
            _buildSpeedControl(),
            const SizedBox(width: 8),

            // Play/Pause button
            GestureDetector(
              onTap: () {
                if (_isPlaying) {
                  _pauseAnimation();
                } else if (_isPaused) {
                  _resumeAnimation();
                } else {
                  _restartAnimation();
                }
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  _isPlaying
                      ? Icons.pause
                      : _isPaused
                          ? Icons.play_arrow
                          : Icons.replay,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),

            const SizedBox(width: 8),

            // ✅ NEW: Step controls
            _buildStepControl(Icons.skip_previous, () => _stepBackward()),
            _buildStepControl(Icons.skip_next, () => _stepForward()),

            const SizedBox(width: 8),

            // ✅ NEW: Analysis toggle
            // _buildAnalysisToggle(),
          ],
        ),
      ],
    );
  }

  Widget _buildTargetWithTraceline(dynamic selectedShot) {
    final tracePoints = _getAnimatedTracePoints(selectedShot);

    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF5EA1FF), width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: InteractiveViewer(
            // ✅ NEW: Pan and zoom functionality
            minScale: 0.5, // Minimum zoom level (50%)
            maxScale: 5.0, // Maximum zoom level (500%)
            // boundaryMargin: const EdgeInsets.all(20),
            // constrained: false,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Target rings
                _buildTargetRings(),

                // ✅ ENHANCED: Traceline with advanced features
                if (tracePoints.isNotEmpty)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: TracePainter(
                        tracePoints,
                        showCurrentPositionMarker:
                            false, // Disable for analysis view
                        showShotPointMarker: true, // Show shot point markers
                        animateCurrentMarker:
                            false, // No animation needed for analysis
                        currentMarkerSize: 12.0,
                      ),
                    ),
                  ),

                // No traceline message
                if (tracePoints.isEmpty && selectedShot != null)
                  Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('No sensor data',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ))))
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyTarget() {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF2A3A64), width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.touch_app, size: 48, color: Color(0xFFA8B3C7)),
              SizedBox(height: 8),
              Text(
                'Select a shot from above\nto view traceline',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFA8B3C7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTargetRings() {
    return SizedBox.expand(
        child: Stack(alignment: Alignment.center, children: [
      _buildTargetRing(
          0.1, AppColors.kRedColor, AppColors.kRedColor), // Ring 10
      _buildTargetRing(0.3, AppColors.kRedColor), // Ring 9
      _buildTargetRing(0.48, AppColors.kRedColor), // Ring 8
      _buildTargetRing(0.65, AppColors.kRedColor), // Ring 7
      _buildTargetRing(0.83, AppColors.kRedColor),
      _buildTargetRing(1, AppColors.kRedColor),
      // Crosshair
      Positioned.fill(child: CustomPaint(painter: CrosshairPainter()))
    ]));
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
              border: Border.all(color: borderColor, width: 2))),
    );
  }

  Widget _buildShotDetailsPanel(List<dynamic> shotTraces) {
    final selectedShot = shotTraces
        .where((shot) =>
            (shot is Map ? shot['shotNumber'] : shot.shotNumber) ==
            _selectedShotNumber)
        .firstOrNull;

    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2332).withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A3A64), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(15),
            decoration: const BoxDecoration(
              color: Color(0xFF5EA1FF),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.analytics, color: Color(0xFFE6EEFC)),
                SizedBox(width: 10),
                Text(
                  'Shot Details',
                  style: TextStyle(
                    color: Color(0xFFE6EEFC),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          selectedShot != null
              ? _buildShotDetailsContent(selectedShot)
              : _buildNoShotSelected(),
        ],
      ),
    );
  }

  Widget _buildShotDetailsContent(dynamic shotTrace) {
    final shotNumber =
        shotTrace is Map ? shotTrace['shotNumber'] : shotTrace.shotNumber;
    final maxMagnitude =
        shotTrace is Map ? shotTrace['maxMagnitude'] : shotTrace.maxMagnitude;
    final timestamp =
        shotTrace is Map ? shotTrace['timestamp'] : shotTrace.timestamp;
    final tracePoints =
        shotTrace is Map ? shotTrace['tracePoints'] : shotTrace.tracePoints;
    final metrics = shotTrace is Map ? shotTrace['metrics'] : shotTrace.metrics;
    final analysisNotes =
        shotTrace is Map ? shotTrace['analysisNotes'] : shotTrace.analysisNotes;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Basic info
          _buildInfoCard('Basic Information', [
            _buildInfoRow('Shot Number', '$shotNumber'),
            _buildInfoRow(
                'Max Magnitude', '${maxMagnitude.toStringAsFixed(3)}'),
            _buildInfoRow(
                'Time', timestamp.toString().split(' ')[1].substring(0, 8)),
          ]),

          const SizedBox(height: 20),

          // Metrics
          _buildInfoCard('Metrics', [
            _buildInfoRow('Total Trace Points', '${tracePoints.length}'),
            _buildInfoRow(
                'Pre-shot Points',
                tracePoints
                    .where((p) => p.phase == streaming.TracePhase.preShot)
                    .length
                    .toString()),
            _buildInfoRow(
                'Shot Points',
                tracePoints
                    .where((p) => p.phase == streaming.TracePhase.shot)
                    .length
                    .toString()),
            _buildInfoRow(
                'Post-shot Points',
                tracePoints
                    .where((p) => p.phase == streaming.TracePhase.postShot)
                    .length
                    .toString()),
          ]),

          const SizedBox(height: 20),

          // Traceline info
          _buildInfoCard('Traceline Data', [
            _buildInfoRow('Status', metrics['status'] ?? 'Complete'),
            _buildInfoRow(
                'Pre-shot Count', (metrics['preShotCount'] ?? 0).toString()),
            _buildInfoRow('Shot Count', (metrics['shotCount'] ?? 0).toString()),
            _buildInfoRow(
                'Post-shot Count', (metrics['postShotCount'] ?? 0).toString()),
            _buildInfoRow(
                'Total Points', (metrics['totalPoints'] ?? 0).toString()),
            _buildInfoRow(
                'Is Balanced', (metrics['isBalanced'] ?? false) ? 'Yes' : 'No'),
            _buildInfoRow('Smoothing Applied',
                (metrics['smoothingApplied'] ?? false) ? 'Yes' : 'No'),
          ]),

          const SizedBox(height: 20),

          // Analysis notes
          if (analysisNotes.isNotEmpty)
            _buildInfoCard('Analysis', [
              Text(
                analysisNotes,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFFE6EEFC),
                ),
              ),
            ]),
        ],
      ),
    );
  }

  Widget _buildNoShotSelected() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline,
            size: 48,
            color: Color(0xFFA8B3C7),
          ),
          SizedBox(height: 16),
          Text(
            'Select a shot to view details',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFFA8B3C7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF111A2B).withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2A3A64)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE6EEFC),
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: Color(0xFFA8B3C7),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFFE6EEFC),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Removed unused _getShotColorFromMagnitude method - using _getShotColorFromScore instead

  List<streaming.TracePoint> _getAnimatedTracePoints(dynamic shotTrace) {
    // Check if shotTrace or tracePoints is null/empty
    final tracePoints =
        shotTrace is Map ? shotTrace['tracePoints'] : shotTrace.tracePoints;
    final shotNumber =
        shotTrace is Map ? shotTrace['shotNumber'] : shotTrace.shotNumber;

    if (shotTrace == null || tracePoints == null || tracePoints.isEmpty) {
      print(
          '🔍 No traceline points available for shot ${shotNumber ?? 'unknown'}');
      return [];
    }

    if (tracePoints.isEmpty) {
      print('🔍 Empty traceline list for shot $shotNumber');
      return [];
    }

    print(
        '🔍 Processing ${tracePoints.length} traceline points for shot $shotNumber');

    try {
      final allPoints = tracePoints
          .map((point) {
            // Validate point structure
            if (point == null || point.point == null) {
              print('⚠️ Invalid point structure: $point');
              return null;
            }

            // Handle both ShotTraceData (sensor coordinates) and SteadinessShotData (internal coordinates)
            double x, y, z;
            if (shotTrace is Map && shotTrace.containsKey('tracePoints')) {
              // This is converted SteadinessShotData - convert from internal to sensor coordinates
              final internalX = point.point.x?.toDouble() ?? 0.0;
              final internalY = point.point.y?.toDouble() ?? 0.0;
              x = ((internalX - 200) / 200) * 4.5;
              y = ((internalY - 200) / 200) * 4.5;
              z = point.point.z?.toDouble() ?? 0.0;
            } else {
              // This is real ShotTraceData - already has sensor coordinates
              x = point.point.x;
              y = point.point.y;
              z = point.point.z;
            }

            return streaming.TracePoint(
              streaming.Point3D(x, y, z),
              point.phase,
            );
          })
          .where((point) => point != null)
          .cast<streaming.TracePoint>()
          .toList();

      final animatedPoints = allPoints.take(_currentAnimatedPoints).toList();
      print(
          '🔍 Returning ${animatedPoints.length} animated points (current: $_currentAnimatedPoints)');

      return animatedPoints;
    } catch (e) {
      print('❌ Error processing traceline points: $e');
      return [];
    }
  }

  void _startTraceAnimation(dynamic shotTrace) {
    _animationTimer?.cancel();

    // Safety check for shotTrace and tracePoints
    final tracePoints =
        shotTrace is Map ? shotTrace['tracePoints'] : shotTrace.tracePoints;

    if (shotTrace == null || tracePoints == null) {
      print('⚠️ Cannot start animation: shotTrace or tracePoints is null');
      return;
    }

    if (tracePoints.isEmpty) {
      print('⚠️ Cannot start animation: no traceline points available');
      return;
    }

    setState(() {
      _isPlaying = true;
      _isPaused = false;
    });

    final totalPoints = tracePoints.length;
    print('🎬 Starting animation with $totalPoints points');

    // ✅ NEW: Adjust animation speed based on playback speed
    final animationInterval = (20 / _playbackSpeed).round();
    final pointsPerFrame = (5 * _playbackSpeed).round().clamp(1, 20);

    _animationTimer =
        Timer.periodic(Duration(milliseconds: animationInterval), (timer) {
      if (mounted && !_isPaused) {
        setState(() {
          if (_currentAnimatedPoints < totalPoints) {
            _currentAnimatedPoints = (_currentAnimatedPoints + pointsPerFrame)
                .clamp(0, totalPoints)
                .toInt();
          } else {
            timer.cancel();
            _isPlaying = false;
            print('🎬 Animation completed');
          }
        });
      } else if (!mounted) {
        timer.cancel();
      }
    });
  }

  void _pauseAnimation() {
    setState(() {
      _isPaused = true;
      _isPlaying = false;
    });
    _animationTimer?.cancel();
  }

  void _resumeAnimation() {
    if (_isPaused && _selectedShotNumber != -1) {
      final trainingState = context.read<TrainingSessionBloc>().state;
      final shotTraces = trainingState.sessionShotTraces;
      final steadinessShots = trainingState.steadinessShots;
      final dataToUse = shotTraces.isNotEmpty
          ? shotTraces
          : _convertSteadinessShotsToShotTraces(steadinessShots);

      final selectedShot = dataToUse
          .where((shot) =>
              (shot is Map ? shot['shotNumber'] : shot.shotNumber) ==
              _selectedShotNumber)
          .firstOrNull;

      if (selectedShot != null) {
        setState(() {
          _isPaused = false;
          _isPlaying = true;
        });
        _startTraceAnimation(selectedShot);
      }
    }
  }

  void _restartAnimation() {
    if (_selectedShotNumber != -1) {
      final trainingState = context.read<TrainingSessionBloc>().state;
      final shotTraces = trainingState.sessionShotTraces;
      final steadinessShots = trainingState.steadinessShots;
      final dataToUse = shotTraces.isNotEmpty
          ? shotTraces
          : _convertSteadinessShotsToShotTraces(steadinessShots);

      final selectedShot = dataToUse
          .where((shot) =>
              (shot is Map ? shot['shotNumber'] : shot.shotNumber) ==
              _selectedShotNumber)
          .firstOrNull;

      if (selectedShot != null) {
        setState(() {
          _isPaused = false;
          _isPlaying = true;
          _currentAnimatedPoints = 0;
        });
        _startTraceAnimation(selectedShot);
      }
    }
  }

  /// Convert SteadinessShotData to ShotTraceData format for compatibility
  List<dynamic> _convertSteadinessShotsToShotTraces(
      List<dynamic> steadinessShots) {
    return steadinessShots.map((shot) {
      // Create a mock ShotTraceData-like object from SteadinessShotData
      return {
        'shotNumber': shot.shotNumber,
        'timestamp': shot.timestamp,
        'maxMagnitude':
            shot.thetaDot / 10.0, // Convert thetaDot to magnitude-like value
        'tracePoints': shot.tracelinePoints,
        'metrics': {
          'status': shot.metrics['status'] ?? 'Complete',
          'preShotCount': shot.metrics['preShotPackets'] ?? 0,
          'shotCount': shot.metrics['shotPackets'] ?? 0,
          'postShotCount': shot.metrics['postShotPackets'] ?? 0,
          'totalPoints': shot.metrics['totalTracelinePackets'] ?? 0,
          'isBalanced': true,
          'smoothingApplied': true,
        },
        'analysisNotes': shot.analysisNotes,
      };
    }).toList();
  }

  /// Build traceline legend to show what different colors mean
  Widget _buildTracelineLegend() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildLegendItem(
                const Color(0xFF5EA1FF), 'Pre-shot', 'Movement before shot'),
            _buildLegendItem(const Color(0xFFF59E0B), 'Recent Pre-shot',
                'Last 0.15s before shot')
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildLegendItem(
                const Color(0xFFEF4444), 'Shot Point', 'Exact shot position'),
            _buildLegendItem(const Color(0xFFEF4444).withValues(alpha: 0.7),
                'Post-shot', 'Movement after shot'),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label, String description) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFFE6EEFC),
          ),
        ),
        Text(
          description,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFFA8B3C7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSpeedControl() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<double>(
        value: _playbackSpeed,
        underline: const SizedBox(),
        icon: const Icon(Icons.speed),
        style: const TextStyle(
            color: Color(0xFFE6EEFC),
            fontSize: 12,
            fontWeight: FontWeight.bold),
        dropdownColor: const Color(0xFF5EA1FF),
        padding: EdgeInsets.zero,
        items: const [
          DropdownMenuItem(value: 0.2, child: Text('0.2x')),
          DropdownMenuItem(value: 0.5, child: Text('0.5x')),
          DropdownMenuItem(value: 0.75, child: Text('0.75x')),
          DropdownMenuItem(value: 1.0, child: Text('1x')),
          DropdownMenuItem(value: 2.0, child: Text('2x')),
        ],
        onChanged: (value) {
          setState(() {
            _playbackSpeed = value!;
          });
        },
      ),
    );
  }

  Widget _buildStepControl(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 16,
        ),
      ),
    );
  }

  // ✅ NEW: Analysis methods

  double _calculateShotScore(List<dynamic> tracePoints, double maxMagnitude) {
    if (tracePoints.isEmpty) return 0.0;

    // Calculate stability score based on movement variance
    double totalVariance = 0.0;
    double centerX = 0.0, centerY = 0.0;

    // Find center point
    for (var point in tracePoints) {
      centerX += point.point.x;
      centerY += point.point.y;
    }
    centerX /= tracePoints.length;
    centerY /= tracePoints.length;

    // Calculate variance from center
    for (var point in tracePoints) {
      final distance =
          ((point.point.x - centerX).abs() + (point.point.y - centerY).abs()) /
              2;
      totalVariance += distance;
    }

    final avgVariance = totalVariance / tracePoints.length;

    // Convert to 0-100 score (lower variance = higher score)
    final stabilityScore = (1.0 - (avgVariance / 2.0)).clamp(0.0, 1.0) * 100;

    // Factor in magnitude (lower magnitude = better)
    final magnitudeScore = (1.0 - (maxMagnitude / 5.0)).clamp(0.0, 1.0) * 100;

    // Combined score (70% stability, 30% magnitude)
    return (stabilityScore * 0.7 + magnitudeScore * 0.3);
  }

  Color _getShotColorFromScore(double score) {
    if (score >= 80) return const Color(0xFF34D399); // Green - excellent
    if (score >= 60) return const Color(0xFF5EA1FF); // Blue - good
    if (score >= 40) return const Color(0xFFF59E0B); // Yellow - fair
    if (score >= 20) return const Color(0xFFEF4444); // Orange - poor
    return const Color(0xFFEF4444); // Red - very poor
  }

  void _analyzeShotData(dynamic shotTrace) {
    final shotNumber =
        shotTrace is Map ? shotTrace['shotNumber'] : shotTrace.shotNumber;
    final tracePoints =
        shotTrace is Map ? shotTrace['tracePoints'] : shotTrace.tracePoints;

    if (tracePoints.isEmpty) return;

    // Calculate stability zones
    _stabilityZonePoints = _calculateStabilityZones(tracePoints);

    // Store analysis data
    _shotAnalysisData[shotNumber] = {
      'stabilityScore': _calculateShotScore(
          tracePoints,
          shotTrace is Map
              ? shotTrace['maxMagnitude']
              : shotTrace.maxMagnitude),
      'centerPoint': _calculateCenterPoint(tracePoints),
      'movementRange': _calculateMovementRange(tracePoints),
      'stabilityZones': _stabilityZonePoints,
      'preShotStability': _calculatePreShotStability(tracePoints),
      'postShotRecovery': _calculatePostShotRecovery(tracePoints),
    };
  }

  List<streaming.TracePoint> _calculateStabilityZones(
      List<dynamic> tracePoints) {
    // Identify points within stability threshold (low movement)
    return tracePoints
        .where((point) {
          // Calculate movement magnitude
          final magnitude = (point.point.x.abs() + point.point.y.abs()) / 2;
          return magnitude < 0.5; // Stability threshold
        })
        .map((point) => streaming.TracePoint(
              streaming.Point3D(point.point.x, point.point.y, point.point.z),
              point.phase,
            ))
        .toList();
  }

  Map<String, double> _calculateCenterPoint(List<dynamic> tracePoints) {
    double centerX = 0.0, centerY = 0.0;
    for (var point in tracePoints) {
      centerX += point.point.x;
      centerY += point.point.y;
    }
    return {
      'x': centerX / tracePoints.length,
      'y': centerY / tracePoints.length,
    };
  }

  Map<String, double> _calculateMovementRange(List<dynamic> tracePoints) {
    double minX = double.infinity, maxX = -double.infinity;
    double minY = double.infinity, maxY = -double.infinity;

    for (var point in tracePoints) {
      minX = minX < point.point.x ? minX : point.point.x;
      maxX = maxX > point.point.x ? maxX : point.point.x;
      minY = minY < point.point.y ? minY : point.point.y;
      maxY = maxY > point.point.y ? maxY : point.point.y;
    }

    return {
      'minX': minX,
      'maxX': maxX,
      'minY': minY,
      'maxY': maxY,
      'rangeX': maxX - minX,
      'rangeY': maxY - minY,
    };
  }

  double _calculatePreShotStability(List<dynamic> tracePoints) {
    final preShotPoints = tracePoints
        .where((p) => p.phase == streaming.TracePhase.preShot)
        .toList();
    if (preShotPoints.isEmpty) return 0.0;

    double totalVariance = 0.0;
    double centerX = 0.0, centerY = 0.0;

    for (var point in preShotPoints) {
      centerX += point.point.x;
      centerY += point.point.y;
    }
    centerX /= preShotPoints.length;
    centerY /= preShotPoints.length;

    for (var point in preShotPoints) {
      final distance =
          ((point.point.x - centerX).abs() + (point.point.y - centerY).abs()) /
              2;
      totalVariance += distance;
    }

    return (1.0 - (totalVariance / preShotPoints.length / 2.0))
            .clamp(0.0, 1.0) *
        100;
  }

  double _calculatePostShotRecovery(List<dynamic> tracePoints) {
    final postShotPoints = tracePoints
        .where((p) => p.phase == streaming.TracePhase.postShot)
        .toList();
    if (postShotPoints.isEmpty) return 0.0;

    // Calculate how quickly the trace returns to stability
    int stablePoints = 0;
    for (var point in postShotPoints) {
      final magnitude = (point.point.x.abs() + point.point.y.abs()) / 2;
      if (magnitude < 0.5) stablePoints++;
    }

    return (stablePoints / postShotPoints.length) * 100;
  }

  void _stepBackward() {
    if (_currentAnimatedPoints > 0) {
      setState(() {
        _currentAnimatedPoints = (_currentAnimatedPoints - 10).clamp(0, 1000);
      });
    }
  }

  void _stepForward() {
    final trainingState = context.read<TrainingSessionBloc>().state;
    final shotTraces = trainingState.sessionShotTraces;
    final steadinessShots = trainingState.steadinessShots;
    final dataToUse = shotTraces.isNotEmpty
        ? shotTraces
        : _convertSteadinessShotsToShotTraces(steadinessShots);

    final selectedShot = dataToUse
        .where((shot) =>
            (shot is Map ? shot['shotNumber'] : shot.shotNumber) ==
            _selectedShotNumber)
        .firstOrNull;

    if (selectedShot != null) {
      final tracePoints = selectedShot is Map
          ? selectedShot['tracePoints']
          : selectedShot.tracePoints;
      final totalPoints = tracePoints?.length ?? 0;

      if (_currentAnimatedPoints < totalPoints) {
        setState(() {
          _currentAnimatedPoints =
              (_currentAnimatedPoints + 10).clamp(0, totalPoints).toInt();
        });
      }
    }
  }
}

// ✅ NEW: Advanced Trace Painter with enhanced visualization features
class AdvancedTracePainter extends CustomPainter {
  final List<streaming.TracePoint> tracePoints;
  final bool showCurrentPositionMarker;
  final bool showShotPointMarker;
  final bool animateCurrentMarker;
  final double currentMarkerSize;
  final bool showStabilityZones;
  final bool showMovementVectors;
  final bool showShotOverlay;
  final List<streaming.TracePoint> stabilityZonePoints;
  final Map<String, dynamic>? analysisData;

  AdvancedTracePainter({
    required this.tracePoints,
    required this.showCurrentPositionMarker,
    required this.showShotPointMarker,
    required this.animateCurrentMarker,
    required this.currentMarkerSize,
    this.showStabilityZones = false,
    this.showMovementVectors = false,
    this.showShotOverlay = false,
    this.stabilityZonePoints = const [],
    this.analysisData,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (tracePoints.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final scale = size.width / 9.0; // Scale for -4.5 to 4.5 range

    // ✅ NEW: Draw stability zones
    if (showStabilityZones && stabilityZonePoints.isNotEmpty) {
      _drawStabilityZones(canvas, size, center, scale);
    }

    // ✅ NEW: Draw movement vectors
    if (showMovementVectors) {
      _drawMovementVectors(canvas, size, center, scale);
    }

    // Draw main traceline
    _drawTraceline(canvas, size, center, scale);

    // ✅ NEW: Draw shot overlay analysis
    if (showShotOverlay && analysisData != null) {
      _drawShotOverlay(canvas, size, center, scale);
    }

    // Draw shot point markers
    if (showShotPointMarker) {
      _drawShotMarkers(canvas, size, center, scale);
    }
  }

  void _drawStabilityZones(
      Canvas canvas, Size size, Offset center, double scale) {
    final stabilityPaint = Paint()
      ..color = const Color(0xFF34D399).withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    for (var point in stabilityZonePoints) {
      final x = center.dx + (point.point.x * scale);
      final y = center.dy + (point.point.y * scale);

      // Draw stability zone circle
      canvas.drawCircle(
        Offset(x, y),
        8.0,
        stabilityPaint,
      );
    }
  }

  void _drawMovementVectors(
      Canvas canvas, Size size, Offset center, double scale) {
    final vectorPaint = Paint()
      ..color = const Color(0xFF5EA1FF).withValues(alpha: 0.6)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (int i = 1; i < tracePoints.length; i++) {
      final prevPoint = tracePoints[i - 1];
      final currentPoint = tracePoints[i];

      final startX = center.dx + (prevPoint.point.x * scale);
      final startY = center.dy + (prevPoint.point.y * scale);
      final endX = center.dx + (currentPoint.point.x * scale);
      final endY = center.dy + (currentPoint.point.y * scale);

      // Draw movement vector
      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        vectorPaint,
      );

      // Draw arrow head
      _drawArrowHead(
          canvas, Offset(startX, startY), Offset(endX, endY), vectorPaint);
    }
  }

  void _drawTraceline(Canvas canvas, Size size, Offset center, double scale) {
    if (tracePoints.length < 2) return;

    // Pre-shot path (blue) - older pre-shot data
    final preShotPaint = Paint()
      ..color = const Color(0xFF5EA1FF)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Recent pre-shot path (yellow) - last 0.15s before shot
    final recentPreShotPaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Shot point (red)
    final shotPaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Post-shot path (red) - movement after shot
    final postShotPaint = Paint()
      ..color = const Color(0xFFEF4444).withValues(alpha: 0.7)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Calculate recent pre-shot threshold (last 0.15s before shot)
    final recentPreShotThreshold = _calculateRecentPreShotThreshold();

    // Draw traceline segments
    for (int i = 1; i < tracePoints.length; i++) {
      final prevPoint = tracePoints[i - 1];
      final currentPoint = tracePoints[i];

      final startX = center.dx + (prevPoint.point.x * scale);
      final startY = center.dy + (prevPoint.point.y * scale);
      final endX = center.dx + (currentPoint.point.x * scale);
      final endY = center.dy + (currentPoint.point.y * scale);

      Paint paint;
      switch (currentPoint.phase) {
        case streaming.TracePhase.preShot:
          // Check if this is recent pre-shot (last 0.15s before shot)
          // i is the current point index, so we check if current point is in recent pre-shot range
          if (i >= recentPreShotThreshold) {
            paint = recentPreShotPaint; // Yellow for recent pre-shot
          } else {
            paint = preShotPaint; // Blue for older pre-shot
          }
          break;
        case streaming.TracePhase.shot:
          paint = shotPaint; // Red for shot point
          break;
        case streaming.TracePhase.postShot:
          paint = postShotPaint; // Red (with transparency) for post-shot
          break;
      }

      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        paint,
      );
    }
  }

  void _drawShotOverlay(Canvas canvas, Size size, Offset center, double scale) {
    if (analysisData == null) return;

    final overlayPaint = Paint()
      ..color = const Color(0xFFE6EEFC).withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    // final textPaint = Paint()
    //   ..color = const Color(0xff2c3e50);

    // Draw center point
    final centerPoint = analysisData!['centerPoint'] as Map<String, double>?;
    if (centerPoint != null) {
      final centerX = center.dx + (centerPoint['x']! * scale);
      final centerY = center.dy + (centerPoint['y']! * scale);

      canvas.drawCircle(
        Offset(centerX, centerY),
        6.0,
        overlayPaint,
      );
    }

    // Draw movement range
    final movementRange =
        analysisData!['movementRange'] as Map<String, double>?;
    if (movementRange != null) {
      final rangePaint = Paint()
        ..color = const Color(0xFFA8B3C7).withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      final minX = center.dx + (movementRange['minX']! * scale);
      final maxX = center.dx + (movementRange['maxX']! * scale);
      final minY = center.dy + (movementRange['minY']! * scale);
      final maxY = center.dy + (movementRange['maxY']! * scale);

      canvas.drawRect(
        Rect.fromLTRB(minX, minY, maxX, maxY),
        rangePaint,
      );
    }
  }

  void _drawShotMarkers(Canvas canvas, Size size, Offset center, double scale) {
    final shotMarkerPaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..style = PaintingStyle.fill;

    final shotOutlinePaint = Paint()
      ..color = const Color(0xFFE6EEFC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (var point in tracePoints) {
      if (point.phase == streaming.TracePhase.shot) {
        final x = center.dx + (point.point.x * scale);
        final y = center.dy + (point.point.y * scale);

        // Draw shot marker
        canvas.drawCircle(
          Offset(x, y),
          currentMarkerSize / 2,
          shotMarkerPaint,
        );

        // Draw outline
        canvas.drawCircle(
          Offset(x, y),
          currentMarkerSize / 2,
          shotOutlinePaint,
        );
      }
    }
  }

  void _drawArrowHead(Canvas canvas, Offset start, Offset end, Paint paint) {
    final angle = (end - start).direction;
    final arrowLength = 8.0;
    final arrowAngle = 0.5;

    final arrow1 = Offset(
      end.dx - arrowLength * cos(angle - arrowAngle),
      end.dy - arrowLength * sin(angle - arrowAngle),
    );

    final arrow2 = Offset(
      end.dx - arrowLength * cos(angle + arrowAngle),
      end.dy - arrowLength * sin(angle + arrowAngle),
    );

    canvas.drawLine(end, arrow1, paint);
    canvas.drawLine(end, arrow2, paint);
  }

  // ✅ NEW: Calculate recent pre-shot threshold (last 0.15s before shot)
  int _calculateRecentPreShotThreshold() {
    if (tracePoints.isEmpty) return 0;

    // Find the shot point index
    int shotIndex = -1;
    for (int i = 0; i < tracePoints.length; i++) {
      if (tracePoints[i].phase == streaming.TracePhase.shot) {
        shotIndex = i;
        break;
      }
    }

    if (shotIndex == -1) {
      return tracePoints.length; // No shot found, all should be blue
    }

    // Calculate how many points represent 0.15 seconds
    // Assuming ~20ms per point (50Hz), 0.15s = 7.5 points ≈ 8 points
    final recentPreShotPoints = 8;

    // Return the threshold index where we switch from blue to yellow
    // This should be the point where recent pre-shot (yellow) starts
    // So points 0 to (threshold-1) are blue, points threshold to shot are yellow
    return (shotIndex - recentPreShotPoints).clamp(0, shotIndex);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

// Crosshair painter for target display
class CrosshairPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFA8B3C7).withValues(alpha: 0.5)
      ..strokeWidth = 1.0;

    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

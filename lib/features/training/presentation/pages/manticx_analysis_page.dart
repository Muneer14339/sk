import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pulse_skadi/core/theme/app_colors.dart';
import 'package:pulse_skadi/features/training/presentation/bloc/training_session/training_session_bloc.dart';
import 'package:pulse_skadi/features/training/presentation/bloc/training_session/training_session_state.dart';
import 'package:pulse_skadi/features/training/presentation/widgets/trace_painter.dart';
import 'package:pulse_skadi/features/training/data/model/streaming_model.dart'
    as streaming;
import 'dart:async';

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

  @override
  void dispose() {
    _animationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8f9fa),
      appBar: AppBar(
        backgroundColor: const Color(0xff2c3e50),
        foregroundColor: Colors.white,
        title: const Text('Shot Analysis'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocBuilder<TrainingSessionBloc, TrainingSessionState>(
        builder: (context, trainingState) {
          final steadinessShots = trainingState.steadinessShots;

          if (steadinessShots.isEmpty) {
            return _buildNoShotsView();
          }

          return ListView(
            children: [
              // Shot selection row
              _buildShotSelectionRow(steadinessShots),
              const SizedBox(height: 20),
              _buildTargetDisplay(steadinessShots),

              _buildShotDetailsPanel(steadinessShots),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNoShotsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.track_changes,
            size: 80,
            color: Color(0xff6c757d),
          ),
          const SizedBox(height: 20),
          const Text(
            'No Shots Recorded',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xff2c3e50),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Complete a training session to view shot analysis',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xff6c757d),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShotSelectionRow(List<dynamic> steadinessShots) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Shot to Analyze (${steadinessShots.length} shots)',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xff2c3e50),
            ),
          ),
          const SizedBox(height: 15),
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: steadinessShots.length,
              itemBuilder: (context, index) {
                final shot = steadinessShots[index];
                final isSelected = _selectedShotNumber == shot.shotNumber;
                final shotColor = _getShotColor(shot.score);

                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedShotNumber = shot.shotNumber;
                        _currentAnimatedPoints = 0;
                        _isPlaying = false;
                        _isPaused = false;
                      });
                      _startTraceAnimation(shot);
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: shotColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: isSelected ? 3 : 0,
                        ),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.8),
                              blurRadius: 12,
                              spreadRadius: 1,
                            ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            '${shot.shotNumber}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (shot.tracelinePoints.isNotEmpty)
                            Positioned(
                              top: 2,
                              right: 2,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xff17a2b8),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
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

  Widget _buildTargetDisplay(List<dynamic> steadinessShots) {
    final selectedShot = steadinessShots
        .where((shot) => shot.shotNumber == _selectedShotNumber)
        .firstOrNull;

    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Text(
                selectedShot != null
                    ? 'Shot #${selectedShot.shotNumber} - Traceline Analysis'
                    : 'Select a shot to view traceline',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (selectedShot != null) ...[
                _buildPlaybackControls(selectedShot),
              ],
            ],
          ),

          // Target display
          Container(
            padding: const EdgeInsets.all(8),
            child: selectedShot != null
                ? _buildTargetWithTraceline(selectedShot)
                : _buildEmptyTarget(),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaybackControls(dynamic selectedShot) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Progress indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$_currentAnimatedPoints/${(selectedShot.tracelinePoints as List).length}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 10),

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
      ],
    );
  }

  Widget _buildTargetWithTraceline(dynamic selectedShot) {
    final tracePoints = _getAnimatedTracePoints(selectedShot);

    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xff17a2b8), width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Target rings
            _buildTargetRings(),

            // Traceline
            if (tracePoints.isNotEmpty)
              Positioned.fill(
                child: CustomPaint(
                  painter: TracePainter(
                    tracePoints,
                    showCurrentPositionMarker: true,
                    animateCurrentMarker: true,
                    currentMarkerSize: 12.0,
                  ),
                ),
              ),

            // Debug info
            if (tracePoints.isNotEmpty)
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Trace: ${tracePoints.length} points',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            // No traceline message
            if (tracePoints.isEmpty && selectedShot != null)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'No trace data',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyTarget() {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xffe9ecef), width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.touch_app, size: 48, color: Color(0xff6c757d)),
              SizedBox(height: 8),
              Text(
                'Select a shot from above\nto view traceline',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xff6c757d),
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
      child: Stack(
        alignment: Alignment.center,
        children: [
          _buildTargetRing(
              0.1, AppColors.kRedColor, AppColors.kRedColor), // Ring 10
          _buildTargetRing(0.3, AppColors.kRedColor), // Ring 9
          _buildTargetRing(0.48, AppColors.kRedColor), // Ring 8
          _buildTargetRing(0.65, AppColors.kRedColor), // Ring 7
          _buildTargetRing(0.83, AppColors.kRedColor),
          _buildTargetRing(1, AppColors.kRedColor),
          // Crosshair
          Positioned.fill(
            child: CustomPaint(painter: CrosshairPainter()),
          ),
        ],
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

  Widget _buildShotDetailsPanel(List<dynamic> steadinessShots) {
    final selectedShot = steadinessShots
        .where((shot) => shot.shotNumber == _selectedShotNumber)
        .firstOrNull;

    return Container(
      margin: const EdgeInsets.only(right: 20, top: 20, bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
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
              color: Color(0xff17a2b8),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.analytics, color: Colors.white),
                SizedBox(width: 10),
                Text(
                  'Shot Details',
                  style: TextStyle(
                    color: Colors.white,
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

  Widget _buildShotDetailsContent(dynamic shot) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Basic info
          _buildInfoCard('Basic Information', [
            _buildInfoRow('Shot Number', '${shot.shotNumber}'),
            _buildInfoRow('Score', '${shot.score}/10'),
            _buildInfoRow('Position',
                '(${shot.position.dx.toStringAsFixed(1)}, ${shot.position.dy.toStringAsFixed(1)})'),
            _buildInfoRow('Time',
                shot.timestamp.toString().split(' ')[1].substring(0, 8)),
          ]),

          const SizedBox(height: 20),

          // Metrics
          _buildInfoCard('Metrics', [
            _buildInfoRow(
                'Accuracy', '${(shot.accuracy * 100).toStringAsFixed(1)}%'),
            _buildInfoRow('Theta Dot', '${shot.thetaDot.toStringAsFixed(2)}°'),
            _buildInfoRow('Traceline Packets',
                '${(shot.tracelinePoints as List).length}'),
          ]),

          const SizedBox(height: 20),

          // Traceline info
          if (shot.tracelinePoints.isNotEmpty)
            _buildInfoCard('Traceline Data', [
              _buildInfoRow('Status', shot.metrics['status'] ?? 'Unknown'),
              _buildInfoRow('Pre-shot Packets',
                  (shot.metrics['preShotPackets'] ?? 0).toString()),
              _buildInfoRow('Shot Packets',
                  (shot.metrics['shotPackets'] ?? 0).toString()),
              _buildInfoRow('Post-shot Packets',
                  (shot.metrics['postShotPackets'] ?? 0).toString()),
              _buildInfoRow('Total Packets',
                  (shot.metrics['totalTracelinePackets'] ?? 0).toString()),
            ]),

          const SizedBox(height: 20),

          // Analysis notes
          if (shot.analysisNotes.isNotEmpty)
            _buildInfoCard('Analysis', [
              Text(
                shot.analysisNotes,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xff2c3e50),
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
            color: Color(0xff6c757d),
          ),
          SizedBox(height: 16),
          Text(
            'Select a shot to view details',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xff6c757d),
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
        color: const Color(0xfff8f9fa),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xffe9ecef)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xff2c3e50),
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
                color: Color(0xff6c757d),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xff2c3e50),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getShotColor(int score) {
    if (score >= 10) return const Color(0xff28a745);
    if (score >= 9) return const Color(0xffffc107);
    if (score >= 8) return const Color(0xfffd7e14);
    return const Color(0xffdc3545);
  }

  List<streaming.TracePoint> _getAnimatedTracePoints(dynamic shot) {
    // Check if shot or tracelinePoints is null/empty
    if (shot == null ||
        shot.tracelinePoints == null ||
        shot.tracelinePoints.isEmpty) {
      print(
          '🔍 No traceline points available for shot ${shot?.shotNumber ?? 'unknown'}');
      return [];
    }

    final tracelineList = shot.tracelinePoints as List;
    if (tracelineList.isEmpty) {
      print('🔍 Empty traceline list for shot ${shot.shotNumber}');
      return [];
    }

    print(
        '🔍 Processing ${tracelineList.length} traceline points for shot ${shot.shotNumber}');

    try {
      final allPoints = tracelineList
          .map((point) {
            // Validate point structure
            if (point == null || point.point == null) {
              print('⚠️ Invalid point structure: $point');
              return null;
            }

            // Convert from internal coordinate system (0-400) to sensor coordinate system (-4.5 to 4.5)
            final internalX = point.point.x?.toDouble() ?? 0.0;
            final internalY = point.point.y?.toDouble() ?? 0.0;

            // Convert to sensor coordinates (400x400 internal system maps to -4.5 to 4.5 sensor system)
            final sensorX = ((internalX - 200) / 200) * 4.5;
            final sensorY = ((internalY - 200) / 200) * 4.5;

            return streaming.TracePoint(
              streaming.Point3D(
                  sensorX, sensorY, point.point.z?.toDouble() ?? 0.0),
              point.phase ?? streaming.TracePhase.preShot,
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

  void _startTraceAnimation(dynamic shot) {
    _animationTimer?.cancel();

    // Safety check for shot and traceline points
    if (shot == null || shot.tracelinePoints == null) {
      print('⚠️ Cannot start animation: shot or tracelinePoints is null');
      return;
    }

    final tracelineList = shot.tracelinePoints as List;
    if (tracelineList.isEmpty) {
      print('⚠️ Cannot start animation: no traceline points available');
      return;
    }

    setState(() {
      _isPlaying = true;
      _isPaused = false;
    });

    final totalPoints = tracelineList.length;
    print('🎬 Starting animation with $totalPoints points');

    _animationTimer = Timer.periodic(const Duration(milliseconds: 20), (timer) {
      if (mounted && !_isPaused) {
        setState(() {
          if (_currentAnimatedPoints < totalPoints) {
            _currentAnimatedPoints =
                (_currentAnimatedPoints + 5).clamp(0, totalPoints);
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
      final selectedShot = trainingState.steadinessShots
          .where((shot) => shot.shotNumber == _selectedShotNumber)
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
      final selectedShot = trainingState.steadinessShots
          .where((shot) => shot.shotNumber == _selectedShotNumber)
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
}

// Crosshair painter for target display
class CrosshairPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
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

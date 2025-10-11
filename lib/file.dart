import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pulse_skadi/core/theme/app_colors.dart';
import 'package:pulse_skadi/core/widgets/primary_button.dart';
import 'package:pulse_skadi/features/training/data/model/analysis_model.dart';
import 'package:pulse_skadi/features/training/presentation/bloc/training_session/training_session_bloc.dart';
import 'package:pulse_skadi/features/training/presentation/bloc/training_session/training_session_state.dart';
import 'package:pulse_skadi/features/training/data/model/streaming_model.dart'
    as streaming;
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pulse_skadi/features/training/data/datasources/saved_sessions_datasource.dart';
import 'package:pulse_skadi/features/training/data/models/saved_session_model.dart';
import 'package:pulse_skadi/features/training/data/repositories/saved_sessions_repository_impl.dart';
import 'package:pulse_skadi/features/training/domain/usecases/save_training_session.dart';
import 'package:pulse_skadi/features/training/presentation/widgets/trace_painter.dart';

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
    final args = ModalRoute.of(context)?.settings.arguments;
    final SavedSessionModel? savedSession =
        args is SavedSessionModel ? args : null;
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
              onPressed: () => Navigator.pop(context))),
      body: BlocBuilder<TrainingSessionBloc, TrainingSessionState>(
        builder: (context, trainingState) {
          // Use passed saved session if available, otherwise use bloc state
          final shotTraces = savedSession?.sessionShotTraces ??
              trainingState.sessionShotTraces;
          final steadinessShots =
              savedSession?.steadinessShots ?? trainingState.steadinessShots;

          // Debug print to see what data we have
          print('🔍 ManticX Analysis: sessionShotTraces: ${shotTraces.length}');
          AnalysisModel? analysisModel;
          if (shotTraces.isEmpty && steadinessShots.isEmpty) {
            return _buildNoShotsView();
          }

          // Use sessionShotTraces if available, otherwise convert steadinessShots
          final dataToUse =
              _convertSteadinessShotsToShotTraces(steadinessShots);
          List<AnalysisModel> analysisModels = dataToUse;
          // Ensure a shot is selected by default when opening from saved
          if (_selectedShotNumber == -1 && (shotTraces.isNotEmpty)) {
            final first = shotTraces.first;
            _selectedShotNumber = first.shotNumber;
            analysisModel = analysisModels[_selectedShotNumber - 1];
          }
          if (_selectedShotNumber != -1) {
            print(
                'selected shot number: $_selectedShotNumber --- ${analysisModels.length}');
            analysisModel = analysisModels
                .firstWhere((e) => e.shotNumber == _selectedShotNumber);
          }

          print('analysisModel: ${analysisModel?.toJson()}');
          return ListView(
            children: [
              // Shot selection row
              _buildShotSelectionRow(analysisModels),
              _buildTargetDisplay(analysisModel),

              _buildShotDetailsPanel(analysisModel),
              if (savedSession == null)
                PrimaryButton(
                    title: 'Save Session',
                    onTap: () async {
                      await _saveCurrentSession(context);
                    }),
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

  Widget _buildShotSelectionRow(List<AnalysisModel> shotTraces) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: const Color(0xFF1A2332).withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2A3A64), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 5))
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Shot Analysis (${shotTraces.length} shots)',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE6EEFC))),
          const SizedBox(height: 15),
          SizedBox(
            height: 60, // Increased height for better shot cards
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: shotTraces.length,
              itemBuilder: (context, index) {
                final analysisModel = shotTraces[index];

                final shotNumber = analysisModel.shotNumber ?? 0;
                final isSelected = _selectedShotNumber == shotNumber;
                final maxMagnitude = analysisModel.maxMagnitude ?? 0;
                final tracePoints = analysisModel.tracePoints ?? [];

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
                      _startTraceAnimation(tracePoints);
                      _analyzeShotData(analysisModel);
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
                          )
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

  Future<void> _saveCurrentSession(BuildContext context) async {
    final state = context.read<TrainingSessionBloc>().state;
    if ((state.sessionShotTraces.isEmpty && state.steadinessShots.isEmpty) ||
        state.sessionStartTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No session data to save'),
      ));
      return;
    }

    final repo = SavedSessionsRepositoryImpl(SavedSessionsDataSourceImpl());
    final usecase = SaveTrainingSession(repo);
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    final session = SavedSessionModel(
      id: '',
      userId: uid,
      programName: state.program?.programName ?? 'Training Session',
      startedAt: state.sessionStartTime!,
      totalShots: state.shotCount,
      distancePresetKey: int.parse(state.selectedDistance),
      angleRangeKey: state.selectedAngleRange,
      sessionShotTraces: state.sessionShotTraces,
      steadinessShots: state.steadinessShots,
    );

    final result = await usecase(session);
    result.fold(
      (l) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to save: ${l.message}'),
      )),
      (id) => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Session saved'),
      )),
    );
  }

  Widget _buildTargetDisplay(AnalysisModel? analysisModel) {
    final selectedShot = analysisModel;
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            child: selectedShot != null
                ? _buildTargetWithTraceline(analysisModel)
                : _buildEmptyTarget(),
          ),
          if (selectedShot != null) ...[_buildPlaybackControls(analysisModel)],
        ],
      ),
    );
  }

  Widget _buildPlaybackControls(AnalysisModel? analysisModel) {
    final tracePoints = analysisModel?.tracePoints;
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
                    _resumeAnimation(analysisModel ?? AnalysisModel());
                  } else {
                    _restartAnimation(analysisModel ?? AnalysisModel());
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20)),
                  child: Icon(
                    _isPlaying
                        ? Icons.pause
                        : _isPaused
                            ? Icons.play_arrow
                            : Icons.replay,
                    color: Colors.white,
                    size: 20,
                  ),
                )),

            const SizedBox(width: 8),

            // ✅ NEW: Step controls
            _buildStepControl(Icons.skip_previous, () => _stepBackward()),
            _buildStepControl(Icons.skip_next,
                () => _stepForward(analysisModel ?? AnalysisModel())),

            const SizedBox(width: 8),

            // ✅ NEW: Analysis toggle
            // _buildAnalysisToggle(),
          ],
        ),
      ],
    );
  }

  Widget _buildTargetWithTraceline(AnalysisModel? analysisModel) {
    final tracePoints =
        _getAnimatedTracePoints(analysisModel ?? AnalysisModel());

    return AspectRatio(
      aspectRatio: 1,
      child: InteractiveViewer(
        // ✅ NEW: Pan and zoom functionality
        minScale: 0.5, // Minimum zoom level (50%)
        maxScale: 5.0, // Maximum zoom level (500%)
        // boundaryMargin: const EdgeInsets.all(16),
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
            if (tracePoints.isEmpty && analysisModel != null)
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

  Widget _buildShotDetailsPanel(AnalysisModel? analysisModel) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: const Color(0xFF1A2332).withValues(alpha: 0.9),
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
          analysisModel != null
              ? _buildShotDetailsContent(analysisModel)
              : _buildNoShotSelected(),
        ],
      ),
    );
  }

  Widget _buildShotDetailsContent(AnalysisModel shotTrace) {
    final shotNumber = shotTrace.shotNumber;
    final maxMagnitude = shotTrace.maxMagnitude;
    final timestamp = shotTrace.timestamp;
    final tracePoints = shotTrace.tracePoints;
    final metrics = shotTrace.metrics;
    final analysisNotes = shotTrace.analysisNotes;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Basic info
          _buildInfoCard('Basic Information', [
            _buildInfoRow('Shot Number', '$shotNumber'),
            _buildInfoRow(
                'Max Magnitude', '${maxMagnitude?.toStringAsFixed(3)}'),
            _buildInfoRow(
                'Time', timestamp.toString().split(' ')[1].substring(0, 8)),
          ]),

          const SizedBox(height: 20),

          // Metrics
          _buildInfoCard('Metrics', [
            _buildInfoRow('Total Trace Points', '${tracePoints?.length}'),
            _buildInfoRow(
                'Pre-shot Points',
                tracePoints
                        ?.where((p) => p.phase == streaming.TracePhase.preShot)
                        .length
                        .toString() ??
                    '0'),
            _buildInfoRow(
                'Shot Points',
                tracePoints
                        ?.where((p) => p.phase == streaming.TracePhase.shot)
                        .length
                        .toString() ??
                    '0'),
            _buildInfoRow(
                'Post-shot Points',
                tracePoints
                        ?.where((p) => p.phase == streaming.TracePhase.postShot)
                        .length
                        .toString() ??
                    '0'),
          ]),

          const SizedBox(height: 20),

          // Traceline info
          _buildInfoCard('Traceline Data', [
            _buildInfoRow('Status', metrics?.status ?? 'Complete'),
            _buildInfoRow(
                'Pre-shot Count', (metrics?.preShotCount ?? 0).toString()),
            _buildInfoRow('Shot Count', (metrics?.shotCount ?? 0).toString()),
            _buildInfoRow(
                'Post-shot Count', (metrics?.postShotCount ?? 0).toString()),
            _buildInfoRow(
                'Total Points', (metrics?.totalPoints ?? 0).toString()),
            _buildInfoRow(
                'Is Balanced', (metrics?.isBalanced ?? false) ? 'Yes' : 'No'),
            _buildInfoRow('Smoothing Applied',
                (metrics?.smoothingApplied ?? false) ? 'Yes' : 'No'),
          ]),

          const SizedBox(height: 20),

          // Analysis notes
          if (analysisNotes?.isNotEmpty ?? false)
            _buildInfoCard('Analysis', [
              Text(
                analysisNotes ?? '',
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

  List<streaming.TracePoint> _getAnimatedTracePoints(AnalysisModel shotTrace) {
    // Check if shotTrace or tracePoints is null/empty
    final tracePoints = shotTrace.tracePoints;
    final shotNumber = shotTrace.shotNumber;

    if (tracePoints == null || tracePoints.isEmpty) {
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
            double x, y, z;
            print('maamammamamamama');
            // This is converted SteadinessShotData - convert from internal to sensor coordinates
            final internalX = point.point.x.toDouble() ?? 0.0;
            final internalY = point.point.y.toDouble() ?? 0.0;
            x = ((internalX - 200) / 200) * 4.5;
            y = ((internalY - 200) / 200) * 4.5;
            z = point.point.z.toDouble() ?? 0.0;

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

  void _startTraceAnimation(List<streaming.TracePoint> shotTrace) {
    _animationTimer?.cancel();

    // Safety check for shotTrace and tracePoints
    final tracePoints = shotTrace;

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

  void _resumeAnimation(AnalysisModel analysisModel) {
    if (_isPaused && _selectedShotNumber != -1) {
      final selectedShot = analysisModel.tracePoints ?? [];

      if (selectedShot.isNotEmpty) {
        setState(() {
          _isPaused = false;
          _isPlaying = true;
        });
        _startTraceAnimation(selectedShot);
      }
    }
  }

  void _restartAnimation(AnalysisModel analysisModel) {
    if (_selectedShotNumber != -1) {
      final selectedShot = analysisModel.tracePoints ?? [];
      setState(() {
        _isPaused = false;
        _isPlaying = true;
        _currentAnimatedPoints = 0;
      });
      _startTraceAnimation(selectedShot);
    }
  }

  /// Convert SteadinessShotData to ShotTraceData format for compatibility
  List<AnalysisModel> _convertSteadinessShotsToShotTraces(
      List<dynamic> steadinessShots) {
    return steadinessShots.map((shot) {
      // Create a mock ShotTraceData-like object from SteadinessShotData
      return AnalysisModel(
        shotNumber: shot.shotNumber,
        timestamp: shot.timestamp,
        maxMagnitude:
            shot.thetaDot / 10.0, // Convert thetaDot to magnitude-like value
        tracePoints: shot.tracelinePoints,
        metrics: AnalysisMetrics(
          status: shot.metrics['status'] ?? 'Complete',
          preShotCount: shot.metrics['preShotPackets'] ?? 0,
          shotCount: shot.metrics['shotPackets'] ?? 0,
          postShotCount: shot.metrics['postShotPackets'] ?? 0,
          totalPoints: shot.metrics['totalTracelinePackets'] ?? 0,
          isBalanced: true,
          smoothingApplied: true,
        ),
        analysisNotes: shot.analysisNotes,
      );
    }).toList();
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

  double _calculateShotScore(
      List<streaming.TracePoint> tracePoints, double maxMagnitude) {
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

  void _analyzeShotData(AnalysisModel shotTrace) {
    final shotNumber = shotTrace.shotNumber;
    final tracePoints = shotTrace.tracePoints;

    if (tracePoints?.isEmpty ?? false) return;

    // Calculate stability zones
    _stabilityZonePoints = _calculateStabilityZones(tracePoints ?? []);

    // Store analysis data
    _shotAnalysisData[shotNumber ?? 0] = {
      'stabilityScore':
          _calculateShotScore(tracePoints ?? [], shotTrace.maxMagnitude ?? 0),
      'centerPoint': _calculateCenterPoint(tracePoints ?? []),
      'movementRange': _calculateMovementRange(tracePoints ?? []),
      'stabilityZones': _stabilityZonePoints,
      'preShotStability': _calculatePreShotStability(tracePoints ?? []),
      'postShotRecovery': _calculatePostShotRecovery(tracePoints ?? []),
    };
  }

  List<streaming.TracePoint> _calculateStabilityZones(
      List<streaming.TracePoint> tracePoints) {
    return tracePoints
        .where((point) {
          final magnitude = (point.point.x.abs() + point.point.y.abs()) / 2;
          return magnitude < 0.5;
        })
        .map((point) => streaming.TracePoint(
              streaming.Point3D(point.point.x, point.point.y, point.point.z),
              point.phase,
            ))
        .toList();
  }

  Map<String, double> _calculateCenterPoint(
      List<streaming.TracePoint> tracePoints) {
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

  Map<String, double> _calculateMovementRange(
      List<streaming.TracePoint> tracePoints) {
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

  double _calculatePreShotStability(List<streaming.TracePoint> tracePoints) {
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

  double _calculatePostShotRecovery(List<streaming.TracePoint> tracePoints) {
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

  void _stepForward(AnalysisModel analysisModel) {
    final selectedShot = analysisModel.tracePoints ?? [];

    if (selectedShot.isNotEmpty) {
      final tracePoints = selectedShot;
      final totalPoints = tracePoints.length;

      if (_currentAnimatedPoints < totalPoints) {
        setState(() {
          _currentAnimatedPoints =
              (_currentAnimatedPoints + 10).clamp(0, totalPoints).toInt();
        });
      }
    }
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

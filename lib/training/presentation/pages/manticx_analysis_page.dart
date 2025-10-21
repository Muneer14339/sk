import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_dialog.dart';
import '../../../core/widgets/icon_container.dart';
import '../../data/model/analysis_model.dart';
import '../../data/model/streaming_model.dart' as streaming;
import '../../data/models/saved_session_model.dart';
import '../bloc/training_session/training_session_bloc.dart';
import '../bloc/training_session/training_session_event.dart';
import '../bloc/training_session/training_session_state.dart';
import '../widgets/shot_details_content.dart';
import '../widgets/target_rings.dart';
import '../widgets/trace_painter.dart';


class ManticXAnalysisPage extends StatefulWidget {
  const ManticXAnalysisPage({super.key});
  @override
  State<ManticXAnalysisPage> createState() => _ManticXAnalysisPageState();
}

class _ManticXAnalysisPageState extends State<ManticXAnalysisPage>
    with TickerProviderStateMixin {
  Timer? _animationTimer;
  late AnimationController _pulseController;
  int _currentAnimatedPoints = 0;
  int _selectedShotNumber = -1;
  bool _isPlaying = false;
  bool _isPaused = false;
  final double _playbackSpeed = 0.5;
  final Map<int, Map<String, dynamic>> _shotAnalysisData = {};
  List<streaming.TracePoint> _stabilityZonePoints = [];
  // NEW: Add zoom state
  bool _zoomEnabled = false;

  // Add after _selectedShotNumber declaration
  bool _isMissedShot = false; // NEW: Track if selected shot is missed

  // NEW: Toggle zoom method
  void _toggleZoom() {
    setState(() {
      _zoomEnabled = !_zoomEnabled;
    });
  }

  @override
  void initState() {
    super.initState();
    _pulseController =
        AnimationController(duration: const Duration(seconds: 2), vsync: this);

    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final SavedSessionModel? savedSession ;
    final int? initialShotNumber;
    if (args is Map) {
      savedSession = args['savedSession'] as SavedSessionModel?;
      initialShotNumber = args['selectedShotNumber'] as int?;
    } else {
      savedSession = args is SavedSessionModel ? args : null;
      initialShotNumber = null;
    }

    return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;

          if (savedSession == null) {
            showDialog(
              context: context,
              builder: (context) {
                return SimpleCustomDialog(
                  title: 'Save Session',
                  content: 'Do you want to save this session?',
                  positiveButtonLabel: 'Save',
                  negativeButtonLabel: 'Cancel',
                  onPositive: () {
                    context.read<TrainingSessionBloc>().add(SaveSession());
                    Navigator.pop(context); // close dialog
                    Navigator.pop(context); // close page
                  },
                  onNegative: () {
                    Navigator.pop(context); // close dialog
                    Navigator.pop(context); // close page
                  },
                );
              },
            );
          } else {
            Navigator.pop(context);
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.kBackground,
          appBar: _buildModernAppBar(savedSession: savedSession),
          body: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: BlocConsumer<TrainingSessionBloc, TrainingSessionState>(
                  listener: (context, trainingState) {
                    if (trainingState.isSessionSaved ?? false) {
                      showDialog(
                          context: context,
                          builder: (context) {
                            return CustomDialog(
                              title: 'Session Saved',
                              content:
                                  'Your session has been saved successfully.',
                              onNewSession: () {
                                Navigator.pop(context);
                                Navigator.pop(context);
                              },
                              onBack: () {
                                Navigator.pop(context);
                                Navigator.pop(context);
                              },
                            );
                          });
                    }
                  },
                  // Update build method's BlocConsumer builder
                  builder: (context, trainingState) {
                    final shotTraces = savedSession?.sessionShotTraces ??
                        trainingState.sessionShotTraces;
                    final steadinessShots = savedSession?.steadinessShots ??
                        trainingState.steadinessShots;
                    final missedShots = savedSession?.missedShotNumbers ??
                        trainingState.missedShotNumbers;

                    final allShotNumbers = <int>{
                      ...steadinessShots.map((s) => s.shotNumber),
                      ...missedShots,
                    }.toList()..sort();

                    final analysisModels =
                    _convertSteadinessShotsToShotTraces(steadinessShots);

                    // NEW: Set initial shot number
                    if (_selectedShotNumber == -1 && allShotNumbers.isNotEmpty) {
                      _selectedShotNumber = initialShotNumber ?? allShotNumbers.first;
                      _isMissedShot = missedShots.contains(_selectedShotNumber);

                      // Auto-start animation for initially selected shot
                      if (!_isMissedShot) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          final matchingShots = analysisModels
                              .where((e) => e.shotNumber == _selectedShotNumber)
                              .toList();
                          if (matchingShots.isNotEmpty) {
                            _startTraceAnimation(matchingShots.first.tracePoints ?? []);
                            _analyzeShotData(matchingShots.first);
                          }
                        });
                      }
                    }

                    final analysisModel =
                        _selectedShotNumber != -1 && !_isMissedShot // NEW
                            ? analysisModels.firstWhere(
                                (e) => e.shotNumber == _selectedShotNumber,
                                orElse: () =>
                                    analysisModels.first) // NEW: Add fallback
                            : null;

                    // NEW: Wrap in Stack HERE (inside builder where analysisModel exists)
                    return Column(children: [
                      _buildShotSelectionRow(allShotNumbers, missedShots,
                          steadinessShots), // NEW: Pass steadinessShots // NEW
                      SizedBox(height: 16),
                      _buildZoomableTarget(analysisModel),
                      SizedBox(height: 16),
                      _buildPlaybackControls(analysisModel ?? AnalysisModel()),
                    ]);
                  },
                ),
              ),
            ],
          ),
        ));
  }

  // NEW: Zoomable target method (similar to session_details_page)
  // Update _buildZoomableTarget to handle missed shots
  Widget _buildZoomableTarget(AnalysisModel? analysisModel) {
    // NEW: Check for missed shot first
    if (_isMissedShot) return _buildMissedShotDisplay();
    if (analysisModel == null) return _buildEmptyTarget();

    final tracePoints = _getAnimatedTracePoints(analysisModel);

    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
        ),
        child: InteractiveViewer(
          minScale: 1.0,
          maxScale: 6.0,
          boundaryMargin: EdgeInsets.zero,
          child: Stack(
            alignment: Alignment.center,
            children: [
              _buildTargetRings(),
              if (tracePoints.isNotEmpty)
                Positioned.fill(
                  child: CustomPaint(
                    painter: TracePainter(
                      tracePoints,
                      showCurrentPositionMarker: false,
                      showShotPointMarker: true,
                      animateCurrentMarker: false,
                      currentMarkerSize: 12.0,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

// Update _buildMissedShotDisplay with new message
  Widget _buildMissedShotDisplay() => Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '⚠ Missing Shot',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.kTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This shot wasn\'t detected or saved. It may have landed outside the target area, been a dry press, or the detection threshold was set too high.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: AppColors.kTextSecondary,
              ),
            ),
          ],
        ),
      );

  PreferredSizeWidget _buildModernAppBar({SavedSessionModel? savedSession}) =>
      PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.kSurface,
                    AppColors.kPrimaryTeal.withValues(alpha: .12)
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: .35),
                      blurRadius: 20,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                          icon: Icon(Icons.arrow_back_ios,
                              color: AppColors.kTextPrimary, size: 20),
                          onPressed: () {
                            if (savedSession == null) {
                              showDialog(
                                  context: context,
                                  builder: (context) {
                                    return SimpleCustomDialog(
                                      title: 'Save Session',
                                      content:
                                          'Do you want to save this session?',
                                      positiveButtonLabel: 'Save',
                                      negativeButtonLabel: 'Cancel',
                                      onPositive: () {
                                        context
                                            .read<TrainingSessionBloc>()
                                            .add(SaveSession());
                                        Navigator.pop(context);
                                        Navigator.pop(context);
                                      },
                                      onNegative: () {
                                        Navigator.pop(context);
                                        Navigator.pop(context);
                                      },
                                    );
                                  });
                            } else {
                              Navigator.pop(context);
                            }
                          },
                          style: IconButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              padding: const EdgeInsets.all(12))),
                      const SizedBox(width: 16),
                      Text('Precision Analysis',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.kTextPrimary
                                  .withValues(alpha: .9))),
                    ],
                  ),
                ),
              )));

  // Update _buildShotSelectionRow signature aur implementation
  Widget _buildShotSelectionRow(
    List<int> allShots,
    List<int> missedShots,
    List<dynamic> steadinessShots, // NEW: Add parameter
  ) {
    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: allShots.length,
        itemBuilder: (_, i) {
          final shotNumber = allShots[i];
          final isSelected = _selectedShotNumber == shotNumber;
          final isMissed = missedShots.contains(shotNumber);

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedShotNumber = shotNumber;
                _isMissedShot = isMissed;
                _currentAnimatedPoints = 0;
                _isPlaying = false;
                _isPaused = false;
              });

              // FIX: Use passed steadinessShots instead of bloc state
              if (!isMissed) {
                final analysisModels = _convertSteadinessShotsToShotTraces(
                    steadinessShots); // NEW: Use passed parameter

                // FIX: Add safe check
                final matchingShots = analysisModels
                    .where((e) => e.shotNumber == shotNumber)
                    .toList();

                if (matchingShots.isNotEmpty) {
                  final analysisModel = matchingShots.first;
                  _startTraceAnimation(analysisModel.tracePoints ?? []);
                  _analyzeShotData(analysisModel);
                }
              }
            },
            child: Container(
              width: 64,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isMissed // NEW: Different color for missed
                        ? AppColors.appYellow.withValues(alpha: .2)
                        : AppColors.kPrimaryTeal.withValues(alpha: .2))
                    : AppColors.kSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? (isMissed
                          ? AppColors.appYellow
                          : const Color(0xFF00CED1))
                      : Colors.white10,
                ),
              ),
              child: Column(
                // NEW: Show icon for missed shots
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isMissed) // NEW
                    Icon(Icons.close,
                        color:
                            isSelected ? AppColors.appYellow : Colors.white54,
                        size: 16),
                  Text(
                    shotNumber.toString(),
                    style: TextStyle(
                      color: isSelected
                          ? (isMissed
                              ? AppColors.appYellow
                              : const Color(0xFF00CED1))
                          : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) => Row(children: [
        IconContainer(icon: Icons.analytics_outlined),
        const SizedBox(width: 12),
        Expanded(
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
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.kTextSecondary.withValues(alpha: 0.72),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ))
      ]);

  BoxDecoration _buildModernCardDecoration() => BoxDecoration(
        color: AppColors.kSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.04),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.32),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      );

  Widget _buildTargetDisplay(AnalysisModel? analysisModel) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (analysisModel != null ||
              _isMissedShot) // NEW: Show header even for missed
            _buildSectionHeader(
                'Target Analysis',
                _isMissedShot
                    ? 'Shot missed'
                    : 'Live traceline visualization'), // NEW
          Container(
            decoration: _buildModernCardDecoration(),
            margin: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                // NEW: Show different content for missed shots
                _isMissedShot
                    ? _buildMissedShotDisplay() // NEW
                    : (analysisModel != null
                        ? _buildTargetWithTraceline(analysisModel)
                        : _buildEmptyTarget()),
                // NEW: Don't show playback controls for missed shots
                if (analysisModel != null && !_isMissedShot) ...[
                  Divider(
                      height: 1, color: Colors.white.withValues(alpha: 0.06)),
                  _buildPlaybackControls(analysisModel),
                ],
              ],
            ),
          ),
        ],
      );

  Widget _buildPlaybackControls(AnalysisModel analysisModel) {
    final tracePoints = analysisModel.tracePoints;
    final totalPoints = tracePoints?.length ?? 0;
    final progress =
        totalPoints > 0 ? _currentAnimatedPoints / totalPoints : 0.0;

    return Container(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          // Enhanced Progress Bar
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress: ${(progress * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                          color: AppColors.kTextPrimary.withValues(alpha: .86),
                          fontSize: 12),
                    ),
                    Text(
                      '$_currentAnimatedPoints/$totalPoints points',
                      style: TextStyle(
                          color: AppColors.kTextPrimary.withValues(alpha: .66),
                          fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.kPrimaryTeal,
                            AppColors.kPrimaryTeal.withValues(alpha: .9)
                          ],
                        ),
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: [
                          BoxShadow(
                            color:
                                AppColors.kPrimaryTeal.withValues(alpha: .28),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Modern Controls
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            //_buildModernSpeedControl(),
            const SizedBox(width: 16),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildModernControlButton(
                    Icons.skip_previous,
                    _isPlaying || _isPaused
                        ? AppColors.kTextPrimary.withValues(alpha: .66)
                        : AppColors.kTextPrimary,
                    () => _stepBackward(),
                    size: 46,
                  ),
                  _buildModernPlayButton(analysisModel),
                  _buildModernControlButton(
                    Icons.skip_next,
                    _isPlaying || _isPaused
                        ? AppColors.kTextPrimary.withValues(alpha: .66)
                        : AppColors.kTextPrimary,
                    () => _stepForward(analysisModel),
                    size: 46,
                  ),
                ],
              ),
            ),
          ])
        ]));
  }

  Widget _buildModernPlayButton(AnalysisModel analysisModel) => GestureDetector(
        onTap: () {
          if (_isPlaying) {
            _pauseAnimation();
          } else if (_isPaused) {
            _resumeAnimation(analysisModel);
          } else {
            _restartAnimation(analysisModel);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isPlaying
                  ? [AppColors.kError, AppColors.kError.withValues(alpha: .9)]
                  : _isPaused
                      ? [
                          AppColors.kPrimaryTeal.withValues(alpha: .95),
                          AppColors.kPrimaryTeal.withValues(alpha: .8)
                        ]
                      : [
                          AppColors.kPrimaryTeal,
                          AppColors.kPrimaryTeal.withValues(alpha: .9)
                        ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (_isPlaying
                        ? AppColors.kError
                        : _isPaused
                            ? AppColors.kPrimaryTeal
                            : AppColors.kSuccess)
                    .withValues(alpha: .36),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            _isPlaying ? Icons.pause : Icons.play_arrow,
            color: AppColors.kTextPrimary,
            size: 24,
          ),
        ),
      );

  Widget _buildModernControlButton(
          IconData icon, Color color, VoidCallback onTap,
          {double size = 40}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: .06)),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      );
  // UPDATE: Modify _buildTargetWithTraceline to add zoom button
  Widget _buildTargetWithTraceline(AnalysisModel analysisModel) {
    final tracePoints = _getAnimatedTracePoints(analysisModel);
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
        ),
        child: GestureDetector(
          onTap: () {
            // if (_isPlaying) {
            //   _pauseAnimation();
            // } else if (_isPaused) {
            //   _resumeAnimation(analysisModel);
            // } else {
            //   _restartAnimation(analysisModel);
            // }
          },
          onDoubleTap: _toggleZoom,
          onHorizontalDragUpdate: (details) {
            if (!_zoomEnabled) {
              _toggleZoom();
            }
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              _buildTargetRings(),
              if (tracePoints.isNotEmpty)
                Positioned.fill(
                  child: CustomPaint(
                    painter: TracePainter(
                      tracePoints,
                      showCurrentPositionMarker: false,
                      showShotPointMarker: true,
                      animateCurrentMarker: false,
                      currentMarkerSize: 12.0,
                    ),
                  ),
                ),
              // NEW: Add zoom button (top right corner)
              Positioned(
                top: 5,
                right: 5,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(
                      _zoomEnabled ? Icons.zoom_in_map : Icons.zoom_out_map,
                      size: 20,
                      color: const Color(0xFF17A2B8),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: _toggleZoom,
                    tooltip: "Zoom Toggle",
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyTarget() => AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.kPrimaryTeal.withValues(alpha: .04),
                Colors.transparent,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: .06)),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .03),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.kTextSecondary.withValues(alpha: .08),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.touch_app_outlined,
                    size: 48,
                    color: AppColors.kTextSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Select a Shot',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.kTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap any shot above to view detailed traceline analysis',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.kTextSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildTargetRings() => const SizedBox.expand(
        child: StaticTargetRings(ringCount: 6),
      );


  // Keep all existing functionality methods unchanged...
  List<streaming.TracePoint> _getAnimatedTracePoints(AnalysisModel shotTrace) {
    final tracePoints = shotTrace.tracePoints;

    if (tracePoints == null || tracePoints.isEmpty) {
      return [];
    }

    try {
      final allPoints = tracePoints
          .map((point) {
            double x, y, z;
            final internalX = point.point.x.toDouble();
            final internalY = point.point.y.toDouble();
            x = ((internalX - 200) / 200) * 4.5;
            y = ((internalY - 200) / 200) * 4.5;
            z = point.point.z.toDouble();
            return streaming.TracePoint(
                streaming.Point3D(x, y, z), point.phase);
          })
          .cast<streaming.TracePoint>()
          .toList();

      final animatedPoints = allPoints.take(_currentAnimatedPoints).toList();

      return animatedPoints;
    } catch (e) {
      return [];
    }
  }

  void _startTraceAnimation(List<streaming.TracePoint> shotTrace) {
    _animationTimer?.cancel();
    if (shotTrace.isEmpty) return;

    setState(() {
      _isPlaying = true;
      _isPaused = false;
    });

    final totalPoints = shotTrace.length;
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

  List<AnalysisModel> _convertSteadinessShotsToShotTraces(
          List<dynamic> steadinessShots) =>
      steadinessShots
          .map((shot) => AnalysisModel(
                shotNumber: shot.shotNumber,
                timestamp: shot.timestamp,
                maxMagnitude: shot.thetaDot / 10.0,
                tracePoints: shot.tracelinePoints,
                score: shot.score,
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
              ))
          .toList();

  void _analyzeShotData(AnalysisModel shotTrace) {
    final shotNumber = shotTrace.shotNumber;
    final tracePoints = shotTrace.tracePoints;

    if (tracePoints?.isEmpty ?? false) return;

    _stabilityZonePoints = _calculateStabilityZones(tracePoints!);
    _shotAnalysisData[shotNumber ?? 0] = {
      'stabilityScore': ShotDetailsContent.calculateShotScore(
          tracePoints, shotTrace.maxMagnitude ?? 0),
      'centerPoint': _calculateCenterPoint(tracePoints),
      'movementRange': _calculateMovementRange(tracePoints),
      'stabilityZones': _stabilityZonePoints,
      'preShotStability': _calculatePreShotStability(tracePoints),
      'postShotRecovery': _calculatePostShotRecovery(tracePoints),
    };
  }

  List<streaming.TracePoint> _calculateStabilityZones(
          List<streaming.TracePoint> tracePoints) =>
      tracePoints
          .where(
              (point) => (point.point.x.abs() + point.point.y.abs()) / 2 < 0.5)
          .map((point) => streaming.TracePoint(
              streaming.Point3D(point.point.x, point.point.y, point.point.z),
              point.phase))
          .toList();

  Map<String, double> _calculateCenterPoint(
      List<streaming.TracePoint> tracePoints) {
    double centerX = 0.0, centerY = 0.0;
    for (var point in tracePoints) {
      centerX += point.point.x;
      centerY += point.point.y;
    }
    return {
      'x': centerX / tracePoints.length,
      'y': centerY / tracePoints.length
    };
  }

  Map<String, double> _calculateMovementRange(
      List<streaming.TracePoint> tracePoints) {
    double minX = double.infinity,
        maxX = -double.infinity,
        minY = double.infinity,
        maxY = -double.infinity;
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
      'rangeY': maxY - minY
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

    int stablePoints = 0;
    for (var point in postShotPoints) {
      final magnitude = (point.point.x.abs() + point.point.y.abs()) / 2;
      if (magnitude < 0.5) stablePoints++;
    }

    return (stablePoints / postShotPoints.length) * 100;
  }

  void _stepBackward() {
    if (_currentAnimatedPoints > 0) {
      setState(() => _currentAnimatedPoints =
          (_currentAnimatedPoints - 10).clamp(0, 1000));
    }
  }

  void _stepForward(AnalysisModel analysisModel) {
    final selectedShot = analysisModel.tracePoints ?? [];
    if (selectedShot.isNotEmpty) {
      final totalPoints = selectedShot.length;
      if (_currentAnimatedPoints < totalPoints) {
        setState(() => _currentAnimatedPoints =
            (_currentAnimatedPoints + 10).clamp(0, totalPoints).toInt());
      }
    }
  }
}

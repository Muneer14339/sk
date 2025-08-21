// lib/features/training/presentation/pages/session_details_page.dart - BLoC Refactored Version
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pulse_skadi/core/theme/app_colors.dart';
import 'package:pulse_skadi/features/training/presentation/bloc/session_details/session_details_bloc.dart';
import 'package:pulse_skadi/features/training/presentation/bloc/session_details/session_details_event.dart';
import 'package:pulse_skadi/features/training/presentation/bloc/session_details/session_details_state.dart';
import 'package:pulse_skadi/features/training/presentation/bloc/training_session/training_session_bloc.dart';
import 'package:pulse_skadi/features/training/presentation/widgets/trace_painter.dart';
import 'package:pulse_skadi/features/training/data/model/streaming_model.dart'
    as streaming;
import 'package:pulse_skadi/features/training/domain/entities/session_details_entity.dart';
import 'dart:async';

// --- Session Detail Page Widget ---
class SessionDetailPage extends StatelessWidget {
  final String sessionId;

  const SessionDetailPage({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context) {
    // Use the global SessionDetailsBloc provider
    final bloc = context.read<SessionDetailsBloc>();
    bloc.add(LoadSessionDetails(sessionId));
    return const _SessionDetailPageView();
  }
}

class _SessionDetailPageView extends StatefulWidget {
  const _SessionDetailPageView();

  @override
  State<_SessionDetailPageView> createState() => _SessionDetailPageViewState();
}

class _SessionDetailPageViewState extends State<_SessionDetailPageView> {
  Timer? _animationTimer;
  int _currentAnimatedPoints = 0;
  int _lastSelectedShotId = -1;
  bool _isPlaying = false;
  bool _isPaused = false;

  bool _zoomEnabled = false;
  void _toggleZoom() {
    setState(() {
      _zoomEnabled = !_zoomEnabled;
    });
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    super.dispose();
  }

  void _pauseAnimation() {
    setState(() {
      _isPaused = true;
      _isPlaying = false;
    });
    _animationTimer?.cancel();
  }

  void _resumeAnimation() {
    if (_isPaused && _lastSelectedShotId != -1) {
      setState(() {
        _isPaused = false;
        _isPlaying = true;
      });
      _startTraceAnimation(context, _lastSelectedShotId, resume: true);
    }
  }

  void _restartAnimation() {
    if (_lastSelectedShotId != -1) {
      setState(() {
        _isPaused = false;
        _isPlaying = true;
      });
      _startTraceAnimation(context, _lastSelectedShotId, restart: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8f9fa),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          backgroundColor: const Color(0xff2c3e50),
          foregroundColor: Colors.white,
          title: const Text('Session Detail'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
            style: IconButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.upload_file),
              onPressed: () {},
              style: IconButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
      body: BlocBuilder<SessionDetailsBloc, SessionDetailsState>(
        builder: (context, state) {
          if (state is SessionDetailsLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is SessionDetailsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${state.message}',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<SessionDetailsBloc>().add(
                            LoadSessionDetails('session1'),
                          );
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else if (state is SessionDetailsLoaded) {
            return _buildLoadedContent(context, state);
          } else if (state is SessionDetailsExporting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Exporting session data...'),
                ],
              ),
            );
          } else if (state is SessionDetailsSharing) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Sharing session results...'),
                ],
              ),
            );
          }
          return const Center(child: Text('Unknown state'));
        },
      ),
    );
  }

  Widget _buildLoadedContent(BuildContext context, SessionDetailsLoaded state) {
    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSessionHeaderCard(context, state),
                    const SizedBox(height: 20),
                    _buildViewTabs(context, state),
                    const SizedBox(height: 20),
                    _buildViewContent(context, state),
                    _buildExportOptions(context, state),
                  ],
                ),
              ),
            ),
          ],
        ),
        // Zoom Mode Overlay
        if (_zoomEnabled)
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggleZoom, // kahin bhi tap karoge to zoom toggle
              behavior: HitTestBehavior
                  .translucent, // invisible areas pe bhi tap capture karega
              child: Container(
                color: Colors.black.withOpacity(0.3), // dim effect
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: Center(
                    child: GestureDetector(
                      onTap: () {}, // Center widget pe tap zoom toggle na ho
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: _buildTargetDisplay(context, state),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSessionHeaderCard(
      BuildContext context, SessionDetailsLoaded state) {
    final sessionDetails = state.sessionDetails;

    // Get actual shot count from training session
    final trainingState = context.read<TrainingSessionBloc>().state;
    final actualShotCount = trainingState.sessionShotTraces.isNotEmpty
        ? trainingState.sessionShotTraces.length
        : sessionDetails.totalShots;

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${sessionDetails.programName} Session',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xff2c3e50),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${sessionDetails.sessionDate.toString().split(' ')[0]} • $actualShotCount shots • ${sessionDetails.duration}',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xff6c757d),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildSessionBadge('Personal Best', const Color(0xff28a745)),
              const SizedBox(width: 8),
              _buildSessionBadge('Target Met', const Color(0xff17a2b8)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSessionBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Widget _buildViewTabs(BuildContext context, SessionDetailsLoaded state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildViewTab(context, 'Overview', 'overview', state.currentView),
        _buildViewTab(context, 'Shot Analysis', 'shots', state.currentView),
        _buildViewTab(context, 'Timeline', 'timeline', state.currentView),
      ],
    );
  }

  Widget _buildViewTab(
      BuildContext context, String label, String viewName, String currentView) {
    final isActive = currentView == viewName;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          context.read<SessionDetailsBloc>().add(ChangeView(viewName));
        },
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? const Color(0xff2c3e50) : const Color(0xff6c757d),
          ),
        ),
      ),
    );
  }

  Widget _buildViewContent(BuildContext context, SessionDetailsLoaded state) {
    switch (state.currentView) {
      case 'overview':
        return _buildOverviewContent(context, state);
      case 'shots':
        return _buildShotAnalysisContent(context, state);
      case 'timeline':
        return _buildTimelineContent(context, state);
      default:
        return Container();
    }
  }

  Widget _buildOverviewContent(
      BuildContext context, SessionDetailsLoaded state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildProgramMetricsSection(context, state),
        const SizedBox(height: 20),
        _buildStandardMetricsGrid(context, state),
        const SizedBox(height: 20),
        _buildAIInsightsSection(context, state),
      ],
    );
  }

  Widget _buildProgramMetricsSection(
      BuildContext context, SessionDetailsLoaded state) {
    final sessionDetails = state.sessionDetails;
    return Container(
      padding: const EdgeInsets.all(15.0),
      decoration: BoxDecoration(
        color: const Color(0xffe8f4f8),
        border: Border.all(color: const Color(0xff17a2b8), width: 2),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart, color: Color(0xff0c5460), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Program Metrics: ${sessionDetails.programName}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff0c5460),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children:
                sessionDetails.metrics.programMetrics.entries.map((entry) {
              return Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: const Color(0xffb3d7e6), width: 1),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(
                        color: Color(0xff6c757d),
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${entry.value.round()}%',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff0c5460),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 15),
          _buildSuccessSummary(context, state),
        ],
      ),
    );
  }

  Widget _buildSuccessSummary(
      BuildContext context, SessionDetailsLoaded state) {
    final isSuccess = state.sessionDetails.isSuccess;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSuccess ? const Color(0xffd4edda) : const Color(0xfff8d7da),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSuccess ? const Color(0xff28a745) : const Color(0xffdc3545),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSuccess ? Icons.check_circle_outline : Icons.cancel_outlined,
                color: isSuccess
                    ? const Color(0xff28a745)
                    : const Color(0xffdc3545),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isSuccess ? 'Success!' : 'Target Not Met',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSuccess
                      ? const Color(0xff28a745)
                      : const Color(0xffdc3545),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStandardMetricsGrid(
      BuildContext context, SessionDetailsLoaded state) {
    final metrics = state.sessionDetails.metrics;
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 1.2,
      ),
      children: [
        _buildMetricCard('${metrics.averageScore.round()}', 'Average Score',
            '+5 from last session', true),
        _buildMetricCard('${metrics.successRate.round()}%', 'Success Rate',
            'Target achieved', true),
        _buildMetricCard(metrics.groupSize.toStringAsFixed(1),
            'Group Size (mm)', '-3.5mm tighter', true),
        _buildMetricCard('12m', 'Session Duration', 'Efficient pace', true),
      ],
    );
  }

  Widget _buildMetricCard(
      String value, String label, String changeText, bool isPositiveChange) {
    return Container(
      padding: const EdgeInsets.all(15.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Color(0xff2c3e50),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xff6c757d),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            changeText,
            style: TextStyle(
              fontSize: 12,
              color: isPositiveChange
                  ? const Color(0xff28a745)
                  : const Color(0xffdc3545),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIInsightsSection(
      BuildContext context, SessionDetailsLoaded state) {
    return Container(
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: const Color(0xff343a40).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🤖', style: TextStyle(fontSize: 20)),
              SizedBox(width: 10),
              Text(
                'ShoQ AI Analysis',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            state.sessionDetails.aiInsights,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildShotAnalysisContent(
      BuildContext context, SessionDetailsLoaded state) {
    // Get actual shot traces from training session
    final trainingState = context.read<TrainingSessionBloc>().state;
    final shotTraces = trainingState.sessionShotTraces;

    // Use actual shots from training session if available, otherwise fallback to session details
    final shots = shotTraces.isNotEmpty
        ? shotTraces.asMap().entries.map((entry) {
            final index = entry.key;
            final trace = entry.value;
            return ShotDetailsEntity(
              id: trace.shotNumber,
              x: 140.0 + (index * 2.0), // Mock position for now
              y: 140.0 + (index * 1.5),
              score: 10, // Mock score for now
              timestamp: trace.timestamp,
              metrics: trace.metrics.map((key, value) {
                if (value is num) {
                  return MapEntry(key, value.toDouble());
                } else if (value is bool) {
                  return MapEntry(key, value ? 1.0 : 0.0);
                } else if (value is String) {
                  return MapEntry(key, 0.0); // Default for string values
                } else {
                  return MapEntry(key, 0.0); // Default for other types
                }
              }),
              hasTraceData: true,
            );
          }).toList()
        : state.sessionDetails.shots;

    final selectedShot = state.selectedShotId != null
        ? shots.firstWhere((shot) => shot.id == state.selectedShotId)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildShotSelectionRow(context, state),
        const SizedBox(height: 15),
        _buildTraceStatusIndicator(context, state),
        const SizedBox(height: 15),
        _buildTargetDisplay(context, state),
        const SizedBox(height: 15),
        _buildShotInfoPanel(context, selectedShot, state),
      ],
    );
  }

  Widget _buildShotSelectionRow(
      BuildContext context, SessionDetailsLoaded state) {
    // Get actual shot traces from training session
    final trainingState = context.read<TrainingSessionBloc>().state;
    final shotTraces = trainingState.sessionShotTraces;

    // Use actual shots from training session if available, otherwise fallback to session details
    final shots = shotTraces.isNotEmpty
        ? shotTraces.asMap().entries.map((entry) {
            final index = entry.key;
            final trace = entry.value;
            return ShotDetailsEntity(
              id: trace.shotNumber,
              x: 140.0 + (index * 2.0), // Mock position for now
              y: 140.0 + (index * 1.5),
              score: 10, // Mock score for now
              timestamp: trace.timestamp,
              metrics: trace.metrics.map((key, value) {
                if (value is num) {
                  return MapEntry(key, value.toDouble());
                } else if (value is bool) {
                  return MapEntry(key, value ? 1.0 : 0.0);
                } else if (value is String) {
                  return MapEntry(key, 0.0); // Default for string values
                } else {
                  return MapEntry(key, 0.0); // Default for other types
                }
              }),
              hasTraceData: true,
            );
          }).toList()
        : [];

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff2c3e50), Color(0xff34495e)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SELECT SHOT TO VIEW TRACELINE',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold)),
          Text('${shots.length} SHOTS',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: shots.length,
              itemBuilder: (context, index) {
                final shot = shots[index];
                final isSelected = state.selectedShotId == shot.id;
                final shotColor = _getShotColor(shot.score);

                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () {
                      context
                          .read<SessionDetailsBloc>()
                          .add(SelectShot(shot.id));
                      _startTraceAnimation(context, shot.id, restart: true);
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
                          if (shot.hasTraceData)
                            BoxShadow(
                              color: const Color(0xff17a2b8)
                                  .withValues(alpha: 0.6),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
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
                          Text(
                            '${shot.id}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (shot.hasTraceData)
                            Positioned(
                                top: 2,
                                right: 2,
                                child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                        color: Color(0xff17a2b8),
                                        shape: BoxShape.circle))),
                          if (isSelected)
                            Positioned(
                              bottom: 2,
                              child: Container(
                                width: 20,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(2),
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

  Color _getShotColor(int score) {
    if (score >= 10) return const Color(0xff28a745);
    if (score >= 9) return const Color(0xffffc107);
    if (score >= 8) return const Color(0xfffd7e14);
    return const Color(0xffdc3545);
  }

  Widget _buildTraceStatusIndicator(
      BuildContext context, SessionDetailsLoaded state) {
    final selectedShotId = state.selectedShotId;
    final hasTraceData = selectedShotId != null &&
        _getActualTracePoints(context, selectedShotId).isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasTraceData ? const Color(0xffd1ecf1) : const Color(0xfff8d7da),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              hasTraceData ? const Color(0xff17a2b8) : const Color(0xffdc3545),
        ),
      ),
      child: Row(
        children: [
          Icon(hasTraceData ? Icons.timeline : Icons.info_outline,
              color: hasTraceData
                  ? const Color(0xff17a2b8)
                  : const Color(0xffdc3545),
              size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hasTraceData
                  ? '🎯 Shot #$selectedShotId traceline is displayed below with ${_getActualTracePoints(context, selectedShotId).length}/${_getTotalPointsForShot(context, selectedShotId)} trace points${_currentAnimatedPoints > 0 ? ' (animating...)' : ''}'
                  : selectedShotId != null
                      ? '⚠️ No trace data available for Shot #$selectedShotId'
                      : '👆 Select a shot from the list above to view its stored traceline',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: hasTraceData
                    ? const Color(0xff17a2b8)
                    : const Color(0xffdc3545),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetDisplay(BuildContext context, SessionDetailsLoaded state) {
    var points, preShotCount, shotCount, postShotCount;
    if (state.selectedShotId != null) {
      points = _getActualTracePoints(context, state.selectedShotId!);
      // Count points by phase for debugging
      preShotCount =
          points.where((tp) => tp.phase == streaming.TracePhase.preShot).length;
      shotCount =
          points.where((tp) => tp.phase == streaming.TracePhase.shot).length;
      postShotCount = points
          .where((tp) => tp.phase == streaming.TracePhase.postShot)
          .length;
    }

    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          double previousScale = 1.0;
          return GestureDetector(
            onDoubleTap: _toggleZoom,
            onScaleUpdate: (details) {
              if (details.scale < previousScale) {
                // Zoom out detected
                _toggleZoom();
              } else if (details.scale > previousScale) {
                // Zoom in detected
                _toggleZoom();
              }
              previousScale = details.scale; // Update for next frame
            },
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                    color: state.selectedShotId != null &&
                            _getActualTracePoints(
                                    context, state.selectedShotId!)
                                .isNotEmpty
                        ? const Color(0xff17a2b8)
                        : const Color(0xffe9ecef),
                    width: state.selectedShotId != null &&
                            _getActualTracePoints(
                                    context, state.selectedShotId!)
                                .isNotEmpty
                        ? 3
                        : 1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: CustomPaint(painter: CrosshairPainter()),
                  ),
                  if (state.selectedShotId == null)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.touch_app,
                                size: 48,
                                color: Color(0xff6c757d),
                              ),
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
                    ),
                  _zoomEnabled
                      ? zoomAbleTargetRigns(state)
                      : _buildTargetRings(state),
                  if (state.selectedShotId != null)
                    Positioned(
                        top: 5,
                        left: 5,
                        child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                                'Trace: Pre($preShotCount) + Shot($shotCount) + Post($postShotCount)',
                                style: const TextStyle(
                                    color: Color(0xFF17A2B8),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)))),
                  if (state.selectedShotId != null)
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
                                  _zoomEnabled
                                      ? Icons.zoom_in_map
                                      : Icons.zoom_out_map,
                                  size: 20,
                                  color: const Color(0xFF17A2B8),
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: _toggleZoom, // same function
                                tooltip: "Zoom Toggle"))),
                  const SizedBox(height: 8),
                  Positioned(
                      bottom: 4,
                      left: 4,
                      child: GestureDetector(
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
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color:
                                AppColors.kPrimaryColor.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            _isPlaying
                                ? Icons.pause
                                : _isPaused
                                    ? Icons.play_arrow
                                    : Icons.replay,
                            color: AppColors.white,
                            size: 20,
                          ),
                        ),
                      ))
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTargetRings(SessionDetailsLoaded state) {
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
          if (state.selectedShotId != null)
            Positioned.fill(
                child: Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                              color: const Color(0xff17a2b8)
                                  .withValues(alpha: 0.2),
                              blurRadius: 8,
                              spreadRadius: 2)
                        ]),
                    child: CustomPaint(
                        painter: TracePainter(
                      _getActualTracePoints(context, state.selectedShotId!),
                      smoothingFactor:
                          0.4, // Higher smoothing for historical data
                      enableInterpolation: true,
                      interpolationPoints:
                          3, // More interpolation for historical data
                      enableVelocityBasedSmoothing:
                          true, // Enable velocity-based smoothing
                      enableAdaptiveThickness:
                          true, // Enable adaptive line thickness
                      movementDampening:
                          0.3, // Moderate dampening for historical data
                      responseDelay: 0.2, // Moderate delay for historical data
                      targetRadius: 1.0, // Full target area
                    )))),
          // Play/Pause controls
          if (state.selectedShotId != null)
            Positioned(
              bottom: 20,
              right: 20,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Progress indicator
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '$_currentAnimatedPoints/${_getTotalPointsForShot(context, state.selectedShotId!)}',
                      style: const TextStyle(
                        color: Color(0xff2c3e50),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget zoomAbleTargetRigns(SessionDetailsLoaded state) {
    // Zoom level track karega
    return StatefulBuilder(
      builder: (context, setState) {
        return InteractiveViewer(
          minScale: 1.0,
          maxScale: 6.0,
          boundaryMargin: EdgeInsets.zero,
          child: _buildTargetRings(state),
        );
      },
    );
  }

  List<streaming.TracePoint> _convertTracePoints(List<TracePoint> tracePoints) {
    // Convert state TracePoints to streaming TracePoints for TracePainter
    return tracePoints.map((point) {
      streaming.TracePhase phase;
      switch (point.phase) {
        case 'preShot':
          phase = streaming.TracePhase.preShot;
          break;
        case 'shot':
          phase = streaming.TracePhase.shot;
          break;
        case 'postShot':
          phase = streaming.TracePhase.postShot;
          break;
        default:
          phase = streaming.TracePhase.preShot;
      }

      return streaming.TracePoint(
        Point(point.x, point.y),
        phase,
      );
    }).toList();
  }

  // Get actual trace points from shot trace data
  List<streaming.TracePoint> _getActualTracePoints(
      BuildContext context, int shotId) {
    final trainingState = context.read<TrainingSessionBloc>().state;
    final shotTraces = trainingState.sessionShotTraces;

    // Find the shot trace for the selected shot
    final shotTrace =
        shotTraces.where((trace) => trace.shotNumber == shotId).firstOrNull;

    if (shotTrace != null && shotTrace.tracePoints.isNotEmpty) {
      // Convert ShotTraceData trace points to streaming TracePoints
      final allPoints = shotTrace.tracePoints.map((point) {
        return streaming.TracePoint(
            Point(point.point.x, point.point.y), point.phase);
      }).toList();
      // Return animated points (only up to current animated count)
      return allPoints.take(_currentAnimatedPoints).toList();
    }

    // Fallback to mock data if no actual trace found
    final mockPoints = _convertTracePoints(_generateMockTracePoints(shotId));
    return mockPoints.take(_currentAnimatedPoints).toList();
  }

  List<TracePoint> _generateMockTracePoints(int shotId) {
    final List<TracePoint> points = [];
    final baseX = 140.0 + (shotId * 2.0);
    final baseY = 140.0 + (shotId * 1.5);

    // Pre-shot points
    for (int i = 0; i < 10; i++) {
      points.add(TracePoint(
        x: baseX + (i * 0.1),
        y: baseY + (i * 0.05),
        phase: 'preShot',
      ));
    }

    // Shot point
    points.add(TracePoint(
      x: baseX + 1.0,
      y: baseY + 0.5,
      phase: 'shot',
    ));

    // Post-shot points
    for (int i = 0; i < 5; i++) {
      points.add(TracePoint(
        x: baseX + 1.0 + (i * 0.2),
        y: baseY + 0.5 + (i * 0.1),
        phase: 'postShot',
      ));
    }

    return points;
  }

  // Start animation for trace points
  void _startTraceAnimation(BuildContext context, int shotId,
      {bool resume = false, bool restart = false}) {
    // Cancel any existing animation
    _animationTimer?.cancel();

    // Reset animation state
    setState(() {
      if (!resume) {
        _currentAnimatedPoints = 0;
      }
      _lastSelectedShotId = shotId;
      _isPlaying = true;
      _isPaused = false;
    });

    // Get total number of points for this shot
    final trainingState = context.read<TrainingSessionBloc>().state;
    final shotTraces = trainingState.sessionShotTraces;
    final shotTrace =
        shotTraces.where((trace) => trace.shotNumber == shotId).firstOrNull;

    int totalPoints = 0;
    if (shotTrace != null && shotTrace.tracePoints.isNotEmpty) {
      totalPoints = shotTrace.tracePoints.length;
    } else {
      // Use mock data count
      totalPoints = _generateMockTracePoints(shotId).length;
    }

    // Start animation timer - 5x faster animation
    _animationTimer = Timer.periodic(const Duration(milliseconds: 20), (timer) {
      if (mounted && !_isPaused) {
        setState(() {
          if (_currentAnimatedPoints < totalPoints) {
            // Add 5 points per tick for 5x faster animation
            _currentAnimatedPoints =
                (_currentAnimatedPoints + 35).clamp(0, totalPoints);
          } else {
            // Animation complete
            timer.cancel();
            _isPlaying = false;
          }
        });
      } else if (!mounted) {
        timer.cancel();
      }
    });
  }

  // Get total number of points for a shot
  int _getTotalPointsForShot(BuildContext context, int shotId) {
    final trainingState = context.read<TrainingSessionBloc>().state;
    final shotTraces = trainingState.sessionShotTraces;
    final shotTrace =
        shotTraces.where((trace) => trace.shotNumber == shotId).firstOrNull;

    if (shotTrace != null && shotTrace.tracePoints.isNotEmpty) {
      return shotTrace.tracePoints.length;
    } else {
      // Use mock data count
      return _generateMockTracePoints(shotId).length;
    }
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

  Widget _buildShotInfoPanel(
      BuildContext context, dynamic selectedShot, SessionDetailsLoaded state) {
    if (selectedShot == null) {
      return Container(
        padding: const EdgeInsets.all(15.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Shot Analysis & Trace Data',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xff2c3e50),
              ),
            ),
            SizedBox(height: 15),
            Text('Select a shot to view detailed analysis'),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(15.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Shot #${selectedShot.id} - Complete Analysis',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xff2c3e50),
            ),
          ),
          const SizedBox(height: 15),
          _buildInfoRow('Score', '${selectedShot.score}/10'),
          _buildInfoRow('Time',
              selectedShot.timestamp.toString().split(' ')[1].substring(0, 8)),
          _buildInfoRow('Position', _getPositionDescription(selectedShot)),
          if (selectedShot.hasTraceData) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xffe8f5e8), Color(0xffd4edda)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xff28a745), width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.timeline,
                          color: Color(0xff28a745), size: 16),
                      const SizedBox(width: 8),
                      const Text(
                        'TRACELINE DATA ✅',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff28a745),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '🎯 Complete traceline stored from training session with ${_getActualTracePoints(context, selectedShot.id).length}/${_getTotalPointsForShot(context, selectedShot.id)} data points${_currentAnimatedPoints > 0 ? ' (animating...)' : ''}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xff28a745),
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, color: Color(0xff2c3e50)),
            ),
          ),
        ],
      ),
    );
  }

  String _getPositionDescription(dynamic shot) {
    const center = {'x': 140.0, 'y': 140.0};
    final deltaX = shot.x - center['x']!;
    final deltaY = shot.y - center['y']!;

    String horizontal = '';
    if (deltaX > 2) {
      horizontal = 'right';
    } else if (deltaX < -2) {
      horizontal = 'left';
    } else {
      horizontal = 'center';
    }

    String vertical = '';
    if (deltaY > 2) {
      vertical = 'low';
    } else if (deltaY < -2) {
      vertical = 'high';
    } else {
      vertical = 'center';
    }

    if (horizontal == 'center' && vertical == 'center') {
      return 'Dead center';
    }
    return (horizontal != 'center' && vertical != 'center')
        ? '$vertical $horizontal'
        : (horizontal != 'center' ? horizontal : vertical);
  }

  Widget _buildTimelineContent(
      BuildContext context, SessionDetailsLoaded state) {
    // Get actual shot traces from training session
    // final trainingState = context.read<TrainingSessionBloc>().state;
    // final shotTraces = trainingState.sessionShotTraces;

    // Use actual shots from training session if available, otherwise fallback to session details
    final shots = state.sessionDetails.shots;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xff2c3e50), Color(0xff34495e)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.timeline, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'SHOT TIMELINE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${shots.length} SHOTS',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ...shots.map((shot) {
          final bgColor = _getShotColor(shot.score);
          final isSelected = state.selectedShotId == shot.id;

          return GestureDetector(
            onTap: () {
              context.read<SessionDetailsBloc>().add(SelectShot(shot.id));
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xfff0f8ff) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xff17a2b8)
                      : shot.hasTraceData
                          ? const Color(0xff17a2b8).withOpacity(0.3)
                          : const Color(0xffe9ecef),
                  width: isSelected
                      ? 3
                      : shot.hasTraceData
                          ? 2
                          : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? const Color(0xff17a2b8).withOpacity(0.2)
                        : Colors.black.withOpacity(0.05),
                    blurRadius: isSelected ? 12 : 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: bgColor,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                      boxShadow: [
                        if (shot.hasTraceData)
                          BoxShadow(
                            color: const Color(0xff17a2b8).withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          '${shot.id}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        if (shot.hasTraceData)
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
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Score: ${shot.score}/10',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isSelected
                                    ? const Color(0xff17a2b8)
                                    : const Color(0xff2c3e50),
                              ),
                            ),
                            const Spacer(),
                            if (shot.hasTraceData) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xff17a2b8),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'TRACE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                            ],
                            if (isSelected)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xff28a745),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'SELECTED',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          shot.timestamp
                              .toString()
                              .split(' ')[1]
                              .substring(0, 8),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xff6c757d),
                          ),
                        ),
                        if (shot.hasTraceData) ...[
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              const Icon(Icons.timeline,
                                  size: 14, color: Color(0xff17a2b8)),
                              const SizedBox(width: 2),
                              Text(
                                'Traceline available',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: const Color(0xff17a2b8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildExportOptions(BuildContext context, SessionDetailsLoaded state) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _ExportButton(
                label: 'Export Data',
                icon: Icons.bar_chart,
                onPressed: () {
                  context.read<SessionDetailsBloc>().add(
                        ExportSessionData(state.sessionDetails.sessionId),
                      );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ExportButton(
                label: 'Share Results',
                icon: Icons.share,
                onPressed: () {
                  context.read<SessionDetailsBloc>().add(
                        ShareSessionResults(state.sessionDetails.sessionId),
                      );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// --- Custom Painter for Crosshair ---
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

// --- Export Button Widget ---
class _ExportButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _ExportButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: const Color(0xff2c3e50)),
      label: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Color(0xff2c3e50),
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xffe9ecef), width: 1),
        ),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
      ),
    );
  }
}

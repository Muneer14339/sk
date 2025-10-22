// lib/features/training/presentation/pages/session_summary_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math' as math;


import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/primary_button.dart';
import '../../data/models/saved_session_model.dart';
import '../bloc/training_session/training_session_bloc.dart';
import '../bloc/training_session/training_session_event.dart';
import '../bloc/training_session/training_session_state.dart';
import 'manticx_analysis_page.dart';
import 'split_times_page.dart';

class SessionSummaryPage extends StatelessWidget {
  final SavedSessionModel? savedSession;

  const SessionSummaryPage({super.key, this.savedSession});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background(context),
      appBar: AppBar(
        backgroundColor: AppTheme.surface(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: AppTheme.textPrimary(context)),
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
        ),
        title: Text(
          'Session Summary',
          style: TextStyle(color: AppTheme.textPrimary(context), fontSize: 18),
        ),
      ),
      body: BlocBuilder<TrainingSessionBloc, TrainingSessionState>(
        builder: (context, state) {
          final steadinessShots = savedSession?.steadinessShots ?? state.steadinessShots;
          final missedCount = savedSession?.missedShotNumbers.length ?? state.missedShotCount;
          final totalShots = steadinessShots.length;
          final detectedShots = totalShots + missedCount;

          if (steadinessShots.isEmpty) {
            return Center(
              child: Text('No session data available', style: TextStyle(color: AppTheme.textSecondary(context))),
            );
          }

          final metrics = _calculateMetrics(steadinessShots);
          final duration = _calculateDuration(steadinessShots);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if(savedSession==null)
                  _buildHeader(context, savedSession?.programName ?? state.program?.programName ?? 'Training'),

                const SizedBox(height: 16),
                _buildStatsCard(duration, totalShots, detectedShots, metrics,context),
                const SizedBox(height: 16),
                _buildActionButtons(context, state, savedSession),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String programName) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary(context), AppTheme.primary(context).withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle, color: Colors.white, size: 48),
          const SizedBox(height: 12),
          Text(
            'Session Complete',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            programName,
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(String duration, int totalShots, int detectedShots, Map<String, dynamic> metrics, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          _buildStatRow('Session Duration', duration,context),
          _buildDivider(),
          _buildStatRow('Total Shots', '$totalShots',context),
          _buildDivider(),
          _buildStatRow('Detected Shots', '$detectedShots',context),
          _buildDivider(),
          _buildStatRow(
            'Average Stability',
            '${metrics['avgStability'].toStringAsFixed(0)}%',context,
            valueColor: _getStabilityColor(metrics['avgStability'],context),
          ),
          _buildDivider(),
          _buildStatRow('Best Stability', '${metrics['bestStability'].toStringAsFixed(0)}%',context),
          _buildDivider(),
          _buildStatRow('Average Score', '${metrics['avgScore'].toStringAsFixed(1)}',context),
          _buildDivider(),
          _buildStatRow(
            'Split Time (avg)',
            '${metrics['avgSplitTime'].toStringAsFixed(2)}s',context,
            isClickable: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, BuildContext context, {Color? valueColor, bool isClickable = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 14),
          ),
          Row(
            children: [
              Text(
                value,
                style: TextStyle(
                  color: valueColor ?? AppTheme.textPrimary(context),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (isClickable) ...[
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.primary(context)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(color: Colors.white.withValues(alpha: 0.06), height: 1);
  }

  Widget _buildActionButtons(BuildContext context, TrainingSessionState state, SavedSessionModel? savedSession) {
    return Column(
      children: [
        PrimaryButton(
          title: 'View Split Times',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SplitTimesPage(savedSession: savedSession),
            ),
          ),
        ),
        const SizedBox(height: 12),
        PrimaryButton(
          title: 'Replay: View All Shots',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ManticXAnalysisPage(),
              settings: RouteSettings(arguments: savedSession),
            ),
          ),

        ),
        if (savedSession == null) ...[
          const SizedBox(height: 12),
          PrimaryButton(
            title: 'Save Session',
            onTap: () => context.read<TrainingSessionBloc>().add(SaveSession()),
            isLoading: state.isSavingSession,
          ),
        ],
      ],
    );
  }

  Map<String, dynamic> _calculateMetrics(List<dynamic> shots) {
    if (shots.isEmpty) return {'avgStability': 0.0, 'bestStability': 0.0, 'avgScore': 0.0, 'avgSplitTime': 0.0};

    double totalStability = 0;
    double bestStability = 0;
    double totalScore = 0;
    List<double> splitTimes = [];

    for (int i = 0; i < shots.length; i++) {
      final shot = shots[i];
      final stability = _calculateStability(shot);
      totalStability += stability;
      bestStability = math.max(bestStability, stability);
      totalScore += shot.score ?? 0;

      if (i > 0) {
        final prevShot = shots[i - 1];
        final splitTime = shot.timestamp.difference(prevShot.timestamp).inMilliseconds / 1000.0;
        splitTimes.add(splitTime);
      }
    }

    final avgSplitTime = splitTimes.isEmpty ? 0.0 : splitTimes.reduce((a, b) => a + b) / splitTimes.length;

    return {
      'avgStability': totalStability / shots.length,
      'bestStability': bestStability,
      'avgScore': totalScore / shots.length,
      'avgSplitTime': avgSplitTime,
    };
  }

  double _calculateStability(dynamic shot) {
    final metrics = shot.metrics as Map<String, dynamic>?;
    if (metrics != null && metrics.containsKey('linearWobble')) {
      final wobble = metrics['linearWobble'] as double;
      return (1.0 - (wobble / 10.0).clamp(0.0, 1.0)) * 100;
    }
    return 85.0;
  }

  Color _getStabilityColor(double stability,BuildContext context) {
    if (stability >= 85) return AppTheme.success(context);
    if (stability >= 70) return AppTheme.warning(context);
    return AppTheme.error(context);
  }

  String _calculateDuration(List<dynamic> shots) {
    if (shots.length < 2) return '00:00';
    final first = shots.first.timestamp as DateTime;
    final last = shots.last.timestamp as DateTime;
    final duration = last.difference(first);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
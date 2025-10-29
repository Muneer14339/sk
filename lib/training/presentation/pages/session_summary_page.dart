// lib/training/presentation/pages/session_summary_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:math' as math;
import '../../../core/theme/app_theme.dart';
import '../../data/models/saved_session_model.dart';
import '../bloc/training_session/training_session_bloc.dart';
import '../bloc/training_session/training_session_event.dart';
import '../bloc/training_session/training_session_state.dart';
import '../widgets/common/training_button.dart';
import '../widgets/common/compact_card.dart';
import '../widgets/common/info_row.dart';
import '../widgets/common/info_divider.dart';
import '../widgets/common/gradient_header.dart';
import 'split_times_page.dart';
import 'manticx_analysis_page.dart';

class SessionSummaryPage extends StatelessWidget {
  final SavedSessionModel? savedSession;

  const SessionSummaryPage({super.key, this.savedSession});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background(context),
      appBar: _buildAppBar(context),
      body: BlocConsumer<TrainingSessionBloc, TrainingSessionState>(
        listener: _handleStateChanges,
        builder: (context, state) {
          final steadinessShots = savedSession?.steadinessShots ?? state.steadinessShots;
          if (steadinessShots.isEmpty) {
            return _buildEmptyState(context);
          }

          return _buildContent(context, state, steadinessShots);
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppTheme.surface(context),
      elevation: 0,
      toolbarHeight: 50,
      leading: IconButton(
        icon: Icon(Icons.close, color: AppTheme.textPrimary(context), size: 20),
        padding: EdgeInsets.zero,
        onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
      ),
      title: Text(
        'Session Summary',
        style: AppTheme.headingSmall(context).copyWith(fontSize: 16),
      ),
      centerTitle: true,
    );
  }

  // lib/training/presentation/pages/session_summary_page.dart
// Remove toast logic from _handleStateChanges (around line 60):
  void _handleStateChanges(BuildContext context, TrainingSessionState state) {
    if (state.isSessionSaved == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Session saved', style: AppTheme.bodyMedium(context)),
          backgroundColor: AppTheme.success(context),
        ),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Text(
        'No session data available',
        style: AppTheme.bodyLarge(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context, TrainingSessionState state, List<dynamic> steadinessShots) {
    final metrics = _SessionMetrics.calculate(steadinessShots);
    final missedCount = savedSession?.missedShotNumbers.length ?? state.missedShotCount;
    final totalShots = steadinessShots.length;
    final detectedShots = totalShots + missedCount;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              children: [
                _buildMetricsCard(context, metrics, totalShots, detectedShots),
                const SizedBox(height: 10),
                _buildActionButtons(context),
                const SizedBox(height: 10),
                _buildBottomActions(context, state),
              ],
            ),
          ),
        ),

      ],
    );
  }
  Widget _buildMetricsCard(BuildContext context, _SessionMetrics metrics, int totalShots, int detectedShots) {
    return CompactCard(
      child: Column(
        children: [
          InfoRow(label: 'Session Duration', value: metrics.duration),
          const InfoDivider(),
          InfoRow(label: 'Total Shots', value: '$totalShots'),
          const InfoDivider(),
          InfoRow(label: 'Detected Shots', value: '$detectedShots'),
          const InfoDivider(),
          InfoRow(label: 'Average Score', value: metrics.avgScore.toStringAsFixed(1)),
          const InfoDivider(),
          InfoRow(
            label: 'Average Stability',
            value: '${metrics.avgStability.toStringAsFixed(0)}%',
            valueColor: _getStabilityColor(context, metrics.avgStability),
          ),
          const InfoDivider(),
          InfoRow(label: 'Best Stability', value: '${metrics.bestStability.toStringAsFixed(0)}%'),
          const InfoDivider(),
          InfoRow(
            label: 'Split Time (avg)',
            value: '${metrics.avgSplitTime.toStringAsFixed(2)}s',
            showArrow: true,
            onTap: () => _navigateToSplitTimes(context),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TrainingButton(
            label: 'Details',
            icon: Icons.info_outline,
            type: ButtonType.secondary,
            onPressed: () => _navigateToSplitTimes(context),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: TrainingButton(
            label: 'Replay',
            icon: Icons.play_circle_outline,
            type: ButtonType.secondary,
            onPressed: () => _navigateToReplay(context),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: TrainingButton(
            label: 'Share',
            icon: Icons.share,
            type: ButtonType.secondary,
            onPressed: () => Share.share('See my session summary in PulseAim app!'),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions(BuildContext context, TrainingSessionState state) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
      decoration: AppTheme.cardDecoration(context),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: TrainingButton(
                label: 'Save Session',
                icon: Icons.save,
                isLoading: state.isSavingSession ?? false,
                onPressed: () => context.read<TrainingSessionBloc>().add(const SaveSession()),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TrainingButton(
                label: 'Start New Session',
                icon: Icons.add,
                type: ButtonType.outlined,
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TrainingButton(
                label: 'Discard',
                icon: Icons.delete_outline,
                type: ButtonType.outlined,
                onPressed: () => _showDiscardDialog(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToSplitTimes(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SplitTimesPage(savedSession: savedSession),
      ),
    );
  }

  void _navigateToReplay(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ManticXAnalysisPage(),
        settings: RouteSettings(arguments: savedSession),
      ),
    );
  }

  void _showDiscardDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surface(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        ),
        title: Text(
          'Discard Session?',
          style: AppTheme.headingMedium(context).copyWith(fontSize: 16),
        ),
        content: Text(
          'Are you sure you want to discard this session? All data will be lost and cannot be recovered.',
          style: AppTheme.bodyMedium(context).copyWith(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: AppTheme.button(context).copyWith(fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: Text(
              'Yes, Discard',
              style: AppTheme.button(context).copyWith(
                color: AppTheme.error(context),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStabilityColor(BuildContext context, double stability) {
    if (stability >= 85) return AppTheme.success(context);
    if (stability >= 70) return AppTheme.warning(context);
    return AppTheme.error(context);
  }
}

class _SessionMetrics {
  final double avgStability;
  final double bestStability;
  final double avgScore;
  final double avgSplitTime;
  final String duration;

  _SessionMetrics({
    required this.avgStability,
    required this.bestStability,
    required this.avgScore,
    required this.avgSplitTime,
    required this.duration,
  });

  static _SessionMetrics calculate(List<dynamic> shots) {
    if (shots.isEmpty) {
      return _SessionMetrics(
        avgStability: 0,
        bestStability: 0,
        avgScore: 0,
        avgSplitTime: 0,
        duration: '00:00',
      );
    }

    double totalStability = 0;
    double bestStability = 0;
    double totalScore = 0;
    List<double> splitTimes = [];

    for (int i = 0; i < shots.length; i++) {
      final shot = shots[i];
      final stability = shot.metrics?['linearWobble'] != null
          ? (1.0 - ((shot.metrics['linearWobble'] as double) / 10).clamp(0.0, 1.0)) * 100
          : 85.0;

      totalStability += stability;
      bestStability = math.max(bestStability, stability);
      totalScore += shot.score ?? 0;

      if (i > 0) {
        splitTimes.add(
          shot.timestamp.difference(shots[i - 1].timestamp).inMilliseconds / 1000.0,
        );
      }
    }

    final duration = shots.length < 2
        ? '00:00'
        : _formatDuration(
      (shots.last.timestamp as DateTime).difference(shots.first.timestamp as DateTime),
    );

    return _SessionMetrics(
      avgStability: totalStability / shots.length,
      bestStability: bestStability,
      avgScore: totalScore / shots.length,
      avgSplitTime: splitTimes.isEmpty ? 0.0 : splitTimes.reduce((a, b) => a + b) / splitTimes.length,
      duration: duration,
    );
  }

  static String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
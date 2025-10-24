// lib/features/training/presentation/pages/session_summary_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math' as math;

import '../../../core/theme/app_theme.dart';
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
      appBar: _buildAppBar(context),
      body: BlocListener<TrainingSessionBloc, TrainingSessionState>(
        listener: _handleBlocListener,
        child: BlocBuilder<TrainingSessionBloc, TrainingSessionState>(
          builder: (context, state) {
            final steadinessShots =
                savedSession?.steadinessShots ?? state.steadinessShots;
            final missedCount =
                savedSession?.missedShotNumbers.length ?? state.missedShotCount;
            final totalShots = steadinessShots.length;
            final detectedShots = totalShots + missedCount;

            if (steadinessShots.isEmpty) {
              return _buildEmptyState(context);
            }

            final metrics = _calculateMetrics(steadinessShots);
            final duration = _calculateDuration(steadinessShots);
            final programName = savedSession?.programName ??
                state.program?.programName ??
                'Training';
            final totalScore = _calculateTotalScore(steadinessShots);
            final maxPossibleScore = totalShots * 10;

            return SingleChildScrollView(
              padding: AppTheme.paddingLarge,
              child: Column(
                children: [
                  if (savedSession == null)
                    _buildSuccessHeader(context, programName),
                  if (savedSession == null)
                    const SizedBox(height: AppTheme.spacingLarge),
                  _buildStatsCard(
                    context: context,
                    duration: duration,
                    totalShots: totalShots,
                    detectedShots: detectedShots,
                    totalScore: totalScore,
                    maxPossibleScore: maxPossibleScore,
                    metrics: metrics,
                  ),
                  const SizedBox(height: AppTheme.spacingLarge),
                  _buildActionButtons(context, state),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppTheme.surface(context),
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.close, color: AppTheme.textPrimary(context)),
        onPressed: () =>
            Navigator.of(context).popUntil((route) => route.isFirst),
      ),
      title: Text(
        'Session Summary',
        style: AppTheme.headingSmall(context),
      ),
      centerTitle: true,
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline,
            size: 64,
            color: AppTheme.textSecondary(context),
          ),
          const SizedBox(height: AppTheme.spacingLarge),
          Text(
            'No session data available',
            style: AppTheme.bodyLarge(context).copyWith(
              color: AppTheme.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessHeader(BuildContext context, String programName) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary(context),
            AppTheme.secondary(context),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 48,
            ),
          ),
          const SizedBox(height: AppTheme.spacingLarge),
          Text(
            'Session Complete',
            style: AppTheme.headingLarge(context).copyWith(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSmall),
          Text(
            programName,
            style: AppTheme.bodyLarge(context).copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard({
    required BuildContext context,
    required String duration,
    required int totalShots,
    required int detectedShots,
    required double totalScore,
    required int maxPossibleScore,
    required Map<String, dynamic> metrics,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatRow(
            context: context,
            label: 'Session Duration',
            value: duration,
          ),
          _buildDivider(context),
          _buildStatRow(
            context: context,
            label: 'Total Shots',
            value: '$totalShots',
          ),
          _buildDivider(context),
          _buildStatRow(
            context: context,
            label: 'Detected Shots',
            value: '$detectedShots',
          ),
          _buildDivider(context),
          _buildStatRow(
            context: context,
            label: 'Total Score',
            value: '${totalScore.toStringAsFixed(0)}/$maxPossibleScore',
          ),
          _buildDivider(context),
          _buildStatRow(
            context: context,
            label: 'Average Score',
            value: '${metrics['avgScore'].toStringAsFixed(1)}',
          ),
          _buildDivider(context),
          _buildStatRow(
            context: context,
            label: 'Average Stability',
            value: '${metrics['avgStability'].toStringAsFixed(0)}%',
            valueColor: _getStabilityColor(metrics['avgStability'], context),
          ),
          _buildDivider(context),
          _buildStatRow(
            context: context,
            label: 'Best Stability',
            value: '${metrics['bestStability'].toStringAsFixed(0)}%',
          ),
          _buildDivider(context),
          _buildStatRow(
            context: context,
            label: 'Split Time (avg)',
            value: '${metrics['avgSplitTime'].toStringAsFixed(2)}s',
            showArrow: true,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SplitTimesPage(savedSession: savedSession),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow({
    required BuildContext context,
    required String label,
    required String value,
    Color? valueColor,
    bool showArrow = false,
    VoidCallback? onTap,
  }) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTheme.bodyMedium(context).copyWith(
              color: AppTheme.textSecondary(context),
            ),
          ),
          Row(
            children: [
              Text(
                value,
                style: AppTheme.titleMedium(context).copyWith(
                  color: valueColor ?? AppTheme.textPrimary(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (showArrow) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: AppTheme.primary(context),
                ),
              ],
            ],
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: row,
      );
    }

    return row;
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(
      color: AppTheme.border(context),
      height: 1,
      thickness: 1,
    );
  }

  Widget _buildActionButtons(
      BuildContext context, TrainingSessionState state) {
    return Column(
      children: [
        _buildActionButton(
          context: context,
          label: 'Details',
          icon: Icons.info_outline,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SplitTimesPage(savedSession: savedSession),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacingMedium),
        _buildActionButton(
          context: context,
          label: 'Replay',
          icon: Icons.replay,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ManticXAnalysisPage(),
              settings: RouteSettings(arguments: savedSession),
            ),
          ),
        ),
        if (savedSession == null) ...[
          const SizedBox(height: AppTheme.spacingMedium),
          _buildActionButton(
            context: context,
            label: 'Save Session',
            icon: Icons.save_outlined,
            isPrimary: true,
            isLoading: state.isSavingSession ?? false,
            onTap: () =>
                context.read<TrainingSessionBloc>().add(SaveSession()),
          ),
        ],
        const SizedBox(height: AppTheme.spacingMedium),
        _buildActionButton(
          context: context,
          label: savedSession == null ? 'Start New Session' : 'Close',
          icon: savedSession == null ? Icons.add : Icons.close,
          onTap: () {
            if (savedSession == null) {
              Navigator.of(context).popUntil((route) => route.isFirst);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        if (savedSession == null) ...[
          const SizedBox(height: AppTheme.spacingMedium),
          _buildActionButton(
            context: context,
            label: 'Discard',
            icon: Icons.delete_outline,
            isDestructive: true,
            onTap: () => _showDiscardDialog(context),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool isPrimary = false,
    bool isDestructive = false,
    bool isLoading = false,
  }) {
    if (isPrimary) {
      return SizedBox(
        width: double.infinity,
        height: AppTheme.buttonHeight,
        child: ElevatedButton.icon(
          onPressed: isLoading ? null : onTap,
          icon: isLoading
              ? SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.textPrimary(context),
            ),
          )
              : Icon(icon, size: AppTheme.iconMedium),
          label: Text(
            label,
            style: AppTheme.button(context).copyWith(
              color: AppTheme.background(context),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: AppTheme.buttonHeight,
      child: OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: isDestructive
              ? AppTheme.error(context)
              : AppTheme.primary(context),
          side: BorderSide(
            color: isDestructive
                ? AppTheme.error(context)
                : AppTheme.primary(context),
            width: 2,
          ),
        ),
        icon: Icon(icon, size: AppTheme.iconMedium),
        label: Text(
          label,
          style: AppTheme.button(context).copyWith(
            color: isDestructive
                ? AppTheme.error(context)
                : AppTheme.primary(context),
          ),
        ),
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
          style: AppTheme.headingMedium(context),
        ),
        content: Text(
          'Are you sure you want to discard this session? All data will be lost and cannot be recovered.',
          style: AppTheme.bodyMedium(context).copyWith(
            color: AppTheme.textSecondary(context),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: AppTheme.button(context).copyWith(
                color: AppTheme.textSecondary(context),
              ),
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
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleBlocListener(BuildContext context, TrainingSessionState state) {
    if (state.isSessionSaved == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text(
                'Session saved',
                style: AppTheme.bodyMedium(context).copyWith(
                  color: Colors.white,
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.success(context),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
        ),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else if (state.saveError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  state.saveError!,
                  style: AppTheme.bodyMedium(context).copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.error(context),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
        ),
      );
    }
  }

  Map<String, dynamic> _calculateMetrics(List<dynamic> shots) {
    if (shots.isEmpty) {
      return {
        'avgStability': 0.0,
        'bestStability': 0.0,
        'avgScore': 0.0,
        'avgSplitTime': 0.0,
      };
    }

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
        final splitTime =
            shot.timestamp.difference(prevShot.timestamp).inMilliseconds /
                1000.0;
        splitTimes.add(splitTime);
      }
    }

    final avgSplitTime = splitTimes.isEmpty
        ? 0.0
        : splitTimes.reduce((a, b) => a + b) / splitTimes.length;

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

  double _calculateTotalScore(List<dynamic> shots) {
    double total = 0;
    for (final shot in shots) {
      total += shot.score ?? 0;
    }
    return total;
  }

  Color _getStabilityColor(double stability, BuildContext context) {
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

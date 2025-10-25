// lib/training/presentation/pages/session_summary_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_theme.dart';
import '../../data/models/saved_session_model.dart';
import '../bloc/training_session/training_session_bloc.dart';
import '../bloc/training_session/training_session_event.dart';
import '../bloc/training_session/training_session_state.dart';
import '../widgets/common/training_card.dart';
import '../widgets/common/training_button.dart';
import 'split_times_page.dart';
import 'manticx_analysis_page.dart';
import 'dart:math' as math;

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
        toolbarHeight: 50,
        leading: IconButton(
          icon: Icon(Icons.close, color: AppTheme.textPrimary(context), size: 20),
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
        ),
        title: Text('Session Summary', style: AppTheme.headingSmall(context).copyWith(fontSize: 16)),
        centerTitle: true,
      ),
      body: BlocConsumer<TrainingSessionBloc, TrainingSessionState>(
        listener: (ctx, state) {
          if (state.isSessionSaved == true) {
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
              content: Text('Session saved', style: AppTheme.bodyMedium(ctx)),
              backgroundColor: AppTheme.success(ctx),
            ));
            Navigator.of(ctx).popUntil((route) => route.isFirst);
          }
        },
        builder: (context, state) {
          final steadinessShots = savedSession?.steadinessShots ?? state.steadinessShots;
          final missedCount = savedSession?.missedShotNumbers.length ?? state.missedShotCount;
          final totalShots = steadinessShots.length;
          final detectedShots = totalShots + missedCount;
          final metrics = _calculateMetrics(steadinessShots);
          final duration = _calculateDuration(steadinessShots);

          if (steadinessShots.isEmpty) {
            return Center(child: Text('No session data available', style: AppTheme.bodyLarge(context)));
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppTheme.primary(context), AppTheme.secondary(context)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Column(
                          children: [
                            Icon(Icons.check_circle, size: 36, color: Colors.white),
                            const SizedBox(height: 4),
                            Text('Session Complete', style: AppTheme.headingLarge(context).copyWith(color: Colors.white, fontSize: 18)),
                            const SizedBox(height: 2),
                            Text(
                              savedSession?.programName ?? state.program?.programName ?? 'Training',
                              style: AppTheme.bodyLarge(context).copyWith(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildCompactCard(
                        context,
                        child: Column(
                          children: [
                            _buildInfoRow(context, 'Session Duration', duration),
                            _buildDivider(context),
                            _buildInfoRow(context, 'Total Shots', '$totalShots'),
                            _buildDivider(context),
                            _buildInfoRow(context, 'Detected Shots', '$detectedShots'),
                            _buildDivider(context),
                            _buildInfoRow(context, 'Average Score', metrics['avgScore'].toStringAsFixed(1)),
                            _buildDivider(context),
                            _buildInfoRow(
                              context,
                              'Average Stability',
                              '${metrics['avgStability'].toStringAsFixed(0)}%',
                              valueColor: _getStabColor(metrics['avgStability'], context),
                            ),
                            _buildDivider(context),
                            _buildInfoRow(context, 'Best Stability', '${metrics['bestStability'].toStringAsFixed(0)}%'),
                            _buildDivider(context),
                            _buildInfoRow(
                              context,
                              'Split Time (avg)',
                              '${metrics['avgSplitTime'].toStringAsFixed(2)}s',
                              showArrow: true,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SplitTimesPage(savedSession: savedSession))),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TrainingButton(
                              label: 'Details',
                              icon: Icons.info_outline,
                              type: ButtonType.secondary,
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SplitTimesPage(savedSession: savedSession))),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: TrainingButton(
                              label: 'Replay',
                              icon: Icons.play_circle_outline,
                              type: ButtonType.secondary,
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => ManticXAnalysisPage(), settings: RouteSettings(arguments: savedSession)),
                              ),
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
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              Container(
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
                          onPressed: () => context.read<TrainingSessionBloc>().add(SaveSession()),
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
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCompactCard(BuildContext context, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: AppTheme.border(context).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: child,
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, {Color? valueColor, bool showArrow = false, VoidCallback? onTap}) {
    final content = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTheme.bodyMedium(context).copyWith(
            color: AppTheme.textSecondary(context),
            fontSize: 12,
          ),
        ),
        Row(
          children: [
            Text(
              value,
              style: AppTheme.bodyMedium(context).copyWith(
                fontWeight: FontWeight.w700,
                color: valueColor ?? AppTheme.textPrimary(context),
                fontSize: 12,
              ),
            ),
            if (showArrow) ...[
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 16, color: AppTheme.textSecondary(context)),
            ],
          ],
        ),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: content,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: content,
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppTheme.border(context).withOpacity(0.2),
    );
  }

  void _showDiscardDialog(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surface(ctx),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusXLarge)),
        title: Text('Discard Session?', style: AppTheme.headingMedium(ctx).copyWith(fontSize: 16)),
        content: Text('Are you sure you want to discard this session? All data will be lost and cannot be recovered.', style: AppTheme.bodyMedium(ctx).copyWith(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: AppTheme.button(ctx).copyWith(fontSize: 13)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.of(ctx).popUntil((route) => route.isFirst);
            },
            child: Text('Yes, Discard', style: AppTheme.button(ctx).copyWith(color: AppTheme.error(ctx), fontSize: 13)),
          ),
        ],
      ),
    );
  }

  static Map<String, dynamic> _calculateMetrics(List<dynamic> shots) {
    double totalStability = 0, bestStability = 0, totalScore = 0;
    List<double> splitTimes = [];
    for (int i = 0; i < shots.length; i++) {
      final shot = shots[i];
      final stability = shot.metrics?['linearWobble'] != null ? (1.0 - ((shot.metrics['linearWobble'] as double) / 10).clamp(0.0, 1.0)) * 100 : 85.0;
      totalStability += stability;
      bestStability = math.max(bestStability, stability);
      totalScore += shot.score ?? 0;
      if (i > 0) splitTimes.add(shot.timestamp.difference(shots[i - 1].timestamp).inMilliseconds / 1000.0);
    }
    return {
      'avgStability': totalStability / shots.length,
      'bestStability': bestStability,
      'avgScore': totalScore / shots.length,
      'avgSplitTime': splitTimes.isEmpty ? 0.0 : splitTimes.reduce((a, b) => a + b) / splitTimes.length,
    };
  }

  static Color _getStabColor(double stability, BuildContext ctx) {
    if (stability >= 85) return AppTheme.success(ctx);
    if (stability >= 70) return AppTheme.warning(ctx);
    return AppTheme.error(ctx);
  }

  static String _calculateDuration(List<dynamic> shots) {
    if (shots.length < 2) return '00:00';
    final first = shots.first.timestamp as DateTime;
    final last = shots.last.timestamp as DateTime;
    final duration = last.difference(first);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

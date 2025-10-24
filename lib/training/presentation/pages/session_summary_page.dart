import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_theme.dart';
import '../../data/models/saved_session_model.dart';
import '../bloc/training_session/training_session_bloc.dart';
import '../bloc/training_session/training_session_event.dart';
import '../bloc/training_session/training_session_state.dart';
import 'split_times_page.dart';
import 'manticx_analysis_page.dart';

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
        title: Text('Session Summary', style: AppTheme.headingSmall(context)),
        centerTitle: true,
      ),
      body: BlocConsumer<TrainingSessionBloc, TrainingSessionState>(
        listener: (ctx, state) {
          if (state.isSessionSaved == true) {
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
              content: Text('Session saved'),
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

          // Dummy Trend Data (replace with actual session trend data)
          final List<int> stabilityTrend = [65, 78, 88, 92, 100];
          final improvementPercent = 12; // e.g. 12% better than last session

          if (steadinessShots.isEmpty) {
            return Center(child: Text('No session data available', style: AppTheme.bodyLarge(context)));
          }

          return SingleChildScrollView(
            padding: AppTheme.paddingLarge,
            child: Column(
              children: [
                // Session Complete Banner
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primary(context), AppTheme.secondary(context)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 22),
                  child: Column(
                    children: [
                      Icon(Icons.check_circle, size: 56, color: Colors.white),
                      const SizedBox(height: 8),
                      Text('Session Complete', style: AppTheme.headingLarge(context).copyWith(color: Colors.white)),
                      const SizedBox(height: 2),
                      Text(savedSession?.programName ?? state.program?.programName ?? 'Training',
                          style: AppTheme.bodyLarge(context).copyWith(color: Colors.white70)),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingLarge),
                // Metrics and Trend Card
                Container(
                  decoration: AppTheme.cardDecoration(context),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      _buildStatRow(context, 'Session Duration', duration),
                      _buildDivider(context),
                      _buildStatRow(context, 'Total Shots', '$totalShots'),
                      _buildDivider(context),
                      _buildStatRow(context, 'Detected Shots', '$detectedShots'),
                      _buildDivider(context),
                      _buildStatRow(context, 'Average Score', metrics['avgScore'].toStringAsFixed(1)),
                      _buildDivider(context),
                      _buildStatRow(
                        context, 'Average Stability', metrics['avgStability'].toStringAsFixed(0) + '%',
                        valueColor: _getStabColor(metrics['avgStability'], context),
                      ),
                      _buildDivider(context),
                      _buildStatRow(context, 'Best Stability', metrics['bestStability'].toStringAsFixed(0) + '%'),
                      _buildDivider(context),
                      _buildStatRow(
                        context, 'Split Time (avg)', metrics['avgSplitTime'].toStringAsFixed(2) + 's',
                        showArrow: true,
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => SplitTimesPage(savedSession: savedSession))),
                      ),
                      const SizedBox(height: 14),
                      // Stability Trend
                      _buildTrendSection(context, stabilityTrend, improvementPercent),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingLarge),
                // --- Actions Row 1: Details, Replay, Share ---
              Row(
                children: [
                  Expanded(
                    child: _buildResponsiveRectButton(
                      context,
                      'Details',
                      Icons.info_outline,
                          () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SplitTimesPage(savedSession: savedSession),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildResponsiveRectButton(
                      context,
                      'Replay',
                      Icons.play_circle_outline,
                          () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ManticXAnalysisPage(),
                          settings: RouteSettings(arguments: savedSession),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildResponsiveRectButton(
                      context,
                      'Share',
                      Icons.share,
                          () async {
                        await Share.share('See my session summary in PulseAim app!');
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
                // --- Actions Row 2: Save ---
                _buildFilledButton(
                  context, 'Save Session', Icons.save,
                  onTap: () => context.read<TrainingSessionBloc>().add(SaveSession()),
                  loading: state.isSavingSession ?? false,
                ),
                const SizedBox(height: 12),
                // --- Actions Row 3: Start New Session ---
                _buildOutlineButton(
                  context, 'Start New Session', Icons.add,
                  onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
                ),
                const SizedBox(height: 12),
                // --- Actions Row 4: Discard ---
                _buildOutlineButton(
                  context, 'Discard', Icons.delete_outline,
                  textColor: AppTheme.error(context),
                  onTap: () => _showDiscardDialog(context),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildResponsiveRectButton(
      BuildContext context,
      String text,
      IconData icon,
      VoidCallback onPressed,
      ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double iconSize = constraints.maxWidth * 0.12; // adjusts icon size
        double fontSize = constraints.maxWidth * 0.09; // adjusts text size

        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: onPressed,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: iconSize),
                const SizedBox(width: 6),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  Widget _buildStatRow(BuildContext ctx, String label, String value, {Color? valueColor, bool showArrow = false, VoidCallback? onTap}) {
    Widget textRow = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTheme.bodyMedium(ctx).copyWith(color: AppTheme.textSecondary(ctx))),
        Row(
          children: [
            Text(value, style: AppTheme.titleMedium(ctx).copyWith(
                color: valueColor ?? AppTheme.textPrimary(ctx), fontWeight: FontWeight.w600)),
            if (showArrow)
              Row(
                children: [
                  const SizedBox(width: 6),
                  Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.primary(ctx)),
                ],
              ),
          ],
        ),
      ],
    );
    return onTap != null
        ? InkWell(child: textRow, onTap: onTap, borderRadius: BorderRadius.circular(AppTheme.radiusSmall))
        : Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: textRow);
  }

  Widget _buildDivider(BuildContext ctx) => Divider(color: AppTheme.border(ctx), thickness: 1, height: 1);

  Widget _buildRectButton(BuildContext ctx, String title, IconData icon, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.surface(ctx),
        foregroundColor: AppTheme.textPrimary(ctx),
        minimumSize: Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      icon: Icon(icon, size: 18),
      label: Text(title, style: AppTheme.button(ctx)),
    );
  }

  Widget _buildFilledButton(BuildContext ctx, String title, IconData icon, {required VoidCallback onTap, bool loading = false}) {
    return SizedBox(
      width: double.infinity,
      height: AppTheme.buttonHeight,
      child: ElevatedButton.icon(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary(ctx),
          foregroundColor: AppTheme.background(ctx),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: loading
            ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Icon(icon, size: 20),
        label: Text(title, style: AppTheme.button(ctx).copyWith(color: AppTheme.background(ctx))),
      ),
    );
  }

  Widget _buildOutlineButton(BuildContext ctx, String title, IconData icon, {Color? textColor, required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      height: AppTheme.buttonHeight,
      child: OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: textColor ?? AppTheme.primary(ctx),
          side: BorderSide(color: textColor ?? AppTheme.primary(ctx), width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: Icon(icon, size: 20),
        label: Text(title, style: AppTheme.button(ctx).copyWith(color: textColor ?? AppTheme.primary(ctx))),
      ),
    );
  }

  Widget _buildTrendSection(BuildContext ctx, List<int> trend, int improvement) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Stability Trend', style: AppTheme.labelSmall(ctx)),
        const SizedBox(height: 7),
        SizedBox(
          height: 50,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: trend.map((percent) => Expanded(
              child: Container(
                height: percent * 0.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primary(ctx), AppTheme.success(ctx)],
                    begin: Alignment.bottomCenter, end: Alignment.topCenter,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                ),
                margin: const EdgeInsets.symmetric(horizontal: 3),
              ),
            )).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.success(ctx).withOpacity(0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppTheme.success(ctx).withOpacity(0.3)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 12),
          child: Row(
            children: [
              Icon(Icons.trending_up, color: AppTheme.success(ctx), size: 16),
              const SizedBox(width: 4),
              Text('$improvement% better than last session',
                  style: AppTheme.bodySmall(ctx).copyWith(
                      color: AppTheme.success(ctx), fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  void _showDiscardDialog(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surface(ctx),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusXLarge)),
        title: Text('Discard Session?', style: AppTheme.headingMedium(ctx)),
        content: Text('Are you sure you want to discard this session? All data will be lost and cannot be recovered.', style: AppTheme.bodyMedium(ctx)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: AppTheme.button(ctx)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.of(ctx).popUntil((route) => route.isFirst);
            },
            child: Text('Yes, Discard', style: AppTheme.button(ctx).copyWith(color: AppTheme.error(ctx))),
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
      final stability = shot.metrics?['linearWobble'] != null
          ? (1.0 - ((shot.metrics['linearWobble'] as double) / 10).clamp(0.0, 1.0)) * 100 : 85.0;
      totalStability += stability;
      bestStability = math.max(bestStability, stability);
      totalScore += shot.score ?? 0;
      if (i > 0) {
        splitTimes.add(
            shot.timestamp.difference(shots[i - 1].timestamp).inMilliseconds /
                1000.0);
      }
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

// lib/training/presentation/pages/split_times_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math' as math;
import '../../../core/theme/app_theme.dart';
import '../../data/models/saved_session_model.dart';
import '../bloc/training_session/training_session_bloc.dart';
import '../bloc/training_session/training_session_state.dart';
import '../widgets/common/training_button.dart';
import '../widgets/common/compact_card.dart';
import '../widgets/split_time_chart.dart';

class SplitTimesPage extends StatelessWidget {
  final SavedSessionModel? savedSession;

  const SplitTimesPage({super.key, this.savedSession});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background(context),
      appBar: _buildAppBar(context),
      body: BlocBuilder<TrainingSessionBloc, TrainingSessionState>(
        builder: (context, state) {
          final shots = savedSession?.steadinessShots ?? state.steadinessShots;
          if (shots.isEmpty) {
            return _buildEmptyState(context);
          }

          return _SplitTimesContent(
            shots: shots,
            savedSession: savedSession, // ✅ NEW
          );
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
        icon: Icon(Icons.arrow_back, color: AppTheme.textPrimary(context), size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Session Details',
        style: AppTheme.headingSmall(context).copyWith(fontSize: 16),
      ),
      centerTitle: true,
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Text(
        'No shot data available',
        style: AppTheme.bodyMedium(context).copyWith(
          color: AppTheme.textSecondary(context),
        ),
      ),
    );
  }
}

// Update _SplitTimesContent widget (around line 44)
class _SplitTimesContent extends StatelessWidget {
  final List<dynamic> shots;
  final SavedSessionModel? savedSession; // ✅ NEW

  const _SplitTimesContent({
    required this.shots,
    this.savedSession, // ✅ NEW
  });

  @override
  Widget build(BuildContext context) {
    return _SplitTimesView(
      shots: shots,
      savedSession: savedSession, // ✅ NEW
    );
  }
}

// Update _SplitTimesView widget (around line 55)
class _SplitTimesView extends StatefulWidget {
  final List<dynamic> shots;
  final SavedSessionModel? savedSession; // ✅ NEW

  const _SplitTimesView({
    required this.shots,
    this.savedSession, // ✅ NEW
  });

  @override
  State<_SplitTimesView> createState() => _SplitTimesViewState();
}

class _SplitTimesViewState extends State<_SplitTimesView> {
  int? _selectedShotIndex;

  // Replace _SplitTimesView widget's build method (around line 55)
  @override
  Widget build(BuildContext context) {
    // ✅ NEW: Get session start time
    final sessionStartTime = widget.savedSession?.startedAt ??
        context.read<TrainingSessionBloc>().state.sessionStartTime;

    // Replace the line where calculate is called (around line 63)
    final splitData = _SplitData.calculate(
        widget.shots,
        widget.savedSession?.startedAt ?? context.read<TrainingSessionBloc>().state.sessionStartTime
    );
    final stats = _SplitStats.calculate(splitData.splits);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              children: [
                _buildInfoCard(context, splitData),
                const SizedBox(height: 10),
                _buildTable(context, widget.shots, splitData, stats),
                const SizedBox(height: 10),
                CompactCard(
                  title: 'Performance Analysis',
                  child: SplitTimeChart(
                    splits: splitData.splits,
                    selectedIndex: _selectedShotIndex,
                  ),
                ),
                const SizedBox(height: 10),
                _buildStatsCard(context, stats, splitData),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        _buildBottomActions(context, splitData),
      ],
    );
  }



  Widget _buildInfoCard(BuildContext context, _SplitData data) {
    return Container(
      width: double.maxFinite,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surface(context).withOpacity(0.6),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.primary(context).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Precision Fundamentals',
            style: AppTheme.titleMedium(context).copyWith(
              color: AppTheme.primary(context),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${data.totalElapsed} • ${data.shotCount} shots',
            style: AppTheme.bodySmall(context).copyWith(
              color: AppTheme.textSecondary(context),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(BuildContext context, List<dynamic> shots, _SplitData data, _SplitStats stats) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: AppTheme.border(context).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _buildTableHeader(context),
          ListView.separated(
            itemCount: shots.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: AppTheme.border(context).withOpacity(0.3),
            ),
            itemBuilder: (context, index) => _buildTableRow(
              context,
              shots[index],
              index,
              data,
              stats,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border(context))),
      ),
      child: Row(
        children: [
          _buildHeaderCell(context, "Shot", flex: 1),
          _buildHeaderCell(context, "Score", flex: 1),
          _buildHeaderCell(context, "Split", flex: 1),
          _buildHeaderCell(context, "Elapsed", flex: 1),
          _buildHeaderCell(context, "Stability", flex: 2),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(BuildContext context, String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        text.toUpperCase(),
        textAlign: TextAlign.center,
        style: AppTheme.labelSmall(context).copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          fontSize: 9,
        ),
      ),
    );
  }

  // Replace _buildTableRow method (around line 85)
  Widget _buildTableRow(BuildContext context, dynamic shot, int index, _SplitData data, _SplitStats stats) {
    final split = index == 0 ? 0.0 : data.splits[index - 1];
    final elapsed = data.timestamps[index];
    final score = shot.score ?? 0;
    final stability = shot.metrics["stability"] ?? 0;
    final isFastest = split > 0 && split == stats.min;
    final isSlowest = split > 0 && split == stats.max;
    final isSelected = _selectedShotIndex == index;
    final stabilityColor = _getStabilityColor(context, stability);

    // ✅ NEW: Check if this is a missed shot
    final isMissedShot = shot.metrics["status"] == "missed";

    return InkWell(
      onTap: () => setState(() => _selectedShotIndex = isSelected ? null : index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary(context).withOpacity(0.08) : Colors.transparent,
        ),
        child: Row(
          children: [
            _buildDataCell(
              context,
              '${shot.shotNumber}',
              flex: 1,
              color: AppTheme.primary(context),
              isBold: true,
            ),
            // ✅ MODIFIED: Show "MISS" for missed shots
            isMissedShot
                ? _buildMissCell(context)
                : _buildDataCell(context, '$score', flex: 1),
            _buildDataCell(
              context,
              index == 0 ? '0.00s' : '${split.toStringAsFixed(2)}s',
              flex: 1,
              color: isFastest
                  ? AppTheme.success(context)
                  : isSlowest
                  ? AppTheme.error(context)
                  : null,
            ),
            _buildDataCell(
              context,
              '${elapsed.toStringAsFixed(2)}s',
              flex: 1,
              color: AppTheme.textSecondary(context),
            ),
            _buildStabilityCell(context, stability, stabilityColor),
          ],
        ),
      ),
    );
  }

// ✅ NEW: Add this method after _buildDataCell (around line 140)
  Widget _buildMissCell(BuildContext context) {
    return Expanded(
      flex: 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: AppTheme.error(context).withOpacity(0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          'MISS',
          textAlign: TextAlign.center,
          style: AppTheme.bodyMedium(context).copyWith(
            color: AppTheme.error(context),
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
  Widget _buildDataCell(BuildContext context, String text, {int flex = 1, Color? color, bool isBold = false}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTheme.bodyMedium(context).copyWith(
          color: color ?? AppTheme.textPrimary(context),
          fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildStabilityCell(BuildContext context, int stability, Color color) {
    return Expanded(
      flex: 2,
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 5,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2.5),
                color: AppTheme.surfaceVariant(context),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: stability / 100.0,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2.5),
                    color: color,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$stability%',
            style: AppTheme.bodySmall(context).copyWith(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context, _SplitStats stats, _SplitData data) {
    return Container(
      width: double.maxFinite,
      padding: const EdgeInsets.all(10),
      decoration: AppTheme.inputDecoration(context),
      child: Text(
        'Avg: ${stats.avg.toStringAsFixed(2)}s • Fast: ⚡${stats.min.toStringAsFixed(2)}s • Slow: 🐌${stats.max.toStringAsFixed(2)}s • Shots: ${data.shotCount}',
        style: AppTheme.bodySmall(context).copyWith(
          color: AppTheme.textSecondary(context),
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context, _SplitData data) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
      decoration: AppTheme.cardDecoration(context),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TrainingButton(
                    label: 'Export CSV',
                    type: ButtonType.secondary,
                    onPressed: () => _exportCsv(context, data),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TrainingButton(
                    label: 'Share',
                    type: ButtonType.secondary,
                    onPressed: () => _shareSummary(context, data),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TrainingButton(
                label: 'Back to Summary',
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStabilityColor(BuildContext context, int stability) {
    if (stability >= 80) return AppTheme.success(context);
    if (stability >= 50) return AppTheme.warning(context);
    return AppTheme.error(context);
  }

  Future<void> _exportCsv(BuildContext context, _SplitData data) async {
    final buffer = StringBuffer('Shot,Split (s),Elapsed (s)\n');
    for (int i = 0; i < data.timestamps.length; i++) {
      final split = i == 0 ? 0.0 : data.splits[i - 1];
      buffer.writeln('${i + 1},${split.toStringAsFixed(2)},${data.timestamps[i].toStringAsFixed(2)}');
    }
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('CSV copied to clipboard', style: AppTheme.bodyMedium(context)),
        ),
      );
    }
  }

  Future<void> _shareSummary(BuildContext context, _SplitData data) async {
    final stats = _SplitStats.calculate(data.splits);
    final summary = StringBuffer()
      ..writeln('Session Details')
      ..writeln('Total: ${data.totalElapsed} • Shots: ${data.shotCount}')
      ..writeln('Avg: ${stats.avg.toStringAsFixed(2)}s | Fast: ${stats.min.toStringAsFixed(2)}s | Slow: ${stats.max.toStringAsFixed(2)}s');
    await Clipboard.setData(ClipboardData(text: summary.toString()));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Summary copied to clipboard', style: AppTheme.bodyMedium(context)),
        ),
      );
    }
  }
}

class _SplitData {
  final int shotCount;
  final List<double> splits;
  final List<double> timestamps;
  final String totalElapsed;

  _SplitData({
    required this.shotCount,
    required this.splits,
    required this.timestamps,
    required this.totalElapsed,
  });

  // Replace _SplitData.calculate method (around line 300)
  static _SplitData calculate(List<dynamic> shots, DateTime? sessionStartTime) {
    if (shots.isEmpty) {
      return _SplitData(
        shotCount: 0,
        splits: [],
        timestamps: [],
        totalElapsed: '00:00.00',
      );
    }

    // ✅ FIXED: Use session start time instead of first shot time
    final baseTime = sessionStartTime ?? shots.first.timestamp as DateTime;
    final splits = <double>[];
    final timestamps = <double>[];

    for (int i = 0; i < shots.length; i++) {
      final currentTime = shots[i].timestamp as DateTime;
      // ✅ Elapsed from session start
      final elapsed = currentTime.difference(baseTime).inMilliseconds / 1000.0;
      timestamps.add(elapsed);

      if (i > 0) {
        final prevTime = shots[i - 1].timestamp as DateTime;
        final split = currentTime.difference(prevTime).inMilliseconds / 1000.0;
        splits.add(split);
      }
    }

    final totalSeconds = timestamps.last;
    final minutes = (totalSeconds / 60).floor();
    final seconds = totalSeconds % 60;
    final totalElapsed = '${minutes.toString().padLeft(2, '0')}:${seconds.toStringAsFixed(2).padLeft(5, '0')}';

    return _SplitData(
      shotCount: shots.length,
      splits: splits,
      timestamps: timestamps,
      totalElapsed: totalElapsed,
    );
  }
}

class _SplitStats {
  final double avg;
  final double min;
  final double max;
  final double stdDev;

  _SplitStats({
    required this.avg,
    required this.min,
    required this.max,
    required this.stdDev,
  });

  static _SplitStats calculate(List<double> splits) {
    if (splits.isEmpty) {
      return _SplitStats(avg: 0.0, min: 0.0, max: 0.0, stdDev: 0.0);
    }

    final avg = splits.reduce((a, b) => a + b) / splits.length;
    final min = splits.reduce(math.min);
    final max = splits.reduce(math.max);
    final variance = splits.map((x) => math.pow(x - avg, 2)).reduce((a, b) => a + b) / splits.length;
    final stdDev = math.sqrt(variance);

    return _SplitStats(avg: avg, min: min, max: max, stdDev: stdDev);
  }
}
// lib/training/presentation/pages/split_times_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math' as math;
import '../../../core/theme/app_theme.dart';
import '../../data/models/saved_session_model.dart';
import '../bloc/training_session/training_session_bloc.dart';
import '../bloc/training_session/training_session_state.dart';
import '../widgets/common/training_card.dart';
import '../widgets/common/training_button.dart';
import '../widgets/common/training_constants.dart';
import '../widgets/split_time_chart.dart';

class SplitTimesPage extends StatefulWidget {
  final SavedSessionModel? savedSession;
  const SplitTimesPage({super.key, this.savedSession});

  @override
  State<SplitTimesPage> createState() => _SplitTimesPageState();
}

class _SplitTimesPageState extends State<SplitTimesPage> {
  int? _selectedShotIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background(context),
      appBar: AppBar(
        backgroundColor: AppTheme.surface(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textPrimary(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Session Details', style: AppTheme.headingSmall(context)),
        centerTitle: true,
      ),
      body: BlocBuilder<TrainingSessionBloc, TrainingSessionState>(
        builder: (context, state) {
          final shots = widget.savedSession?.steadinessShots ?? state.steadinessShots;
          if (shots.isEmpty) {
            return Center(child: Text('No shot data available', style: AppTheme.bodyMedium(context).copyWith(color: AppTheme.textSecondary(context))));
          }

          final splitData = _calculateSplitTimes(shots);
          final splits = splitData['splits'] as List<double>;
          final stats = _calculateStats(splits);

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: AppTheme.paddingLarge,
                  child: Column(
                    children: [
                      _buildInfoCard(splitData, context),
                      const SizedBox(height: AppTheme.spacingLarge),
                      _buildTable(context, shots, splitData, stats),
                      const SizedBox(height: AppTheme.spacingLarge),
                      TrainingCard(
                        title: 'Performance Analysis',
                        child: SplitTimeChart(splits: splits, selectedIndex: _selectedShotIndex),
                      ),
                      const SizedBox(height: AppTheme.spacingLarge),
                      _buildStatsCompact(stats, splitData, context),
                    ],
                  ),
                ),
              ),
              Container(
                padding: AppTheme.paddingLarge,
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
                              onPressed: () => _exportCsv(splitData, splits),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TrainingButton(
                              label: 'Share',
                              type: ButtonType.secondary,
                              onPressed: () => _shareSummary(splitData, splits),
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
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(Map<String, dynamic> data, BuildContext context) {
    final title = 'Precision Fundamentals';
    final meta = '${data['totalElapsed']} • ${data['shotCount']} shots';

    return Container(
      padding: AppTheme.paddingLarge,
      decoration: BoxDecoration(
        color: AppTheme.surface(context).withOpacity(0.6),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.primary(context).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTheme.titleMedium(context).copyWith(color: AppTheme.primary(context))),
          const SizedBox(height: 4),
          Text(meta, style: AppTheme.bodySmall(context).copyWith(color: AppTheme.textSecondary(context))),
        ],
      ),
    );
  }

  Widget _buildTable(BuildContext context, List<dynamic> shots, Map<String, dynamic> data, Map<String, double> stats) {
    final splits = data['splits'] as List<double>;
    final timestamps = data['timestamps'] as List<double>;

    return TrainingCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            padding: AppTheme.paddingLarge,
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
          ),
          ListView.separated(
            itemCount: shots.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            separatorBuilder: (_, __) => Divider(height: 1, color: AppTheme.border(context).withOpacity(0.3)),
            itemBuilder: (context, index) {
              final shot = shots[index];
              final split = index == 0 ? 0.0 : splits[index - 1];
              final elapsed = timestamps[index];
              final score = shot.score ?? 0;
              final stability = shot.metrics["stability"] ?? 0;
              final isFastest = split > 0 && split == stats['min'];
              final isSlowest = split > 0 && split == stats['max'];
              final isSelected = _selectedShotIndex == index;
              final stabilityColor = stability >= 80 ? AppTheme.success(context) : stability >= 50 ? AppTheme.warning(context) : AppTheme.error(context);

              return InkWell(
                onTap: () => setState(() => _selectedShotIndex = isSelected ? null : index),
                child: Container(
                  padding: AppTheme.paddingLarge,
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primary(context).withOpacity(0.08) : Colors.transparent,
                  ),
                  child: Row(
                    children: [
                      _buildDataCell(context, '${shot.shotNumber}', flex: 1, color: AppTheme.primary(context), isBold: true),
                      _buildDataCell(context, '$score', flex: 1),
                      _buildDataCell(
                        context,
                        index == 0 ? '0.00s' : '${split.toStringAsFixed(2)}s',
                        flex: 1,
                        color: isFastest ? AppTheme.success(context) : isSlowest ? AppTheme.error(context) : null,
                      ),
                      _buildDataCell(context, '${elapsed.toStringAsFixed(2)}s', flex: 1, color: AppTheme.textSecondary(context)),
                      _buildStabilityCell(context, stability, stabilityColor),
                    ],
                  ),
                ),
              );
            },
          ),
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
        style: AppTheme.labelSmall(context).copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.5),
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
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: AppTheme.surfaceVariant(context),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: stability / 100.0,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: color,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text('$stability%', style: AppTheme.bodySmall(context).copyWith(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildStatsCompact(Map<String, double> stats, Map<String, dynamic> data, BuildContext context) {
    final avg = stats['avg'] ?? 0.0;
    final min = stats['min'] ?? 0.0;
    final max = stats['max'] ?? 0.0;
    return Container(
      padding: AppTheme.paddingLarge,
      decoration: AppTheme.inputDecoration(context),
      child: Text(
        'Avg: ${avg.toStringAsFixed(2)}s • Fast: ⚡${min.toStringAsFixed(2)}s • Slow: 🐌${max.toStringAsFixed(2)}s • Shots: ${data['shotCount']}',
        style: AppTheme.bodySmall(context).copyWith(color: AppTheme.textSecondary(context)),
      ),
    );
  }

  Map<String, dynamic> _calculateSplitTimes(List<dynamic> shots) {
    if (shots.isEmpty) return {'shotCount': 0, 'splits': [], 'timestamps': [], 'totalElapsed': '00:00.00'};

    final firstTime = shots.first.timestamp as DateTime;
    final splits = <double>[];
    final timestamps = <double>[];

    for (int i = 0; i < shots.length; i++) {
      final currentTime = shots[i].timestamp as DateTime;
      final elapsed = currentTime.difference(firstTime).inMilliseconds / 1000.0;
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

    return {'shotCount': shots.length, 'splits': splits, 'timestamps': timestamps, 'totalElapsed': totalElapsed};
  }

  Map<String, double> _calculateStats(List<double> splits) {
    if (splits.isEmpty) return {'avg': 0.0, 'min': 0.0, 'max': 0.0, 'stdDev': 0.0};
    final avg = splits.reduce((a, b) => a + b) / splits.length;
    final min = splits.reduce(math.min);
    final max = splits.reduce(math.max);
    final variance = splits.map((x) => math.pow(x - avg, 2)).reduce((a, b) => a + b) / splits.length;
    final stdDev = math.sqrt(variance);
    return {'avg': avg, 'min': min, 'max': max, 'stdDev': stdDev};
  }

  Future<void> _exportCsv(Map<String, dynamic> data, List<double> splits) async {
    final timestamps = (data['timestamps'] as List<double>);
    final buffer = StringBuffer('Shot,Split (s),Elapsed (s)\n');
    for (int i = 0; i < timestamps.length; i++) {
      final split = i == 0 ? 0.0 : splits[i - 1];
      buffer.writeln('${i + 1},${split.toStringAsFixed(2)},${timestamps[i].toStringAsFixed(2)}');
    }
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('CSV copied to clipboard', style: AppTheme.bodyMedium(context))));
  }

  Future<void> _shareSummary(Map<String, dynamic> data, List<double> splits) async {
    final stats = _calculateStats(splits);
    final summary = StringBuffer()
      ..writeln('Session Details')
      ..writeln('Total: ${data['totalElapsed']} • Shots: ${data['shotCount']}')
      ..writeln('Avg: ${stats['avg']?.toStringAsFixed(2)}s | Fast: ${stats['min']?.toStringAsFixed(2)}s | Slow: ${stats['max']?.toStringAsFixed(2)}s');
    await Clipboard.setData(ClipboardData(text: summary.toString()));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Summary copied to clipboard', style: AppTheme.bodyMedium(context))));
  }
}
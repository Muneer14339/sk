
// lib/features/training/presentation/pages/split_times_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math' as math;

import '../../../core/theme/app_theme.dart';
import '../../data/models/saved_session_model.dart';
import '../bloc/training_session/training_session_bloc.dart';
import '../bloc/training_session/training_session_state.dart';
import '../widgets/split_time_chart.dart';
import 'manticx_analysis_page.dart';

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
        title: Text(
          'Session Details',
          style: TextStyle(color: AppTheme.textPrimary(context), fontSize: 16, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<TrainingSessionBloc, TrainingSessionState>(
        builder: (context, state) {
          final shots = widget.savedSession?.steadinessShots ?? state.steadinessShots;
          if (shots.isEmpty) {
            return Center(
              child: Text('No shot data available', style: TextStyle(color: AppTheme.textSecondary(context))),
            );
          }

          final splitData = _calculateSplitTimes(shots);
          final splits = splitData['splits'] as List<double>;
          final stats = _calculateStats(splits);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInfoCard(splitData),
                const SizedBox(height: 12),
                _buildTable(context, shots, splitData, stats),
                const SizedBox(height: 12),
                _buildChartSection(splitData, stats),
                const SizedBox(height: 12),
                _buildStatsCompact(stats, splitData),
                const SizedBox(height: 12),
                _buildActionButtons(splitData, splits),
              ],
            ),
          );
        },
      ),
    );
  }

  // ===== Info Card (like HTML) =====
  Widget _buildInfoCard(Map<String, dynamic> data) {
    final title = 'Precision Fundamentals'; // If you later add a drill name, replace this.
    final meta = '${data['totalElapsed']} • ${data['shotCount']} shots';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface(context).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.primary(context).withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.primary(context))),
          const SizedBox(height: 4),
          Text(meta, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary(context))),
        ],
      ),
    );
  }

  // ===== Table Section (Header + Body) =====
  Widget _buildTable(
      BuildContext context,
      List<dynamic> shots,
      Map<String, dynamic> data,
      Map<String, double> stats,
      ) {
    final splits = data['splits'] as List<double>;
    final timestamps = data['timestamps'] as List<double>;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface(context).withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          // ===== Table Header =====
          LayoutBuilder(
            builder: (context, constraints) {
              double fontSize = constraints.maxWidth * 0.028;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  border: Border(
                    bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildHeaderCell(context, "Shot", flex: 1, fontSize: fontSize),
                    _buildHeaderCell(context, "Score", flex: 1, fontSize: fontSize),
                    _buildHeaderCell(context, "Split", flex: 1, fontSize: fontSize),
                    _buildHeaderCell(context, "Elapsed", flex: 1, fontSize: fontSize),
                    _buildHeaderCell(context, "Stability", flex: 2, fontSize: fontSize),
                  ],
                ),
              );
            },
          ),

          // ===== Table Body =====
          ListView.separated(
            itemCount: shots.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: Colors.white.withOpacity(0.06),
            ),
            itemBuilder: (context, index) {
              final shot = shots[index];
              final split = index == 0 ? 0.0 : splits[index - 1];
              final elapsed = timestamps[index];
              final score = shot.score ?? 0;
              final stability = shot.metrics["stability"] ?? 0;
              final isFastest = split > 0 && split == stats['min'];
              final isSlowest = split > 0 && split == stats['max'];
              final isSelected = _selectedShotIndex == index;
              final stabilityColor = stability >= 80
                  ? AppTheme.success(context)
                  : stability >= 50
                  ? Colors.orange
                  : AppTheme.error(context);

              return InkWell(
                onTap: () {
                  // your tap logic
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primary(context).withOpacity(0.08)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      double fontSize = constraints.maxWidth * 0.03;

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _buildDataCell(
                            context,
                            '${shot.shotNumber}',
                            flex: 1,
                            fontSize: fontSize,
                            textColor: AppTheme.primary(context),
                            isBold: true,
                          ),
                          _buildDataCell(
                            context,
                            '$score',
                            flex: 1,
                            fontSize: fontSize,
                            textColor: AppTheme.textPrimary(context),
                          ),
                          _buildDataCell(
                            context,
                            index == 0
                                ? '0.00s'
                                : '${split.toStringAsFixed(2)}s',
                            flex: 1,
                            fontSize: fontSize,
                            textColor: isFastest
                                ? AppTheme.success(context)
                                : isSlowest
                                ? AppTheme.error(context)
                                : AppTheme.textPrimary(context),
                          ),
                          _buildDataCell(
                            context,
                            '${elapsed.toStringAsFixed(2)}s',
                            flex: 1,
                            fontSize: fontSize * 0.95,
                            textColor: AppTheme.textSecondary(context),
                          ),
                          _buildStabilityCell(
                            context,
                            stability,
                            stabilityColor,
                            fontSize,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// ==== Helper Widgets ====

  Widget _buildHeaderCell(BuildContext context, String text,
      {int flex = 1, double fontSize = 12}) {
    return Expanded(
      flex: flex,
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            text.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textSecondary(context),
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDataCell(
      BuildContext context,
      String text, {
        int flex = 1,
        required double fontSize,
        required Color textColor,
        bool isBold = false,
      }) {
    return Expanded(
      flex: flex,
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStabilityCell(
      BuildContext context, int stability, Color color, double fontSize) {
    return Expanded(
      flex: 2,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              height: fontSize * 0.4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: Colors.white.withOpacity(0.08),
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
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$stability%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: fontSize * 0.9,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hdr(String text, {double? width}) => SizedBox(
    width: width,
    child: Text(
      text.toUpperCase(),
      style: TextStyle(
        color: AppTheme.textSecondary(context),
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    ),
  );

  // ===== Chart Section =====
  Widget _buildChartSection(Map<String, dynamic> data, Map<String, double> stats) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface(context).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Analysis'.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: AppTheme.textSecondary(context),
            ),
          ),
          const SizedBox(height: 8),
          SplitTimeChart(
            splits: data['splits'] as List<double>,
            selectedIndex: _selectedShotIndex,
          ),
        ],
      ),
    );
  }

  // ===== Stats Compact =====
  Widget _buildStatsCompact(Map<String, double> stats, Map<String, dynamic> data) {
    final avg = stats['avg'] ?? 0.0;
    final min = stats['min'] ?? 0.0;
    final max = stats['max'] ?? 0.0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface(context).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Text(
        'Avg: ${avg.toStringAsFixed(2)}s • Fast: ⚡${min.toStringAsFixed(2)}s • Slow: 🐌${max.toStringAsFixed(2)}s • Shots: ${data['shotCount']}',
        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary(context)),
      ),
    );
  }

  // ===== Action Buttons (2 in first row, 1 below) =====
  Widget _buildActionButtons(Map<String, dynamic> data, List<double> splits) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _actionBtn(
                label: 'Export CSV',
                onTap: () => _exportCsv(data, splits),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _actionBtn(
                label: 'Share',
                onTap: () => _shareSummary(data, splits),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: _primaryBtn(
            label: 'Back to Summary',
            onTap: () => Navigator.pop(context),
          ),
        ),
      ],
    );
  }

  Widget _actionBtn({required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Ink(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Center(
          child: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary(context))),
        ),
      ),
    );
  }

  Widget _primaryBtn({required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Ink(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.primary(context),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.background(context))),
        ),
      ),
    );
  }

  // ===== Helpers =====
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

    return {
      'shotCount': shots.length,
      'splits': splits,
      'timestamps': timestamps,
      'totalElapsed': totalElapsed,
    };
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
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CSV copied to clipboard')),
      );
    }
  }

  Future<void> _shareSummary(Map<String, dynamic> data, List<double> splits) async {
    final stats = _calculateStats(splits);
    final summary = StringBuffer()
      ..writeln('Session Details')
      ..writeln('Total: ${data['totalElapsed']} • Shots: ${data['shotCount']}')
      ..writeln('Avg: ${stats['avg']?.toStringAsFixed(2)}s | Fast: ${stats['min']?.toStringAsFixed(2)}s | Slow: ${stats['max']?.toStringAsFixed(2)}s');
    await Clipboard.setData(ClipboardData(text: summary.toString()));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Summary copied to clipboard')),
      );
    }
  }
}

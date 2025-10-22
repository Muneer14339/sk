// lib/features/training/presentation/pages/split_times_page.dart
import 'package:flutter/material.dart';
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
          'Split Times',
          style: TextStyle(color: AppTheme.textPrimary(context), fontSize: 18),
        ),
      ),
      body: BlocBuilder<TrainingSessionBloc, TrainingSessionState>(
        builder: (context, state) {
          final steadinessShots = widget.savedSession?.steadinessShots ?? state.steadinessShots;

          if (steadinessShots.isEmpty) {
            return Center(
              child: Text('No shot data available', style: TextStyle(color: AppTheme.textSecondary(context))),
            );
          }

          final splitData = _calculateSplitTimes(steadinessShots);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsChips(splitData),
                const SizedBox(height: 16),
                _buildChart(splitData),
                const SizedBox(height: 16),
                _buildTotalElapsed(splitData),
                const SizedBox(height: 16),
                _buildShotList(context, steadinessShots, splitData),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsChips(Map<String, dynamic> data) {
    final splits = data['splits'] as List<double>;
    final stats = _calculateStats(splits);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildChip('Shots', '${data['shotCount']}'),
        _buildChip('Avg', '${stats['avg']?.toStringAsFixed(2)}s'),
        _buildChip('Fastest', '${stats['min']?.toStringAsFixed(2)}s'),
        _buildChip('Slowest', '${stats['max']?.toStringAsFixed(2)}s'),
        _buildChip('Std Dev', '${stats['stdDev']?.toStringAsFixed(2)}s'),
      ],
    );
  }

  Widget _buildChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: RichText(
        text: TextSpan(
          text: '$label: ',
          style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 13),
          children: [
            TextSpan(
              text: value,
              style: TextStyle(color: AppTheme.textPrimary(context), fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          SplitTimeChart(
            splits: data['splits'] as List<double>,
            selectedIndex: _selectedShotIndex,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap a shot below to highlight on chart',
            style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalElapsed(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total Elapsed',
            style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 14),
          ),
          Text(
            data['totalElapsed'],
            style: TextStyle(
              color: AppTheme.textPrimary(context),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShotList(BuildContext context, List<dynamic> shots, Map<String, dynamic> data) {
    final splits = data['splits'] as List<double>;
    final stats = _calculateStats(splits);

    return Column(
      children: List.generate(shots.length, (index) {
        final shot = shots[index];
        final splitTime = index == 0 ? 0.0 : splits[index - 1];
        final elapsed = data['timestamps'][index] as double;
        final isFastest = splitTime > 0 && splitTime == stats['min'];
        final isSlowest = splitTime > 0 && splitTime == stats['max'];
        final isSelected = _selectedShotIndex == index;

        return GestureDetector(
          onTap: () {
            setState(() => _selectedShotIndex = index);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ManticXAnalysisPage(),
                settings: RouteSettings(
                  arguments: {
                    'savedSession': widget.savedSession,
                    'selectedShotNumber': shot.shotNumber,  // Pass shot number
                  },
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primary(context).withValues(alpha: 0.1) : AppTheme.surface(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppTheme.primary(context) : Colors.white.withValues(alpha: 0.1),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.background(context),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Center(
                    child: Text(
                      'X${index + 1}',
                      style: TextStyle(
                        color: AppTheme.textPrimary(context),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            index == 0 ? 'Start • ' : 'Split • ',
                            style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 13),
                          ),
                          Text(
                            index == 0 ? '0.00s' : '${splitTime.toStringAsFixed(2)}s',
                            style: TextStyle(
                              color: isFastest
                                  ? AppTheme.success(context)
                                  : isSlowest
                                  ? AppTheme.error(context)
                                  : AppTheme.textPrimary(context),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Elapsed ${elapsed.toStringAsFixed(2)}s',
                        style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Text(
                  index == 0 ? '—' : 'Δ${index.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: AppTheme.textSecondary(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
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
}
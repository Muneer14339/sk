import 'package:flutter/material.dart';

import '../../data/model/analysis_model.dart';
import '../../data/model/streaming_model.dart' as streaming;

class ShotDetailsContent extends StatelessWidget {
  const ShotDetailsContent({
    super.key,
    required this.shotTrace,
  });
  final AnalysisModel shotTrace;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Performance Overview Cards
          Row(
            children: [
              Expanded(
                  child: _buildMetricCard(
                      'Precision',
                      '${(100 - (shotTrace.maxMagnitude ?? 0) * 20).toStringAsFixed(1)}%',
                      Icons.precision_manufacturing,
                      const Color(0xFF10B981))),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildMetricCard(
                      'Stability',
                      calculateShotScore(shotTrace.tracePoints ?? [],
                              shotTrace.maxMagnitude ?? 0)
                          .toStringAsFixed(0),
                      Icons.star_border_outlined,
                      const Color(0xFF3B82F6))),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoCard('Basic Information', [
            _buildModernInfoRow(
                'Shot Number', '${shotTrace.shotNumber}', Icons.numbers),
            _buildModernInfoRow('Max Movement',
                '${shotTrace.maxMagnitude?.toStringAsFixed(3)}°', Icons.speed),
            _buildModernInfoRow(
                'Timestamp',
                shotTrace.timestamp.toString().split(' ')[1].substring(0, 8),
                Icons.access_time),
          ]),
          const SizedBox(height: 20),
          _buildInfoCard('Trace Analysis', [
            _buildModernInfoRow('Total Points',
                '${shotTrace.tracePoints?.length}', Icons.data_usage),
            _buildModernInfoRow(
                'Pre-Shot',
                shotTrace.tracePoints
                        ?.where((p) => p.phase == streaming.TracePhase.preShot)
                        .length
                        .toString() ??
                    '0',
                Icons.timeline),
            _buildModernInfoRow(
                'Shot Phase',
                shotTrace.tracePoints
                        ?.where((p) => p.phase == streaming.TracePhase.shot)
                        .length
                        .toString() ??
                    '0',
                Icons.flash_on),
            _buildModernInfoRow(
                'Post-Shot',
                shotTrace.tracePoints
                        ?.where((p) => p.phase == streaming.TracePhase.postShot)
                        .length
                        .toString() ??
                    '0',
                Icons.replay),
          ]),
          const SizedBox(height: 20),
          _buildInfoCard('Technical Data', [
            _buildModernInfoRow('Status',
                shotTrace.metrics?.status ?? 'Complete', Icons.verified),
            _buildModernInfoRow(
                'Balance',
                (shotTrace.metrics?.isBalanced ?? false) ? 'Optimal' : 'Adjust',
                Icons.balance),
            _buildModernInfoRow(
                'Smoothing',
                (shotTrace.metrics?.smoothingApplied ?? false)
                    ? 'Applied'
                    : 'Raw',
                Icons.filter_alt),
          ]),
          if (shotTrace.analysisNotes?.isNotEmpty ?? false) ...[
            const SizedBox(height: 20),
            _buildInfoCard('Coach Notes', [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF475569)),
                ),
                child: Text(
                  shotTrace.analysisNotes ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFFE6EEFC),
                    height: 1.4,
                  ),
                ),
              )
            ])
          ]
        ],
      ),
    );
  }

  static double calculateShotScore(
      List<streaming.TracePoint> tracePoints, double maxMagnitude) {
    if (tracePoints.isEmpty) return 0.0;

    double totalVariance = 0.0;
    double centerX = 0.0, centerY = 0.0;

    for (var point in tracePoints) {
      centerX += point.point.x;
      centerY += point.point.y;
    }
    centerX /= tracePoints.length;
    centerY /= tracePoints.length;

    for (var point in tracePoints) {
      final distance =
          ((point.point.x - centerX).abs() + (point.point.y - centerY).abs()) /
              2;
      totalVariance += distance;
    }

    final avgVariance = totalVariance / tracePoints.length;
    final stabilityScore = (1.0 - (avgVariance / 2.0)).clamp(0.0, 1.0) * 100;
    final magnitudeScore = (1.0 - (maxMagnitude / 5.0)).clamp(0.0, 1.0) * 100;

    return (stabilityScore * 0.7 + magnitudeScore * 0.3);
  }

  Widget _buildMetricCard(
          String title, String value, IconData icon, Color color) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.1), Colors.transparent],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );

  Widget _buildModernInfoRow(String label, String value, IconData icon) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: const Color(0xFF3B82F6)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFFE6EEFC),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
  Widget _buildInfoCard(String title, List<Widget> children) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: const Color(0xFF334155).withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF475569),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE6EEFC),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      );
}

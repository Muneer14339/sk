import 'package:flutter/material.dart';

class MetricsSectionCard extends StatelessWidget {
  const MetricsSectionCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFe8f4f8),
        border: Border.all(
          color: const Color(0xFF17a2b8),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Text(
                  '📊',
                  style: TextStyle(
                    fontSize: 14.4, // 0.9em equivalent (16 * 0.9 = 14.4)
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Measurement Metrics',
                  style: TextStyle(
                    fontSize: 14.4, // 0.9em equivalent
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0c5460),
                  ),
                ),
              ],
            ),
          ),

          // Metric Items
          _buildMetricItem(
            label: 'Stability Score:',
            threshold: '0-100 (muzzle steadiness)',
            isLast: false,
          ),
          _buildMetricItem(
            label: 'Trigger Control:',
            threshold: '0-100 (straight-back pull)',
            isLast: false,
          ),
          _buildMetricItem(
            label: 'Success Target:',
            threshold: '4/5 shots ≥85% on both',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required String label,
    required String threshold,
    required bool isLast,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11, // 0.8em equivalent (16 * 0.8 = 12.8)
              color: Color(0xFF495057),
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            threshold,
            style: const TextStyle(
              fontSize: 11, // 0.8em equivalent
              fontWeight: FontWeight.bold,
              color: Color(0xFF0c5460),
            ),
          ),
        ],
      ),
    );
  }
}

// color: Color(0xFF2C3E50),
import 'package:flutter/material.dart';

class ProgramStatsCard extends StatelessWidget {
  const ProgramStatsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          _buildStatItem(
            icon: '⏱️',
            value: '30',
            label: 'min\navg',
          ),
          const SizedBox(width: 15),
          _buildStatItem(
            icon: '🎯',
            value: '92%',
            label: 'success\nrate',
          ),
          const SizedBox(width: 15),
          _buildStatItem(
            icon: '👥',
            value: '567',
            label: 'completed',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String icon,
    required String value,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          icon,
          style: const TextStyle(fontSize: 12.8),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12.8, // 0.8em equivalent
            fontWeight: FontWeight.bold,
            color: Color(0xFF2c3e50),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9, // 0.8em equivalent
            color: Color(0xFF6c757d),
          ),
        ),
      ],
    );
  }
}

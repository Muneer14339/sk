// Build program information header
import 'package:flutter/material.dart';

import '../../data/model/programs_model.dart';
import '../bloc/training_session/training_session_state.dart';
Widget buildProgramInfoHeader(
    {required String programName, required String programDescription}) {
  return Container(
    padding: const EdgeInsets.all(8.0),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [
          Color.fromARGB(255, 76, 57, 54),
          Color.fromARGB(255, 56, 16, 12)
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(12.0),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: 10,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: Column(
      children: [
        Text(
          programName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          programDescription,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

// Build connection status
Widget buildConnectionStatus(bool isConnected) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: isConnected
            ? [const Color(0xFF28A745), const Color(0xFF218838)]
            : [const Color(0xFFDC3545), const Color(0xFFC82333)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(10.0),
    ),
    child: Text(
      isConnected ? "RT Sensor Connected" : "RT Sensor Not Connected",
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      textAlign: TextAlign.center,
    ),
  );
}

// Format duration helper method
String _formatDuration(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, "0");
  String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
  String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
  return "$twoDigitMinutes:$twoDigitSeconds";
}

// Build enhanced status card
Widget buildEnhancedStatusCard(TrainingSessionState sessionState,
    ProgramsModel program, int selectedDistance) {
  return Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: const Color(0xFF111A2B),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFF1A2440), width: 1),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: buildMetricItem(
                'Shots',
                '${sessionState.shotCount}/${program.noOfShots}',
                Icons.gps_fixed,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: buildMetricItem(
                'Time',
                _formatDuration(DateTime.now().difference(
                    sessionState.sessionStartTime ?? DateTime.now())),
                Icons.timer,
                valueColor: sessionState.isTraining
                    ? const Color(0xFF5EA1FF)
                    : const Color(0xFFA8B3C7),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: buildMetricItem(
                'Distance',
                '$selectedDistance m',
                Icons.straighten,
                valueColor: sessionState.isTraining
                    ? const Color(0xFF5EA1FF)
                    : const Color(0xFFA8B3C7),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget buildMetricItem(
  String label,
  String value,
  IconData icon, {
  Color? valueColor,
}) {
  return Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: const Color(0xFF0F1830),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFF1A2440), width: 1),
    ),
    child: Column(
      children: [
        Icon(icon, color: const Color(0xFF93A4C7), size: 16),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF93A4C7), fontSize: 12),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? const Color(0xFFE6EEFC),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

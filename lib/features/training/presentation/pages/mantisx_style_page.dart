// import 'package:flutter/material.dart';
// import '../../data/datasources/sensor_processor.dart';

// /// Widget that displays MantisX-style dynamic aim point information
// class MantisXAimPointDisplay extends StatelessWidget {
//   final SensorProcessor sensorProcessor;
//   final bool showDebugInfo;

//   const MantisXAimPointDisplay({
//     super.key,
//     required this.sensorProcessor,
//     this.showDebugInfo = false,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final aimingStatus = sensorProcessor.currentAimingStatus;

//     return Container(
//       padding: const EdgeInsets.all(16.0),
//       decoration: BoxDecoration(
//         color: Colors.white.withValues(alpha: 0.95),
//         borderRadius: BorderRadius.circular(12.0),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: 0.1),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           // Header
//           Row(
//             children: [
//               const Icon(
//                 Icons.gps_fixed,
//                 color: Color(0xFF17A2B8),
//                 size: 24,
//               ),
//               const SizedBox(width: 8),
//               const Text(
//                 'MantisX Aim Point',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: Color(0xFF2C3E50),
//                 ),
//               ),
//               const Spacer(),
//               _buildAimingStatusIndicator(),
//             ],
//           ),
//           const SizedBox(height: 16),

//           // Aim Point Information
//           _buildAimPointInfo(),

//           // Aim Point Quality
//           const SizedBox(height: 12),
//           _buildAimPointQuality(),

//           // Aim Status Message
//           if (aimingStatus['aimPoint'] != null) ...[
//             const SizedBox(height: 8),
//             _buildAimStatusMessage(aimingStatus),
//           ],

//           // Debug Information (optional)
//           if (showDebugInfo) ...[
//             const SizedBox(height: 12),
//             _buildDebugInfo(),
//           ],

//           // Manual Controls
//           const SizedBox(height: 16),
//           _buildManualControls(),
//         ],
//       ),
//     );
//   }

//   Widget _buildAimingStatusIndicator() {
//     final isAiming = sensorProcessor.isAiming;
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//       decoration: BoxDecoration(
//         color: isAiming ? Colors.green : Colors.grey,
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Text(
//         isAiming ? 'AIMING' : 'NOT AIMING',
//         style: const TextStyle(
//           color: Colors.white,
//           fontSize: 10,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//     );
//   }

//   Widget _buildAimPointInfo() {
//     final aimPoint = sensorProcessor.currentAimPoint;

//     if (aimPoint == null) {
//       return Container(
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           color: Colors.grey.withOpacity(0.1),
//           borderRadius: BorderRadius.circular(8),
//         ),
//         child: const Row(
//           children: [
//             Icon(Icons.info_outline, color: Colors.grey, size: 20),
//             SizedBox(width: 8),
//             Text(
//               'No aim point set - hold steady to establish aim point',
//               style: TextStyle(
//                 color: Colors.grey,
//                 fontSize: 14,
//               ),
//             ),
//           ],
//         ),
//       );
//     }

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Current Aim Point:',
//           style: TextStyle(
//             fontSize: 14,
//             fontWeight: FontWeight.w600,
//             color: Color(0xFF6C757D),
//           ),
//         ),
//         const SizedBox(height: 8),
//         Row(
//           children: [
//             Expanded(
//               child: _buildAimPointMetric(
//                 'Roll',
//                 '${aimPoint.roll.toStringAsFixed(1)}°',
//                 Icons.rotate_right,
//                 Colors.blue,
//               ),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: _buildAimPointMetric(
//                 'Pitch',
//                 '${aimPoint.pitch.toStringAsFixed(1)}°',
//                 Icons.arrow_upward,
//                 Colors.orange,
//               ),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: _buildAimPointMetric(
//                 'Yaw',
//                 '${aimPoint.yaw.toStringAsFixed(1)}°',
//                 Icons.compass_calibration,
//                 Colors.purple,
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 8),
//         Text(
//           'Set at: ${_formatTimestamp(aimPoint.timestamp)}',
//           style: const TextStyle(
//             fontSize: 12,
//             color: Colors.grey,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildAimPointMetric(
//     String label,
//     String value,
//     IconData icon,
//     Color color,
//   ) {
//     return Container(
//       padding: const EdgeInsets.all(8),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(6),
//         border: Border.all(color: color.withOpacity(0.3)),
//       ),
//       child: Column(
//         children: [
//           Icon(icon, color: color, size: 16),
//           const SizedBox(height: 4),
//           Text(
//             label,
//             style: TextStyle(
//               fontSize: 10,
//               color: color,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//           const SizedBox(height: 2),
//           Text(
//             value,
//             style: TextStyle(
//               fontSize: 14,
//               fontWeight: FontWeight.bold,
//               color: color,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildAimPointQuality() {
//     final quality = sensorProcessor.aimPointQuality;
//     final qualityPercentage = (quality * 100).round();

//     Color qualityColor;
//     String qualityText;

//     if (quality >= 0.8) {
//       qualityColor = Colors.green;
//       qualityText = 'Excellent';
//     } else if (quality >= 0.6) {
//       qualityColor = Colors.orange;
//       qualityText = 'Good';
//     } else if (quality >= 0.4) {
//       qualityColor = Colors.yellow.shade700;
//       qualityText = 'Fair';
//     } else {
//       qualityColor = Colors.red;
//       qualityText = 'Poor';
//     }

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             const Text(
//               'Aim Point Quality:',
//               style: TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w600,
//                 color: Color(0xFF6C757D),
//               ),
//             ),
//             const Spacer(),
//             Text(
//               qualityText,
//               style: TextStyle(
//                 fontSize: 12,
//                 fontWeight: FontWeight.bold,
//                 color: qualityColor,
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 8),
//         LinearProgressIndicator(
//           value: quality,
//           backgroundColor: Colors.grey.withOpacity(0.3),
//           valueColor: AlwaysStoppedAnimation<Color>(qualityColor),
//           minHeight: 8,
//         ),
//         const SizedBox(height: 4),
//         Text(
//           '$qualityPercentage%',
//           style: TextStyle(
//             fontSize: 12,
//             color: qualityColor,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildAimStatusMessage(Map<String, dynamic> aimingStatus) {
//     return Container(
//       padding: const EdgeInsets.all(8),
//       decoration: BoxDecoration(
//         color: Colors.green.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(6),
//         border: Border.all(color: Colors.green.withOpacity(0.3)),
//       ),
//       child: Row(
//         children: [
//           Icon(
//             Icons.info_outline,
//             color: Colors.green[700],
//             size: 16,
//           ),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Text(
//               aimingStatus['message'] ?? 'Aim status unknown',
//               style: TextStyle(
//                 fontSize: 12,
//                 color: Colors.green[700],
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDebugInfo() {
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Colors.blue.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: Colors.blue.withOpacity(0.3)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Row(
//             children: [
//               Icon(Icons.bug_report, color: Colors.blue, size: 16),
//               SizedBox(width: 8),
//               Text(
//                 'Debug Information',
//                 style: TextStyle(
//                   fontSize: 12,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.blue,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Buffer Size: ${sensorProcessor.preShotBufferSize}',
//             style: const TextStyle(fontSize: 11, color: Colors.blue),
//           ),
//           Text(
//             'Stability Threshold: 0.01°²',
//             style: const TextStyle(fontSize: 11, color: Colors.blue),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildManualControls() {
//     return Row(
//       children: [
//         Expanded(
//           child: ElevatedButton.icon(
//             onPressed: () {
//               sensorProcessor.forceAimPointRecalculation();
//             },
//             icon: const Icon(Icons.refresh, size: 16),
//             label: const Text('Recalculate'),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.orange,
//               foregroundColor: Colors.white,
//               padding: const EdgeInsets.symmetric(vertical: 8),
//             ),
//           ),
//         ),
//         const SizedBox(width: 8),
//         Expanded(
//           child: ElevatedButton.icon(
//             onPressed: () {
//               // Set a test aim point for demonstration
//               sensorProcessor.setManualAimPoint(0.0, 0.0, 0.0);
//             },
//             icon: const Icon(Icons.settings, size: 16),
//             label: const Text('Test'),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.blue,
//               foregroundColor: Colors.white,
//               padding: const EdgeInsets.symmetric(vertical: 8),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   String _formatTimestamp(DateTime timestamp) {
//     final now = DateTime.now();
//     final difference = now.difference(timestamp);

//     if (difference.inSeconds < 60) {
//       return '${difference.inSeconds}s ago';
//     } else if (difference.inMinutes < 60) {
//       return '${difference.inMinutes}m ago';
//     } else {
//       return '${difference.inHours}h ago';
//     }
//   }
// }

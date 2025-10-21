// lib/features/training/presentation/pages/calibration_page.dart
import 'dart:async';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';


import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_appbar.dart';
import '../../../core/widgets/primary_button.dart';
import '../bloc/training_session/training_session_bloc.dart';
import '../bloc/training_session/training_session_event.dart';
import '../bloc/training_session/training_session_state.dart';

class CalibrationPage extends StatefulWidget {
  final String calibrationType;
  final int targetShots;

  const CalibrationPage({
    super.key,
    required this.calibrationType,
    this.targetShots = 10, // NEW: Default value for backwards compatibility
  });

  @override
  State<CalibrationPage> createState() => _CalibrationPageState();
}

class _CalibrationPageState extends State<CalibrationPage> {
  bool isCalibrating = false;
  bool showResults = false;

  int detectedShots = 0;
  int falsePositives = 0;
  int missedShots = 0;
  List<Map<String, dynamic>> shotData = [];

  File? savedCsvFile;
  StreamSubscription? _shotSubscription;

  // NEW: Getter for target shots
  int get targetShots => widget.targetShots;

  // NEW: Timer state
  DateTime? _calibrationStartTime;
  Timer? _uiTimer;

  @override
  void initState() {
    super.initState();
    final bloc = context.read<TrainingSessionBloc>();
    final device = bloc.state.device;
    // NEW: Clear all previous session data when entering calibration
    context.read<TrainingSessionBloc>().add(ClearLastSession(device: device!));
    _setupShotDetectionListener();
  }

  @override
  void dispose() {
    _shotSubscription?.cancel();
    _uiTimer?.cancel();
    super.dispose();
  }

  // NEW: Format duration helper
  String _formatDuration(Duration d) =>
      "${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}";

  void _setupShotDetectionListener() {
    int lastProcessedShot = 0;

    _shotSubscription = context.read<TrainingSessionBloc>().stream.listen((
        state,
        ) {
      if (isCalibrating && state.shotCount > lastProcessedShot) {
        lastProcessedShot = state.shotCount;
        _showShotConfirmationDialog(state);
      }
      // ✅ NEW: Handle sensor errors
      if (state.sensorError != null) {
        _handleSensorError(context, state.sensorError!);
      }
    });
  }

  // Add the same method:
  void _handleSensorError(BuildContext context, String error) {
    // Stop calibration if running
    if (isCalibrating) {
      _stopCalibration();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.kSurface,
        title: Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.kError),
            const SizedBox(width: 8),
            Text(
              'Sensor Error',
              style: TextStyle(color: AppColors.kTextPrimary),
            ),
          ],
        ),
        content: Text(error, style: TextStyle(color: AppColors.kTextSecondary)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext); // Close dialog
              Navigator.pop(context); // Navigate back
            },
            style:
            TextButton.styleFrom(foregroundColor: AppColors.kPrimaryTeal),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showShotConfirmationDialog(TrainingSessionState state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.sensors, color: AppColors.kPrimaryTeal),
            const SizedBox(width: 8),
            const Text('Shot Detected'),
          ],
        ),
        content: const Text('Was this an actual shot?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _recordFalsePositive(state);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.kError),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _recordConfirmedShot(state);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.kSuccess,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  void _recordConfirmedShot(TrainingSessionState state) {
    setState(() {
      detectedShots++;
      final now = DateTime.now();
      final shotRecord = {
        'timestamp': now.millisecondsSinceEpoch,
        'shot_number': detectedShots,
        'shot_type': 'detected',
        'theta_deg': state.thetaInstDeg,
        'position_x': state.lastDrawX,
        'position_y': state.lastDrawY,
        'calibration_type': widget.calibrationType,
      };
      shotData.add(shotRecord);
    });

    _checkCompletion();
  }

  void _recordFalsePositive(TrainingSessionState state) {
    setState(() {
      falsePositives++;
      final now = DateTime.now();
      final shotRecord = {
        'timestamp': now.millisecondsSinceEpoch,
        'shot_number': falsePositives,
        'shot_type': 'false_positive',
        'theta_deg': state.thetaInstDeg,
        'position_x': state.lastDrawX,
        'position_y': state.lastDrawY,
        'calibration_type': widget.calibrationType,
      };
      shotData.add(shotRecord);
    });

    _checkCompletion();
  }

  void _simulateShot() {
    if (!isCalibrating) return;

    setState(() {
      missedShots++;
      final shotRecord = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'shot_number': missedShots,
        'shot_type': 'missed',
        'theta_deg': 0.0,
        'position_x': 0.0,
        'position_y': 0.0,
        'calibration_type': widget.calibrationType
      };
      shotData.add(shotRecord);
    });

    _checkCompletion();
  }

  void _checkCompletion() {
    final totalShots = detectedShots + falsePositives + missedShots;
    if (totalShots >= targetShots) {
      // CHANGED
      _completeCalibration();
    }
  }

  Future<void> _saveShotDataToCsv() async {
    try {
      if (await Permission.storage.request().isGranted ||
          await Permission.manageExternalStorage.request().isGranted) {
        final directory = await getExternalStorageDirectory();
        if (directory != null) {
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final filename = 'shotdata_${widget.calibrationType}_$timestamp.csv';
          final file = File('${directory.path}/$filename');

          List<List<dynamic>> csvData = [
            [
              'Timestamp',
              'Shot_Number',
              'Shot_Type',
              'Theta_Deg',
              'Position_X',
              'Position_Y',
              'Calibration_Type',
            ],
          ];

          for (var shot in shotData) {
            csvData.add([
              shot['timestamp'],
              shot['shot_number'],
              shot['shot_type'],
              shot['theta_deg'],
              shot['position_x'],
              shot['position_y'],
              shot['calibration_type'],
            ]);
          }

          String csvString = const ListToCsvConverter().convert(csvData);
          await file.writeAsString(csvString);

          savedCsvFile = file;

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Shot data saved to: $filename')),
            );
          }

          _showOpenFileDialog(file);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving data: $e')));
      }
    }
  }

  void _startCalibration() {
    setState(() {
      isCalibrating = true;
      detectedShots = 0;
      falsePositives = 0;
      missedShots = 0;
      shotData.clear();
      showResults = false;
      _calibrationStartTime = DateTime.now(); // NEW: Start timer
    });

    // NEW: Start UI timer for updates
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && isCalibrating) {
        setState(() {}); // Trigger rebuild for timer
      }
    });

    // CHANGED: Use calibration-specific event
    context.read<TrainingSessionBloc>().add(const StartCalibrationSession());
  }

  void _stopCalibration() {
    setState(() {
      isCalibrating = false;
    });

    _uiTimer?.cancel(); // NEW: Stop timer

    // CHANGED: Use calibration-specific event
    context.read<TrainingSessionBloc>().add(const StopCalibrationSession());
  }

  void _completeCalibration() {
    setState(() {
      isCalibrating = false;
      showResults = true;
    });

    _stopCalibration();
    _showExportDialog();
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export CSV'),
        content: const Text(
          'Do you want to save the calibration results as a CSV file?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _saveShotDataToCsv();
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  void _showOpenFileDialog(File file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('CSV Saved'),
        content: Text('File saved at:\n${file.path}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _openCsvFile(file);
            },
            child: const Text('Open File'),
          ),
        ],
      ),
    );
  }

  void _openCsvFile(File file) {
    OpenFilex.open(file.path);
  }

  void _removeLastDetection() {
    if (shotData.isEmpty) return;

    setState(() {
      final lastShot = shotData.last;
      final shotType = lastShot['shot_type'];

      shotData.removeLast();

      if (shotType == 'detected') {
        detectedShots--;
      } else if (shotType == 'false_positive') {
        falsePositives--;
      } else if (shotType == 'missed') {
        missedShots--;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBackground,
      appBar: customAppBar(
        title: 'Calibration - ${widget.calibrationType.toUpperCase()} Fire',
        context: context,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (!showResults) ...[
                _buildInstructionsCard(),
                const SizedBox(height: 16),
                _buildStatusCard(),
                const SizedBox(height: 16),
                _buildControlButtons(),
              ] else ...[
                _buildResultsCard(),
                const SizedBox(height: 16),
                _buildActionButtons(),
              ],
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.kPrimaryTeal.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.kPrimaryTeal),
              const SizedBox(width: 8),
              Text(
                '${widget.calibrationType.toUpperCase()} Fire Calibration',
                style: TextStyle(
                  color: AppColors.kTextPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '• Fire $targetShots shots at normal pace\n' // CHANGED
                '• Confirm each detected shot\n'
                '• Use "Missed Shot" for undetected shots\n'
                '• System will auto-complete at $targetShots total', // CHANGED
            style: TextStyle(
              color: AppColors.kTextSecondary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // UPDATED: Add timer display to status card
  Widget _buildStatusCard() {
    final totalShots = detectedShots + falsePositives + missedShots;
    final elapsed = _calibrationStartTime != null
        ? DateTime.now().difference(_calibrationStartTime!)
        : Duration.zero;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.kSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // NEW: Timer display
          if (isCalibrating || _calibrationStartTime != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.kPrimaryTeal.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timer, color: AppColors.kPrimaryTeal, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    _formatDuration(elapsed),
                    style: TextStyle(
                      color: AppColors.kPrimaryTeal,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),

          // Existing metrics
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetric(
                'Detected',
                detectedShots.toString(),
                AppColors.kSuccess,
              ),
              _buildMetric(
                'False+',
                falsePositives.toString(),
                AppColors.kError,
              ),
              _buildMetric(
                'Missed',
                missedShots.toString(),
                AppColors.appYellow,
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: totalShots / targetShots,
            backgroundColor: AppColors.kBackground,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.kPrimaryTeal),
          ),
          const SizedBox(height: 8),
          Text(
            '$totalShots / $targetShots total shots',
            style: TextStyle(color: AppColors.kTextSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // UPDATED: Show timer in results card
  Widget _buildResultsCard() {
    final totalShots = detectedShots + falsePositives + missedShots;
    final accuracy = totalShots > 0 ? (detectedShots / totalShots * 100) : 0.0;
    final totalTime = _calibrationStartTime != null
        ? DateTime.now().difference(_calibrationStartTime!)
        : Duration.zero;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.kSuccess.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_outline, color: AppColors.kSuccess),
              const SizedBox(width: 8),
              Text(
                'Calibration Complete',
                style: TextStyle(
                  color: AppColors.kTextPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildResultRow('Total Time:', _formatDuration(totalTime)), // NEW
          _buildResultRow('Total Shots:', '$totalShots'),
          _buildResultRow('Successfully Detected:', '$detectedShots'),
          _buildResultRow('False Positives:', '$falsePositives'),
          _buildResultRow('Missed Shots:', '$missedShots'),
          const Divider(height: 24),
          _buildResultRow(
            'Detection Accuracy:',
            '${accuracy.toStringAsFixed(1)}%',
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: AppColors.kTextSecondary, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildControlButtons() {
    return Column(
      children: [
        if (!isCalibrating) ...[
          PrimaryButton(title: 'START CALIBRATION', onTap: _startCalibration),
        ] else ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _stopCalibration,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.kError,
                    side: BorderSide(color: AppColors.kError),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Stop'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _simulateShot,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.appYellow.withValues(alpha: .3),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: AppColors.appYellow),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('+ Add Shot Manually'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _removeLastDetection,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.kError,
              side: BorderSide(color: AppColors.kError.withValues(alpha: .5)),
              padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Remove Last Detection'),
          ),
        ],
      ],
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: AppColors.kTextSecondary, fontSize: 14),
          ),
          Text(
            value,
            style: TextStyle(
              color: AppColors.kTextPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        PrimaryButton(
          title: 'Try Again',
          onTap: () {
            setState(() {
              showResults = false;
              detectedShots = 0;
              falsePositives = 0;
              missedShots = 0;
              shotData.clear();
            });
          },
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.kTextSecondary,
            side: BorderSide(color: AppColors.kTextSecondary.withOpacity(0.5)),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          ),
          child: const Text('Back to Training'),
        ),
      ],
    );
  }
}

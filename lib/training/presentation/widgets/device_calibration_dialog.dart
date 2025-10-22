// lib/features/training/presentation/widgets/device_calibration_dialog.dart
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';


class DeviceCalibrationDialog extends StatefulWidget {
  final VoidCallback onStartCalibration;
  final VoidCallback onFactoryReset;

  const DeviceCalibrationDialog({
    super.key,
    required this.onStartCalibration,
    required this.onFactoryReset,
  });

  @override
  State<DeviceCalibrationDialog> createState() => _DeviceCalibrationDialogState();
}

class _DeviceCalibrationDialogState extends State<DeviceCalibrationDialog> {
  bool _isCalibrating = false;
  bool _showHelp = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF0E141B),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF283142)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ===== Header =====
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFF0B1117),
                borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                border: Border(bottom: BorderSide(color: Color(0xFF283142))),
              ),
              child: const Text(
                "Sensor calibration required",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),

            // ===== Scrollable Content =====
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Please mount the device in its actual shooting position — on your firearm, bipod, or tripod — exactly as you plan to use it.',
                      style: TextStyle(color: Colors.white.withOpacity(0.95), fontSize: 14, height: 1.4),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Once mounted, ensure the setup is completely still on a stable surface.',
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    _buildBullet('Do not touch or move the firearm or device during calibration.'),
                    _buildBullet('Calibration captures mounting angle and sensor bias.'),
                    const SizedBox(height: 10),
                    Text(
                      'Calibration takes about 3–5 seconds.',
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                    ),
                    const SizedBox(height: 18),

                    // ===== Optional Help Panel =====
                    if (_showHelp) _buildHelpPanel(),

                    // ===== "More tips" section =====
                    Theme(
                      data: ThemeData().copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        iconColor: AppTheme.primary(context),
                        collapsedIconColor: Colors.white70,
                        title: const Text(
                          'More tips',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF121822),
                              border: Border.all(color: const Color(0xFF283142)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Quick guide',
                                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                                SizedBox(height: 8),
                                _TipText('• Calibrate once per connection. Recalibrate if the device disconnects, is power-cycled, or you remount/move it.'),
                                _TipText('• Orientation doesn’t need to be upright — calibrate in the actual mounted orientation.'),
                                _TipText('• Temperature or long idle can introduce drift; recalibrate if readings feel off.'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ===== Footer Buttons =====
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFF0B1117),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
                border: Border(top: BorderSide(color: Color(0xFF283142))),
              ),
              child: Row(
                children: [
                  TextButton(
                    onPressed: _isCalibrating ? null : widget.onFactoryReset,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white70,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: const Text('Factory Reset'),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _isCalibrating
                        ? null
                        : () {
                      setState(() => _isCalibrating = true);
                      widget.onStartCalibration();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary(context),
                      foregroundColor: const Color(0xFF001524),
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isCalibrating
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                    )
                        : const Text('Start calibration', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Colors.white)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpPanel() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF121822),
        border: Border.all(color: const Color(0xFF283142)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'If calibration fails:',
            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8),
          _TipText('1. Retry while keeping firearm perfectly still.'),
          _TipText('2. Use solid table/bench; avoid soft mats.'),
          _TipText('3. Tighten clamps; eliminate micro-movement.'),
          _TipText('4. Move away from metal, magnets, motors.'),
          _TipText('5. Power off device for 5s, reconnect, retry.'),
          SizedBox(height: 6),
          Text(
            'Restarting the phone is rarely necessary — only do it if Bluetooth pairing is stuck.',
            style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.3),
          ),
        ],
      ),
    );
  }
}

class _TipText extends StatelessWidget {
  final String text;
  const _TipText(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
      ),
    );
  }
}

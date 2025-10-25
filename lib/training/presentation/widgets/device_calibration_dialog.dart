// lib/training/presentation/widgets/device_calibration_dialog.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'common/training_dialog.dart';
import 'common/training_button.dart';

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

  @override
  Widget build(BuildContext context) {
    return TrainingDialog(
      title: 'Sensor calibration required',
      showCloseButton: false,
      content: SingleChildScrollView(
        padding: AppTheme.paddingLarge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Please mount the device in its actual shooting position — on your firearm, bipod, or tripod — exactly as you plan to use it.',
              style: AppTheme.bodyMedium(context),
            ),
            const SizedBox(height: AppTheme.spacingMedium),
            Text(
              'Once mounted, ensure the setup is completely still on a stable surface.',
              style: AppTheme.bodyMedium(context).copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppTheme.spacingLarge),
            _buildBullet('Do not touch or move the firearm or device during calibration.'),
            _buildBullet('Calibration captures mounting angle and sensor bias.'),
            const SizedBox(height: AppTheme.spacingMedium),
            Text(
              'Calibration takes about 3–5 seconds.',
              style: AppTheme.bodySmall(context).copyWith(color: AppTheme.textSecondary(context)),
            ),
            const SizedBox(height: AppTheme.spacingLarge),
            Theme(
              data: ThemeData().copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                iconColor: AppTheme.primary(context),
                collapsedIconColor: AppTheme.textSecondary(context),
                title: Text('More tips', style: AppTheme.titleMedium(context)),
                children: [
                  Container(
                    padding: AppTheme.paddingLarge,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant(context),
                      border: Border.all(color: AppTheme.border(context)),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Quick guide', style: AppTheme.titleSmall(context)),
                        const SizedBox(height: AppTheme.spacingSmall),
                        _TipText('• Calibrate once per connection. Recalibrate if the device disconnects, is power-cycled, or you remount/move it.'),
                        _TipText("• Orientation doesn't need to be upright — calibrate in the actual mounted orientation."),
                            _TipText('• Temperature or long idle can introduce drift; recalibrate if readings feel off.'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingLarge),
            Theme(
              data: ThemeData().copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                iconColor: AppTheme.primary(context),
                collapsedIconColor: AppTheme.textSecondary(context),
                title: Text('If calibration fails', style: AppTheme.titleMedium(context)),
                children: [
                  Container(
                    padding: AppTheme.paddingLarge,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant(context),
                      border: Border.all(color: AppTheme.border(context)),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        _TipText('1. Retry while keeping firearm perfectly still.'),
                        _TipText('2. Use solid table/bench; avoid soft mats.'),
                        _TipText('3. Tighten clamps; eliminate micro-movement.'),
                        _TipText('4. Move away from metal, magnets, motors.'),
                        _TipText('5. Power off device for 5s, reconnect, retry.'),
                        SizedBox(height: AppTheme.spacingSmall),
                        _TipText('Restarting the phone is rarely necessary — only do it if Bluetooth pairing is stuck.'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        Expanded(
          child: TrainingButton(
            label: 'Factory Reset',
            type: ButtonType.outlined,
            onPressed: _isCalibrating ? null : widget.onFactoryReset,
          ),
        ),
        const SizedBox(width: AppTheme.spacingLarge),
        Expanded(
          child: TrainingButton(
            label: 'Start calibration',
            isLoading: _isCalibrating,
            onPressed: () {
              setState(() => _isCalibrating = true);
              widget.onStartCalibration();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: AppTheme.bodyMedium(context)),
          Expanded(
            child: Text(
              text,
              style: AppTheme.bodySmall(context).copyWith(color: AppTheme.textSecondary(context)),
            ),
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
        style: AppTheme.bodySmall(context).copyWith(color: AppTheme.textSecondary(context)),
      ),
    );
  }
}
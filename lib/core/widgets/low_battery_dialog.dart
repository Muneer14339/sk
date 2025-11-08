// lib/core/widgets/low_battery_dialog.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LowBatteryDialog extends StatelessWidget {
  final int batteryLevel;
  final VoidCallback onDismiss;

  const LowBatteryDialog({
    Key? key,
    required this.batteryLevel,
    required this.onDismiss,
  }) : super(key: key);

  static Future<void> show(
      BuildContext context, {
        required int batteryLevel,
        required VoidCallback onDismiss,
      }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LowBatteryDialog(
        batteryLevel: batteryLevel,
        onDismiss: onDismiss,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surface(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        side: BorderSide(color: AppTheme.error(context), width: 2),
      ),
      child: Container(
        padding: AppTheme.paddingLarge,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.error(context).withOpacity(0.1),
              AppTheme.surface(context),
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.error(context).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.battery_alert,
                size: 48,
                color: AppTheme.error(context),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Low Battery Warning',
              style: AppTheme.headingMedium(context).copyWith(
                color: AppTheme.error(context),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.error(context).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Battery Level: $batteryLevel%',
                style: AppTheme.titleMedium(context).copyWith(
                  color: AppTheme.error(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your device battery is critically low.\nPlease charge or replace the battery soon.',
              style: AppTheme.bodyMedium(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onDismiss();
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppTheme.error(context), width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Dismiss',
                      style: AppTheme.button(context).copyWith(
                        color: AppTheme.error(context),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
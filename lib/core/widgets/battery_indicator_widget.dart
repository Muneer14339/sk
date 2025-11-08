// lib/core/widgets/battery_indicator_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../training/presentation/bloc/ble_scan/ble_scan_bloc.dart';
import '../../training/presentation/bloc/ble_scan/ble_scan_state.dart';
import '../theme/app_theme.dart';

class BatteryIndicatorWidget extends StatelessWidget {
  const BatteryIndicatorWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BleScanBloc, BleScanState>(
      builder: (context, state) {
        if (!state.isConnected || state.deviceInfo == null) {
          return const SizedBox.shrink();
        }

        final batteryLevel = state.deviceInfo!['batteryLevel'] as int? ?? 0;
        final batteryColor = _getBatteryColor(batteryLevel, context);
        final batteryIcon = _getBatteryIcon(batteryLevel);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: batteryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: batteryColor.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(batteryIcon, size: 16, color: batteryColor),
              const SizedBox(width: 4),
              Text(
                '$batteryLevel%',
                style: AppTheme.labelSmall(context).copyWith(
                  color: batteryColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getBatteryColor(int level, BuildContext context) {
    if (level > 50) return AppTheme.success(context);
    if (level > 20) return AppTheme.warning(context);
    return AppTheme.error(context);
  }

  IconData _getBatteryIcon(int level) {
    if (level > 90) return Icons.battery_full;
    if (level > 60) return Icons.battery_5_bar;
    if (level > 30) return Icons.battery_3_bar;
    if (level > 20) return Icons.battery_2_bar;
    return Icons.battery_alert;
  }
}
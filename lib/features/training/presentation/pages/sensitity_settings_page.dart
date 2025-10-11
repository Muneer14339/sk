import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pulse_skadi/core/services/prefs.dart';
import 'package:pulse_skadi/core/theme/app_colors.dart';
import 'package:pulse_skadi/core/utils/toast_utils.dart';
import 'package:pulse_skadi/core/widgets/custom_appbar.dart';
import 'package:pulse_skadi/core/widgets/primary_button.dart';
import 'package:pulse_skadi/features/training/presentation/bloc/ble_scan/ble_scan_bloc.dart';
import 'package:pulse_skadi/features/training/presentation/bloc/ble_scan/ble_scan_state.dart';
import 'package:pulse_skadi/features/training/presentation/bloc/sensitivity_settings/counter_sens_bloc.dart';
import 'package:pulse_skadi/features/training/presentation/bloc/training_session/training_session_bloc.dart';
import 'package:pulse_skadi/features/training/presentation/bloc/training_session/training_session_event.dart';
import 'package:pulse_skadi/features/training/presentation/widgets/circuler_button.dart';
import 'package:vibration/vibration.dart';

class SettingViewPage extends StatefulWidget {
  final List<String> sensPerms;

  const SettingViewPage({
    super.key,
    required this.sensPerms,
  });

  @override
  State<SettingViewPage> createState() => _SettingViewPageState();
}

class _SettingViewPageState extends State<SettingViewPage> {
  // Constants
  static const int _vibrationDuration = 200;
  static const double _snsRowBorderRadius = 10.0;
  static const double _mainPadding = 16.0;
  int dvcCp = 0;
  int swdCp = 0;
  int spiCp = 0;
  int ditIndex = 5;
  int dvcIndex = 0;
  int swdIndex = 0;
  int swbdIndex = 0;
  int avtIndex = 0;
  int avdtIndex = 0;
  int tester = 0;
  bool isConnected = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Formats DateTime to time string (preserved functionality)
  String formatDateTimeToTime(DateTime dateTime) {
    final minutes = dateTime.minute;
    final seconds = dateTime.second;
    final milliseconds = dateTime.millisecond;

    return '$minutes:${seconds.toString().padLeft(2, '0')}:${milliseconds.toString().padLeft(3, '0')}';
  }

  /// Triggers device vibration if available
  Future<void> vibrateDevice() async {
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator) {
      await Vibration.vibrate(duration: _vibrationDuration);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(title: 'Sensitivity Settings', context: context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(_mainPadding),
          child: BlocProvider(
            create: (_) => CounterSensBloc()
              ..add(SetInitialValues(
                  int.parse(widget.sensPerms[0]),
                  int.parse(widget.sensPerms[1]),
                  int.parse(widget.sensPerms[2]),
                  int.parse(widget.sensPerms[3]),
                  int.parse(widget.sensPerms[4]),
                  int.parse(widget.sensPerms[5]))),
            child: BlocBuilder<CounterSensBloc, CounterSensState>(
              builder: (context, state) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSensitivityList(context, state),
                    const SizedBox(height: 12),
                    _buildSaveButton(context, state),
                    const SizedBox(height: 5),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the sensitivity parameters list
  Widget _buildSensitivityList(BuildContext context, CounterSensState state) {
    return Expanded(
      child: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          _buildSensitivityRow(
            context: context,
            heading: 'PFI',
            value: state.pfi.toString(),
            onIncrease: () =>
                context.read<CounterSensBloc>().add(IncrementPfi()),
            onDecrease: () =>
                context.read<CounterSensBloc>().add(DecrementPfi()),
          ),
          _buildSensitivityRow(
            context: context,
            heading: 'PPF',
            value: state.ppf.toString(),
            onIncrease: () =>
                context.read<CounterSensBloc>().add(IncrementPpf()),
            onDecrease: () =>
                context.read<CounterSensBloc>().add(DecrementPpf()),
          ),
          _buildSensitivityRow(
            context: context,
            heading: 'PWD',
            value: state.pwd.toString(),
            onIncrease: () =>
                context.read<CounterSensBloc>().add(IncrementPwd()),
            onDecrease: () =>
                context.read<CounterSensBloc>().add(DecrementPwd()),
          ),
          _buildSensitivityRow(
            context: context,
            heading: 'SPI',
            value: state.spi.toString(),
            onIncrease: () =>
                context.read<CounterSensBloc>().add(IncrementSpi()),
            onDecrease: () =>
                context.read<CounterSensBloc>().add(DecrementSpi()),
          )
        ],
      ),
    );
  }

  /// Builds individual sensitivity parameter row
  Widget _buildSensitivityRow({
    required BuildContext context,
    required String heading,
    required String value,
    required VoidCallback onIncrease,
    required VoidCallback onDecrease,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.kSurface,
        borderRadius: BorderRadius.circular(_snsRowBorderRadius),
        border:
            Border.all(color: AppColors.kSuccess.withOpacity(0.2), width: 0.5),
        boxShadow: [],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            heading,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.kTextPrimary,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ) ??
                TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                  color: AppColors.kTextPrimary,
                ),
          ),
          const Spacer(),
          _buildControlButton(
            size: 35,
            onPressed: onDecrease,
            backgroundColor: AppColors.kPrimaryTeal,
            child: Icon(Icons.remove, color: AppColors.kTextPrimary),
          ),
          _buildValueDisplay(value),
          _buildControlButton(
            size: 35,
            onPressed: onIncrease,
            backgroundColor: AppColors.kPrimaryTeal,
            child: Icon(Icons.add, color: AppColors.kTextPrimary),
          ),
        ],
      ),
    );
  }

  /// Builds control button (increment/decrement)
  Widget _buildControlButton({
    required double size,
    required VoidCallback onPressed,
    required Color backgroundColor,
    required Widget child,
  }) {
    return CustomCircularButton(
      size: size,
      onPressed: onPressed,
      backgroundColor: backgroundColor,
      child: child,
    );
  }

  /// Builds value display widget
  Widget _buildValueDisplay(String value) {
    return CustomCircularButton(
      size: 40,
      onPressed: () {}, // Empty function as in original
      backgroundColor: Colors.transparent,
      borderColor: AppColors.kPrimaryTeal,
      borderWidth: 1,
      child: Text(
        value,
        style: TextStyle(
          color: AppColors.kTextPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Builds save button with BLE state handling
  Widget _buildSaveButton(BuildContext context, CounterSensState state) {
    return BlocBuilder<BleScanBloc, BleScanState>(
      builder: (context, bleState) {
        return PrimaryButton(
          title: 'Save',
          onTap: () {
            context.read<TrainingSessionBloc>().add(
                  SendCommand(
                    ditCommand: state.pfi,
                    dvcCommand: state.ppf,
                    swdCommand: state.pwd,
                    swbdCommand: state.spi,
                    avdCommand: state.avt,
                    avdtCommand: state.avdt,
                    device: bleState.connectedDevice!,
                  ),
                );
            prefs?.setString(sensitivityKey,
                '${state.pfi}/${state.ppf}/${state.pwd}/${state.spi}/${state.avt}/${state.avdt}');
            Navigator.pop(context);
            ToastUtils.showSuccess(context,
                message: 'Sensitivity saved successfully');
          },
        );
      },
    );
  }
}

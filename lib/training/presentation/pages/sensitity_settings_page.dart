import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/services/prefs.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../core/widgets/custom_appbar.dart';
import '../../../core/widgets/primary_button.dart';
import '../bloc/ble_scan/ble_scan_bloc.dart';
import '../bloc/ble_scan/ble_scan_state.dart';
import '../bloc/sensitivity_settings/counter_sens_bloc.dart';
import '../bloc/training_session/training_session_bloc.dart';
import '../bloc/training_session/training_session_event.dart';
import '../widgets/circuler_button.dart';


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



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(title: 'Sensitivity Settings', context: context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(_mainPadding),
          // Line ~72-89 ko replace karo
          child: BlocProvider(
            create: (_) {
              final sensPerms = widget.sensPerms;
              // ✅ Load haptic settings
              final hapticEnabled = prefs?.getBool(hapticEnabledKey) ?? true;
              // ✅ Load traceline setting
              final traceModeInt = prefs?.getInt(traceDisplayModeKey) ?? 0;
              final traceMode = TraceDisplayMode.values[traceModeInt.clamp(0, 2)];
              final customSettingsJson = prefs?.getString(hapticCustomSettingsKey);

              Map<int, int> customHapticValues = {
                10: 0, 9: 0, 8: 1, 7: 1, 6: 1, 5: 1,
              };

              if (customSettingsJson != null) {
                try {
                  final decoded = jsonDecode(customSettingsJson) as Map<String, dynamic>;
                  customHapticValues = decoded.map((k, v) => MapEntry(int.parse(k), v as int));
                } catch (e) {
                  print('Error loading custom haptic settings: $e');
                }
              }
              // ✅ Safe parsing with fallback values
              return CounterSensBloc()
                ..add(SetInitialValues(
                  sensPerms.length > 0 ? int.parse(sensPerms[0]) : 5,  // pfi
                  sensPerms.length > 1 ? int.parse(sensPerms[1]) : 4,  // ppf
                  sensPerms.length > 2 ? int.parse(sensPerms[2]) : 1,  // pwd
                  sensPerms.length > 3 ? int.parse(sensPerms[3]) : 1,  // spi
                  sensPerms.length > 4 ? int.parse(sensPerms[4]) : 1,  // avt
                  sensPerms.length > 5 ? int.parse(sensPerms[5]) : 1,  // avdt
                  hapticEnabled,
                  false, // useCustomHaptic - always start collapsed
                  customHapticValues,
                  traceMode, // ✅ CHANGED
                ));
            },
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

  // lib/features/training/presentation/pages/sensitity_settings_page.dart - Replace _buildSensitivityList method

  Widget _buildSensitivityList(BuildContext context, CounterSensState state) {
    return Expanded(
      child: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          _buildSensitivityRow(
            context: context,
            heading: 'PFI',
            value: state.pfi.toString(),
            onIncrease: () => context.read<CounterSensBloc>().add(IncrementPfi()),
            onDecrease: () => context.read<CounterSensBloc>().add(DecrementPfi()),
          ),
          _buildSensitivityRow(
            context: context,
            heading: 'PPF',
            value: state.ppf.toString(),
            onIncrease: () => context.read<CounterSensBloc>().add(IncrementPpf()),
            onDecrease: () => context.read<CounterSensBloc>().add(DecrementPpf()),
          ),
          _buildSensitivityRow(
            context: context,
            heading: 'PWD',
            value: state.pwd.toString(),
            onIncrease: () => context.read<CounterSensBloc>().add(IncrementPwd()),
            onDecrease: () => context.read<CounterSensBloc>().add(DecrementPwd()),
          ),
          _buildSensitivityRow(
            context: context,
            heading: 'SPI',
            value: state.spi.toString(),
            onIncrease: () => context.read<CounterSensBloc>().add(IncrementSpi()),
            onDecrease: () => context.read<CounterSensBloc>().add(DecrementSpi()),
          ),

          // ✅ NEW: Haptic Toggle Section
          //_buildHapticToggleSection(context, state),

          // ✅ UPDATED: Show combined toggles
          _buildToggleSection(context, state),

          // // ✅ NEW: Custom Haptic Settings (Expandable)
          // if (state.hapticEnabled) _buildCustomHapticSection(context, state),
        ],
      ),
    );
  }

  // ✅ IMPROVED: Visual 3-mode selector with cards
  Widget _buildToggleSection(BuildContext context, CounterSensState state) {
    return Column(
      children: [
        // Haptic Toggle (same as before)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.kSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.kSuccess.withOpacity(0.2), width: 0.5),
          ),
          child: Row(
            children: [
              Icon(Icons.vibration, color: AppColors.kPrimaryTeal, size: 20),
              const SizedBox(width: 12),
              Text(
                'Haptic Feedback',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.kTextPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Switch(
                value: state.hapticEnabled,
                onChanged: (_) => context.read<CounterSensBloc>().add(ToggleHaptic()),
                activeColor: AppColors.kPrimaryTeal,
              ),
            ],
          ),
        ),

        // ✅ NEW: Display Mode Selector Header
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            children: [
              Icon(Icons.remove_red_eye, color: AppColors.kPrimaryTeal, size: 18),
              const SizedBox(width: 8),
              Text(
                'Display Mode',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.kTextPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // ✅ NEW: 3 Mode Cards
        Row(
          children: [
            Expanded(
              child: _buildModeCard(
                context,
                mode: TraceDisplayMode.tracelineAndDot,
                icon: Icons.timeline,
                label: 'Traceline\n& Dot',
                isSelected: state.traceDisplayMode == TraceDisplayMode.tracelineAndDot,
                onTap: () => _selectMode(context, TraceDisplayMode.tracelineAndDot),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildModeCard(
                context,
                mode: TraceDisplayMode.dotOnly,
                icon: Icons.circle,
                label: 'Dot\nOnly',
                isSelected: state.traceDisplayMode == TraceDisplayMode.dotOnly,
                onTap: () => _selectMode(context, TraceDisplayMode.dotOnly),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildModeCard(
                context,
                mode: TraceDisplayMode.hidden,
                icon: Icons.visibility_off,
                label: 'Hidden',
                isSelected: state.traceDisplayMode == TraceDisplayMode.hidden,
                onTap: () => _selectMode(context, TraceDisplayMode.hidden),
              ),
            ),
          ],
        ),
      ],
    );
  }

// ✅ NEW: Mode selection helper
  void _selectMode(BuildContext context, TraceDisplayMode targetMode) {
    final currentMode = context.read<CounterSensBloc>().state.traceDisplayMode;
    if (currentMode != targetMode) {
      // Calculate how many toggles needed to reach target
      final currentIndex = currentMode.index;
      final targetIndex = targetMode.index;
      final steps = (targetIndex - currentIndex) % 3;

      for (int i = 0; i < steps; i++) {
        context.read<CounterSensBloc>().add(ToggleTraceDisplay());
      }
    }
  }

// ✅ NEW: Individual mode card
  Widget _buildModeCard(
      BuildContext context, {
        required TraceDisplayMode mode,
        required IconData icon,
        required String label,
        required bool isSelected,
        required VoidCallback onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.kPrimaryTeal.withOpacity(0.15)
              : AppColors.kSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppColors.kPrimaryTeal
                : AppColors.kSuccess.withOpacity(0.2),
            width: isSelected ? 2 : 0.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppColors.kPrimaryTeal
                  : AppColors.kTextSecondary,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected
                    ? AppColors.kPrimaryTeal
                    : AppColors.kTextSecondary,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                height: 1.2,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 6),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.kPrimaryTeal,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

// ✅ NEW: Haptic Toggle Widget
  Widget _buildHapticToggleSection(BuildContext context, CounterSensState state) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.kSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.kSuccess.withOpacity(0.2), width: 0.5),
      ),
      child: Row(
        children: [
          Icon(Icons.vibration, color: AppColors.kPrimaryTeal, size: 20),
          const SizedBox(width: 12),
          Text(
            'Haptic Feedback',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.kTextPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Switch(
            value: state.hapticEnabled,
            onChanged: (_) => context.read<CounterSensBloc>().add(ToggleHaptic()),
            activeColor: AppColors.kPrimaryTeal,
          ),
        ],
      ),
    );
  }

// ✅ NEW: Expandable Custom Haptic Settings
  Widget _buildCustomHapticSection(BuildContext context, CounterSensState state) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.kSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.kSuccess.withOpacity(0.2), width: 0.5),
      ),
      child: ExpansionTile(
        title: Text(
          'Custom Haptic Settings',
          style: TextStyle(color: AppColors.kTextPrimary, fontWeight: FontWeight.w500),
        ),
        trailing: Icon(
          state.useCustomHaptic ? Icons.expand_less : Icons.expand_more,
          color: AppColors.kTextPrimary,
        ),
        onExpansionChanged: (_) {
          context.read<CounterSensBloc>().add(ToggleCustomHaptic());
        },
        children: state.useCustomHaptic
            ? [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                _buildCustomHapticRow(context, state, 10, 'Center (Ring 10)'),
                _buildCustomHapticRow(context, state, 9, 'Ring 9'),
                _buildCustomHapticRow(context, state, 8, 'Ring 8'),
                _buildCustomHapticRow(context, state, 7, 'Ring 7'),
                _buildCustomHapticRow(context, state, 6, 'Ring 6'),
                _buildCustomHapticRow(context, state, 5, 'Ring 5 (Outer)'),
              ],
            ),
          ),
        ]
            : [],
      ),
    );
  }

// ✅ NEW: Custom Haptic Row
  Widget _buildCustomHapticRow(
      BuildContext context, CounterSensState state, int ring, String label) {
    final value = state.customHapticValues[ring] ?? 1;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: AppColors.kTextSecondary, fontSize: 14),
            ),
          ),
          _buildControlButton(
            size: 30,
            onPressed: () {
              context
                  .read<CounterSensBloc>()
                  .add(UpdateCustomHapticValue(ring, value - 1));
            },
            backgroundColor: AppColors.kPrimaryTeal.withOpacity(0.7),
            child: Icon(Icons.remove, color: AppColors.kTextPrimary, size: 16),
          ),
          _buildValueDisplay(value.toString()),
          _buildControlButton(
            size: 30,
            onPressed: () {
              context
                  .read<CounterSensBloc>()
                  .add(UpdateCustomHapticValue(ring, value + 1));
            },
            backgroundColor: AppColors.kPrimaryTeal.withOpacity(0.7),
            child: Icon(Icons.add, color: AppColors.kTextPrimary, size: 16),
          ),
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

  // Line ~200: Update save button
  Widget _buildSaveButton(BuildContext context, CounterSensState state) {
    return BlocBuilder<BleScanBloc, BleScanState>(
      builder: (context, bleState) {
        return PrimaryButton(
          title: 'Save',
          onTap: () async {
            await prefs?.setBool(hapticEnabledKey, state.hapticEnabled);

            final customJson = jsonEncode(
              state.customHapticValues.map((k, v) => MapEntry(k.toString(), v)),
            );
            await prefs?.setString(hapticCustomSettingsKey, customJson);

            // ✅ CHANGED: Save display mode as int
            await prefs?.setInt(traceDisplayModeKey, state.traceDisplayMode.index);

            context.read<TrainingSessionBloc>().add(
              SendCommand(
                ditCommand: state.pfi,
                dvcCommand: state.ppf,
                swdCommand: state.pwd,
                swbdCommand: state.spi,
                avdCommand: state.avt,
                avdtCommand: state.avdt,
                hapticCommand: state.hapticEnabled ? 1 : 0,
                device: bleState.connectedDevice!,
              ),
            );

            // ✅ CHANGED: Update sensitivity string
            prefs?.setString(
              sensitivityKey,
              '${state.pfi}/${state.ppf}/${state.pwd}/${state.spi}/${state.avt}/${state.avdt}/${state.hapticEnabled ? 1 : 0}/${state.traceDisplayMode.index}',
            );

            Navigator.pop(context);
            ToastUtils.showSuccess(context, message: 'Settings saved successfully');
          },
        );
      },
    );
  }
}

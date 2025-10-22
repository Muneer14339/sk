import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../training/presentation/bloc/ble_scan/ble_scan_bloc.dart';
import '../../training/presentation/bloc/ble_scan/ble_scan_event.dart';
import '../../training/presentation/bloc/ble_scan/ble_scan_state.dart';
import '../theme/app_theme.dart';

class ModernCustomDialog extends StatefulWidget {
  final String title;
  final Function(BluetoothDevice)? onItemSelected;
  final BleScanState state;

  const ModernCustomDialog({
    super.key,
    required this.title,
    this.onItemSelected,
    required this.state,
  });

  @override
  State<ModernCustomDialog> createState() => _ModernCustomDialogState();
}

class _ModernCustomDialogState extends State<ModernCustomDialog>
    with TickerProviderStateMixin {
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          constraints: const BoxConstraints(
            maxWidth: 400,
            maxHeight: 600,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8)),
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 40,
                  offset: const Offset(0, 16))
            ],
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.2), width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                if (widget.state.error != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      widget.state.error ?? '',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppTheme.error(context),
                          fontSize: 14,
                          fontWeight: FontWeight.normal),
                    ),
                  )
                else
                  _buildListView(),
                _buildFooter(widget.state),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primary(context).withValues(alpha: 0.2),
            AppTheme.primary(context).withValues(alpha: 0.1),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: AppTheme.primary(context),
                borderRadius: BorderRadius.circular(8)),
            child: const Icon(
              Icons.list_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primary(context),
                  ),
                ),
                Text(
                  '${widget.state.discoveredDevices.length} items',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    return widget.state.isScanning && widget.state.discoveredDevices.isEmpty
        ? Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircularProgressIndicator(),
          )
        : Flexible(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 400),
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: widget.state.discoveredDevices.length,
                itemBuilder: (context, index) {
                  final item = widget.state.discoveredDevices[index];
                  final isSelected = _selectedIndex == index;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          setState(() {
                            _selectedIndex = index;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? LinearGradient(
                                    colors: [
                                      AppTheme.primary(context)
                                          .withValues(alpha: 0.1),
                                      AppTheme.primary(context)
                                          .withValues(alpha: 0.1),
                                    ],
                                  )
                                : null,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primary(context)
                                      .withValues(alpha: 0.3)
                                  : Colors.transparent,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: isSelected
                                        ? LinearGradient(colors: [
                                            AppTheme.primary(context),
                                            AppTheme.primary(context)
                                          ])
                                        : LinearGradient(colors: [
                                            Colors.grey.withValues(alpha: 0.1),
                                            Colors.grey.withValues(alpha: 0.05)
                                          ]),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.bluetooth,
                                      color: isSelected
                                          ? Colors.white
                                          : AppTheme.primary(context),
                                      size: 16)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.device.platformName,
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: isSelected
                                                ? AppTheme.primary(context)
                                                : AppTheme.primary(context))),
                                    Text('${item.device.remoteId}',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600]))
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
  }

  Widget _buildFooter(BleScanState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
              child: TextButton(
                  onPressed: () {
                    context.read<BleScanBloc>().add(StopBleScan());
                    Navigator.of(context).pop();
                  },
                  style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                              color: Colors.grey.withValues(alpha: 0.3)))),
                  child: Text('Cancel',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280))))),
          const SizedBox(width: 12),
          state.isConnecting
              ? CircularProgressIndicator()
              : Expanded(
                  child: GestureDetector(
                  onTap: _selectedIndex != null
                      ? () {
                          widget.onItemSelected?.call(widget
                              .state.discoveredDevices[_selectedIndex!].device);
                        }
                      : null,
                  child: Container(
                    decoration: _selectedIndex != null
                        ? BoxDecoration(
                            color: AppTheme.primary(context),
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                            border: Border.all(
                                color: AppTheme.primary(context), width: 1),
                          )
                        : null,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                      child: Text(
                        'Connect',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _selectedIndex != null
                              ? Colors.white
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                )),
        ],
      ),
    );
  }
}

class CustomDialog extends StatelessWidget {
  final String title;
  final String content;
  final VoidCallback? onNewSession;
  final VoidCallback? onBack;
  final Color? primaryColor;
  final Color? accentColor;

  const CustomDialog({
    super.key,
    required this.title,
    required this.content,
    this.onNewSession,
    this.onBack,
    this.primaryColor,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectivePrimaryColor = primaryColor ?? theme.primaryColor;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10))
            ]),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with gradient and icon
            Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      effectivePrimaryColor.withValues(alpha: 0.8),
                      effectivePrimaryColor,
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ])),

            // Content
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  // Content text
                  Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 24),
                    child: Text(
                      content,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 16,
                        height: 1.5,
                        letterSpacing: 0.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Buttons
                  Row(
                    children: [
                      // Back Button
                      Expanded(
                        child: TextButton.icon(
                          onPressed:
                              onBack ?? () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            size: 18,
                            color: Colors.grey,
                          ),
                          label: const Text(
                            'Back',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey[300]!),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // New Session Button
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: onNewSession ??
                              () => Navigator.of(context).pop(true),
                          icon: const Icon(
                            Icons.refresh,
                            size: 18,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'New Session',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: effectivePrimaryColor,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shadowColor:
                                effectivePrimaryColor.withValues(alpha: 0.3),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Alternative simpler version without custom colors
class SimpleCustomDialog extends StatelessWidget {
  final String title;
  final String? positiveButtonLabel, negativeButtonLabel;
  final String content;
  final VoidCallback? onPositive;
  final VoidCallback? onNegative;

  const SimpleCustomDialog({
    super.key,
    required this.title,
    required this.content,
    this.positiveButtonLabel,
    this.negativeButtonLabel,
    this.onPositive,
    this.onNegative,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Content
            Text(
              content,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                    child: OutlinedButton(
                        onPressed:
                            onNegative ?? () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: Colors.grey),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))),
                        child: Text(negativeButtonLabel ?? 'Cancel'))),
                const SizedBox(width: 12),
                Expanded(
                    child: ElevatedButton(
                        onPressed:
                            onPositive ?? () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))),
                        child: Text(positiveButtonLabel ?? 'OK',
                            style: const TextStyle(color: Colors.white)))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class ToastUtils {
  static void showLoading(BuildContext context) {
    Flushbar(
      message: 'Loading...',
      duration: const Duration(seconds: 3),
      backgroundColor: Colors.black.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(12),
      margin: const EdgeInsets.all(16),
      flushbarPosition: FlushbarPosition.TOP,
    ).show(context);
  }

  static void showSuccess(
    BuildContext context, {
    required String message,
    Duration? duration,
  }) {
    Flushbar(
      message: message,
      dismissDirection: FlushbarDismissDirection.HORIZONTAL,
      icon: const Icon(
        Icons.check_circle_outline,
        size: 28.0,
        color: Colors.white,
      ),
      duration: duration ?? const Duration(seconds: 3),
      backgroundColor: const Color(0xFF1D8E5C),
      borderRadius: BorderRadius.circular(12),
      margin: const EdgeInsets.all(16),
      flushbarPosition: FlushbarPosition.TOP,
    ).show(context);
  }

  static void showError(
    BuildContext context, {
    required String message,
    Duration? duration,
  }) {
    Flushbar(
      message: message,
      dismissDirection: FlushbarDismissDirection.HORIZONTAL,
      icon: const Icon(
        Icons.error_outline,
        size: 28.0,
        color: Colors.white,
      ),
      duration: duration ?? const Duration(seconds: 3),
      backgroundColor: AppColors.kRedColor,
      borderRadius: BorderRadius.circular(12),
      margin: const EdgeInsets.all(16),
      flushbarPosition: FlushbarPosition.TOP,
    ).show(context);
  }

  static void showWarning(
    BuildContext context, {
    required String message,
    Duration? duration,
  }) {
    Flushbar(
      dismissDirection: FlushbarDismissDirection.HORIZONTAL,
      message: message,
      icon: const Icon(
        Icons.warning_amber_rounded,
        size: 28.0,
        color: Colors.white,
      ),
      duration: duration ?? const Duration(seconds: 3),
      backgroundColor: AppColors.kRedColor,
      borderRadius: BorderRadius.circular(12),
      margin: const EdgeInsets.all(16),
      flushbarPosition: FlushbarPosition.TOP,
    ).show(context);
  }

  static void showInfo(
    BuildContext context, {
    required String message,
    Duration? duration,
  }) {
    Flushbar(
      message: message,
      dismissDirection: FlushbarDismissDirection.HORIZONTAL,
      icon: const Icon(
        Icons.info_outline,
        size: 28.0,
        color: Colors.white,
      ),
      duration: duration ?? const Duration(seconds: 3),
      backgroundColor: AppColors.kPrimaryColor,
      borderRadius: BorderRadius.circular(12),
      margin: const EdgeInsets.all(16),
      flushbarPosition: FlushbarPosition.TOP,
    ).show(context);
  }
}

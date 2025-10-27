import 'package:flutter/material.dart';

class ArmoryConstants {
  static const double dialogMaxWidth = 600;
  static const double dialogPadding = 6;
  static const double fieldSpacing = 16;
  static const double sectionSpacing = 20;
  static const double itemSpacing = 8;
  static const double smallSpacing = 4;
  static const double largeSpacing = 24;
  static const double borderRadius = 10;
  static const double cardBorderRadius = 16;
  static const double itemCardBorderRadius = 12;
  static const double badgeBorderRadius = 6;
  static const EdgeInsets cardPadding = EdgeInsets.all(8);
  static const EdgeInsets itemPadding = EdgeInsets.all(10);
  static const EdgeInsets fieldPadding = EdgeInsets.all(12);
  static const EdgeInsets pageMargin = EdgeInsets.all(16);
  static const EdgeInsets cardMargin = EdgeInsets.only(bottom: 12);
  static const EdgeInsets itemMargin = EdgeInsets.symmetric(vertical: 5, horizontal: 14);
  static const double smallIcon = 16;
  static const double mediumIcon = 20;
  static const double largeIcon = 24;
  static const double loadingSize = 16;
  static const double loadingStroke = 2;
  static const double tablet = 520;
  static const double mobile = 400;
  static const double desktop = 800;
  static const Duration shortDuration = Duration(milliseconds: 200);
  static const Duration mediumDuration = Duration(milliseconds: 300);
  static const Duration longDuration = Duration(milliseconds: 500);
}

extension StatusColors on String {
  Color statusColor(BuildContext context) {
    switch (toLowerCase()) {
      case 'available':
        return const Color(0xFF4CAF50);
      case 'in-use':
      case 'low-stock':
        return const Color(0xFFFFA726);
      case 'maintenance':
      case 'out-of-stock':
        return const Color(0xFFFF5252);
      default:
        return const Color(0xFFB0B0B0);
    }
  }

  TextStyle statusTextStyle(BuildContext context) {
    return TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: statusColor(context),
    );
  }
}
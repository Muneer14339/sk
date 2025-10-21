// lib/core/utils/caliber_calculator.dart (NEW FILE)

import 'dart:math';

class CaliberCalculator {
  static String? calculateBulletDiameter(String? caliber, String? existingDiameter) {
    // Agar already diameter hai, use that
    if (existingDiameter != null && existingDiameter.isNotEmpty) {
      return existingDiameter;
    }

    // Agar caliber null/empty hai
    if (caliber == null || caliber.isEmpty) return null;

    final cal = caliber.trim().toLowerCase();

    try {
      // Rule 1: Starts with "." → already in inches
      if (cal.startsWith('.')) {
        final match = RegExp(r'^\.(\d+)').firstMatch(cal);
        if (match != null) {
          return '0.${match.group(1)}';
        }
      }

      // Rule 2: Contains "gauge", "ga", or "bore" → shotgun formula
      if (cal.contains('gauge') || cal.contains(' ga') || cal.contains('bore')) {
        final gaugeMatch = RegExp(r'(\d+\.?\d*)').firstMatch(cal);
        if (gaugeMatch != null) {
          final gauge = double.parse(gaugeMatch.group(1)!);
          final diameter = 1.67 / pow(gauge, 1/3);
          return diameter.toStringAsFixed(3);
        }
      }

      // Rule 3: Multi-part caliber like "7.62x39mm" → take first number
      if (cal.contains('x') && cal.contains('mm')) {
        final match = RegExp(r'(\d+\.?\d*)x').firstMatch(cal);
        if (match != null) {
          final mm = double.parse(match.group(1)!);
          return (mm / 25.4).toStringAsFixed(3);
        }
      }

      // Rule 4: Contains "mm" → convert to inches
      if (cal.contains('mm')) {
        final match = RegExp(r'(\d+\.?\d*)mm').firstMatch(cal);
        if (match != null) {
          final mm = double.parse(match.group(1)!);
          return (mm / 25.4).toStringAsFixed(3);
        }
      }

      // Rule 5: Pure number at start (like "45 ACP") → assume inches
      final numberMatch = RegExp(r'^(\d+)(?:\s|$)').firstMatch(cal);
      if (numberMatch != null) {
        final num = int.parse(numberMatch.group(1)!);
        return '0.$num';
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}
// lib/core/validators/caliber_validator.dart

class CaliberValidator {
  // Exact pattern matchers - ONLY ONE format allowed
  static final _inchPattern = RegExp(r'^\.(\d{2,3})');  // .45, .308
  static final _gaugePattern = RegExp(r'^(\d{1,2}(\.\d+)?)\s*(gauge|ga)', caseSensitive: false);
  static final _mmPattern = RegExp(r'^(\d{1,2}(\.\d+)?)\s*mm', caseSensitive: false);  // 9mm, 5.56mm
  static final _crossMmPattern = RegExp(r'^(\d{1,2}(\.\d+)?)x(\d{1,2}(\.\d+)?)\s*mm', caseSensitive: false);
  static final _namedPattern = RegExp(r'^(\d{2,3})\s+[a-zA-Z][a-zA-Z\s-]+');  // 45 ACP

  /// Validates if the caliber string matches ONE acceptable format ONLY
  static bool isValid(String? caliber) {
    if (caliber == null || caliber.trim().isEmpty) return false;

    final normalized = caliber.trim();

    // Check for mixed format violations
    if (_hasMixedFormats(normalized)) return false;

    // Check if matches exactly one valid pattern
    return _inchPattern.hasMatch(normalized) ||
        _gaugePattern.hasMatch(normalized) ||
        _mmPattern.hasMatch(normalized) ||
        _crossMmPattern.hasMatch(normalized) ||
        _namedPattern.hasMatch(normalized);
  }

  /// Detects if input has mixed/conflicting formats
  static bool _hasMixedFormats(String input) {
    final lower = input.toLowerCase();

    // Can't have dot AND mm together
    if (lower.startsWith('.') && lower.contains('mm')) return true;

    // Can't have multiple dots (like .9.mm or 9..45)
    if (lower.split('.').length > 2) return true;

    // Can't have gauge AND mm
    if ((lower.contains('gauge') || lower.contains('ga')) && lower.contains('mm')) {
      return true;
    }

    return false;
  }

  /// Returns detailed validation error message or null if valid
  static String? validate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Caliber is required';
    }

    final normalized = value.trim();

    // Check for mixed formats first
    if (_hasMixedFormats(normalized)) {
      return 'Mixed formats not allowed. Use ONLY one format:\n'
          '• Inches: .45, .308\n'
          '• MM: 9mm, 5.56mm\n'
          '• Gauge: 12 gauge, 20ga\n'
          '• Cross: 7.62x39mm';
    }

    // Check if valid format
    if (!isValid(normalized)) {
      return 'Invalid format. Examples:\n'
          '• .45 or .308 (inches)\n'
          '• 9mm or 5.56mm (millimeters)\n'
          '• 12 gauge or 20ga (gauge)\n'
          '• 7.62x39mm (cross format)\n'
          '• 45 ACP (named caliber)';
    }

    return null;
  }

  /// Normalizes caliber input (removes extra spaces, standardizes case)
  static String normalize(String caliber) {
    return caliber.trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'(?<=\d)\s*mm', caseSensitive: false), 'mm')
        .replaceAll(RegExp(r'(?<=\d)\s*x\s*(?=\d)', caseSensitive: false), 'x');
  }
}
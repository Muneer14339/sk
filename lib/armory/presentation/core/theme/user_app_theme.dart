// lib/core/theme/user_app_theme.dart
import 'package:flutter/material.dart';

class AppColors {
  // Background Colors
  static const Color primaryBackground = Color(0xFF0F1115);
  static const Color cardBackground = Color(0xFF151923);
  static const Color inputBackground = Color(0xFF0B1020);
  static const Color itemBackground = Color(0xFF0E1220);
  static const Color sectionBackground = Color(0xFF1B2130);
  static const Color headerBackground = Color(0xFF101522);

  // Border Colors
  static const Color primaryBorder = Color(0xFF222838);
  static const Color focusBorder = Color(0xFF57B7FF);
  static const Color errorBorder = Color(0xFFFF6B6B);

  // Text Colors
  static const Color primaryText = Color(0xFFE8EEF7);
  static const Color secondaryText = Color(0xFF9AA4B2);
  static const Color accentText = Color(0xFF57B7FF);
  static const Color lightText = Color(0xFFCFE0FF);
  static const Color buttonText = Color(0xFFDBE6FF);

  // Status Colors
  static const Color successColor = Color(0xFF51CF66);
  static const Color warningColor = Color(0xFFFFD43B);
  static const Color errorColor = Color(0xFFFF6B6B);

  // Button Colors
  static const Color buttonBackground = Color(0xFF2A3BFF);
  static const Color buttonBorder = Color(0xFF3050FF);

  // Opacity Colors
  static Color get buttonBackgroundWithOpacity => buttonBackground.withOpacity(0.15);
  static Color get buttonBorderWithOpacity => buttonBorder.withOpacity(0.35);
  static Color get accentBackgroundWithOpacity => accentText.withOpacity(0.1);
  static Color get accentBorderWithOpacity => accentText.withOpacity(0.2);
  static Color get successBackgroundWithOpacity => successColor.withOpacity(0.1);
  static Color get successBorderWithOpacity => successColor.withOpacity(0.2);
  static Color get warningBackgroundWithOpacity => warningColor.withOpacity(0.1);
  static Color get warningBorderWithOpacity => warningColor.withOpacity(0.2);
  static Color get errorBackgroundWithOpacity => errorColor.withOpacity(0.1);
  static Color get errorBorderWithOpacity => errorColor.withOpacity(0.2);
}

class AppTextStyles {
  // Page Titles
  static const TextStyle pageTitle = TextStyle(
    color: AppColors.primaryText,
    fontSize: 18,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.3,
  );

  static const TextStyle pageSubtitle = TextStyle(
    color: AppColors.secondaryText,
    fontSize: 12,
  );

  // Dialog Titles
  static const TextStyle dialogTitle = TextStyle(
    color: AppColors.primaryText,
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  // Card Titles
  static const TextStyle cardTitle = TextStyle(
    color: AppColors.primaryText,
    fontSize: 15,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle cardDescription = TextStyle(
    color: AppColors.secondaryText,
    fontSize: 12,
  );

  // Item Cards
  static const TextStyle itemTitle = TextStyle(
    color: AppColors.primaryText,
    fontSize: 14,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle itemSubtitle = TextStyle(
    color: AppColors.secondaryText,
    fontSize: 12,
  );

  // Form Fields
  static const TextStyle fieldLabel = TextStyle(
    color: AppColors.secondaryText,
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle inputText = TextStyle(
    color: AppColors.primaryText,
    fontSize: 14,
  );

  static const TextStyle hintText = TextStyle(
    color: AppColors.secondaryText,
    fontSize: 14,
  );

  // Badges and Tags
  static const TextStyle badgeText = TextStyle(
    color: AppColors.accentText,
    fontSize: 11,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle tagText = TextStyle(
    color: AppColors.secondaryText,
    fontSize: 11,
  );

  static const TextStyle statusText = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
  );

  // Buttons
  static const TextStyle buttonText = TextStyle(
    color: AppColors.buttonText,
  );

  static const TextStyle cancelButtonText = TextStyle(
    color: AppColors.secondaryText,
  );

  // Tab Bar
  static const TextStyle tabLabel = TextStyle(
    fontWeight: FontWeight.w700,
    fontSize: 12,
    letterSpacing: 0.2,
  );

  // Report Tables
  static const TextStyle tableHeader = TextStyle(
    color: AppColors.lightText,
    fontWeight: FontWeight.w800,
    fontSize: 12,
  );

  static const TextStyle tableData = TextStyle(
    color: AppColors.primaryText,
    fontSize: 12,
  );

  // Empty States
  static const TextStyle emptyStateText = TextStyle(
    color: AppColors.secondaryText,
    fontSize: 13,
  );

  // Count Badges
  static const TextStyle countBadgeText = TextStyle(
    color: AppColors.secondaryText,
    fontSize: 11,
  );
}

class AppDecorations {
  // Page Decorations
  static BoxDecoration get pageDecoration => const BoxDecoration(
    color: AppColors.primaryBackground,
  );

  // Card Decorations
  static BoxDecoration get mainCardDecoration => BoxDecoration(
    color: AppColors.cardBackground,
    border: Border.all(color: AppColors.primaryBorder),
    borderRadius: BorderRadius.circular(14),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.35),
        blurRadius: 24,
        offset: const Offset(0, 10),
      ),
    ],
  );

  static BoxDecoration get itemCardDecoration => BoxDecoration(
    color: AppColors.itemBackground,
    border: Border.all(color: AppColors.primaryBorder),
    borderRadius: BorderRadius.circular(12),
  );

  // Dialog Decorations
  static BoxDecoration get dialogDecoration => BoxDecoration(
    color: AppColors.cardBackground,
    borderRadius: BorderRadius.circular(16),
  );

  // Input Decorations
  static BoxDecoration get inputDecoration => BoxDecoration(
    color: AppColors.inputBackground,
    borderRadius: BorderRadius.circular(10),
    border: Border.all(color: AppColors.primaryBorder),
  );

  // Badge Decorations
  static BoxDecoration get accentBadgeDecoration => BoxDecoration(
    color: AppColors.accentBackgroundWithOpacity,
    border: Border.all(color: AppColors.accentBorderWithOpacity),
    borderRadius: BorderRadius.circular(6),
  );

  static BoxDecoration get tagDecoration => BoxDecoration(
    color: AppColors.sectionBackground,
    border: Border.all(color: AppColors.primaryBorder),
    borderRadius: BorderRadius.circular(999),
  );

  static BoxDecoration get countBadgeDecoration => BoxDecoration(
    color: AppColors.sectionBackground,
    border: Border.all(color: AppColors.primaryBorder),
    borderRadius: BorderRadius.circular(999),
  );

  // Status Decorations
  static BoxDecoration getStatusDecoration(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'available':
        color = AppColors.successColor;
        break;
      case 'in-use':
      case 'low-stock':
        color = AppColors.warningColor;
        break;
      case 'maintenance':
      case 'out-of-stock':
        color = AppColors.errorColor;
        break;
      default:
        color = AppColors.secondaryText;
    }

    return BoxDecoration(
      color: color.withOpacity(0.1),
      border: Border.all(color: color.withOpacity(0.2)),
      borderRadius: BorderRadius.circular(999),
    );
  }

  // Border Decorations
  static BoxDecoration get headerBorderDecoration => const BoxDecoration(
    border: Border(bottom: BorderSide(color: AppColors.primaryBorder)),
  );

  static BoxDecoration get footerBorderDecoration => const BoxDecoration(
    border: Border(top: BorderSide(color: AppColors.primaryBorder)),
  );

  static BoxDecoration get sectionBorderDecoration => const BoxDecoration(
    border: Border(bottom: BorderSide(color: AppColors.primaryBorder)),
  );

  // Table Decorations
  static BoxDecoration get tableDecoration => BoxDecoration(
    border: Border.all(color: AppColors.primaryBorder),
    borderRadius: BorderRadius.circular(8),
  );

  static BoxDecoration get tableHeaderDecoration => const BoxDecoration(
    color: AppColors.headerBackground,
  );
}

class AppInputDecorations {
  static InputDecoration getInputDecoration({
    String? hintText,
    bool enabled = true,
    bool isLoading = false,
  }) {
    return InputDecoration(
      hintText: enabled ? hintText : 'Select required field first...',
      hintStyle: TextStyle(
        color: AppColors.secondaryText.withOpacity(0.6),
      ),
      filled: true,
      fillColor: enabled
          ? AppColors.inputBackground
          : AppColors.inputBackground.withOpacity(0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        borderSide: const BorderSide(color: AppColors.primaryBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        borderSide: BorderSide(
          color: enabled
              ? AppColors.primaryBorder
              : AppColors.primaryBorder.withOpacity(0.5),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        borderSide: const BorderSide(color: AppColors.focusBorder),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        borderSide: const BorderSide(color: AppColors.errorBorder),
      ),
      contentPadding: const EdgeInsets.all(12),
      suffixIcon: isLoading
          ? const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.focusBorder,
          ),
        ),
      )
          : null,
    );
  }
}

class AppButtonStyles {
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: AppColors.buttonBackgroundWithOpacity,
    foregroundColor: AppColors.buttonText,
    side: BorderSide(color: AppColors.buttonBorderWithOpacity),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  );

  static ButtonStyle get cancelButtonStyle => TextButton.styleFrom(
    foregroundColor: AppColors.secondaryText,
  );

  static ButtonStyle get addButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: AppColors.buttonBackgroundWithOpacity,
    foregroundColor: AppColors.buttonText,
    side: BorderSide(color: AppColors.buttonBorderWithOpacity),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  );
}

class AppTabBarTheme {
  static TabBarTheme get theme => const TabBarTheme(
    labelColor: AppColors.accentText,
    unselectedLabelColor: AppColors.secondaryText,
    indicatorColor: AppColors.accentText,
    labelStyle: AppTextStyles.tabLabel,
  );
}

class AppSizes {
  // Dialog Sizes
  static const double dialogMaxWidth = 600;
  static const double dialogPadding = 6;

  // Spacing
  static const double fieldSpacing = 16;
  static const double sectionSpacing = 20;
  static const double itemSpacing = 8;
  static const double smallSpacing = 4;
  static const double largeSpacing = 24;

  // Border Radius
  static const double borderRadius = 10;
  static const double cardBorderRadius = 16;
  static const double itemCardBorderRadius = 12;
  static const double badgeBorderRadius = 6;

  // Padding
  static const EdgeInsets cardPadding = EdgeInsets.all(14);
  static const EdgeInsets itemPadding = EdgeInsets.all(10);
  //static const EdgeInsets dialogPadding = EdgeInsets.all(16);
  static const EdgeInsets fieldPadding = EdgeInsets.all(12);

  // Margins
  static const EdgeInsets pageMargin = EdgeInsets.all(16);
  static const EdgeInsets cardMargin = EdgeInsets.only(bottom: 12);
  static const EdgeInsets itemMargin = EdgeInsets.symmetric(vertical: 5, horizontal: 14);

  // Icon Sizes
  static const double smallIcon = 16;
  static const double mediumIcon = 20;
  static const double largeIcon = 24;

  // Loading Indicator
  static const double loadingSize = 16;
  static const double loadingStroke = 2;
}

class AppBreakpoints {
  static const double tablet = 520;
  static const double mobile = 400;
  static const double desktop = 800;
}

class AppAnimations {
  static const Duration shortDuration = Duration(milliseconds: 200);
  static const Duration mediumDuration = Duration(milliseconds: 300);
  static const Duration longDuration = Duration(milliseconds: 500);
}

// Helper Extensions
extension AppColorExtensions on Color {
  Color get withLightOpacity => withOpacity(0.1);
  Color get withMediumOpacity => withOpacity(0.2);
  Color get withHeavyOpacity => withOpacity(0.6);
}

extension AppStatusColors on String {
  Color get statusColor {
    switch (toLowerCase()) {
      case 'available':
        return AppColors.successColor;
      case 'in-use':
      case 'low-stock':
        return AppColors.warningColor;
      case 'maintenance':
      case 'out-of-stock':
        return AppColors.errorColor;
      default:
        return AppColors.secondaryText;
    }
  }

  TextStyle get statusTextStyle => AppTextStyles.statusText.copyWith(
    color: statusColor,
  );
}
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'training_constants.dart';

class TrainingButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final ButtonType type;

  const TrainingButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.type = ButtonType.primary,
  });

  @override
  Widget build(BuildContext context) {
    final style = _getButtonStyle(context);
    final foreground = _getForegroundColor(context);

    final child = isLoading
        ? SizedBox(
      width: TrainingConstants.iconSizeMedium,
      height: TrainingConstants.iconSizeMedium,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: foreground,
      ),
    )
        : LayoutBuilder(
      builder: (context, constraints) {
        // Dynamically calculate icon & text sizes based on parent width
        final iconSize = constraints.maxHeight * 0.5; // about half of button height
        final fontSize = constraints.maxHeight * 0.5; // scales text

        return FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: iconSize),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  style: AppTheme.button(context).copyWith(
                    color: foreground,
                    fontSize: fontSize,
                  ),
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
              ),
            ],
          ),
        );
      },
    );

    return SizedBox(
      height: TrainingConstants.buttonHeight,
      child: type == ButtonType.outlined
          ? OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: style,
        child: child,
      )
          : ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: style,
        child: child,
      ),
    );
  }

  ButtonStyle _getButtonStyle(BuildContext context) {
    switch (type) {
      case ButtonType.primary:
        return ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary(context),
          foregroundColor: AppTheme.background(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
        );
      case ButtonType.secondary:
        return ElevatedButton.styleFrom(
          backgroundColor: AppTheme.surfaceVariant(context),
          foregroundColor: AppTheme.textPrimary(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
        );
      case ButtonType.success:
        return ElevatedButton.styleFrom(
          backgroundColor: AppTheme.success(context),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
        );
      case ButtonType.error:
        return ElevatedButton.styleFrom(
          backgroundColor: AppTheme.error(context),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
        );
      case ButtonType.outlined:
        return OutlinedButton.styleFrom(
          foregroundColor: AppTheme.primary(context),
          side: BorderSide(color: AppTheme.primary(context), width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
        );
    }
  }

  Color _getForegroundColor(BuildContext context) {
    switch (type) {
      case ButtonType.primary:
        return AppTheme.background(context);
      case ButtonType.secondary:
        return AppTheme.textPrimary(context);
      case ButtonType.success:
      case ButtonType.error:
        return Colors.white;
      case ButtonType.outlined:
        return AppTheme.primary(context);
    }
  }
}

enum ButtonType { primary, secondary, success, error, outlined }

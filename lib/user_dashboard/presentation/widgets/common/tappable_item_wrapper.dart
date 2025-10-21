// lib/user_dashboard/presentation/widgets/common/tappable_item_wrapper.dart
import 'package:flutter/material.dart';
import 'item_details_dialog.dart';
import '../../core/theme/user_app_theme.dart';

class TappableItemWrapper extends StatelessWidget {
  final Widget child;
  final dynamic item;
  final VoidCallback? onTap;

  const TappableItemWrapper({
    super.key,
    required this.child,
    required this.item,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (onTap != null) {
            onTap!();
          } else {
            ItemDetailsDialog.show(context, item);
          }
        },
        borderRadius: BorderRadius.circular(AppSizes.itemCardBorderRadius),
        splashColor: AppColors.accentText.withOpacity(0.1),
        highlightColor: AppColors.accentText.withOpacity(0.05),
        child: child,
      ),
    );
  }
}
// lib/armory/presentation/widgets/common/tappable_item_wrapper.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'armory_constants.dart';
import 'item_details_bottom_sheet.dart';

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
            ItemDetailsBottomSheet.show(context, item);
          }
        },
        borderRadius: BorderRadius.circular(ArmoryConstants.itemCardBorderRadius),
        splashColor: AppTheme.primary(context).withOpacity(0.1),
        highlightColor: AppTheme.primary(context).withOpacity(0.05),
        child: child,
      ),
    );
  }
}
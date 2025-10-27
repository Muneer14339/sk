// lib/armory/presentation/widgets/common/tappable_item_wrapper.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'armory_constants.dart';
import 'item_details_bottom_sheet.dart';
import 'common_delete_dilogue.dart';

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

  ArmoryTabType _getTabType(dynamic item) {
    final typeName = item.runtimeType.toString();
    if (typeName.contains('Firearm')) return ArmoryTabType.firearms;
    if (typeName.contains('Ammunition')) return ArmoryTabType.ammunition;
    if (typeName.contains('Gear')) return ArmoryTabType.gear;
    if (typeName.contains('Tool')) return ArmoryTabType.tools;
    if (typeName.contains('Loadout')) return ArmoryTabType.loadouts;
    if (typeName.contains('Maintenance')) return ArmoryTabType.maintenence;
    return ArmoryTabType.firearms;
  }

  @override
  Widget build(BuildContext context) {
    final navContext = Navigator.of(context).context; // Root context save karo
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (onTap != null) {
            onTap!();
          } else {
            final userId = FirebaseAuth.instance.currentUser?.uid;
            ItemDetailsBottomSheet.show(
              navContext,
              item,
              userId!,
              _getTabType(item),

            );
          }
        },
        borderRadius: BorderRadius.circular(8),
        splashColor: AppTheme.primary(context).withOpacity(0.1),
        highlightColor: AppTheme.primary(context).withOpacity(0.05),
        child: child,
      ),
    );
  }
}
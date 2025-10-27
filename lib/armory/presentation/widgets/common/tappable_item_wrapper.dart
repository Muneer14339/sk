import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../domain/entities/armory_firearm.dart';
import '../../../domain/entities/armory_ammunition.dart';
import '../../../../core/theme/app_theme.dart';
import 'item_details_bottom_sheet.dart';
import 'common_delete_dilogue.dart';

class TappableItemWrapper extends StatelessWidget {
  final Widget child;
  final dynamic item;
  final VoidCallback? onTap;
  final ArmoryFirearm? firearm;
  final ArmoryAmmunition? ammunition;

  const TappableItemWrapper({
    super.key,
    required this.child,
    required this.item,
    this.onTap,
    this.firearm,
    this.ammunition,
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
    final navContext = Navigator.of(context).context;
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
              firearm: firearm,
              ammunition: ammunition,
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
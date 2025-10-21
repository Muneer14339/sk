// lib/user_dashboard/presentation/widgets/common/common_dialogs.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/armory_ammunition.dart';
import '../../../domain/entities/armory_firearm.dart';
import '../../../domain/entities/armory_gear.dart';
import '../../../domain/entities/armory_loadout.dart';
import '../../../domain/entities/armory_maintenance.dart';
import '../../../domain/entities/armory_tool.dart';
import '../../bloc/armory_bloc.dart';
import '../../bloc/armory_event.dart';
import '../../core/theme/user_app_theme.dart';

enum ArmoryTabType { firearms, ammunition, gear, tools, loadouts, maintenance }

class CommonDialogs {
  static void showDeleteDialog({
    required BuildContext context,
    required String userId,
    required ArmoryTabType armoryType,
    required String itemName,
    dynamic item, // pass the actual entity (firearm, gear, etc.)
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "$itemName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final bloc = context.read<ArmoryBloc>();

              switch (armoryType) {
                case ArmoryTabType.firearms:
                  bloc.add(DeleteFirearmEvent(userId: userId, firearm: item as ArmoryFirearm));
                  break;
                case ArmoryTabType.ammunition:
                  bloc.add(DeleteAmmunitionEvent(userId: userId, ammunition: item as ArmoryAmmunition));
                  break;
                case ArmoryTabType.gear:
                  bloc.add(DeleteGearEvent(userId: userId, gear: item as ArmoryGear));
                  break;
                case ArmoryTabType.tools:
                  bloc.add(DeleteToolEvent(userId: userId, tool: item as ArmoryTool));
                  break;
                case ArmoryTabType.loadouts:
                  bloc.add(DeleteLoadoutEvent(userId: userId, loadout: item as ArmoryLoadout));
                  break;
                case ArmoryTabType.maintenance:
                  bloc.add(DeleteMaintenanceEvent(userId: userId, maintenance: item as ArmoryMaintenance));
                  break;
              }

              Navigator.of(ctx).pop(); // Close dialog
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.errorColor),
            ),
          ),
        ],
      ),
    );
  }
}

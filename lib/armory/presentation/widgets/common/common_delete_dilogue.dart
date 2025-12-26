// lib/armory/presentation/widgets/common/common_delete_dilogue.dart - REPLACE entire file

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
import '../../bloc/armory_state.dart';
import '../../../../core/theme/app_theme.dart';
import 'armory_constants.dart';

enum ArmoryTabType { firearms, ammunition, gear, tools, loadouts, report, maintenence }

class CommonDialogs {
  static void showDeleteDialog({
    required BuildContext context,
    required String userId,
    required ArmoryTabType armoryType,
    required String itemName,
    dynamic item,
    BuildContext? parentContext
  }) {
    final state = context.read<ArmoryBloc>().state;
    if (state is! ArmoryDataLoaded) return;

    if (armoryType == ArmoryTabType.firearms) {
      _showFirearmDeleteDialog(context, userId, itemName, item as ArmoryFirearm, state, parentContext);
    } else if (armoryType == ArmoryTabType.ammunition) {
      _showAmmunitionDeleteDialog(context, userId, itemName, item as ArmoryAmmunition, state, parentContext);
    } else {
      _showSimpleDeleteDialog(context, userId, armoryType, itemName, item, parentContext);
    }
  }

  static void _showFirearmDeleteDialog(
      BuildContext context,
      String userId,
      String itemName,
      ArmoryFirearm firearm,
      ArmoryDataLoaded state,
      BuildContext? parentContext,
      ) {
    final sameCaliberFirearms = state.firearms.where((f) => f.caliber.toLowerCase() == firearm.caliber.toLowerCase()).toList();
    final isSingleCaliberFirearm = sameCaliberFirearms.length == 1;

    final dependentLoadouts = state.loadouts.where((l) => l.firearmId == firearm.id).toList();
    // In _showFirearmDeleteDialog, REPLACE caliber checking
    final List<ArmoryAmmunition> dependentAmmunition = [];
    final Set<String> ammunitionIds = {};

    final firearmCalibers = firearm.caliber.split(',').map((c) => c.trim().toLowerCase()).toList();

    for (final cal in firearmCalibers) {
      final firearmsWithThisCaliber = state.firearms.where((f) {
        final fCalibers = f.caliber.split(',').map((c) => c.trim().toLowerCase()).toList();
        return fCalibers.contains(cal);
      }).toList();

      if (firearmsWithThisCaliber.length == 1) {
        final ammoForCaliber = state.ammunition.where(
                (a) => a.caliber.toLowerCase() == cal
        );
        for (final ammo in ammoForCaliber) {
          if (!ammunitionIds.contains(ammo.id)) {
            ammunitionIds.add(ammo.id!);
            dependentAmmunition.add(ammo);
          }
        }
      }
    }

    final hasLoadouts = dependentLoadouts.isNotEmpty;
    final hasAmmunition = dependentAmmunition.isNotEmpty;

    if (!hasLoadouts && !hasAmmunition) {
      _showSimpleDeleteDialog(context, userId, ArmoryTabType.firearms, itemName, firearm, parentContext);
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface(context),
        title: Text('Confirm Delete', style: AppTheme.headingSmall(context)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you sure you want to delete "$itemName"?', style: AppTheme.bodyMedium(context)),
              const SizedBox(height: 16),
              if (hasLoadouts) ...[
                Text('${dependentLoadouts.length} Loadout(s) will be deleted:',
                    style: AppTheme.labelMedium(context).copyWith(color: AppTheme.error(context), fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ...dependentLoadouts.map((l) => Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.circle, size: 6, color: AppTheme.textSecondary(context)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(l.name, style: AppTheme.bodySmall(context))),
                    ],
                  ),
                )),
                const SizedBox(height: 12),
              ],
              if (hasAmmunition) ...[
                Text('${dependentAmmunition.length} Ammunition lot(s) will be deleted:',
                    style: AppTheme.labelMedium(context).copyWith(color: AppTheme.error(context), fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ...dependentAmmunition.map((a) => Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.circle, size: 6, color: AppTheme.textSecondary(context)),
                      const SizedBox(width: 8),
                      Expanded(child: Text('${a.brand} ${a.caliber} ${a.bullet}', style: AppTheme.bodySmall(context))),
                    ],
                  ),
                )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<ArmoryBloc>().add(DeleteFirearmWithDependenciesEvent(
                userId: userId,
                firearm: firearm,
                dependentLoadoutIds: dependentLoadouts.map((l) => l.id!).toList(),
                dependentAmmunitionIds: dependentAmmunition.map((a) => a.id!).toList(),
              ));
              Navigator.of(ctx).pop();
              if (parentContext != null) Navigator.of(context).pop();
            },
            child: Text('Delete All', style: TextStyle(color: AppTheme.error(context))),
          ),
        ],
      ),
    );
  }

  static void _showAmmunitionDeleteDialog(
      BuildContext context,
      String userId,
      String itemName,
      ArmoryAmmunition ammunition,
      ArmoryDataLoaded state,
      BuildContext? parentContext,
      ) {
    final dependentLoadouts = state.loadouts.where((l) => l.ammunitionId == ammunition.id).toList();

    if (dependentLoadouts.isEmpty) {
      _showSimpleDeleteDialog(context, userId, ArmoryTabType.ammunition, itemName, ammunition, parentContext);
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface(context),
        title: Text('Confirm Delete', style: AppTheme.headingSmall(context)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you sure you want to delete "$itemName"?', style: AppTheme.bodyMedium(context)),
              const SizedBox(height: 16),
              Text('${dependentLoadouts.length} Loadout(s) will be deleted:',
                  style: AppTheme.labelMedium(context).copyWith(color: AppTheme.error(context), fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...dependentLoadouts.map((l) => Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.circle, size: 6, color: AppTheme.textSecondary(context)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(l.name, style: AppTheme.bodySmall(context))),
                  ],
                ),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<ArmoryBloc>().add(DeleteAmmunitionWithDependenciesEvent(
                userId: userId,
                ammunition: ammunition,
                dependentLoadoutIds: dependentLoadouts.map((l) => l.id!).toList(),
              ));
              Navigator.of(ctx).pop();
              if (parentContext != null) Navigator.of(context).pop();
            },
            child: Text('Delete All', style: TextStyle(color: AppTheme.error(context))),
          ),
        ],
      ),
    );
  }

  static void _showSimpleDeleteDialog(
      BuildContext context,
      String userId,
      ArmoryTabType armoryType,
      String itemName,
      dynamic item,
      BuildContext? parentContext,
      ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface(context),
        title: Text('Confirm Delete', style: AppTheme.headingSmall(context)),
        content: Text('Are you sure you want to delete "$itemName"?', style: AppTheme.bodyMedium(context)),
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
                case ArmoryTabType.maintenence:
                  bloc.add(DeleteMaintenanceEvent(userId: userId, maintenance: item as ArmoryMaintenance));
                  break;
                case ArmoryTabType.report:
                  break;
              }
              Navigator.of(ctx).pop();
              if (parentContext != null) Navigator.of(context).pop();
            },
            child: Text('Delete', style: TextStyle(color: AppTheme.error(context))),
          ),
        ],
      ),
    );
  }
}
// lib/armory/presentation/widgets/tab_widgets/report_tab_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../domain/entities/armory_firearm.dart';
import '../../../domain/entities/armory_ammunition.dart';
import '../../../domain/entities/armory_gear.dart';
import '../../../domain/entities/armory_maintenance.dart';
import '../../../domain/entities/armory_tool.dart';
import '../../../domain/entities/armory_loadout.dart';
import '../../bloc/armory_bloc.dart';
import '../../bloc/armory_event.dart';
import '../../bloc/armory_state.dart';
import '../common/armory_constants.dart';
import '../common/common_widgets.dart';

class ReportTabWidget extends StatefulWidget {
  final String userId;

  const ReportTabWidget({super.key, required this.userId});

  @override
  State<ReportTabWidget> createState() => _ReportTabWidgetState();
}

class _ReportTabWidgetState extends State<ReportTabWidget> {
  List<ArmoryFirearm> _firearms = [];
  List<ArmoryAmmunition> _ammunition = [];
  List<ArmoryGear> _gear = [];
  List<ArmoryTool> _tools = [];
  List<ArmoryLoadout> _loadouts = [];
  List<ArmoryMaintenance> _maintenance = [];

  final Map<String, bool> _expandedSections = {
    'firearms': false,
    'ammunition': false,
    'gear': false,
    'tools': false,
    'loadouts': false,
  };

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  void _loadAllData() {
    final bloc = context.read<ArmoryBloc>();
    bloc.add(LoadFirearmsEvent(userId: widget.userId));
    bloc.add(LoadAmmunitionEvent(userId: widget.userId));
    bloc.add(LoadGearEvent(userId: widget.userId));
    bloc.add(LoadToolsEvent(userId: widget.userId));
    bloc.add(LoadLoadoutsEvent(userId: widget.userId));
    bloc.add(LoadMaintenanceEvent(userId: widget.userId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ArmoryBloc, ArmoryState>(
      listener: (context, state) {
        if (state is FirearmsLoaded) {
          setState(() => _firearms = state.firearms);
        } else if (state is AmmunitionLoaded) {
          setState(() => _ammunition = state.ammunition);
        } else if (state is GearLoaded) {
          setState(() => _gear = state.gear);
        } else if (state is ToolsLoaded) {
          setState(() => _tools = state.tools);
        } else if (state is LoadoutsLoaded) {
          setState(() => _loadouts = state.loadouts);
        } else if (state is MaintenanceLoaded) {
          setState(() => _maintenance = state.maintenance);
        }
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
          border: Border.all(color: AppTheme.border(context)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildReportHeader(),
            _buildReportSection(
              'firearms',
              'Firearms',
              _firearms.length,
              _buildFirearmsTable(),
            ),
            _buildReportSection(
              'ammunition',
              'Ammunition',
              _ammunition.length,
              _buildAmmunitionTable(),
            ),
            _buildReportSection(
              'gear',
              'Gear & Accessories',
              _gear.length,
              _buildGearTable(),
            ),
            _buildReportSection(
              'tools',
              'Tools & Equipment',
              _tools.length,
              _buildToolsTable(),
            ),
            _buildReportSection(
              'maintenance',
              'Maintenance History',
              _maintenance.length,
              _buildMaintenanceTable(),
            ),
            _buildReportSection(
              'loadouts',
              'Loadouts',
              _loadouts.length,
              _buildLoadoutsTable(),
            ),
          ],
        ),
      ),
    );
  }

  String _getFirearmName(String? firearmId) {
    if (firearmId == null || firearmId.isEmpty) return '';
    try {
      final firearm = _firearms.firstWhere((f) => f.id == firearmId);
      return firearm.nickname.isNotEmpty ? firearm.nickname : '${firearm.make} ${firearm.model}';
    } catch (e) {
      return 'Unknown Firearm';
    }
  }

  String _getAmmunitionName(String? ammunitionId) {
    if (ammunitionId == null || ammunitionId.isEmpty) return '';
    try {
      final ammo = _ammunition.firstWhere((a) => a.id == ammunitionId);
      return '${ammo.brand} ${ammo.caliber} ${ammo.bullet}';
    } catch (e) {
      return 'Unknown Ammo';
    }
  }

  String _getAssetName(String assetType, String assetId) {
    if (assetType == 'firearm') {
      return _getFirearmName(assetId);
    } else if (assetType == 'gear') {
      try {
        final gear = _gear.firstWhere((g) => g.id == assetId);
        return gear.model;
      } catch (e) {
        return 'Unknown Gear';
      }
    }
    return 'Unknown Asset';
  }

  Widget _buildReportHeader() {
    return CommonWidgets.buildPageHeader(
      context: context,
      title: 'Inventory Report',
      actions: [
        CommonWidgets.buildActionButton(
          context: context,
          label: 'Print Report',
          onPressed: _printReport,
          icon: Icons.print,
        ),
      ],
    );
  }

  Widget _buildReportSection(String key, String title, int count, Widget content) {
    final isExpanded = _expandedSections[key] ?? false;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border(context))),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _expandedSections[key] = !isExpanded;
              });
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(title, style: AppTheme.titleLarge(context)),
                  ),
                  const SizedBox(width: 12),
                  CommonWidgets.buildCountBadge(context, count, 'items'),
                  const SizedBox(width: 12),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: ArmoryConstants.shortDuration,
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: AppTheme.textSecondary(context),
                      size: ArmoryConstants.mediumIcon,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Container(
              width: double.infinity,
              padding: ArmoryConstants.cardPadding,
              child: content,
            ),
        ],
      ),
    );
  }

  Widget _buildFirearmsTable() {
    return CommonWidgets.buildDataTable(
      context,
      emptyMessage: 'No firearms in inventory',
      columns: const [
        DataColumn(label: Text('Make')),
        DataColumn(label: Text('Model')),
        DataColumn(label: Text('Caliber')),
        DataColumn(label: Text('Type')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Serial')),
        DataColumn(label: Text('Nickname')),
      ],
      rows: _firearms.map((firearm) {
        return DataRow(
          cells: [
            DataCell(SizedBox(width: 60, child: Text(firearm.make, overflow: TextOverflow.ellipsis))),
            DataCell(SizedBox(width: 80, child: Text(firearm.model, overflow: TextOverflow.ellipsis))),
            DataCell(SizedBox(width: 70, child: Text(firearm.caliber, overflow: TextOverflow.ellipsis))),
            DataCell(SizedBox(width: 60, child: Text(firearm.type, overflow: TextOverflow.ellipsis))),
            DataCell(SizedBox(width: 80, child: CommonWidgets.buildStatusChip(context, firearm.status))),
            DataCell(SizedBox(width: 70, child: Text(firearm.serial ?? '', overflow: TextOverflow.ellipsis))),
            DataCell(SizedBox(width: 80, child: Text(firearm.nickname, overflow: TextOverflow.ellipsis))),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildAmmunitionTable() {
    return CommonWidgets.buildDataTable(
      context,
      emptyMessage: 'No ammunition in inventory',
      columns: const [
        DataColumn(label: Text('Brand')),
        DataColumn(label: Text('Line')),
        DataColumn(label: Text('Caliber')),
        DataColumn(label: Text('Bullet')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Quantity')),
        DataColumn(label: Text('Lot')),
      ],
      rows: _ammunition.map((ammo) {
        return DataRow(
          cells: [
            DataCell(SizedBox(width: 70, child: Text(ammo.brand, overflow: TextOverflow.ellipsis))),
            DataCell(SizedBox(width: 70, child: Text(ammo.line ?? '', overflow: TextOverflow.ellipsis))),
            DataCell(SizedBox(width: 70, child: Text(ammo.caliber, overflow: TextOverflow.ellipsis))),
            DataCell(SizedBox(width: 80, child: Text(ammo.bullet, overflow: TextOverflow.ellipsis))),
            DataCell(SizedBox(width: 80, child: CommonWidgets.buildStatusChip(context, ammo.status))),
            DataCell(SizedBox(width: 60, child: Text('${ammo.quantity}', overflow: TextOverflow.ellipsis))),
            DataCell(SizedBox(width: 60, child: Text(ammo.lot ?? '', overflow: TextOverflow.ellipsis))),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildGearTable() {
    return CommonWidgets.buildDataTable(
      context,
      emptyMessage: 'No gear in inventory',
      columns: const [
        DataColumn(label: Text('Category')),
        DataColumn(label: Text('Model')),
        DataColumn(label: Text('Serial')),
        DataColumn(label: Text('Qty')),
        DataColumn(label: Text('Notes')),
      ],
      rows: _gear.map((gear) {
        return DataRow(
          cells: [
            DataCell(SizedBox(width: 80, child: Text(gear.category, overflow: TextOverflow.ellipsis))),
            DataCell(SizedBox(width: 120, child: Text(gear.model, overflow: TextOverflow.ellipsis))),
            DataCell(SizedBox(width: 80, child: Text(gear.serial ?? '', overflow: TextOverflow.ellipsis))),
            DataCell(SizedBox(width: 40, child: Text('${gear.quantity}'))),
            DataCell(SizedBox(width: 100, child: Text(gear.notes ?? '', overflow: TextOverflow.ellipsis))),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildToolsTable() {
    return CommonWidgets.buildDataTable(
      context,
      emptyMessage: 'No tools in inventory',
      columns: const [
        DataColumn(label: Text('Name')),
        DataColumn(label: Text('Category')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Qty')),
      ],
      rows: _tools.map((tool) {
        return DataRow(
          cells: [
            DataCell(SizedBox(width: 120, child: Text(tool.name, overflow: TextOverflow.ellipsis))),
            DataCell(SizedBox(width: 80, child: Text(tool.category ?? '', overflow: TextOverflow.ellipsis))),
            DataCell(SizedBox(width: 80, child: CommonWidgets.buildStatusChip(context, tool.status))),
            DataCell(SizedBox(width: 40, child: Text('${tool.quantity}'))),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildMaintenanceTable() {
    return CommonWidgets.buildDataTable(
      context,
      emptyMessage: 'No maintenance records',
      columns: const [
        DataColumn(label: Text('Date')),
        DataColumn(label: Text('Asset')),
        DataColumn(label: Text('Type')),
        DataColumn(label: Text('Rounds')),
        DataColumn(label: Text('Notes')),
      ],
      rows: _maintenance.map((maint) {
        return DataRow(
          cells: [
            DataCell(SizedBox(width: 80, child: Text('${maint.date.day}/${maint.date.month}/${maint.date.year}'))),
            DataCell(SizedBox(width: 120, child: Text(_getAssetName(maint.assetType, maint.assetId), overflow: TextOverflow.ellipsis))),
            DataCell(SizedBox(width: 80, child: Text(maint.maintenanceType, overflow: TextOverflow.ellipsis))),
            DataCell(SizedBox(width: 60, child: Text('${maint.roundsFired ?? 0}'))),
            DataCell(SizedBox(width: 100, child: Text(maint.notes ?? '', overflow: TextOverflow.ellipsis))),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildLoadoutsTable() {
    return CommonWidgets.buildDataTable(
      context,
      emptyMessage: 'No loadouts configured',
      columns: const [
        DataColumn(label: Text('Name')),
        DataColumn(label: Text('Firearm')),
        DataColumn(label: Text('Ammo')),
        DataColumn(label: Text('Gear')),
        DataColumn(label: Text('Notes')),
      ],
      rows: _loadouts.map((loadout) {
        return DataRow(
          cells: [
            DataCell(SizedBox(width: 100, child: Text(loadout.name, overflow: TextOverflow.ellipsis))),
            DataCell(SizedBox(width: 120, child: Text(_getFirearmName(loadout.firearmId), overflow: TextOverflow.ellipsis))),
            DataCell(SizedBox(width: 120, child: Text(_getAmmunitionName(loadout.ammunitionId), overflow: TextOverflow.ellipsis))),
            DataCell(SizedBox(width: 60, child: Text('${loadout.gearIds.length} items'))),
            DataCell(SizedBox(width: 100, child: Text(loadout.notes ?? '', overflow: TextOverflow.ellipsis))),
          ],
        );
      }).toList(),
    );
  }

  void _printReport() {
    setState(() {
      _expandedSections.updateAll((key, value) => true);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Print functionality would be implemented here'),
        backgroundColor: AppTheme.primary(context),
      ),
    );
  }
}
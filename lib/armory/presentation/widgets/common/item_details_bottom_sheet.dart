// lib/armory/presentation/widgets/common/item_details_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:pa_sreens/armory/presentation/widgets/common/armory_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../domain/entities/armory_ammunition.dart';
import '../../../domain/entities/armory_firearm.dart';
import '../../../domain/entities/armory_loadout.dart';
import 'entity_field_helper.dart';
import 'common_delete_dilogue.dart';

class ItemDetailsBottomSheet extends StatefulWidget {
  final dynamic item;
  final String userId;
  final ArmoryTabType tabType;
  final ArmoryFirearm? firearm;
  final ArmoryAmmunition? ammunition;

  const ItemDetailsBottomSheet({
    super.key,
    required this.item,
    required this.userId,
    required this.tabType,
    this.firearm,
    this.ammunition,
  });

  static void show(
      BuildContext context,
      dynamic item,
      String userId,
      ArmoryTabType tabType, {
        ArmoryFirearm? firearm,
        ArmoryAmmunition? ammunition,
      }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => ItemDetailsBottomSheet(
        item: item,
        userId: userId,
        tabType: tabType,
        firearm: firearm,
        ammunition: ammunition,
      ),
    );
  }

  @override
  State<ItemDetailsBottomSheet> createState() => _ItemDetailsBottomSheetState();
}

class _ItemDetailsBottomSheetState extends State<ItemDetailsBottomSheet>
    with SingleTickerProviderStateMixin {
  final Map<String, bool> _expandedSections = {};
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final details = widget.tabType == ArmoryTabType.loadouts
        ? _buildLoadoutDetails()
        : EntityFieldHelper.extractDetails(widget.item);
    final screenHeight = MediaQuery.of(context).size.height;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _animation.value) * screenHeight * 0.85),
          child: child,
        );
      },
      child: Container(
        height: screenHeight * 0.85,
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(details),
            Expanded(child: _buildContent(details)),
            _buildFooter(details),
          ],
        ),
      ),
    );
  }

  EntityDetailsData _buildLoadoutDetails() {
    final loadout = widget.item as ArmoryLoadout;
    final List<EntityField> fields = [];

    // Additional info section
    if (loadout.notes != null && loadout.notes!.isNotEmpty) {
      fields.add(EntityField(
        label: 'Notes',
        value: loadout.notes,
        type: EntityFieldType.multiline,
      ));
    }

    fields.add(EntityField(
      label: 'Date Created',
      value: '${loadout.dateAdded.day}/${loadout.dateAdded.month}/${loadout.dateAdded.year}',
      type: EntityFieldType.date,
    ));

    return EntityDetailsData(
      title: loadout.name,
      subtitle: 'Training Loadout',
      type: 'Loadout',
      sections: fields,
    );
  }
  Widget _buildHeader(EntityDetailsData details) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border(context))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  details.title,
                  style: AppTheme.titleLarge(context).copyWith(fontSize: 16, fontWeight: FontWeight.w700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (details.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    details.subtitle,
                    style: AppTheme.labelMedium(context).copyWith(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close, color: AppTheme.textSecondary(context), size: 22),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(EntityDetailsData details) {
    // For loadouts, show enhanced details with firearm/ammo info
    if (widget.tabType == ArmoryTabType.loadouts) {
      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildLoadoutPrimarySection(),
            if (details.sections.isNotEmpty) ..._buildSecondarySection(details.sections),
            const SizedBox(height: 80),
          ],
        ),
      );
    }

    // Original logic for other types
    final required = details.sections.where((f) => f.isImportant).toList();
    final additional = details.sections.where((f) => !f.isImportant).toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          if (required.isNotEmpty) _buildPrimarySection(required),
          if (additional.isNotEmpty) ..._buildSecondarySection(additional),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildLoadoutPrimarySection() {
    final loadout = widget.item as ArmoryLoadout;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primary(context).withOpacity(0.08),
        border: Border(bottom: BorderSide(color: AppTheme.primary(context).withOpacity(0.15))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LOADOUT CONFIGURATION',
            style: AppTheme.labelMedium(context).copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.primary(context),
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 10),
          if (widget.firearm != null) ...[
            _buildLoadoutInfoCard(
              'FIREARM',
              '${widget.firearm!.make} ${widget.firearm!.model}',
              widget.firearm!.caliber,
            ),
            const SizedBox(height: 10),
          ],
          if (widget.ammunition != null) ...[
            _buildLoadoutInfoCard(
              'AMMUNITION',
              '${widget.ammunition!.brand} ${widget.ammunition!.line ?? ''}',
              '${widget.ammunition!.caliber} • ${widget.ammunition!.bullet} • ${widget.ammunition!.quantity} rds',
            ),
            const SizedBox(height: 10),
          ],
          _buildLoadoutInfoCard(
            'GEAR',
            '${loadout.gearIds.length} items attached',
            'Optics, supports, attachments',
          ),
        ],
      ),
    );
  }

  Widget _buildLoadoutInfoCard(String title, String primary, String secondary) {
    return Container(
      width: double.maxFinite,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        border: Border.all(color: AppTheme.primary(context).withOpacity(0.2)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.labelSmall(context).copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppTheme.primary(context),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            primary,
            style: AppTheme.bodySmall(context).copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            secondary,
            style: AppTheme.labelMedium(context).copyWith(
              fontSize: 12,
              color: AppTheme.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimarySection(List<EntityField> fields) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primary(context).withOpacity(0.08),
        border: Border(bottom: BorderSide(color: AppTheme.primary(context).withOpacity(0.15))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'KEY INFORMATION',
            style: AppTheme.labelMedium(context).copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.primary(context),
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 10),
          _buildGrid(fields, true),
        ],
      ),
    );
  }

  List<Widget> _buildSecondarySection(List<EntityField> fields) {
    return _groupFields(fields).entries.map((e) => _buildAccordion(e.key, e.value)).toList();
  }

  Map<String, List<EntityField>> _groupFields(List<EntityField> fields) {
    final groups = <String, List<EntityField>>{
      'Type & Status': [],
      'Technical Details': [],
      'Physical Specs': [],
      'Purchase & Value': [],
      'Usage & Maintenance': [],
      'Additional Info': [],
    };

    for (final field in fields) {
      final label = field.label.toLowerCase();
      if (label.contains('type') || label.contains('status') || label.contains('brand') || label.contains('generation')) {
        groups['Type & Status']!.add(field);
      } else if (label.contains('firing') || label.contains('action') || label.contains('feed') || label.contains('capacity') || label.contains('mechanism') || label.contains('primer') || label.contains('powder') || label.contains('case')) {
        groups['Technical Details']!.add(field);
      } else if (label.contains('barrel') || label.contains('length') || label.contains('weight') || label.contains('twist') || label.contains('thread') || label.contains('finish') || label.contains('stock') || label.contains('trigger') || label.contains('safety')) {
        groups['Physical Specs']!.add(field);
      } else if (label.contains('purchase') || label.contains('price') || label.contains('value') || label.contains('dealer') || label.contains('cost')) {
        groups['Purchase & Value']!.add(field);
      } else if (label.contains('round') || label.contains('clean') || label.contains('zero') || label.contains('storage') || label.contains('velocity') || label.contains('energy') || label.contains('ballistic') || label.contains('group') || label.contains('test')) {
        groups['Usage & Maintenance']!.add(field);
      } else {
        groups['Additional Info']!.add(field);
      }
    }

    groups.removeWhere((_, v) => v.isEmpty);
    return groups;
  }

  Widget _buildAccordion(String title, List<EntityField> fields) {
    final isExpanded = _expandedSections[title] ?? false;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border(context).withOpacity(0.5))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => setState(() => _expandedSections[title] = !isExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: AppTheme.labelMedium(context).copyWith(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.keyboard_arrow_down, size: 20, color: AppTheme.textSecondary(context)),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: isExpanded
                ? Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: _buildGrid(fields, false),
            )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(List<EntityField> fields, bool isPrimary) {
    final orientation = MediaQuery.of(context).orientation;
    final screenWidth = MediaQuery.of(context).size.width;
    final columns = orientation == Orientation.landscape ? 3 : (screenWidth > 400 ? 2 : 1);

    final rows = <Widget>[];
    for (int i = 0; i < fields.length; i += columns) {
      final children = <Widget>[];
      for (int j = 0; j < columns; j++) {
        if (i + j < fields.length) {
          children.add(Expanded(child: _buildFieldCard(fields[i + j], isPrimary)));
        } else {
          children.add(const Expanded(child: SizedBox()));
        }
        if (j < columns - 1) children.add(const SizedBox(width: 10));
      }
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: children),
          ),
        ),
      );
    }

    return Column(children: rows);
  }

  Widget _buildFieldCard(EntityField field, bool isPrimary) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isPrimary ? AppTheme.surface(context) : AppTheme.surfaceVariant(context),
        border: Border.all(
          color: isPrimary ? AppTheme.primary(context).withOpacity(0.2) : AppTheme.border(context),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            field.label,
            style: AppTheme.labelSmall(context).copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isPrimary ? AppTheme.primary(context) : AppTheme.textSecondary(context),
            ),
          ),
          const SizedBox(height: 4),
          _buildFieldValue(field, isPrimary),
        ],
      ),
    );
  }

  Widget _buildFieldValue(EntityField field, bool isPrimary) {
    if (field.value == null || field.value!.trim().isEmpty) {
      return Text('—', style: AppTheme.bodySmall(context).copyWith(color: AppTheme.textSecondary(context), fontStyle: FontStyle.italic, fontSize: 14));
    }

    final value = field.value!.trim();
    final style = AppTheme.bodySmall(context).copyWith(fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w500, fontSize: 14);

    switch (field.type) {
      case EntityFieldType.status:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: value.statusColor(context).withOpacity(0.1),
            border: Border.all(color: value.statusColor(context).withOpacity(0.2)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(value, style: value.statusTextStyle(context).copyWith(fontWeight: FontWeight.w600, fontSize: 11)),
        );
      case EntityFieldType.multiline:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppTheme.background(context), borderRadius: BorderRadius.circular(6)),
          child: Text(value, style: style),
        );
      case EntityFieldType.date:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_outlined, size: 12, color: isPrimary ? AppTheme.primary(context) : AppTheme.textSecondary(context)),
            const SizedBox(width: 4),
            Expanded(child: Text(value, style: style)),
          ],
        );
      default:
        return Text(value, style: style);
    }
  }

  Widget _buildFooter(EntityDetailsData details) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        border: Border(top: BorderSide(color: AppTheme.border(context))),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary(context),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('Edit', style: AppTheme.button(context).copyWith(fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  CommonDialogs.showDeleteDialog(
                    context: context,
                    userId: widget.userId,
                    armoryType: widget.tabType,
                    itemName: details.title,
                    item: widget.item,
                    parentContext: context
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.error(context).withOpacity(0.1),
                  foregroundColor: AppTheme.error(context),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('Delete', style: AppTheme.button(context).copyWith(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.error(context))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

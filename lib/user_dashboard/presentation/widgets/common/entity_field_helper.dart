// lib/user_dashboard/presentation/widgets/common/entity_field_helper.dart
import '../../../domain/entities/armory_ammunition.dart';
import '../../../domain/entities/armory_firearm.dart';
import '../../../domain/entities/armory_gear.dart';
import '../../../domain/entities/armory_loadout.dart';
import '../../../domain/entities/armory_maintenance.dart';
import '../../../domain/entities/armory_tool.dart';

class EntityField {
  final String label;
  final String? value;
  final bool isImportant;
  final EntityFieldType type;

  const EntityField({
    required this.label,
    required this.value,
    this.isImportant = false,
    this.type = EntityFieldType.text,
  });
}

enum EntityFieldType { text, status, date, number, multiline }

class EntityDetailsData {
  final String title;
  final String subtitle;
  final String type;
  final List<EntityField> sections;

  const EntityDetailsData({
    required this.title,
    required this.subtitle,
    required this.type,
    required this.sections,
  });
}

class EntityFieldHelper {
  static EntityDetailsData extractDetails(dynamic entity) {
    if (entity is ArmoryFirearm) {
      return _extractFirearmDetails(entity);
    } else if (entity is ArmoryAmmunition) {
      return _extractAmmunitionDetails(entity);
    } else if (entity is ArmoryGear) {
      return _extractGearDetails(entity);
    } else if (entity is ArmoryTool) {
      return _extractToolDetails(entity);
    } else if (entity is ArmoryLoadout) {
      return _extractLoadoutDetails(entity);
    } else if (entity is ArmoryMaintenance) {
      return _extractMaintenanceDetails(entity);
    }

    return const EntityDetailsData(
      title: 'Unknown Item',
      subtitle: 'Unknown Type',
      type: 'unknown',
      sections: [],
    );
  }

  static EntityDetailsData _extractFirearmDetails(ArmoryFirearm firearm) {
    final List<EntityField> fields = [];

    // Basic Information
    _addField(fields, 'Make', firearm.make, isImportant: true);
    _addField(fields, 'Model', firearm.model, isImportant: true);
    _addField(fields, 'Caliber', firearm.caliber, isImportant: true);
    _addField(fields, 'Type', firearm.type);
    _addField(fields, 'Nickname', firearm.nickname);
    _addField(fields, 'Status', firearm.status, type: EntityFieldType.status);
    _addField(fields, 'Serial Number', firearm.serial);
    _addField(fields, 'Brand', firearm.brand);

    // Technical Details
    _addField(fields, 'Generation', firearm.generation);
    _addField(fields, 'Firing Mechanism', firearm.firingMechanism);
    _addField(fields, 'Detailed Type', firearm.detailedType);
    _addField(fields, 'Purpose', firearm.purpose);
    _addField(fields, 'Condition', firearm.condition);
    _addField(fields, 'Action Type', firearm.actionType);
    _addField(fields, 'Feed System', firearm.feedSystem);
    _addField(fields, 'Magazine Capacity', firearm.magazineCapacity);

    // Physical Specifications
    _addField(fields, 'Barrel Length', firearm.barrelLength);
    _addField(fields, 'Overall Length', firearm.overallLength);
    _addField(fields, 'Weight', firearm.weight);
    _addField(fields, 'Twist Rate', firearm.twistRate);
    _addField(fields, 'Thread Pattern', firearm.threadPattern);
    _addField(fields, 'Finish', firearm.finish);
    _addField(fields, 'Stock Material', firearm.stockMaterial);
    _addField(fields, 'Trigger Type', firearm.triggerType);
    _addField(fields, 'Safety Type', firearm.safetyType);

    // Purchase & Value
    _addField(fields, 'Purchase Date', firearm.purchaseDate, type: EntityFieldType.date);
    _addField(fields, 'Purchase Price', firearm.purchasePrice);
    _addField(fields, 'Current Value', firearm.currentValue);
    _addField(fields, 'FFL Dealer', firearm.fflDealer);
    _addField(fields, 'Manufacturer PN', firearm.manufacturerPN);

    // Usage & Maintenance
    _addField(fields, 'Round Count', firearm.roundCount.toString(), type: EntityFieldType.number);
    _addField(fields, 'Last Cleaned', firearm.lastCleaned, type: EntityFieldType.date);
    _addField(fields, 'Zero Distance', firearm.zeroDistance);
    _addField(fields, 'Storage Location', firearm.storageLocation);

    // Additional Info
    _addField(fields, 'Modifications', firearm.modifications, type: EntityFieldType.multiline);
    _addField(fields, 'Accessories Included', firearm.accessoriesIncluded, type: EntityFieldType.multiline);
    _addField(fields, 'Notes', firearm.notes, type: EntityFieldType.multiline);
    _addField(fields, 'Date Added', _formatDate(firearm.dateAdded), type: EntityFieldType.date);

    return EntityDetailsData(
      title: '${firearm.make} ${firearm.model}',
      subtitle: firearm.nickname.isNotEmpty ? '"${firearm.nickname}"' : firearm.caliber,
      type: 'Firearm',
      sections: fields,
    );
  }

  static EntityDetailsData _extractAmmunitionDetails(ArmoryAmmunition ammo) {
    final List<EntityField> fields = [];

    // Basic Information
    _addField(fields, 'Brand', ammo.brand, isImportant: true);
    _addField(fields, 'Line', ammo.line);
    _addField(fields, 'Caliber', ammo.caliber, isImportant: true);
    _addField(fields, 'Bullet', ammo.bullet, isImportant: true);
    _addField(fields, 'Quantity', ammo.quantity.toString(), type: EntityFieldType.number);
    _addField(fields, 'Status', ammo.status, type: EntityFieldType.status);
    _addField(fields, 'Lot Number', ammo.lot);
    _addField(fields, 'Is Handloaded', ammo.isHandloaded ? 'Yes' : 'No');

    // Component Details
    _addField(fields, 'Primer Type', ammo.primerType);
    _addField(fields, 'Powder Type', ammo.powderType);
    _addField(fields, 'Powder Weight', ammo.powderWeight);
    _addField(fields, 'Case Material', ammo.caseMaterial);
    _addField(fields, 'Case Condition', ammo.caseCondition);
    _addField(fields, 'Headstamp', ammo.headstamp);

    // Ballistic Data
    _addField(fields, 'Ballistic Coefficient', ammo.ballisticCoefficient);
    _addField(fields, 'Muzzle Energy', ammo.muzzleEnergy);
    _addField(fields, 'Velocity', ammo.velocity);
    _addField(fields, 'Temperature Tested', ammo.temperatureTested);
    _addField(fields, 'Standard Deviation', ammo.standardDeviation);
    _addField(fields, 'Extreme Spread', ammo.extremeSpread);

    // Performance Data
    _addField(fields, 'Group Size', ammo.groupSize);
    _addField(fields, 'Test Distance', ammo.testDistance);
    _addField(fields, 'Test Firearm', ammo.testFirearm);
    _addField(fields, 'Environmental Conditions', ammo.environmentalConditions);
    _addField(fields, 'Performance Notes', ammo.performanceNotes, type: EntityFieldType.multiline);

    // Purchase & Storage
    _addField(fields, 'Purchase Date', ammo.purchaseDate, type: EntityFieldType.date);
    _addField(fields, 'Purchase Price', ammo.purchasePrice);
    _addField(fields, 'Cost Per Round', ammo.costPerRound);
    _addField(fields, 'Expiration Date', ammo.expirationDate, type: EntityFieldType.date);
    _addField(fields, 'Storage Location', ammo.storageLocation);

    // Load Data & Notes
    _addField(fields, 'Load Data', ammo.loadData, type: EntityFieldType.multiline);
    _addField(fields, 'Notes', ammo.notes, type: EntityFieldType.multiline);
    _addField(fields, 'Date Added', _formatDate(ammo.dateAdded), type: EntityFieldType.date);

    return EntityDetailsData(
      title: '${ammo.brand} ${ammo.line ?? ''}',
      subtitle: '${ammo.caliber} - ${ammo.bullet}',
      type: 'Ammunition',
      sections: fields,
    );
  }

  static EntityDetailsData _extractGearDetails(ArmoryGear gear) {
    final List<EntityField> fields = [];

    _addField(fields, 'Category', gear.category, isImportant: true);
    _addField(fields, 'Model', gear.model, isImportant: true);
    _addField(fields, 'Serial Number', gear.serial);
    _addField(fields, 'Quantity', gear.quantity.toString(), type: EntityFieldType.number);
    _addField(fields, 'Notes', gear.notes, type: EntityFieldType.multiline);
    _addField(fields, 'Date Added', _formatDate(gear.dateAdded), type: EntityFieldType.date);

    return EntityDetailsData(
      title: gear.model,
      subtitle: gear.category,
      type: 'Gear',
      sections: fields,
    );
  }

  static EntityDetailsData _extractToolDetails(ArmoryTool tool) {
    final List<EntityField> fields = [];

    _addField(fields, 'Name', tool.name, isImportant: true);
    _addField(fields, 'Category', tool.category);
    _addField(fields, 'Quantity', tool.quantity.toString(), type: EntityFieldType.number);
    _addField(fields, 'Status', tool.status, type: EntityFieldType.status);
    _addField(fields, 'Notes', tool.notes, type: EntityFieldType.multiline);
    _addField(fields, 'Date Added', _formatDate(tool.dateAdded), type: EntityFieldType.date);

    return EntityDetailsData(
      title: tool.name,
      subtitle: tool.category ?? 'Tool',
      type: 'Tool',
      sections: fields,
    );
  }

  static EntityDetailsData _extractLoadoutDetails(ArmoryLoadout loadout) {
    final List<EntityField> fields = [];

    _addField(fields, 'Name', loadout.name, isImportant: true);
    _addField(fields, 'Firearm ID', loadout.firearmId);
    _addField(fields, 'Ammunition ID', loadout.ammunitionId);
    _addField(fields, 'Gear Count', loadout.gearIds.length.toString(), type: EntityFieldType.number);
    _addField(fields, 'Notes', loadout.notes, type: EntityFieldType.multiline);
    _addField(fields, 'Date Added', _formatDate(loadout.dateAdded), type: EntityFieldType.date);

    return EntityDetailsData(
      title: loadout.name,
      subtitle: 'Training Loadout',
      type: 'Loadout',
      sections: fields,
    );
  }

  static EntityDetailsData _extractMaintenanceDetails(ArmoryMaintenance maintenance) {
    final List<EntityField> fields = [];

    _addField(fields, 'Asset Type', maintenance.assetType, isImportant: true);
    _addField(fields, 'Asset ID', maintenance.assetId);
    _addField(fields, 'Maintenance Type', maintenance.maintenanceType, isImportant: true);
    _addField(fields, 'Date', _formatDate(maintenance.date), type: EntityFieldType.date, isImportant: true);
    _addField(fields, 'Rounds Fired', maintenance.roundsFired?.toString(), type: EntityFieldType.number);
    _addField(fields, 'Notes', maintenance.notes, type: EntityFieldType.multiline);
    _addField(fields, 'Date Added', _formatDate(maintenance.dateAdded), type: EntityFieldType.date);

    return EntityDetailsData(
      title: maintenance.maintenanceType,
      subtitle: maintenance.assetType,
      type: 'Maintenance',
      sections: fields,
    );
  }

  static void _addField(List<EntityField> fields, String label, String? value,
      {bool isImportant = false, EntityFieldType type = EntityFieldType.text}) {
    if (value != null && value.trim().isNotEmpty) {
      fields.add(EntityField(
        label: label,
        value: value.trim(),
        isImportant: isImportant,
        type: type,
      ));
    }
  }

  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
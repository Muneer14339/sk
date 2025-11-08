// lib/user_dashboard/data/models/armory_ammunition_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/armory_ammunition.dart';

class ArmoryAmmunitionModel extends ArmoryAmmunition {
  ArmoryAmmunitionModel({
    super.id,
    required super.brand,
    super.line,
    required super.caliber,
    required super.bullet,
    required super.quantity,
    required super.status,
    super.lot,
    super.notes,
    super.primerType,
    super.powderType,
    super.powderWeight,
    super.caseMaterial,
    super.caseCondition,
    super.headstamp,
    super.ballisticCoefficient,
    super.muzzleEnergy,
    super.velocity,
    super.temperatureTested,
    super.standardDeviation,
    super.extremeSpread,
    super.groupSize,
    super.testDistance,
    super.testFirearm,
    super.storageLocation,
    super.purchaseDate,
    super.purchasePrice,
    super.costPerRound,
    super.expirationDate,
    super.performanceNotes,
    super.environmentalConditions,
    super.isHandloaded = false,
    super.loadData,
    required super.dateAdded,
    super.bulletDiameter,  // ADD THIS
  });

  // lib/armory/data/models/armory_ammunition_model.dart - MODIFY fromMap
  factory ArmoryAmmunitionModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime? safeToDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      if (value is DateTime) return value;
      return null;
    }

    return ArmoryAmmunitionModel(
      id: id,
      brand: map['brand'] ?? '',
      line: map['line'],
      caliber: map['caliber'] ?? '',
      bullet: map['bullet weight (gr)'] ?? map['bullet'] ?? '',
      quantity: map['quantity'] ?? 0,
      status: map['status'] ?? 'available',
      lot: map['lot'],
      notes: map['notes'],
      primerType: map['primerType'],
      powderType: map['powderType'],
      powderWeight: map['powderWeight'],
      caseMaterial: map['caseMaterial'],
      caseCondition: map['caseCondition'],
      headstamp: map['headstamp'],
      ballisticCoefficient: map['ballisticCoefficient'],
      muzzleEnergy: map['muzzleEnergy'],
      velocity: map['velocity'],
      temperatureTested: map['temperatureTested'],
      standardDeviation: map['standardDeviation'],
      extremeSpread: map['extremeSpread'],
      groupSize: map['groupSize'],
      testDistance: map['testDistance'],
      testFirearm: map['testFirearm'],
      storageLocation: map['storageLocation'],
      purchaseDate: map['purchaseDate'],
      purchasePrice: map['purchasePrice'],
      costPerRound: map['costPerRound'],
      expirationDate: map['expirationDate'],
      performanceNotes: map['performanceNotes'],
      environmentalConditions: map['environmentalConditions'],
      isHandloaded: (map['isHandloaded'] == 1 || map['isHandloaded'] == true), // 👈 Handle both int and bool
      loadData: map['loadData'],
      dateAdded: safeToDate(map['dateAdded']) ?? DateTime.now(),
      //bulletDiameter: map['bulletdiameter'] as double?,
    );
  }

  // lib/armory/data/models/armory_ammunition_model.dart - MODIFY toMap
  Map<String, dynamic> toMap() {
    return {
      'brand': brand,
      'line': line,
      'caliber': caliber,
      'bullet': bullet,
      'quantity': quantity,
      'status': status,
      'lot': lot,
      'notes': notes,
      'primerType': primerType,
      'powderType': powderType,
      'powderWeight': powderWeight,
      'caseMaterial': caseMaterial,
      'caseCondition': caseCondition,
      'headstamp': headstamp,
      'ballisticCoefficient': ballisticCoefficient,
      'muzzleEnergy': muzzleEnergy,
      'velocity': velocity,
      'temperatureTested': temperatureTested,
      'standardDeviation': standardDeviation,
      'extremeSpread': extremeSpread,
      'groupSize': groupSize,
      'testDistance': testDistance,
      'testFirearm': testFirearm,
      'storageLocation': storageLocation,
      'purchaseDate': purchaseDate,
      'purchasePrice': purchasePrice,
      'costPerRound': costPerRound,
      'expirationDate': expirationDate,
      'performanceNotes': performanceNotes,
      'environmentalConditions': environmentalConditions,
      'isHandloaded': isHandloaded ? 1 : 0, // 👈 Convert bool to int
      'loadData': loadData,
      'bulletdiameter': bulletDiameter,
      'dateAdded': dateAdded.toIso8601String(),
    };
  }
}
// lib/user_dashboard/data/models/armory_firearm_model.dart
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/armory_firearm.dart';

class ArmoryFirearmModel extends ArmoryFirearm {
   ArmoryFirearmModel({
    super.id,
    required super.type,
    required super.make,
    required super.model,
    required super.caliber,
    required super.nickname,
    required super.status,
    super.serial,
    super.notes,
    super.brand,
    super.generation,
    super.firingMechanism,
    super.detailedType,
    super.purpose,
    super.condition,
    super.purchaseDate,
    super.purchasePrice,
    super.currentValue,
    super.fflDealer,
    super.manufacturerPN,
    super.finish,
    super.stockMaterial,
    super.triggerType,
    super.safetyType,
    super.feedSystem,
    super.magazineCapacity,
    super.twistRate,
    super.threadPattern,
    super.overallLength,
    super.weight,
    super.barrelLength,
    super.actionType,
    super.roundCount = 0,
    super.lastCleaned,
    super.zeroDistance,
    super.modifications,
    super.accessoriesIncluded,
    super.storageLocation,
    super.photos = '',
    required super.dateAdded,
  });

  factory ArmoryFirearmModel.fromMap(Map<String, dynamic> map, String ?id) {
     DateTime? safeToDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    if (value is DateTime) return value;
    return null;
  }

    return ArmoryFirearmModel(
      id: id,
      type: map['type'] ?? '',
      make: map['make'] ?? '',
      model: map['model'] ?? '',
      caliber: map['caliber'] ?? '',
      nickname: map['nickname'] ?? '',
      status: map['status'] ?? 'available',
      serial: map['serial'],
      notes: map['notes'],
      brand: map['brand'],
      generation: map['generation'],
      firingMechanism: map['firing_machanism'],
      detailedType: map['detailedType'],
      purpose: map['purpose'],
      condition: map['condition'],
      purchaseDate: map['purchaseDate'],
      purchasePrice: map['purchasePrice'],
      currentValue: map['currentValue'],
      fflDealer: map['fflDealer'],
      manufacturerPN: map['manufacturerPN'],
      finish: map['finish'],
      stockMaterial: map['stockMaterial'],
      triggerType: map['triggerType'],
      safetyType: map['safetyType'],
      feedSystem: map['feedSystem'],
      magazineCapacity: map['magazineCapacity'],
      twistRate: map['twistRate'],
      threadPattern: map['threadPattern'],
      overallLength: map['overallLength'],
      weight: map['weight'],
      barrelLength: map['barrelLength'],
      actionType: map['actionType'],
      roundCount: map['roundCount'] ?? 0,
      lastCleaned: map['lastCleaned'],
      zeroDistance: map['zeroDistance'],
      modifications: map['modifications'],
      accessoriesIncluded: map['accessoriesIncluded'],
      storageLocation: map['storageLocation'],
      // photos: map['photos'],
      dateAdded: safeToDate(map['dateAdded']) ?? DateTime.now(),
    );
  }

   Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'make': make,
      'model': model,
      'caliber': caliber,
      'nickname': nickname,
      'status': status,
      'serial': serial ?? '',
      'notes': notes ?? '',
      'brand': brand ?? '',
      'generation': generation ?? '',
      'firingMechanism': firingMechanism ?? '',
      'detailedType': detailedType ?? '',
      'purpose': purpose ?? '',
      'condition': condition ?? '',
      'purchaseDate': purchaseDate ?? '',
      'purchasePrice': purchasePrice ?? '',
      'currentValue': currentValue ?? '',
      'fflDealer': fflDealer ?? '',
      'manufacturerPN': manufacturerPN ?? '',
      'finish': finish ?? '',
      'stockMaterial': stockMaterial ?? '',
      'triggerType': triggerType ?? '',
      'safetyType': safetyType ?? '',
      'feedSystem': feedSystem ?? '',
      'magazineCapacity': magazineCapacity ?? '',
      'twistRate': twistRate ?? '',
      'threadPattern': threadPattern ?? '',
      'overallLength': overallLength ?? '',
      'weight': weight ?? '',
      'barrelLength': barrelLength ?? '',
      'actionType': actionType ?? '',
      'roundCount': roundCount,
      'lastCleaned': lastCleaned ?? '',
      'zeroDistance': zeroDistance ?? '',
      'modifications': modifications ?? '',
      'accessoriesIncluded': accessoriesIncluded ?? '',
      'storageLocation': storageLocation ?? '',
      'photos': jsonEncode(photos), 
      'dateAdded': dateAdded.toIso8601String(), 
    };
  }
}


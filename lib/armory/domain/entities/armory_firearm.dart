// lib/user_dashboard/domain/entities/armory_firearm.dart
import 'package:equatable/equatable.dart';

class ArmoryFirearm extends Equatable {
   String? id;
  final String type;
  final String make;
  final String model;
  final String caliber;
  final String nickname;
  final String status;
  final String? serial;
  final String? notes;

  // Additional fields from existing model
  final String? brand;
  final String? generation;
  final String? firingMechanism;

  // Level 3 fields from HTML
  final String? detailedType;
  final String? purpose;
  final String? condition;
  final String? purchaseDate;
  final String? purchasePrice;
  final String? currentValue;
  final String? fflDealer;
  final String? manufacturerPN;
  final String? finish;
  final String? stockMaterial;
  final String? triggerType;
  final String? safetyType;
  final String? feedSystem;
  final String? magazineCapacity;
  final String? twistRate;
  final String? threadPattern;
  final String? overallLength;
  final String? weight;
  final String? barrelLength;
  final String? actionType;
  final int roundCount;
  final String? lastCleaned;
  final String? zeroDistance;
  final String? modifications;
  final String? accessoriesIncluded;
  final String? storageLocation;
  final String? photos;
  final DateTime dateAdded;

   ArmoryFirearm({
    this.id,
    required this.type,
    required this.make,
    required this.model,
    required this.caliber,
    required this.nickname,
    required this.status,
    this.serial,
    this.notes,
    this.brand,
    this.generation,
    this.firingMechanism,
    this.detailedType,
    this.purpose,
    this.condition,
    this.purchaseDate,
    this.purchasePrice,
    this.currentValue,
    this.fflDealer,
    this.manufacturerPN,
    this.finish,
    this.stockMaterial,
    this.triggerType,
    this.safetyType,
    this.feedSystem,
    this.magazineCapacity,
    this.twistRate,
    this.threadPattern,
    this.overallLength,
    this.weight,
    this.barrelLength,
    this.actionType,
    this.roundCount = 0,
    this.lastCleaned,
    this.zeroDistance,
    this.modifications,
    this.accessoriesIncluded,
    this.storageLocation,
    this.photos = '',
    required this.dateAdded,
  });

  @override
  List<Object?> get props => [
    id, type, make, model, caliber, nickname, status, serial, notes,
    brand, generation, firingMechanism, detailedType, purpose, condition,
    purchaseDate, purchasePrice, currentValue, fflDealer, manufacturerPN,
    finish, stockMaterial, triggerType, safetyType, feedSystem,
    magazineCapacity, twistRate, threadPattern, overallLength, weight,
    barrelLength, actionType, roundCount, lastCleaned, zeroDistance,
    modifications, accessoriesIncluded, storageLocation, photos, dateAdded
  ];
}
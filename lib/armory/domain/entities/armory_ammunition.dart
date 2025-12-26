// lib/user_dashboard/domain/entities/armory_ammunition.dart
import 'package:equatable/equatable.dart';

class ArmoryAmmunition extends Equatable {
   String? id;
  final String brand;
  final String? line;
  final String caliber;
  final String bullet;
  final int quantity;
  final String status;
  final String? lot;
  final String? notes;

  // Level 3 fields from HTML
  final String? primerType;
  final String? powderType;
  final String? powderWeight;
  final String? caseMaterial;
  final String? caseCondition;
  final String? headstamp;
  final String? ballisticCoefficient;
  final String? muzzleEnergy;
  final String? velocity;
  final String? temperatureTested;
  final String? standardDeviation;
  final String? extremeSpread;
  final String? groupSize;
  final String? testDistance;
  final String? testFirearm;
  final String? storageLocation;
  final String? purchaseDate;
  final String? purchasePrice;
  final String? costPerRound;
  final String? expirationDate;
  final String? performanceNotes;
  final String? environmentalConditions;
  final bool isHandloaded;
  final String? loadData;
  final DateTime dateAdded;
  // Add this field in the class:
  final String? bulletDiameter; // in inches

   ArmoryAmmunition({
    this.id,
    required this.brand,
    this.line,
    required this.caliber,
    required this.bullet,
    required this.quantity,
    required this.status,
    this.lot,
    this.notes,
    this.primerType,
    this.powderType,
    this.powderWeight,
    this.caseMaterial,
    this.caseCondition,
    this.headstamp,
    this.ballisticCoefficient,
    this.muzzleEnergy,
    this.velocity,
    this.temperatureTested,
    this.standardDeviation,
    this.extremeSpread,
    this.groupSize,
    this.testDistance,
    this.testFirearm,
    this.storageLocation,
    this.purchaseDate,
    this.purchasePrice,
    this.costPerRound,
    this.expirationDate,
    this.performanceNotes,
    this.environmentalConditions,
    this.isHandloaded = false,
    this.loadData,
    this.bulletDiameter,  // ADD THIS
    required this.dateAdded,
  });

  @override
  List<Object?> get props => [
    id, brand, line, caliber, bullet, quantity, status, lot, notes,
    primerType, powderType, powderWeight, caseMaterial, caseCondition,
    headstamp, ballisticCoefficient, muzzleEnergy, velocity,
    temperatureTested, standardDeviation, extremeSpread, groupSize,
    testDistance, testFirearm, storageLocation, purchaseDate,
    purchasePrice, costPerRound, expirationDate, performanceNotes,
    environmentalConditions, isHandloaded, loadData, dateAdded, bulletDiameter,  // ADD THIS
  ];
}
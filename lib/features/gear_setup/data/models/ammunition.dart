class Ammunition {
  final String caliber;
  final String bulletType;
  final String bulletWeight;
  final String manufacturer;
  final String notes;
  final String cartridgeType;
  final String caseMaterial;
  final String primerType;
  final String pressureClass;
  final String muzzleVelocity;
  final String ballisticCoefficient;
  final String sectionalDensity;
  final String recoilEnergy;
  final String powderCharge;
  final String powderType;

  Ammunition({
    required this.caliber,
    required this.bulletType,
    required this.bulletWeight,
    required this.manufacturer,
    required this.notes,
    required this.cartridgeType,
    required this.caseMaterial,
    required this.primerType,
    required this.pressureClass,
    required this.muzzleVelocity,
    required this.ballisticCoefficient,
    required this.sectionalDensity,
    required this.recoilEnergy,
    required this.powderCharge,
    required this.powderType,
  });

  factory Ammunition.fromJson(Map<String, dynamic> json) {
    return Ammunition(
      caliber: json['Caliber'] ?? '',
      bulletType: json['Bullet Type'] ?? '',
      bulletWeight: json['Bullet Weight (grains)'] ?? '',
      manufacturer: json['Manufacturer'] ?? '',
      notes: json['Notes'] ?? '',
      cartridgeType: json['Cartridge Type'] ?? '',
      caseMaterial: json['Case Material'] ?? '',
      primerType: json['Primer Type'] ?? '',
      pressureClass: json['Pressure Class'] ?? '',
      muzzleVelocity: json['Muzzle Velocity (fps)'] ?? '',
      ballisticCoefficient: json['Ballistic Coefficient (G1)'] ?? '',
      sectionalDensity: json['Sectional Density'] ?? '',
      recoilEnergy: json['Recoil Energy (ft-lbs)'] ?? '',
      powderCharge: json['Powder Charge (grains)'] ?? '',
      powderType: json['Powder Type'] ?? '',
    );
  }
}

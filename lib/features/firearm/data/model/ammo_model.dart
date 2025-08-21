class AmmoModel {
  String? id;
  String? caliber;
  String? bulletType;
  int? bulletWeight;
  String? manufacturer;
  String? notes;
  bool? advancedExpanded;
  String? cartridgeType;
  String? caseMaterial;
  String? primerType;
  String? pressureClass;
  String? muzzleVelocity;
  String? ballisticCoefficient;
  String? sectionalDensity;
  String? recoilEnergy;
  String? powderCharge;
  String? powderType;
  String? lotNumber;
  String? chronographFPS;

  AmmoModel({
    this.id,
    this.caliber,
    this.bulletType,
    this.bulletWeight,
    this.manufacturer,
    this.notes,
    this.advancedExpanded,
    this.cartridgeType,
    this.caseMaterial,
    this.primerType,
    this.pressureClass,
    this.muzzleVelocity,
    this.ballisticCoefficient,
    this.sectionalDensity,
    this.recoilEnergy,
    this.powderCharge,
    this.powderType,
    this.lotNumber,
    this.chronographFPS,
  });

  AmmoModel copyWith(
          {String? id,
          String? caliber,
          String? bulletType,
          int? bulletWeight,
          String? manufacturer,
          String? notes,
          bool? advancedExpanded,
          String? cartridgeType,
          String? caseMaterial,
          String? primerType,
          String? pressureClass,
          String? muzzleVelocity,
          String? ballisticCoefficient,
          String? sectionalDensity,
          String? recoilEnergy,
          String? powderCharge,
          String? powderType,
          String? lotNumber,
          String? chronographFPS}) =>
      AmmoModel(
        id: id ?? this.id,
        caliber: caliber ?? this.caliber,
        bulletType: bulletType ?? this.bulletType,
        bulletWeight: bulletWeight ?? this.bulletWeight,
        manufacturer: manufacturer ?? this.manufacturer,
        notes: notes ?? this.notes,
        advancedExpanded: advancedExpanded ?? advancedExpanded,
        cartridgeType: cartridgeType ?? this.cartridgeType,
        caseMaterial: caseMaterial ?? this.caseMaterial,
        primerType: primerType ?? this.primerType,
        pressureClass: pressureClass ?? this.pressureClass,
        muzzleVelocity: muzzleVelocity ?? this.muzzleVelocity,
        ballisticCoefficient: ballisticCoefficient ?? this.ballisticCoefficient,
        sectionalDensity: sectionalDensity ?? this.sectionalDensity,
        recoilEnergy: recoilEnergy ?? this.recoilEnergy,
        powderCharge: powderCharge ?? this.powderCharge,
        powderType: powderType ?? this.powderType,
        lotNumber: lotNumber ?? this.lotNumber,
        chronographFPS: chronographFPS ?? this.chronographFPS,
      );

  factory AmmoModel.fromJson(Map<String, dynamic> json) => AmmoModel(
        id: json["id"],
        caliber: json["caliber"],
        bulletType: json["bullet_type"],
        bulletWeight: json["bullet_weight"],
        manufacturer: json["manufacturer"],
        notes: json["notes"],
        advancedExpanded: json['advanced_expanded'],
        cartridgeType: json['cartridge_type'],
        caseMaterial: json['case_material'],
        primerType: json['primer_type'],
        pressureClass: json['pressure_class'],
        muzzleVelocity: json['muzzle_velocity'],
        ballisticCoefficient: json['ballistic_coefficient'],
        sectionalDensity: json['sectional_density'],
        recoilEnergy: json['recoil_energy'],
        powderCharge: json['powder_charge'],
        powderType: json['powder_type'],
        lotNumber: json['lot_number'],
        chronographFPS: json['chronograph_fps'],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "caliber": caliber,
        "bullet_type": bulletType,
        "bullet_weight": bulletWeight,
        "manufacturer": manufacturer,
        "notes": notes,
        "advanced_expanded": advancedExpanded,
        "cartridge_type": cartridgeType,
        "case_material": caseMaterial,
        "primer_type": primerType,
        "pressure_class": pressureClass,
        "muzzle_velocity": muzzleVelocity,
        "ballistic_coefficient": ballisticCoefficient,
        "sectional_density": sectionalDensity,
        "recoil_energy": recoilEnergy,
        "powder_type": powderType,
        "powder_charge": powderCharge,
        "lot_number": lotNumber,
        "chronograph_fps": chronographFPS,
      };
}

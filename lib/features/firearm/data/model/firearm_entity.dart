// To parse this JSON data, do
//
//     final firearmEntity = firearmEntityFromJson(jsonString);

import 'dart:convert';

FirearmEntity firearmEntityFromJson(String str) =>
    FirearmEntity.fromJson(json.decode(str));

String firearmEntityToJson(FirearmEntity data) => json.encode(data.toJson());

class FirearmEntity {
  String? id;
  String? type;
  String? brand;
  String? model;
  String? generation;
  String? caliber;
  String? firingMachanism;
  String? ammoType;
  String? serialNumber;
  String? barrelLength;
  String? overallLength;
  String? weight;
  String? riflingTwistRate;
  String? capacity;
  String? finishColor;
  String? sightType;
  String? sightModel;
  String? sightHeightOverBore;
  String? triggerPullWeight;
  String? purchaseDate;
  String? roundCount;
  String? modificationsAttachments;
  String? notes;

  int? addedByUser;
  bool? brandIsCustom;
  bool? modelIsCustom;
  bool? generationIsCustom;
  bool? caliberIsCustom;
  bool? firingMacIsCustom;
  bool? ammoTypeMacIsCustom;
  bool? advancedInfoExpanded;

  FirearmEntity({
    this.id,
    this.type,
    this.brand,
    this.model,
    this.generation,
    this.caliber,
    this.firingMachanism,
    this.ammoType,
    this.addedByUser,
    this.serialNumber,
    this.barrelLength,
    this.overallLength,
    this.weight,
    this.riflingTwistRate,
    this.capacity,
    this.finishColor,
    this.sightType,
    this.sightModel,
    this.sightHeightOverBore,
    this.triggerPullWeight,
    this.purchaseDate,
    this.roundCount,
    this.modificationsAttachments,
    this.notes,
    this.brandIsCustom,
    this.modelIsCustom,
    this.generationIsCustom,
    this.caliberIsCustom,
    this.firingMacIsCustom,
    this.ammoTypeMacIsCustom,
    this.advancedInfoExpanded,
  });

  FirearmEntity copyWith({
    String? id,
    String? type,
    String? brand,
    String? model,
    String? generation,
    String? caliber,
    String? firingMachanism,
    String? ammoType,
    String? notes,
    int? addedByUser,
    String? serialNumber,
    String? barrelLength,
    String? overallLength,
    String? weight,
    String? riflingTwistRate,
    String? capacity,
    String? finishColor,
    String? sightType,
    String? sightModel,
    String? sightHeightOverBore,
    String? triggerPullWeight,
    String? purchaseDate,
    String? roundCount,
    String? modificationsAttachments,
    bool? brandIsCustom,
    bool? modelIsCustom,
    bool? generationIsCustom,
    bool? caliberIsCustom,
    bool? firingMacIsCustom,
    bool? ammoTypeMacIsCustom,
    bool? advancedInfoExpanded,
  }) =>
      FirearmEntity(
        id: id ?? this.id,
        type: type ?? this.type,
        brand: brand ?? this.brand,
        model: model ?? this.model,
        generation: generation ?? this.generation,
        caliber: caliber ?? this.caliber,
        firingMachanism: firingMachanism ?? this.firingMachanism,
        ammoType: ammoType ?? this.ammoType,
        notes: notes ?? this.notes,
        addedByUser: addedByUser ?? this.addedByUser,
        serialNumber: serialNumber ?? this.serialNumber,
        barrelLength: barrelLength ?? this.barrelLength,
        overallLength: overallLength ?? this.overallLength,
        weight: weight ?? this.weight,
        riflingTwistRate: riflingTwistRate ?? this.riflingTwistRate,
        capacity: capacity ?? this.capacity,
        finishColor: finishColor ?? this.finishColor,
        sightType: sightType ?? this.sightType,
        sightModel: sightModel ?? this.sightModel,
        sightHeightOverBore: sightHeightOverBore ?? this.sightHeightOverBore,
        triggerPullWeight: triggerPullWeight ?? this.triggerPullWeight,
        purchaseDate: purchaseDate ?? this.purchaseDate,
        roundCount: roundCount ?? this.roundCount,
        modificationsAttachments:
            modificationsAttachments ?? this.modificationsAttachments,
        //
        brandIsCustom: brandIsCustom ?? this.brandIsCustom,
        modelIsCustom: modelIsCustom ?? this.modelIsCustom,
        generationIsCustom: generationIsCustom ?? this.generationIsCustom,
        caliberIsCustom: caliberIsCustom ?? this.caliberIsCustom,
        firingMacIsCustom: firingMacIsCustom ?? this.firingMacIsCustom,
        ammoTypeMacIsCustom: ammoTypeMacIsCustom ?? this.ammoTypeMacIsCustom,
        advancedInfoExpanded: advancedInfoExpanded ?? this.advancedInfoExpanded,
      );

  factory FirearmEntity.fromJson(Map<String, dynamic> json) => FirearmEntity(
        id: json["id"],
        type: json["type"],
        brand: json["brand"],
        model: json["model"],
        generation: json["generation"],
        caliber: json["caliber"],
        firingMachanism: json["firing_machanism"],
        ammoType: json["ammo_type"],
        notes: json["notes"],
        addedByUser: json["added_by_user"],
        serialNumber: json["serial_number"],
        barrelLength: json["barrel_length"],
        overallLength: json["overall_length"],
        weight: json["weight"],
        riflingTwistRate: json["rifling_twist_rate"],
        capacity: json["capacity"],
        finishColor: json["finish_color"],
        sightType: json["sight_type"],
        sightModel: json["sight_model"],
        sightHeightOverBore: json["sight_height_over_bore"],
        triggerPullWeight: json["trigger_pull_weight"],
        purchaseDate: json["purchase_date"],
        roundCount: json["round_count"],
        modificationsAttachments: json["modifications_attachments"],
        // brandIsCustom: json["brand_is_custom"],
        // modelIsCustom: json["model_is_custom"],
        // generationIsCustom: json["generation_is_custom"],
        // caliberIsCustom: json["caliber_is_custom"],
        // firingMacIsCustom: json["firing_mac_is_custom"],
        // ammoTypeMacIsCustom: json["ammo_type_mac_is_custom"],
        advancedInfoExpanded: json["advanced_info_expanded"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "type": type,
        "brand": brand,
        "model": model,
        "generation": generation,
        "caliber": caliber,
        "firing_machanism": firingMachanism,
        "ammo_type": ammoType,
        "notes": notes,
        "added_by_user": addedByUser,
        "advanced_info_expanded": advancedInfoExpanded,
        "serial_number": serialNumber,
        "barrel_length": barrelLength,
        "overall_length": overallLength,
        "weight": weight,
        "rifling_twist_rate": riflingTwistRate,
        "capacity": capacity,
        "finish_color": finishColor,
        "sight_type": sightType,
        "sight_model": sightModel,
        "sight_height_over_bore": sightHeightOverBore,
        "trigger_pull_weight": triggerPullWeight,
        "purchase_date": purchaseDate,
        "round_count": roundCount,
        "modifications_attachments": modificationsAttachments,
      };
}



// class FirearmEntity {
//   String? weaponType;
//   String? brand;
//   String? model;
//   String? genvar;
//   String? caliber;
//   String? mechanism;
//   String? ammoType;
//   FirearmEntity({
//     this.weaponType,
//     this.brand,
//     this.model,
//     this.genvar,
//     this.caliber,
//     this.mechanism,
//     this.ammoType,
//   });
// }


/*
 "type":"sdf"
   "brand":"aesdf"
   "model":"asgdf"
   "generation":"asdqqwef"
   "caliber":"fgas"
   "firing_machanism":"wer"
   "ammo_type":"a43rd"
 */
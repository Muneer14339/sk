import 'package:pulse_skadi/features/firearm/data/model/ammo_model.dart';
import 'package:pulse_skadi/features/firearm/data/model/firearm_entity.dart';

class GearSetupModel {
  final String? id;
  final String name;
  final FirearmEntity firearm;
  final AmmoModel ammoModel;
  final String? ammo;
  final String? mode;
  final Set<String>? sights;
  final String? location;

  GearSetupModel({
    this.id,
    required this.name,
    required this.firearm,
    required this.ammoModel,
    this.ammo,
    this.mode,
    this.sights,
    this.location,
  });

  GearSetupModel copyWith({
    String? id,
    String? name,
    FirearmEntity? firearm,
    AmmoModel? ammoModel,
    String? ammo,
    String? mode,
    Set<String>? sights,
    String? location,
  }) {
    return GearSetupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      firearm: firearm ?? this.firearm,
      ammoModel: ammoModel ?? this.ammoModel,
      ammo: ammo ?? this.ammo,
      mode: mode ?? this.mode,
      sights: sights ?? this.sights,
      location: location ?? this.location,
    );
  }

  factory GearSetupModel.fromJson(Map<String, dynamic> json) {
    return GearSetupModel(
      id: json['id'],
      name: json['name'],
      firearm: FirearmEntity.fromJson(json['firearm']),
      ammoModel: AmmoModel.fromJson(json['ammo_model']),
      ammo: json['ammo'],
      mode: json['mode'],
      sights: json['sights'] != null ? Set.from(json['sights']) : null,
      location: json['location'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'firearm': firearm.toJson(),
      'ammo_model': ammoModel.toJson(),
      'ammo': ammo,
      'mode': mode,
      'sights': sights?.toList(),
      'location': location,
    };
  }
}

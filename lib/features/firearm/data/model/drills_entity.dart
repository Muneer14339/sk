import 'dart:convert';

DrillsModel drillsModelFromJson(String str) =>
    DrillsModel.fromJson(json.decode(str));

String drillsModelToJson(DrillsModel data) => json.encode(data.toJson());

class DrillsModel {
  int? id;
  final DrillsEntity? drill;

  DrillsModel({
    this.id,
    this.drill,
  });

  DrillsModel copyWith({
    int? id,
    DrillsEntity? drill,
  }) =>
      DrillsModel(
        id: id ?? this.id,
        drill: drill ?? this.drill,
      );

  factory DrillsModel.fromJson(Map<String, dynamic> json) => DrillsModel(
        id: json["id"],
        drill:
            json["drill"] == null ? null : DrillsEntity.fromJson(json["drill"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "drill": drill?.toJson(),
      };
}

class DrillsEntity {
  String? name;
  String? description;
  String? fireType;
  String? noOfShots;
  String? partTimeType;
  List<int>? parTimeList;
  int? isMute;

  DrillsEntity({
    this.name,
    this.description,
    this.fireType,
    this.noOfShots,
    this.partTimeType,
    this.parTimeList,
    this.isMute,
  });

  DrillsEntity copyWith({
    String? name,
    String? description,
    String? fireType,
    String? noOfShots,
    String? partTimeType,
    List<int>? parTimeList,
    int? isMute,
  }) =>
      DrillsEntity(
        name: name ?? this.name,
        description: description ?? this.description,
        fireType: fireType ?? this.fireType,
        noOfShots: noOfShots ?? this.noOfShots,
        partTimeType: partTimeType ?? this.partTimeType,
        parTimeList: parTimeList ?? this.parTimeList,
        isMute: isMute ?? this.isMute,
      );

  factory DrillsEntity.fromJson(Map<String, dynamic> json) => DrillsEntity(
        name: json["name"],
        description: json["description"],
        fireType: json["fireType"],
        noOfShots: json["noOfShots"],
        partTimeType: json["partTimeType"],
        parTimeList: json["parTimeList"] == null
            ? []
            : List<int>.from(json["parTimeList"]!.map((x) => x)),
        isMute: json["isMute"],
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "description": description,
        "fireType": fireType,
        "noOfShots": noOfShots,
        "partTimeType": partTimeType,
        "parTimeList": parTimeList == null
            ? []
            : List<dynamic>.from(parTimeList!.map((x) => x)),
        "isMute": isMute,
      };
}

/*

import 'package:freezed_annotation/freezed_annotation.dart';

part 'drills_entity.freezed.dart';
part 'drills_entity.g.dart';

@freezed
class DrillsEntity with _$DrillsEntity {
  const factory DrillsEntity({
    required int id,
    required String name,
    required String description,
    required String fireType,
    required String noOfShots,
    required String partTimeType,
    required List<String>? parTimeList,
    required int isMute,
  }) = _DrillsEntity;

  factory DrillsEntity.fromJson(Map<String, Object?> json) =>
      _$DrillsEntityFromJson(json);
}
  */

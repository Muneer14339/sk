import 'package:pulse_skadi/features/firearm/data/model/drills_entity.dart';
import 'package:pulse_skadi/features/firearm/data/model/firearm_entity.dart';

class StageEntity {
  DrillsModel? drill;
  Mode? mode;
  FirearmEntity? firearm;
  String? mountLocation;
  String? sensitivity;
  String? venue;
  String? dominantHand;
  String? distance;
  List<DrillsModel>? drillsList;

  StageEntity({
    this.drill,
    this.mode,
    this.firearm,
    this.mountLocation,
    this.sensitivity,
    this.venue,
    this.dominantHand,
    this.distance,
    this.drillsList,
  });

  // copyWith method
  StageEntity copyWith({
    int? id,
    String? userName,
    DrillsModel? drill,
    Mode? mode,
    FirearmEntity? firearm,
    String? mountLocation,
    String? sensitivity,
    String? venue,
    String? dominantHand,
    String? distance,
    List<DrillsModel>? drillsList,
  }) {
    return StageEntity(
      drill: drill ?? this.drill,
      mode: mode ?? this.mode,
      firearm: firearm ?? this.firearm,
      mountLocation: mountLocation ?? this.mountLocation,
      sensitivity: sensitivity ?? this.sensitivity,
      venue: venue ?? this.venue,
      dominantHand: dominantHand ?? this.dominantHand,
      distance: distance ?? this.distance,
      drillsList: drillsList ?? this.drillsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'drill': drill?.toJson(),
      'mode': mode?.toJson(),
      'firearm': firearm?.toJson(),
      'mountLocation': mountLocation,
      'sensitivity': sensitivity,
      'venue': venue,
      'dominant_hand': dominantHand,
      'distance': distance,
      'drillsList': drillsList?.map((drill) => drill.toJson()).toList(),
    };
  }

  factory StageEntity.fromJson(Map<String, dynamic> json) {
    return StageEntity(
      drill: json['drill'] != null ? DrillsModel.fromJson(json['drill']) : null,
      mode: json['mode'] != null ? Mode.fromJson(json['mode']) : null,
      firearm: json['firearm'] != null
          ? FirearmEntity.fromJson(json['firearm'])
          : null,
      mountLocation: json['mountLocation'],
      sensitivity: json['sensitivity'],
      venue: json['venue'],
      dominantHand: json['dominant_hand'],
      distance: json['distance'],
      drillsList: json['drillsList'] != null
          ? (json['drillsList'] as List)
              .map((drill) => DrillsModel.fromJson(drill))
              .toList()
          : null,
    );
  }
}

class Mode {
  int? id;
  String? name;
  int? seconds;

  Mode({
    this.id,
    this.name,
    this.seconds,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'seconds': seconds,
    };
  }

  factory Mode.fromJson(Map<String, dynamic> json) {
    return Mode(
      id: json['id'],
      name: json['name'],
      seconds: json['seconds'],
    );
  }
}

//- -  - -- - - - - - - - - - - - - - - - - - -

class SessionSaveStageEntity {
  DrillsModel? drill;
  Mode? mode;
  FirearmEntity? firearm;
  String? mountLocation;
  String? sensitivity;
  String? venue;
  String? dominantHand;
  String? distance;

  SessionSaveStageEntity({
    this.drill,
    this.mode,
    this.firearm,
    this.mountLocation,
    this.sensitivity,
    this.venue,
    this.dominantHand,
    this.distance,
  });

  SessionSaveStageEntity copyWith({
    DrillsModel? drill,
    Mode? mode,
    FirearmEntity? firearm,
    String? mountLocation,
    String? sensitivity,
    String? venue,
    String? dominantHand,
    String? distance,
  }) {
    return SessionSaveStageEntity(
      drill: drill ?? this.drill,
      mode: mode ?? this.mode,
      firearm: firearm ?? this.firearm,
      mountLocation: mountLocation ?? this.mountLocation,
      sensitivity: sensitivity ?? this.sensitivity,
      venue: venue ?? this.venue,
      dominantHand: dominantHand ?? this.dominantHand,
      distance: distance ?? this.distance,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'drill': drill?.toJson(),
      'mode': mode?.toJson(),
      'firearm': firearm?.toJson(),
      'mountLocation': mountLocation,
      'sensitivity': sensitivity,
      'venue': venue,
      'dominant_hand': dominantHand,
      'distance': distance,
    };
  }

  factory SessionSaveStageEntity.fromJson(Map<String, dynamic> json) {
    return SessionSaveStageEntity(
      drill: json['drill'] != null ? DrillsModel.fromJson(json['drill']) : null,
      mode: json['mode'] != null ? Mode.fromJson(json['mode']) : null,
      firearm: json['firearm'] != null
          ? FirearmEntity.fromJson(json['firearm'])
          : null,
      mountLocation: json['mountLocation'],
      sensitivity: json['sensitivity'],
      venue: json['venue'],
      dominantHand: json['dominant_hand'],
      distance: json['distance'],
    );
  }
}

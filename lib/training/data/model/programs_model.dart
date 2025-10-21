
class ProgramsModel {
  String? id;
  String? modeName;
  String? trainingType;
  String? focusArea;
  String? difficultyLevel;
  int? noOfShots;
  String? timePressure;
  String? type;
  String? position;
  String? badge;
  String? badgeColor;
  GearSetupModel? weaponProfile;
  String? programName;
  String? programDescription;
  String? timeLimit;
  String? recommenedDistance;
  String? successCriteria;
  String? successThreshold;
  DateTime? createdAt;
  List<PerformanceMetrics>? performanceMetrics;

  ProgramsModel({
    this.id,
    this.modeName,
    this.trainingType,
    this.focusArea,
    this.difficultyLevel,
    this.noOfShots,
    this.timePressure,
    this.type,
    this.position,
    this.badge,
    this.badgeColor,
    this.weaponProfile,
    this.programName,
    this.programDescription,
    this.timeLimit,
    this.recommenedDistance,
    this.successCriteria,
    this.successThreshold,
    this.createdAt,
    this.performanceMetrics,
  });

  ProgramsModel copyWith({
    String? id,
    String? modeName,
    String? trainingType,
    String? focusArea,
    String? difficultyLevel,
    int? noOfShots,
    String? timePressure,
    String? type,
    String? position,
    String? badge,
    String? badgeColor,
    GearSetupModel? weaponProfile,
    String? programName,
    String? programDescription,
    String? timeLimit,
    String? recommenedDistance,
    String? successCriteria,
    String? successThreshold,
    DateTime? createdAt,
    List<PerformanceMetrics>? performanceMetrics,
  }) =>
      ProgramsModel(
        id: id ?? this.id,
        modeName: modeName ?? this.modeName,
        trainingType: trainingType ?? this.trainingType,
        focusArea: focusArea ?? this.focusArea,
        difficultyLevel: difficultyLevel ?? this.difficultyLevel,
        noOfShots: noOfShots ?? this.noOfShots,
        timePressure: timePressure ?? this.timePressure,
        type: type ?? this.type,
        position: position ?? this.position,
        badge: badge ?? this.badge,
        badgeColor: badgeColor ?? this.badgeColor,
        weaponProfile: weaponProfile ?? this.weaponProfile,
        programName: programName ?? this.programName,
        programDescription: programDescription ?? this.programDescription,
        timeLimit: timeLimit ?? this.timeLimit,
        recommenedDistance: recommenedDistance ?? this.recommenedDistance,
        successCriteria: successCriteria ?? this.successCriteria,
        successThreshold: successThreshold ?? this.successThreshold,
        createdAt: createdAt ?? this.createdAt,
        performanceMetrics: performanceMetrics ?? this.performanceMetrics,
      );

  factory ProgramsModel.fromJson(Map<String, dynamic> json) => ProgramsModel(
        id: json['id'],
        modeName: json['mode_name'],
        trainingType: json['training_type'],
        focusArea: json['focus_area'],
        difficultyLevel: json['difficulty_level'],
        noOfShots: json['no_of_shots'],
        timePressure: json['time_pressure'],
        type: json['type'],
        position: json['position'],
        badge: json['badge'],
        badgeColor: json['badge_color'],
        weaponProfile: json['weapon_profile'] != null
            ? GearSetupModel.fromJson(json['weapon_profile'])
            : null,
        programName: json['program_name'],
        programDescription: json['program_description'],
        timeLimit: json['time_limit'],
        recommenedDistance: json['recommened_distance'],
        successCriteria: json['success_criteria'],
        successThreshold: json['success_threshold'],
        createdAt: json['created_at'],
        performanceMetrics: json['performance_metrics'] != null
            ? List<PerformanceMetrics>.from(json['performance_metrics']
                .map((x) => PerformanceMetrics.fromJson(x)))
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'mode_name': modeName,
        'training_type': trainingType,
        'focus_area': focusArea,
        'difficulty_level': difficultyLevel,
        'no_of_shots': noOfShots,
        'time_pressure': timePressure,
        'type': type,
        'position': position,
        'badge': badge,
        'badge_color': badgeColor,
        'weapon_profile': weaponProfile?.toJson(),
        'program_name': programName,
        'program_description': programDescription,
        'time_limit': timeLimit,
        'recommened_distance': recommenedDistance,
        'success_criteria': successCriteria,
        'success_threshold': successThreshold,
        'created_at': createdAt,
        'performance_metrics':
            performanceMetrics?.map((x) => x.toJson()).toList(),
      };
}

class PerformanceMetrics {
  String? stability;
  String? target;
  String? unit;

  PerformanceMetrics({
    this.stability,
    this.target,
    this.unit,
  });

  PerformanceMetrics copyWith({
    String? stability,
    String? target,
    String? unit,
  }) =>
      PerformanceMetrics(
        stability: stability ?? this.stability,
        target: target ?? this.target,
        unit: unit ?? this.unit,
      );

  factory PerformanceMetrics.fromJson(Map<String, dynamic> json) =>
      PerformanceMetrics(
        stability: json['stability'],
        target: json['target'],
        unit: json['unit'],
      );

  Map<String, dynamic> toJson() => {
        'stability': stability,
        'target': target,
        'unit': unit,
      };
}

//------------------------------------

List<ProgramsModel> systemPrograms = [
  ProgramsModel(
    // 'icon': '📈',
    programName: 'Consistency Builder',
    type: 'Form Development',
    programDescription:
        'Focus on developing consistent shooting form and muscle memory through repetitive practice.',
    weaponProfile: GearSetupModel(
        firearm: FirearmEntity(
          type: 'Pistol',
          brand: 'Smith & Wesson',
          model: 'M&P 15',
          caliber: '9mm',
          serialNumber: '123456789',
        ),
        ammoModel: AmmoModel(
            bulletType: 'FMJ',
            bulletWeight: 12,
            caliber: '9mm',
            cartridgeType: '115gr'),
        name: 'Consistency Builder'),
    recommenedDistance: '10-25 yards',
    trainingType: 'Dry Fire',
    difficultyLevel: 'Beginner',
    badge: 'System',
    position: 'Standing',
    badgeColor: '0xFF0DB30D',
    noOfShots: 3,
    timeLimit: '20',
    successCriteria: '91%',
    successThreshold: '91%',
    timePressure: 'None',
    focusArea: 'Form Development',
    performanceMetrics: [
      PerformanceMetrics(
          stability: 'Stability Score', target: 'Target', unit: '≥85%'),
      PerformanceMetrics(
          stability: 'Trigger Control', target: 'Target', unit: '≥85%')
    ],
  ),
  ProgramsModel(
      // 'icon': '📈',
      programName: 'Rapid Fire Control',
      type: 'Speed & Accuracy',
      programDescription:
          'Develop controlled rapid fire techniques while maintaining accuracy under time pressure.',
      weaponProfile: GearSetupModel(
          firearm: FirearmEntity(
            type: 'Pistol',
            brand: 'Smith & Wesson',
            model: 'M&P 15',
            caliber: '9mm',
            serialNumber: '123456789',
          ),
          ammoModel: AmmoModel(bulletType: 'FMJ', bulletWeight: 12, caliber: '9mm', cartridgeType: '115gr'),
          name: 'Rapid Fire Control'),
      recommenedDistance: '10-25 yards',
      trainingType: 'Dry Fire',
      difficultyLevel: 'Beginner',
      badge: 'System',
      position: 'Sitting',
      badgeColor: '0xFF0DB30D',
      noOfShots: 20,
      timeLimit: '20',
      successCriteria: '91%',
      successThreshold: '91%',
      timePressure: 'None',
      focusArea: 'Form Development',
      performanceMetrics: [
        PerformanceMetrics(
            stability: 'Stability', target: 'Target', unit: 'Unit')
      ])
];

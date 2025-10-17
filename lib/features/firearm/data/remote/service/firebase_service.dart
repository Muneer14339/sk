import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pulse_skadi/features/firearm/data/model/ammo_model.dart';
import 'package:pulse_skadi/features/firearm/data/model/firearm_entity.dart';
import 'package:pulse_skadi/features/gear_setup/data/models/gear_setup_model.dart';
import 'package:pulse_skadi/features/training/data/model/programs_model.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> addFirearmSetup({
    required GearSetupModel gearSetup,
  }) async {
    await _firestore
        .collection('Firearm Setups')
        .doc(_auth.currentUser!.uid)
        .collection('Setups')
        .add(gearSetup.toJson());
  }

//----------------------------------------------------------------------------------------------

  Future<void> addPrograms({
    required ProgramsModel programsModel,
  }) async {
    await _firestore
        .collection('Programs')
        .doc(_auth.currentUser!.uid)
        .collection('Programs')
        .add(programsModel.toJson());
  }

//----------------------------------------------------------------------------------------------

  Future<List<ProgramsModel>> getPrograms() async {
    final QuerySnapshot querySnapshot = await _firestore
        .collection('Programs')
        .doc(_auth.currentUser!.uid)
        .collection('Programs')
        .get();
    return querySnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return ProgramsModel.fromJson(data).copyWith(id: doc.id);
    }).toList();
  }

//----------------------------------------------------------------------------------------------
  Future<void> addEquipmentProfile({
    required GearSetupModel gearSetup,
  }) async {
    await _firestore
        .collection('Equipment Profiles')
        .doc(_auth.currentUser!.uid)
        .collection('Profiles')
        .add(gearSetup.toJson());
  }
//----------------------------------------------------------------------------------------------

  Future<void> updateFirearmSetup({
    required FirearmEntity firearm,
  }) async {
    await _firestore
        .collection('Firearm Setups')
        .doc(_auth.currentUser!.uid)
        .collection('Setups')
        .doc(firearm.id.toString())
        .update(firearm.toJson());
  }

//----------------------------------------------------------------------------------------------
  Future<void> removeFirearmSetup({
    required String setupId,
  }) async {
    await _firestore
        .collection('Firearm Setups')
        .doc(_auth.currentUser!.uid)
        .collection('Setups')
        .doc(setupId)
        .delete();
  }

//-----------------------------------------------------------------------------------------------
  Future<List<GearSetupModel>> getFirearmSetups() async {
    final QuerySnapshot querySnapshot = await _firestore
        .collection('Firearm Setups')
        .doc(_auth.currentUser!.uid)
        .collection('Setups')
        .get();
    return querySnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      GearSetupModel model = GearSetupModel(
        id: doc.id,
        name: data['name'] ?? '',
        firearm: FirearmEntity(
          id: data['firearm']['id'] ?? '',
          type: data['firearm']['type'] ?? '',
          brand: data['firearm']['brand'] ?? '',
          model: data['firearm']['model'] ?? '',
          generation: data['firearm']['generation'] ?? '',
          caliber: data['firearm']['caliber'] ?? '',
          firingMachanism: data['firearm']['firing_machanism'] ?? '',
          ammoType: data['firearm']['ammo_type'] ?? '',
          addedByUser: data['firearm']['added_by_user'] ?? 0,
          advancedInfoExpanded:
              data['firearm']['advanced_info_expanded'] ?? false,
          serialNumber: data['firearm']['serial_number'] ?? '',
          barrelLength: data['firearm']['barrel_length'] ?? '',
          overallLength: data['firearm']['overall_length'] ?? '',
          weight: data['firearm']['weight'] ?? '',
          riflingTwistRate: data['firearm']['rifling_twist_rate'] ?? '',
          capacity: data['firearm']['capacity'] ?? '',
          finishColor: data['firearm']['finish_color'] ?? '',
          sightType: data['firearm']['sight_type'] ?? '',
          sightModel: data['firearm']['sight_model'] ?? '',
          sightHeightOverBore: data['firearm']['sight_height_over_bore'] ?? '',
          triggerPullWeight: data['firearm']['trigger_pull_weight'] ?? '',
          purchaseDate: data['firearm']['purchase_date'] ?? '',
          roundCount: data['firearm']['round_count'] ?? '',
          modificationsAttachments:
              data['firearm']['modifications_attachments'] ?? '',
          brandIsCustom: data['firearm']['brand_is_custom'] ?? false,
          modelIsCustom: data['firearm']['model_is_custom'] ?? false,
          generationIsCustom: data['firearm']['generation_is_custom'] ?? false,
          caliberIsCustom: data['firearm']['caliber_is_custom'] ?? false,
          firingMacIsCustom: data['firearm']['firing_mac_is_custom'] ?? false,
          ammoTypeMacIsCustom:
              data['firearm']['ammo_type_mac_is_custom'] ?? false,
        ),
        ammo: data['ammo'] ?? '',
        mode: data['mode'] ?? '',
        sights: Set<String>.from(data['sights'] ?? []),
        location: data['location'] ?? '',
        ammoModel: AmmoModel.fromJson(data['ammo_model'] ?? {}),
      );

      log('  = = = = = = = ------ getFirearmSetups ${model.ammoModel.bulletType}------');

      return model;
    }).toList();
  }

//-----------------------------------------------------------------------------------------------

  Future<void> updateEquipmentProfile({
    required GearSetupModel gearSetup,
  }) async {
    await _firestore
        .collection('Equipment Profiles')
        .doc(_auth.currentUser!.uid)
        .collection('Profiles')
        .doc(gearSetup.id)
        .update(gearSetup.toJson());
  }

//-----------------------------------------------------------------------------------------------
  Future<List<GearSetupModel>> getEquipmentProfiles() async {
    final QuerySnapshot querySnapshot = await _firestore
        .collection('Equipment Profiles')
        .doc(_auth.currentUser!.uid)
        .collection('Profiles')
        .get();
    return querySnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return GearSetupModel(
        id: doc.id,
        name: data['name'] ?? '',
        firearm: FirearmEntity.fromJson(data['firearm'] ?? {}),
        ammo: data['ammo'] ?? '',
        mode: data['mode'] ?? '',
        ammoModel: AmmoModel.fromJson(data['ammo_model'] ?? {}),
        sights: Set<String>.from(data['sights'] ?? []),
        location: data['location'] ?? '',
      );
    }).toList();
  }
//----------------------------------------------------------------------------------------------
}

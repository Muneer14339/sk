import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/logger.dart';
import '../../utils/caliber_calculator.dart';
import '../models/armory_firearm_model.dart';
import '../models/armory_ammunition_model.dart';
import '../models/armory_gear_model.dart';
import '../models/armory_maintenance_model.dart';
import '../models/armory_tool_model.dart';
import '../models/armory_loadout_model.dart';

abstract class ArmoryRemoteDataSource {
  Future<List<ArmoryFirearmModel>> getFirearms(String userId);
  Future<void> addFirearm(String userId, ArmoryFirearmModel firearm);
  Future<void> updateFirearm(String userId, ArmoryFirearmModel firearm);
  Future<void> deleteFirearm(String userId, String firearmId);
  Future<List<ArmoryAmmunitionModel>> getAmmunition(String userId);
  Future<void> addAmmunition(String userId, ArmoryAmmunitionModel ammunition);
  Future<void> updateAmmunition(String userId, ArmoryAmmunitionModel ammunition);
  Future<void> deleteAmmunition(String userId, String ammunitionId);
  Future<List<ArmoryGearModel>> getGear(String userId);
  Future<void> addGear(String userId, ArmoryGearModel gear);
  Future<void> updateGear(String userId, ArmoryGearModel gear);
  Future<void> deleteGear(String userId, String gearId);
  Future<List<ArmoryToolModel>> getTools(String userId);
  Future<void> addTool(String userId, ArmoryToolModel tool);
  Future<void> updateTool(String userId, ArmoryToolModel tool);
  Future<void> deleteTool(String userId, String toolId);
  Future<List<ArmoryLoadoutModel>> getLoadouts(String userId);
  Future<void> addLoadout(String userId, ArmoryLoadoutModel loadout);
  Future<void> updateLoadout(String userId, ArmoryLoadoutModel loadout);
  Future<void> deleteLoadout(String userId, String loadoutId);
  Future<List<ArmoryMaintenanceModel>> getMaintenance(String userId);
  Future<void> addMaintenance(String userId, ArmoryMaintenanceModel maintenance);
  Future<void> deleteMaintenance(String userId, String maintenanceId);
  Future<List<Map<String, dynamic>>> getFirearmsRawData();
  Future<List<Map<String, dynamic>>> getAmmunitionRawData();
  Future<List<Map<String, dynamic>>> getUserFirearmsRawData(String userId);
  Future<List<Map<String, dynamic>>> getUserAmmunitionRawData(String userId);
}

class ArmoryRemoteDataSourceImpl implements ArmoryRemoteDataSource {
  final FirebaseFirestore firestore;

  ArmoryRemoteDataSourceImpl({required this.firestore});

  @override
  Future<List<ArmoryFirearmModel>> getFirearms(String userId) async {
    log.i('Getting firearms from firebase of user: $userId');
    try {
      final querySnapshot = await firestore.collection('armory').doc(userId).collection('firearms').orderBy('dateAdded', descending: true).get();
      return querySnapshot.docs.where((doc) => !doc.data().containsKey('isDeleted')).map((doc) => ArmoryFirearmModel.fromMap(doc.data(), doc.id)).toList();
    } catch (e) {
      throw Exception('Failed to get firearms: $e');
    }
  }

  @override
  Future<void> addFirearm(String userId, ArmoryFirearmModel firearm) async {
    try {
      await firestore.collection('armory').doc(userId).collection('firearms').doc(firearm.id)  // Use provided ID instead of auto-generating
          .set(firearm.toMap());
    } catch (e) {
      throw Exception('Failed to add firearm: $e');
    }
  }

  @override
  Future<void> updateFirearm(String userId, ArmoryFirearmModel firearm) async {
    try {
      await firestore.collection('armory').doc(userId).collection('firearms').doc(firearm.id).update(firearm.toMap());
    } catch (e) {
      throw Exception('Failed to update firearm: $e');
    }
  }

  @override
  Future<void> deleteFirearm(String userId, String firearmId) async {
    try {
      await firestore.collection('armory').doc(userId).collection('firearms').doc(firearmId).update({'isDeleted': true});
    } catch (e) {
      throw Exception('Failed to delete firearm: $e');
    }
  }

  @override
  Future<List<ArmoryAmmunitionModel>> getAmmunition(String userId) async {
    try {
      final querySnapshot = await firestore.collection('armory').doc(userId).collection('ammunition').orderBy('dateAdded', descending: true).get();
      return querySnapshot.docs.where((doc) => !doc.data().containsKey('isDeleted')).map((doc) {
        final data = doc.data();
        final diameter = CaliberCalculator.calculateBulletDiameter(data['caliber'], data['bulletdiameter']);
        if (diameter != null) {
          data['bulletdiameter'] = diameter;
        }
        return ArmoryAmmunitionModel.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get ammunition: $e');
    }
  }

  @override
  Future<void> addAmmunition(String userId, ArmoryAmmunitionModel ammunition) async {
    try {
      await firestore.collection('armory').doc(userId).collection('ammunition').doc(ammunition.id)  // Use provided ID instead of auto-generating
          .set(ammunition.toMap());
    } catch (e) {
      throw Exception('Failed to add ammunition: $e');
    }
  }

  @override
  Future<void> updateAmmunition(String userId, ArmoryAmmunitionModel ammunition) async {
    try {
      await firestore.collection('armory').doc(userId).collection('ammunition').doc(ammunition.id).update(ammunition.toMap());
    } catch (e) {
      throw Exception('Failed to update ammunition: $e');
    }
  }

  @override
  Future<void> deleteAmmunition(String userId, String ammunitionId) async {
    try {
      await firestore.collection('armory').doc(userId).collection('ammunition').doc(ammunitionId).update({'isDeleted': true});
    } catch (e) {
      throw Exception('Failed to delete ammunition: $e');
    }
  }

  @override
  Future<List<ArmoryGearModel>> getGear(String userId) async {
    try {
      final querySnapshot = await firestore.collection('armory').doc(userId).collection('gear').orderBy('dateAdded', descending: true).get();
      return querySnapshot.docs.where((doc) => !doc.data().containsKey('isDeleted')).map((doc) => ArmoryGearModel.fromMap(doc.data(), doc.id)).toList();
    } catch (e) {
      throw Exception('Failed to get gear: $e');
    }
  }

  @override
  Future<void> addGear(String userId, ArmoryGearModel gear) async {
    try {
      await firestore.collection('armory').doc(userId).collection('gear').doc(gear.id)  // Use provided ID instead of auto-generating
          .set(gear.toMap());
    } catch (e) {
      throw Exception('Failed to add gear: $e');
    }
  }

  @override
  Future<void> updateGear(String userId, ArmoryGearModel gear) async {
    try {
      await firestore.collection('armory').doc(userId).collection('gear').doc(gear.id).update(gear.toMap());
    } catch (e) {
      throw Exception('Failed to update gear: $e');
    }
  }

  @override
  Future<void> deleteGear(String userId, String gearId) async {
    try {
      await firestore.collection('armory').doc(userId).collection('gear').doc(gearId).update({'isDeleted': true});
    } catch (e) {
      throw Exception('Failed to delete gear: $e');
    }
  }

  @override
  Future<List<ArmoryToolModel>> getTools(String userId) async {
    try {
      final querySnapshot = await firestore.collection('armory').doc(userId).collection('tools').orderBy('dateAdded', descending: true).get();
      return querySnapshot.docs.where((doc) => !doc.data().containsKey('isDeleted')).map((doc) => ArmoryToolModel.fromMap(doc.data(), doc.id)).toList();
    } catch (e) {
      throw Exception('Failed to get tools: $e');
    }
  }

  @override
  Future<void> addTool(String userId, ArmoryToolModel tool) async {
    try {
      await firestore.collection('armory').doc(userId).collection('tools').doc(tool.id)  // Use provided ID instead of auto-generating
          .set(tool.toMap());
    } catch (e) {
      throw Exception('Failed to add tool: $e');
    }
  }

  @override
  Future<void> updateTool(String userId, ArmoryToolModel tool) async {
    try {
      await firestore.collection('armory').doc(userId).collection('tools').doc(tool.id).update(tool.toMap());
    } catch (e) {
      throw Exception('Failed to update tool: $e');
    }
  }

  @override
  Future<void> deleteTool(String userId, String toolId) async {
    try {
      await firestore.collection('armory').doc(userId).collection('tools').doc(toolId).update({'isDeleted': true});
    } catch (e) {
      throw Exception('Failed to delete tool: $e');
    }
  }

  @override
  Future<List<ArmoryLoadoutModel>> getLoadouts(String userId) async {
    try {
      final querySnapshot = await firestore.collection('armory').doc(userId).collection('loadouts').orderBy('dateAdded', descending: true).get();
      return querySnapshot.docs.where((doc) => !doc.data().containsKey('isDeleted')).map((doc) => ArmoryLoadoutModel.fromMap(doc.data(), doc.id)).toList();
    } catch (e) {
      throw Exception('Failed to get loadouts: $e');
    }
  }

  @override
  Future<void> addLoadout(String userId, ArmoryLoadoutModel loadout) async {
    try {
      await firestore.collection('armory').doc(userId).collection('loadouts').doc(loadout.id)  // Use provided ID instead of auto-generating
          .set(loadout.toMap());
    } catch (e) {
      throw Exception('Failed to add loadout: $e');
    }
  }

  @override
  Future<void> updateLoadout(String userId, ArmoryLoadoutModel loadout) async {
    try {
      await firestore.collection('armory').doc(userId).collection('loadouts').doc(loadout.id).update(loadout.toMap());
    } catch (e) {
      throw Exception('Failed to update loadout: $e');
    }
  }

  @override
  Future<void> deleteLoadout(String userId, String loadoutId) async {
    try {
      await firestore.collection('armory').doc(userId).collection('loadouts').doc(loadoutId).update({'isDeleted': true});
    } catch (e) {
      throw Exception('Failed to delete loadout: $e');
    }
  }

  @override
  Future<List<ArmoryMaintenanceModel>> getMaintenance(String userId) async {
    try {
      final querySnapshot = await firestore.collection('armory').doc(userId).collection('maintenance').orderBy('date', descending: true).get();
      return querySnapshot.docs.where((doc) => !doc.data().containsKey('isDeleted')).map((doc) => ArmoryMaintenanceModel.fromMap(doc.data(), doc.id)).toList();
    } catch (e) {
      throw Exception('Failed to get maintenance: $e');
    }
  }

  @override
  Future<void> addMaintenance(String userId, ArmoryMaintenanceModel maintenance) async {
    try {
      await firestore.collection('armory').doc(userId).collection('maintenance').doc(maintenance.id)  // Use provided ID instead of auto-generating
          .set(maintenance.toMap());
    } catch (e) {
      throw Exception('Failed to add maintenance: $e');
    }
  }

  @override
  Future<void> deleteMaintenance(String userId, String maintenanceId) async {
    try {
      await firestore.collection('armory').doc(userId).collection('maintenance').doc(maintenanceId).update({'isDeleted': true});
    } catch (e) {
      throw Exception('Failed to delete maintenance: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getFirearmsRawData() async {
    log.i('Getting raw firearms data from Firestore');
    try {
      final querySnapshot = await firestore.collection('firearms').get();
      return querySnapshot.docs.map((doc) => {
        'id': doc.id, // 👈 Add document ID manually
        ...doc.data(),
      }).toList();
    } catch (e) {
      throw Exception('Failed to load firearms data: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAmmunitionRawData() async {
    log.i('Getting raw ammunition data from Firestore');
    try {
      final querySnapshot = await firestore.collection('ammunition').get();
      return querySnapshot.docs.map((doc) => {
        'id': doc.id, // 👈 Add document ID manually
        ...doc.data(),
      }).toList();
    } catch (e) {
      throw Exception('Failed to load ammunition data: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getUserFirearmsRawData(String userId) async {
    try {
      final querySnapshot = await firestore.collection('armory').doc(userId).collection('firearms').get();
      return querySnapshot.docs.where((doc) => !doc.data().containsKey('isDeleted')).map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Failed to load user firearms data: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getUserAmmunitionRawData(String userId) async {
    try {
      final querySnapshot = await firestore.collection('armory').doc(userId).collection('ammunition').get();
      return querySnapshot.docs.where((doc) => !doc.data().containsKey('isDeleted')).map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Failed to load user ammunition data: $e');
    }
  }

  // ADD method for incremental sync
  Future<List<ArmoryFirearmModel>> getFirearmsAfterTimestamp(String userId, int timestamp) async {
    try {
      final querySnapshot = await firestore
          .collection('armory')
          .doc(userId)
          .collection('firearms')
          .where('dateAdded', isGreaterThan: timestamp)
          .where('isDeleted', isEqualTo: false)
          .get();
      return querySnapshot.docs
          .map((doc) => ArmoryFirearmModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get firearms: $e');
    }
  }
}
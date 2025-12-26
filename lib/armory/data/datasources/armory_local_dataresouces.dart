import 'package:pa_sreens/armory/data/models/armory_ammunition_model.dart';
import 'package:pa_sreens/armory/data/models/armory_firearm_model.dart';
import 'package:pa_sreens/armory/data/models/armory_gear_model.dart';
import 'package:pa_sreens/armory/data/models/armory_loadout_model.dart';
import 'package:pa_sreens/armory/data/models/armory_maintenance_model.dart';
import 'package:pa_sreens/armory/data/models/armory_tool_model.dart';

abstract class ArmoryLocalDataSource {
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

  Future<void> saveSystemFirearms(List<ArmoryFirearmModel> firearms);
  Future<void> saveSystemAmmunition(List<ArmoryAmmunitionModel> ammunition);
  Future<void> saveUserFirearms(String userId, List<ArmoryFirearmModel> firearms);
  Future<void> saveUserAmmunition(String userId, List<ArmoryAmmunitionModel> ammunition);
  Future<void> saveUserGear(String userId, List<ArmoryGearModel> gear);
  Future<void> saveUserTools(String userId, List<ArmoryToolModel> tools);
  Future<void> saveUserLoadouts(String userId, List<ArmoryLoadoutModel> loadouts);
  Future<void> saveUserMaintenance(String userId, List<ArmoryMaintenanceModel> maintenance);

  // lib/armory/data/datasources/armory_local_dataresouces.dart - ADD these methods
  Future<List<ArmoryFirearmModel>> getUnsyncedFirearms(String userId);
  Future<List<ArmoryAmmunitionModel>> getUnsyncedAmmunition(String userId);
  Future<List<ArmoryGearModel>> getUnsyncedGear(String userId);
  Future<List<ArmoryToolModel>> getUnsyncedTools(String userId);
  Future<List<ArmoryLoadoutModel>> getUnsyncedLoadouts(String userId);
  Future<List<ArmoryMaintenanceModel>> getUnsyncedMaintenance(String userId);
  Future<void> markAsSynced(String table, String userId, String id);
  Future<void> markAsUnsynced(String table, String userId, String id);
  Future<bool> hasUserData(String userId);

  // lib/armory/data/datasources/armory_local_dataresouces.dart - ADD these methods at the end
  Future<int> getFirearmCountByCaliber(String userId, String caliber);
  Future<List<ArmoryAmmunitionModel>> getAmmunitionByCaliber(String userId, String caliber);
  Future<List<ArmoryLoadoutModel>> getLoadoutsByFirearmId(String userId, String firearmId);
  Future<List<ArmoryLoadoutModel>> getLoadoutsByAmmunitionId(String userId, String ammunitionId);
  Future<void> batchDeleteLoadouts(String userId, List<String> loadoutIds);
  Future<void> batchDeleteAmmunition(String userId, List<String> ammunitionIds);


  Future<bool> isDatabaseEmpty();
  Future<void> clearAllData();
}
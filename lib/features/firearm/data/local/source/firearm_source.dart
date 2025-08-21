import 'package:pulse_skadi/features/firearm/data/model/firearm_entity.dart';

abstract class FirearmSource {
  Future<FirearmEntity?> addNewFirearm(String userId, FirearmEntity firearm);
  //---------
  Future<void> updateFirearmInStage(String userId, FirearmEntity firearm);
  //---------
  Future<List<FirearmEntity>> geFirearms(String userId);
  //---------
  Future<void> removeFirearm(int drillId, String userId);
  //---------
}

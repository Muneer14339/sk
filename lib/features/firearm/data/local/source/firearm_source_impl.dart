import 'package:injectable/injectable.dart';
import 'package:pulse_skadi/features/firearm/data/local/service/firearm_db_helper.dart';
import 'package:pulse_skadi/features/firearm/data/model/firearm_entity.dart';

import 'firearm_source.dart';

@Injectable(as: FirearmSource)
class FirearmSourceImpl implements FirearmSource {
  final FirearmDbHelper _firearmDbHelper = FirearmDbHelper();

  @override
  Future<FirearmEntity?> addNewFirearm(String userId, FirearmEntity firearm) {
    return _firearmDbHelper.addNewFirearm(userId, firearm);
  }

  @override
  Future<List<FirearmEntity>> geFirearms(String userId) {
    return _firearmDbHelper.getFirearms(userId);
  }

  @override
  Future<void> removeFirearm(int drillId, String userId) {
    return _firearmDbHelper.removeFirearm(drillId, userId);
  }

  @override
  Future<void> updateFirearmInStage(String userId, FirearmEntity firearm) {
    return _firearmDbHelper.updateFirearmInStage(userId, firearm);
  }
}

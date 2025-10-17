import 'package:dartz/dartz.dart';

import '../../data/model/firearm_entity.dart';

abstract class FirearmRepository {
  Future<Either<FirearmEntity?, String>> addNewFirearm(
      String userId, FirearmEntity firearm);
  //---------
  Future<void> updateFirearmInStage(String userId, FirearmEntity firearm);
  //---------

  Future<Either<List<FirearmEntity>, String>> geFirearms(String userId);
  //---------
  Future<void> removeFirearm(int drillId, String userId);
  //---------
}

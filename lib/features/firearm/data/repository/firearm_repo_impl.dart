import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_skadi/features/firearm/data/local/source/firearm_source.dart';
import 'package:pulse_skadi/features/firearm/data/model/firearm_entity.dart';

import '../../domain/repository/furearm_repository.dart';

@Injectable(as: FirearmRepository)
class FirearmRepositoryImpl implements FirearmRepository {
  FirearmRepositoryImpl(this._firearmSource);
  final FirearmSource _firearmSource;

  @override
  Future<Either<FirearmEntity?, String>> addNewFirearm(
      String userId, FirearmEntity firearm) async {
    try {
      final result = await _firearmSource.addNewFirearm(userId, firearm);
      return left(result);
    } catch (e) {
      return right(e.toString());
    }
  }

  @override
  Future<Either<List<FirearmEntity>, String>> geFirearms(String userId) async {
    try {
      final result = await _firearmSource.geFirearms(userId);
      return left(result);
    } catch (e) {
      return right(e.toString());
    }
  }

  @override
  Future<void> removeFirearm(int firearmId, String userId) {
    return _firearmSource.removeFirearm(firearmId, userId);
  }

  @override
  Future<void> updateFirearmInStage(String userId, FirearmEntity firearm) {
    return _firearmSource.updateFirearmInStage(userId, firearm);
  }
}

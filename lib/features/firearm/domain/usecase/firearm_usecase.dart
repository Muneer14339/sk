import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_skadi/features/firearm/data/model/firearm_entity.dart';
import '../repository/furearm_repository.dart';

@injectable
class FirearmUsecase {
  FirearmUsecase(this._firearmRepository);

  final FirearmRepository _firearmRepository;

  Future<Either<FirearmEntity?, String>> addFirearm(
      String userId, FirearmEntity firearm) {
    return _firearmRepository.addNewFirearm(userId, firearm);
  }

  Future<Either<List<FirearmEntity>, String>> getFirearm(String userId) {
    return _firearmRepository.geFirearms(userId);
  }

  Future<void> removeFirearm(int firearmId, String userId) {
    return _firearmRepository.removeFirearm(firearmId, userId);
  }

  Future<void> updateFirearmInStage(String userId, FirearmEntity firearm) {
    return _firearmRepository.updateFirearmInStage(userId, firearm);
  }
}

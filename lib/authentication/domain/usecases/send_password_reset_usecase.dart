import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class SendPasswordResetUseCase implements UseCase<void, String> {
  final AuthRepository repository;

  SendPasswordResetUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String email) async {
    return await repository.sendPasswordResetEmail(email);
  }
}
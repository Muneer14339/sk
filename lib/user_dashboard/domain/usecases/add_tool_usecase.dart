// lib/user_dashboard/domain/usecases/get_firearms_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../entities/armory_firearm.dart';
import '../repositories/armory_repository.dart';
// lib/user_dashboard/domain/usecases/add_tool_usecase.dart
class AddToolUseCase implements UseCase<void, AddToolParams> {
  final ArmoryRepository repository;

  AddToolUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(AddToolParams params) async {
    return await repository.addTool(params.userId, params.tool);
  }
}
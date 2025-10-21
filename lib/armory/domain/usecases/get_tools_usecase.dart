// lib/user_dashboard/domain/usecases/get_firearms_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../entities/armory_firearm.dart';
import '../entities/armory_tool.dart';
import '../repositories/armory_repository.dart';

// lib/user_dashboard/domain/usecases/get_tools_usecase.dart
class GetToolsUseCase implements UseCase<List<ArmoryTool>, UserIdParams> {
  final ArmoryRepository repository;

  GetToolsUseCase(this.repository);

  @override
  Future<Either<Failure, List<ArmoryTool>>> call(UserIdParams params) async {
    return await repository.getTools(params.userId);
  }
}
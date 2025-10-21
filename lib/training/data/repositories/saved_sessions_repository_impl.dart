// lib/features/training/data/repositories/saved_sessions_repository_impl.dart
import 'package:dartz/dartz.dart';


import '../../../core/error/old_failuers.dart';
import '../../domain/repositories/saved_sessions_repository.dart';
import '../datasources/saved_sessions_datasource.dart';
import '../models/saved_session_model.dart';

class SavedSessionsRepositoryImpl implements SavedSessionsRepository {
  final SavedSessionsDataSource dataSource;

  SavedSessionsRepositoryImpl(this.dataSource);

  @override
  Future<Either<Failure, String>> saveSession(SavedSessionModel session) async {
    try {
      final id = await dataSource.saveSession(session);
      return Right(id);
    } catch (e) {
      print('------- $e');
      return Left(ServerFailure('Failed to save session'));
    }
  }

  @override
  Future<Either<Failure, List<SavedSessionModel>>> listSessions() async {
    try {
      final list = await dataSource.listSessions();
      return Right(list);
    } catch (e) {
      print('------- $e');
      return Left(ServerFailure('Failed to load sessions'));
    }
  }

  @override
  Future<Either<Failure, SavedSessionModel>> getSession(
      String sessionId) async {
    try {
      final session = await dataSource.getSession(sessionId);
      return Right(session);
    } catch (e) {
      print('------- $e');
      return Left(ServerFailure('Failed to load session'));
    }
  }
}

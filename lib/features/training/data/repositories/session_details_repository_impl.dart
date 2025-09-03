// lib/features/training/data/repositories/session_details_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:pulse_skadi/core/errors/failures.dart';
import 'package:pulse_skadi/core/errors/exceptions.dart';
import 'package:pulse_skadi/core/network/network_info.dart';
import 'package:pulse_skadi/features/training/data/datasources/session_details_local_datasource.dart';
import 'package:pulse_skadi/features/training/data/datasources/session_details_remote_datasource.dart';
import 'package:pulse_skadi/features/training/domain/entities/session_details_entity.dart';
import 'package:pulse_skadi/features/training/domain/repositories/session_details_repository.dart';

class SessionDetailsRepositoryImpl implements SessionDetailsRepository {
  final SessionDetailsRemoteDataSource remoteDataSource;
  final SessionDetailsLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  SessionDetailsRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, SessionDetailsEntity>> getSessionDetails(
      String sessionId) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteSessionDetails =
            await remoteDataSource.getSessionDetails(sessionId);
        await localDataSource.cacheSessionDetails(remoteSessionDetails);
        return Right(remoteSessionDetails);
      } on ServerException {
        return Left(ServerFailure('Failed to get session details from server'));
      }
    } else {
      try {
        final localSessionDetails =
            await localDataSource.getLastSessionDetails();
        return Right(localSessionDetails);
      } on CacheException {
        return Left(CacheFailure('Failed to get cached session details'));
      }
    }
  }

  @override
  Future<Either<Failure, List<SessionDetailsEntity>>> getAllSessions() async {
    if (await networkInfo.isConnected) {
      try {
        final remoteSessions = await remoteDataSource.getAllSessions();
        await localDataSource.cacheAllSessions(remoteSessions);
        return Right(remoteSessions);
      } on ServerException {
        return Left(ServerFailure('Failed to get all sessions from server'));
      }
    } else {
      try {
        final localSessions = await localDataSource.getAllCachedSessions();
        return Right(localSessions);
      } on CacheException {
        return Left(CacheFailure('Failed to get cached sessions'));
      }
    }
  }

  @override
  Future<Either<Failure, void>> exportSessionData(String sessionId) async {
    try {
      await remoteDataSource.exportSessionData(sessionId);
      return const Right(null);
    } on ServerException {
      return Left(ServerFailure('Failed to export session data'));
    }
  }

  @override
  Future<Either<Failure, void>> shareSessionResults(String sessionId) async {
    try {
      await remoteDataSource.shareSessionResults(sessionId);
      return const Right(null);
    } on ServerException {
      return Left(ServerFailure('Failed to share session results'));
    }
  }
}

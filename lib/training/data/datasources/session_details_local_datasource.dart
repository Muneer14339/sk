// lib/features/training/data/datasources/session_details_local_datasource.dart

import '../../../core/error/exceptions.dart';
import '../models/session_details_model.dart';
abstract class SessionDetailsLocalDataSource {
  Future<SessionDetailsModel> getLastSessionDetails();
  Future<List<SessionDetailsModel>> getAllCachedSessions();
  Future<void> cacheSessionDetails(SessionDetailsModel sessionDetails);
  Future<void> cacheAllSessions(List<SessionDetailsModel> sessions);
}

class SessionDetailsLocalDataSourceImpl
    implements SessionDetailsLocalDataSource {
  // In a real app, this would use SharedPreferences, Hive, or SQLite
  // For now, we'll use in-memory storage for demonstration

  SessionDetailsModel? _cachedSessionDetails;
  List<SessionDetailsModel> _cachedSessions = [];

  @override
  Future<SessionDetailsModel> getLastSessionDetails() async {
    if (_cachedSessionDetails != null) {
      return _cachedSessionDetails!;
    } else {
      throw CacheException('No cached session details found');
    }
  }

  @override
  Future<List<SessionDetailsModel>> getAllCachedSessions() async {
    return _cachedSessions;
  }

  @override
  Future<void> cacheSessionDetails(SessionDetailsModel sessionDetails) async {
    _cachedSessionDetails = sessionDetails;
  }

  @override
  Future<void> cacheAllSessions(List<SessionDetailsModel> sessions) async {
    _cachedSessions = sessions;
  }
}

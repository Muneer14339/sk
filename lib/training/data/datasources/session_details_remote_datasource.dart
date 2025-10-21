// lib/features/training/data/datasources/session_details_remote_datasource.dart


import '../../../core/error/exceptions.dart';
import '../../../core/network/api_client.dart';
import '../models/session_details_model.dart';

abstract class SessionDetailsRemoteDataSource {
  Future<SessionDetailsModel> getSessionDetails(String sessionId);
  Future<List<SessionDetailsModel>> getAllSessions();
  Future<void> exportSessionData(String sessionId);
  Future<void> shareSessionResults(String sessionId);
}

class SessionDetailsRemoteDataSourceImpl
    implements SessionDetailsRemoteDataSource {
  final ApiClient apiClient;

  SessionDetailsRemoteDataSourceImpl(this.apiClient);

  @override
  Future<SessionDetailsModel> getSessionDetails(String sessionId) async {
    try {
      // For now, return mock data. In a real app, this would make an API call
      // final response = await apiClient.get('/sessions/$sessionId');
      // return SessionDetailsModel.fromJson(response.data);

      // Mock data for demonstration
      return _getMockSessionDetails(sessionId);
    } catch (e) {
      throw ServerException('Failed to get session details');
    }
  }

  @override
  Future<List<SessionDetailsModel>> getAllSessions() async {
    try {
      // Mock data for demonstration
      return [_getMockSessionDetails('session1')];
    } catch (e) {
      throw ServerException('Failed to get all sessions');
    }
  }

  @override
  Future<void> exportSessionData(String sessionId) async {
    try {
      // Mock implementation
      await Future.delayed(const Duration(seconds: 1));
    } catch (e) {
      throw ServerException('Failed to export session data');
    }
  }

  @override
  Future<void> shareSessionResults(String sessionId) async {
    try {
      // Mock implementation
      await Future.delayed(const Duration(seconds: 1));
    } catch (e) {
      throw ServerException('Failed to share session results');
    }
  }

  SessionDetailsModel _getMockSessionDetails(String sessionId) {
    return SessionDetailsModel(
      sessionId: sessionId,
      programName: 'Precision Fundamentals',
      sessionDate: DateTime.now(),
      duration: '12 minutes',
      totalShots: 5,
      shots: [
        ShotDetailsModel(
          id: 1,
          x: 142.0,
          y: 138.0,
          score: 10,
          timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
          metrics: {'stability': 92.0, 'triggerControl': 88.0},
          hasTraceData: true,
        ),
        ShotDetailsModel(
          id: 2,
          x: 145.0,
          y: 142.0,
          score: 10,
          timestamp: DateTime.now().subtract(const Duration(minutes: 9)),
          metrics: {'stability': 89.0, 'triggerControl': 91.0},
          hasTraceData: true,
        ),
        ShotDetailsModel(
          id: 3,
          x: 148.0,
          y: 140.0,
          score: 9,
          timestamp: DateTime.now().subtract(const Duration(minutes: 8)),
          metrics: {'stability': 85.0, 'triggerControl': 87.0},
          hasTraceData: false,
        ),
        ShotDetailsModel(
          id: 4,
          x: 140.0,
          y: 145.0,
          score: 10,
          timestamp: DateTime.now().subtract(const Duration(minutes: 7)),
          metrics: {'stability': 91.0, 'triggerControl': 89.0},
          hasTraceData: true,
        ),
        ShotDetailsModel(
          id: 5,
          x: 143.0,
          y: 138.0,
          score: 10,
          timestamp: DateTime.now().subtract(const Duration(minutes: 6)),
          metrics: {'stability': 94.0, 'triggerControl': 92.0},
          hasTraceData: true,
        ),
      ],
      metadata: SessionMetadataModel(
        firearm: 'Glock 19',
        optic: 'Red Dot',
        ammunition: '115gr 9mm',
        distance: '25 yards',
        conditions: 'Indoor Range, 72°F',
      ),
      metrics: SessionMetricsModel(
        averageScore: 87.0,
        successRate: 94.0,
        groupSize: 15.2,
        programMetrics: {
          'stability': 90.2,
          'triggerControl': 89.4,
        },
      ),
      isSuccess: true,
      aiInsights:
          'Excellent fundamental execution - 4/5 shots met both stability and trigger control thresholds.',
    );
  }
}

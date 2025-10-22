import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/constants.dart';
import '../../../core/widgets/custom_appbar.dart';
import '../../../core/widgets/icon_container.dart';
import '../../data/datasources/saved_sessions_datasource.dart';
import '../../data/models/saved_session_model.dart';
import '../../data/repositories/saved_sessions_repository_impl.dart';
import '../../domain/repositories/saved_sessions_repository.dart';
import '../../domain/usecases/list_saved_sessions.dart';
import '../bloc/saved_sessions/saved_sessions_bloc.dart';
import '../bloc/saved_sessions/saved_sessions_event.dart';
import '../bloc/saved_sessions/saved_sessions_state.dart';
import 'session_summary_page.dart';

class SavedSessionsPage extends StatefulWidget {
  const SavedSessionsPage({super.key});

  @override
  State<SavedSessionsPage> createState() => _SavedSessionsPageState();
}

class _SavedSessionsPageState extends State<SavedSessionsPage> {
  late final SavedSessionsBloc _bloc;

  @override
  void initState() {
    super.initState();
    final SavedSessionsRepository repo =
        SavedSessionsRepositoryImpl(SavedSessionsDataSourceImpl());
    _bloc = SavedSessionsBloc(listSavedSessions: ListSavedSessions(repo))
      ..add(const LoadSavedSessions());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background(context),
      appBar: customAppBar(
          title: 'Saved Sessions', context: context, showBackButton: false),
      body: BlocBuilder<SavedSessionsBloc, SavedSessionsState>(
        bloc: _bloc,
        builder: (context, state) {
          if (state.isLoading) {
            return Center(
                child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppTheme.primary(context))));
          }
          if (state.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: AppTheme.error(context),
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${state.error}',
                    style: TextStyle(
                      color: AppTheme.textPrimary(context),
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          if (state.sessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.surface(context),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.history,
                      color: AppTheme.primary(context),
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No saved sessions yet',
                    style: TextStyle(
                      color: AppTheme.textPrimary(context),
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your training sessions will appear here',
                    style: TextStyle(
                      color: AppTheme.textSecondary(context),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView(children: [
            _AnalyticsSection(sessions: state.sessions),
            ListView.builder(
                itemCount: state.sessions.length,
                primary: false,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  final s = state.sessions[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _SessionCard(
                      session: s,
                      onTap: () async {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SessionSummaryPage(savedSession: s),
                            settings: RouteSettings(arguments: s),
                          ),
                        );
                      },
                    ),
                  );
                })
          ]);
        },
      ),
    );
  }
}

class _AnalyticsSection extends StatelessWidget {
  final List<SavedSessionModel> sessions;

  const _AnalyticsSection({required this.sessions});

  @override
  Widget build(BuildContext context) {
    final totalSessions = sessions.length;
    final totalShots =
        sessions.fold<int>(0, (sum, session) => sum + session.totalShots);
    final averageShots =
        totalSessions > 0 ? (totalShots / totalSessions).round() : 0;
    final mostRecentSession = sessions.isNotEmpty
        ? sessions.reduce((a, b) => a.startedAt.isAfter(b.startedAt) ? a : b)
        : null;
    final daysSinceLastSession = mostRecentSession != null
        ? DateTime.now().difference(mostRecentSession.startedAt).inDays
        : 0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [AppTheme.surface(context), AppTheme.background(context)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.surface(context).withValues(alpha: 0.8),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconContainer(icon: Icons.analytics),
              const SizedBox(width: 12),
              Text('Training Overview',
                  style: TextStyle(
                      color: AppTheme.textPrimary(context),
                      fontSize: 16,
                      fontWeight: FontWeight.w500))
            ],
          ),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
                child: _AnalyticsCard(
                    title: 'Total Sessions',
                    value: totalSessions.toString(),
                    icon: Icons.fitness_center)),
            const SizedBox(width: 12),
            Expanded(
                child: _AnalyticsCard(
                    title: 'Total Shots',
                    value: totalShots.toString(),
                    icon: Icons.my_location))
          ]),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _AnalyticsCard(
                      title: 'Avg per Session',
                      value: averageShots.toString(),
                      icon: Icons.trending_up)),
              const SizedBox(width: 12),
              Expanded(
                child: _AnalyticsCard(
                  title: 'Days Since Last',
                  value: daysSinceLastSession.toString(),
                  icon: Icons.schedule,
                  // color: daysSinceLastSession <= 1
                  //     ? AppTheme.success(context)
                  //     : daysSinceLastSession <= 7
                  //         ? AppTheme.primary(context)
                  //         : AppTheme.error(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _AnalyticsCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppTheme.background(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: AppTheme.primary(context).withValues(alpha: 0.3), width: 1)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: AppTheme.primary(context),
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.textSecondary(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: AppTheme.textPrimary(context),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final SavedSessionModel session;
  final VoidCallback onTap;

  const _SessionCard({
    required this.session,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [AppTheme.surface(context), AppTheme.background(context)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: AppTheme.surface(context).withOpacity(0.8), width: 1),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ]),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconContainer(icon: Icons.sports_esports),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      session.programName.isEmpty
                          ? 'Training Session'
                          : session.programName,
                      style: TextStyle(
                        color: AppTheme.textPrimary(context),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: AppTheme.textSecondary(context),
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _StatChip(
                    icon: Icons.my_location,
                    label: '${session.totalShots} shots',
                    color: AppTheme.primary(context),
                  ),
                  const SizedBox(width: 12),
                  _StatChip(
                    icon: Icons.access_time,
                    label: kDateFormat.format(session.startedAt),
                    color: AppTheme.textSecondary(context),
                  ),
                ],
              ),
              if (session.distancePresetKey > 0 ||
                  session.angleRangeKey.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (session.distancePresetKey > 0) ...[
                      _InfoTag(
                        label: session.distancePresetKey.toString(),
                        icon: Icons.straighten,
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (session.angleRangeKey.isNotEmpty)
                      _InfoTag(
                        label: session.angleRangeKey,
                        icon: Icons.rotate_right,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTag extends StatelessWidget {
  final String label;
  final IconData icon;

  const _InfoTag({
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: AppTheme.textSecondary(context),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textSecondary(context),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

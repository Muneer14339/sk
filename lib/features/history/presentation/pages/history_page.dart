import 'package:flutter/material.dart';

class TrainingHistoryPage extends StatefulWidget {
  const TrainingHistoryPage({super.key});

  @override
  State<TrainingHistoryPage> createState() => _TrainingHistoryPageState();
}

class _TrainingHistoryPageState extends State<TrainingHistoryPage>
    with TickerProviderStateMixin {
  String _selectedFilter = 'all';
  String _selectedView = 'list';
  DateTime _currentCalendarDate = DateTime.now();

  final List<TrainingSession> _sessions = [
    TrainingSession(
      date: DateTime.now(),
      time: '2:45 PM',
      duration: '12 min',
      shots: 18,
      avgScore: 87,
      accuracy: 94,
      groupSize: 15.2,
      performance: SessionPerformance.excellent,
      gear: 'Glock 19 + Red Dot • 115gr 9mm',
      isNew: true,
      trend: TrendDirection.up,
    ),
    TrainingSession(
      date: DateTime.now().subtract(const Duration(days: 1)),
      time: '6:20 PM',
      duration: '8 min',
      shots: 12,
      avgScore: 82,
      accuracy: 89,
      groupSize: 18.7,
      performance: SessionPerformance.good,
      gear: 'Glock 19 + Iron Sights • 124gr 9mm',
      trend: TrendDirection.up,
    ),
    TrainingSession(
      date: DateTime.now().subtract(const Duration(days: 4)),
      time: '4:15 PM',
      duration: '15 min',
      shots: 22,
      avgScore: 91,
      accuracy: 96,
      groupSize: 12.3,
      performance: SessionPerformance.excellent,
      gear: 'AR-15 + Scope • 55gr .223',
      trend: TrendDirection.up,
    ),
    TrainingSession(
      date: DateTime.now().subtract(const Duration(days: 5)),
      time: '7:30 PM',
      duration: '6 min',
      shots: 8,
      avgScore: 75,
      accuracy: 78,
      groupSize: 25.8,
      performance: SessionPerformance.fair,
      gear: 'Glock 19 + Iron Sights • 147gr 9mm',
      trend: TrendDirection.down,
    ),
    TrainingSession(
      date: DateTime.now().subtract(const Duration(days: 7)),
      time: '3:45 PM',
      duration: '20 min',
      shots: 28,
      avgScore: 84,
      accuracy: 85,
      groupSize: 19.4,
      performance: SessionPerformance.good,
      gear: 'Ruger 10/22 + Iron Sights • 40gr .22 LR',
      trend: TrendDirection.up,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildHistoryOverview(),
                    const SizedBox(height: 20),
                    _buildQuickActions(),
                    const SizedBox(height: 20),
                    _buildAIInsights(),
                    const SizedBox(height: 20),
                    _buildFilterControls(),
                    const SizedBox(height: 20),
                    _buildContent(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: const Color(0xFF2C3E50),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 20),
          const Text('Training History',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600)),
          GestureDetector(
            onTap: _showHistoryOptions,
            child: Container(
              padding: const EdgeInsets.all(8),
              child: const Text('📊', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryOverview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text(
            'Training Progress',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your marksmanship journey at a glance',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 15),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 1.5,
            children: [
              _buildOverviewStat('24', 'Total Sessions'),
              _buildOverviewStat('8.2h', 'Training Time'),
              _buildOverviewStat('87.4', 'Average Score'),
              _buildOverviewStat('+12%', 'This Month'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewStat(String value, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildQuickActionButton(
          '📈',
          'Progress Charts',
          const Color(0xFF2C3E50),
          _viewProgressCharts,
        ),
        _buildQuickActionButton(
          '🎯',
          'New Session',
          const Color(0xFFE74C3C),
          _startNewSession,
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(
    String icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              icon,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIInsights() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF343A40).withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('🤖', style: TextStyle(fontSize: 16)),
              SizedBox(width: 10),
              Text(
                'Recent Performance Insights',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            '"Your accuracy has improved by 12% this month with excellent consistency. Your best time for training appears to be 2-4 PM with 91% average accuracy. Consider focusing on rapid fire drills to reach the next skill level."',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterControls() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE9ECEF)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildFilterTabs(),
          const SizedBox(height: 15),
          _buildViewOptions(),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _buildFilterTab('All Sessions', 'all'),
          _buildFilterTab('This Week', 'week'),
          _buildFilterTab('This Month', 'month'),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String title, String filter) {
    final isActive = _selectedFilter == filter;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilter = filter),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF2C3E50) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? Colors.white : const Color(0xFF2C3E50),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildViewOptions() {
    return Row(
      children: [
        _buildViewOption('📋', 'List View', 'list'),
        const SizedBox(width: 10),
        _buildViewOption('📅', 'Calendar', 'calendar'),
      ],
    );
  }

  Widget _buildViewOption(String icon, String label, String view) {
    final isActive = _selectedView == view;
    return GestureDetector(
      onTap: () => setState(() => _selectedView = view),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2C3E50) : const Color(0xFFF8F9FA),
          border: Border.all(
            color: isActive ? const Color(0xFF2C3E50) : const Color(0xFFDEE2E6),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : const Color(0xFF2C3E50),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_selectedView == 'calendar') {
      return _buildCalendarView();
    } else {
      return _buildSessionList();
    }
  }

  Widget _buildSessionList() {
    final filteredSessions = _getFilteredSessions();

    if (filteredSessions.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: filteredSessions
          .map((session) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildSessionItem(session),
              ))
          .toList(),
    );
  }

  Widget _buildSessionItem(TrainingSession session) {
    return GestureDetector(
      onTap: () => _viewSession(session),
      child: Stack(
        children: [
          Container(
            padding: EdgeInsets.only(left: 4),
            decoration: BoxDecoration(
              color: _getPerformanceColor(session.performance),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              // margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE9ECEF)),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Text(
                        _formatSessionDate(session.date),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          session.duration,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6C757D),
                          ),
                        ),
                      ),
                      Text(
                        _getTrendIcon(session.trend),
                        style: TextStyle(
                          fontSize: 20,
                          color: _getTrendColor(session.trend),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Stats grid
                  Wrap(
                    direction: Axis.horizontal,
                    alignment: WrapAlignment.spaceBetween,
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _buildSessionStat('${session.shots}', 'Shots'),
                      _buildSessionStat('${session.avgScore}', 'Avg Score'),
                      _buildSessionStat('${session.accuracy}%', 'Accuracy'),
                      _buildSessionStat('${session.groupSize}', 'Group(mm)'),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Performance and gear
                  Container(
                    padding: const EdgeInsets.only(top: 12),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Color(0xFFF8F9FA)),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getPerformanceBadgeColor(
                                    session.performance),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                _getPerformanceText(session.performance),
                                style: TextStyle(
                                  color: _getPerformanceTextColor(
                                      session.performance),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              // width: 280,
                              child: Text(
                                session.gear,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6C757D),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const Text(
                          '→',
                          style: TextStyle(
                            color: Color(0xFF6C757D),
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (session.isNew)
            Positioned(
              top: -0,
              right: -0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE74C3C),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'NEW',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSessionStat(String value, String label) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF6C757D),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarView() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE9ECEF)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildCalendarHeader(),
          _buildCalendarWeekdays(),
          _buildCalendarGrid(),
          _buildCalendarLegend(),
        ],
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: _previousMonth,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                '‹',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Text(
            _getCalendarTitle(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          GestureDetector(
            onTap: _nextMonth,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                '›',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarWeekdays() {
    const weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FA),
        border: Border(
          bottom: BorderSide(color: Color(0xFFE9ECEF)),
        ),
      ),
      child: Row(
        children: weekdays
            .map((day) => Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: const BoxDecoration(
                      border: Border(
                        right: BorderSide(color: Color(0xFFE9ECEF)),
                      ),
                    ),
                    child: Text(
                      day,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF6C757D),
                      ),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final daysInMonth = _getDaysInCalendarMonth();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.0,
      ),
      itemCount: daysInMonth.length,
      itemBuilder: (context, index) {
        final day = daysInMonth[index];
        return _buildCalendarDay(day);
      },
    );
  }

  Widget _buildCalendarDay(CalendarDay day) {
    final sessionsForDay = _getSessionsForDate(day.date);
    final isToday = _isSameDay(day.date, DateTime.now());

    return GestureDetector(
      onTap: () => _showDayDetails(day.date, sessionsForDay),
      child: Container(
        decoration: BoxDecoration(
          color: day.isCurrentMonth ? Colors.white : const Color(0xFFFAFAFA),
          border: const Border(
            right: BorderSide(color: Color(0xFFF0F0F0)),
            bottom: BorderSide(color: Color(0xFFF0F0F0)),
          ),
        ),
        child: Stack(
          children: [
            if (isToday)
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF667EEA).withValues(alpha: 0.15),
                  border: Border.all(color: const Color(0xFF667EEA), width: 2),
                ),
              ),
            if (sessionsForDay.isNotEmpty)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 4,
                  color: sessionsForDay.length > 1
                      ? const Color(0xFFDC3545)
                      : const Color(0xFF28A745),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${day.date.day}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
                      color: day.isCurrentMonth
                          ? (isToday
                              ? const Color(0xFF667EEA)
                              : const Color(0xFF2C3E50))
                          : const Color(0xFFCCCCCC),
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (sessionsForDay.isNotEmpty)
                    Expanded(
                      child: Wrap(
                        spacing: 2,
                        runSpacing: 2,
                        children: sessionsForDay.take(4).map((session) {
                          return Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _getPerformanceColor(session.performance),
                              shape: BoxShape.circle,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  if (sessionsForDay.length > 4)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C3E50),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${sessionsForDay.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FA),
        border: Border(
          top: BorderSide(color: Color(0xFFE9ECEF)),
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildLegendItem('Excellent', const Color(0xFF28A745)),
          _buildLegendItem('Good', const Color(0xFFFFC107)),
          _buildLegendItem('Needs Work', const Color(0xFFFD7E14)),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6C757D),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        children: [
          const Text(
            '🎯',
            style: TextStyle(
              fontSize: 48,
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            'No Training Sessions Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6C757D),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start your first training session to begin tracking your marksmanship progress and see detailed analytics.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6C757D),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _startNewSession,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE74C3C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Start Your First Session',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  List<TrainingSession> _getFilteredSessions() {
    final now = DateTime.now();

    switch (_selectedFilter) {
      case 'week':
        final weekAgo = now.subtract(const Duration(days: 7));
        return _sessions.where((s) => s.date.isAfter(weekAgo)).toList();
      case 'month':
        final monthAgo = now.subtract(const Duration(days: 30));
        return _sessions.where((s) => s.date.isAfter(monthAgo)).toList();
      default:
        return _sessions;
    }
  }

  List<CalendarDay> _getDaysInCalendarMonth() {
    final firstDay =
        DateTime(_currentCalendarDate.year, _currentCalendarDate.month, 1);
    final startDate = firstDay.subtract(Duration(days: firstDay.weekday % 7));

    final days = <CalendarDay>[];
    for (int i = 0; i < 42; i++) {
      final date = startDate.add(Duration(days: i));
      days.add(CalendarDay(
        date: date,
        isCurrentMonth: date.month == _currentCalendarDate.month,
      ));
    }

    return days;
  }

  List<TrainingSession> _getSessionsForDate(DateTime date) {
    return _sessions
        .where((session) => _isSameDay(session.date, date))
        .toList();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _getCalendarTitle() {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${months[_currentCalendarDate.month - 1]} ${_currentCalendarDate.year}';
  }

  String _formatSessionDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sessionDate = DateTime(date.year, date.month, date.day);

    if (sessionDate == today) {
      return 'Today, ${_formatTime(date)}';
    } else if (sessionDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday, ${_formatTime(date)}';
    } else {
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return '${months[date.month - 1]} ${date.day}, ${_formatTime(date)}';
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour;
    final minute = date.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  Color _getPerformanceColor(SessionPerformance performance) {
    switch (performance) {
      case SessionPerformance.excellent:
        return const Color(0xFF28A745);
      case SessionPerformance.good:
        return const Color(0xFFFFC107);
      case SessionPerformance.fair:
        return const Color(0xFFFD7E14);
    }
  }

  Color _getPerformanceBadgeColor(SessionPerformance performance) {
    switch (performance) {
      case SessionPerformance.excellent:
        return const Color(0xFFD4EDDA);
      case SessionPerformance.good:
        return const Color(0xFFFFF3CD);
      case SessionPerformance.fair:
        return const Color(0xFFF8D7DA);
    }
  }

  Color _getPerformanceTextColor(SessionPerformance performance) {
    switch (performance) {
      case SessionPerformance.excellent:
        return const Color(0xFF155724);
      case SessionPerformance.good:
        return const Color(0xFF856404);
      case SessionPerformance.fair:
        return const Color(0xFF721C24);
    }
  }

  String _getPerformanceText(SessionPerformance performance) {
    switch (performance) {
      case SessionPerformance.excellent:
        return 'Excellent';
      case SessionPerformance.good:
        return 'Good';
      case SessionPerformance.fair:
        return 'Needs Improvement';
    }
  }

  String _getTrendIcon(TrendDirection trend) {
    switch (trend) {
      case TrendDirection.up:
        return '↗';
      case TrendDirection.down:
        return '↘';
      case TrendDirection.stable:
        return '→';
    }
  }

  Color _getTrendColor(TrendDirection trend) {
    switch (trend) {
      case TrendDirection.up:
        return const Color(0xFF28A745);
      case TrendDirection.down:
        return const Color(0xFFDC3545);
      case TrendDirection.stable:
        return const Color(0xFF6C757D);
    }
  }

  void _previousMonth() {
    setState(() {
      _currentCalendarDate = DateTime(
        _currentCalendarDate.year,
        _currentCalendarDate.month - 1,
      );
    });
  }

  void _nextMonth() {
    setState(() {
      _currentCalendarDate = DateTime(
        _currentCalendarDate.year,
        _currentCalendarDate.month + 1,
      );
    });
  }

  void _showDayDetails(DateTime date, List<TrainingSession> sessions) {
    if (sessions.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_formatSessionDate(date)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: sessions
              .map((session) => ListTile(
                    title: Text('${session.time} - ${session.shots} shots'),
                    subtitle: Text(
                        'Score: ${session.avgScore} (${session.accuracy}%)'),
                    trailing: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getPerformanceColor(session.performance),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ))
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _viewSession(TrainingSession session) {
    // Navigate to session detail page
    print('Viewing session: ${session.date}');
  }

  void _viewProgressCharts() {
    print('Viewing progress charts');
  }

  void _startNewSession() {
    print('Starting new session');
  }

  void _showHistoryOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'History Options',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Text('📊'),
              title: const Text('Export all sessions'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Text('📈'),
              title: const Text('View progress charts'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Text('📋'),
              title: const Text('Session statistics'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Text('📊'),
              title: const Text('Performance trends'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

// Data models
enum SessionPerformance { excellent, good, fair }

enum TrendDirection { up, down, stable }

class TrainingSession {
  final DateTime date;
  final String time;
  final String duration;
  final int shots;
  final int avgScore;
  final int accuracy;
  final double groupSize;
  final SessionPerformance performance;
  final String gear;
  final bool isNew;
  final TrendDirection trend;

  TrainingSession({
    required this.date,
    required this.time,
    required this.duration,
    required this.shots,
    required this.avgScore,
    required this.accuracy,
    required this.groupSize,
    required this.performance,
    required this.gear,
    this.isNew = false,
    required this.trend,
  });
}

class CalendarDay {
  final DateTime date;
  final bool isCurrentMonth;

  CalendarDay({
    required this.date,
    required this.isCurrentMonth,
  });
}

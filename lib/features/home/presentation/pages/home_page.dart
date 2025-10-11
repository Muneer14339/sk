import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pulse_skadi/core/theme/app_colors.dart';
import 'package:pulse_skadi/core/widgets/custom_appbar.dart';
import 'package:pulse_skadi/features/training/presentation/bloc/ble_scan/ble_scan_bloc.dart';
import 'package:pulse_skadi/features/training/presentation/bloc/ble_scan/ble_scan_state.dart';
import 'package:pulse_skadi/features/training/presentation/pages/training_programs_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.0, 1.0, curve: Curves.easeOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _showNotifications() {
    HapticFeedback.mediumImpact();
    _showModernDialog(
      '📢 Notifications',
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNotificationItem('🎖️', 'New Achievement', 'Precision Master'),
          _buildNotificationItem('⏰', 'Reminder', 'Session in 2 hours'),
          _buildNotificationItem('📊', 'Weekly Report', 'View progress'),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(String icon, String title, String subtitle) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.kPrimaryTeal.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(icon, style: const TextStyle(fontSize: 12)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.kTextPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.kTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  void _showModernDialog(String title, Widget content) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.kSurface,
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: AppColors.kTextSecondary.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.kPrimaryTeal,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.notifications_active,
                        color: AppColors.kTextPrimary, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: AppColors.kTextPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close,
                          color: AppColors.kTextPrimary, size: 16),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: content,
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.kTextSecondary.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Dismiss',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.kTextPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          HapticFeedback.lightImpact();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.kPrimaryTeal,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'View All',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.kTextPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _hapticFeedback() {
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBackground,
      appBar: customAppBar(
          title: 'Pulse Skadi', context: context, showBackButton: false),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _buildWelcomeSection(),
              ),
            ),
            SliverToBoxAdapter(child: _buildPerformanceMetrics()),
            SliverToBoxAdapter(child: _buildStartTrainingCTA()),
            SliverToBoxAdapter(child: _buildQuickActionsGrid()),
            SliverToBoxAdapter(child: _buildProgramOverview()),
            SliverToBoxAdapter(child: _buildAIInsights()),
            SliverToBoxAdapter(child: _buildGoalsProgress()),
            const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
          ],
        ),
      ),
    );
  }

  Widget _buildModernAppBar() => SliverAppBar(
        expandedHeight: 80,
        floating: false,
        pinned: true,
        backgroundColor: Colors.transparent,
        flexibleSpace: FlexibleSpaceBar(
          background: Container(
            color: AppColors.kSurface,
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        _hapticFeedback();
                        _showNotifications();
                      },
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) => Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.kPrimaryTeal.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: AppColors.kTextSecondary
                                      .withOpacity(0.3)),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(
                                  Icons.notifications_none,
                                  color: AppColors.kTextPrimary,
                                  size: 16,
                                ),
                                Positioned(
                                  right: 2,
                                  top: 2,
                                  child: Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: AppColors.kError,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'PulseSkadi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.kTextPrimary,
                      ),
                    ),
                    const Spacer(flex: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.kPrimaryTeal.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.kTextSecondary.withOpacity(0.3)),
                      ),
                      child: Icon(
                        Icons.account_circle,
                        color: AppColors.kTextPrimary,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  Widget _buildWelcomeSection() => Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.kSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.kPrimaryTeal.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.kPrimaryTeal.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppColors.kTextSecondary.withOpacity(0.3)),
                  ),
                  child: Icon(
                    Icons.military_tech,
                    color: AppColors.kTextPrimary,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.kTextPrimary,
                        ),
                      ),
                      Text(
                        'Your training program',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.kTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildConnectionStatus(),
          ],
        ),
      );

  Widget _buildConnectionStatus() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.kBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.kTextSecondary.withOpacity(0.3)),
        ),
        child: BlocBuilder<BleScanBloc, BleScanState>(
          builder: (context, state) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: state.isConnected
                        ? AppColors.kSuccess
                        : AppColors.kError,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  state.isConnected
                      ? 'RT Sensor Connected'
                      : 'Connect RT Sensor',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.kTextPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                if (!state.isConnected)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.kPrimaryTeal,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Connect',
                      style: TextStyle(
                        color: AppColors.kTextPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      );

  Widget _buildPerformanceMetrics() => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Performance'),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: Wrap(
                runSpacing: 12,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  _buildModernMetricCard('87.4', 'Precision Avg', '+5.2% MoM',
                      AppColors.kSuccess, Icons.trending_up),
                  _buildModernMetricCard('24', 'Sessions', '8.2h total',
                      AppColors.kPrimaryTeal, Icons.schedule),
                  _buildModernMetricCard('89%', 'Consistency', '+7% improved',
                      AppColors.kPrimaryTeal, Icons.confirmation_num),
                  _buildModernMetricCard('12', 'Streak', 'New Record!',
                      AppColors.kSuccess, Icons.local_fire_department),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildModernMetricCard(String value, String label, String subtitle,
          Color accentColor, IconData icon) =>
      Container(
        padding: const EdgeInsets.all(12),
        width: 160,
        decoration: BoxDecoration(
          color: AppColors.kSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accentColor.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: accentColor, size: 16),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.kTextPrimary,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: AppColors.kTextSecondary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 8,
                color: accentColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );

  Widget _buildStartTrainingCTA() => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Quick Start'),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                _hapticFeedback();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => TrainingProgramsPage()),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.kError,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.kError.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.play_arrow,
                      color: AppColors.kTextPrimary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Start Training',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.kTextPrimary,
                          ),
                        ),
                        Text(
                          'Choose program',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.kTextSecondary,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: AppColors.kTextPrimary,
                      size: 12,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildQuickActionsGrid() => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Actions'),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                runSpacing: 12,
                children: [
                  _buildModernActionCard(Icons.library_books, 'Programs',
                      'View all', () => _hapticFeedback()),
                  _buildModernActionCard(Icons.analytics, 'Analytics',
                      'Track progress', () => _hapticFeedback()),
                  _buildModernActionCard(Icons.settings, 'Gear', 'Configure',
                      () => _hapticFeedback()),
                  _buildModernActionCard(Icons.emoji_events, 'Achievements',
                      'View rewards', () => _hapticFeedback()),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildModernActionCard(
          IconData icon, String title, String subtitle, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          // width: 150,
          decoration: BoxDecoration(
            color: AppColors.kSurface,
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: AppColors.kTextSecondary.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.kPrimaryTeal, size: 16),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.kTextPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 8,
                  color: AppColors.kTextSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

  Widget _buildProgramOverview() => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Progress'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.kSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.kTextSecondary.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.trending_up,
                          color: AppColors.kSuccess, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Program Overview',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.kTextPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                          child: _buildModernMetric('3', 'Active Goals',
                              Icons.flag, AppColors.kPrimaryTeal)),
                      Expanded(
                          child: _buildModernMetric('12', 'Achievements',
                              Icons.emoji_events, AppColors.kSuccess)),
                      Expanded(
                          child: _buildModernMetric('Top 15%', 'Ranking',
                              Icons.leaderboard, AppColors.kSuccess)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.kSuccess.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'You\'re performing well! Consider increasing training frequency.',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.kSuccess,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildModernMetric(
          String value, String label, IconData icon, Color color) =>
      Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.kTextPrimary,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: AppColors.kTextSecondary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _buildAIInsights() => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('AI Insights'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.kSurface,
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppColors.kPrimaryTeal.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.psychology,
                          color: AppColors.kTextPrimary, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'ShoQ AI Insight',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.kTextPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.kPrimaryTeal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '"Your shot grouping is 23% tighter. Increase session frequency to 5x/week."',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.kTextPrimary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildGoalsProgress() => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Goals'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.kSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.kTextSecondary.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.flag, color: AppColors.kSuccess, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Goals Progress',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.kTextPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildModernGoalItem(
                    'Accuracy Master',
                    '3/5 sessions',
                    'On Track',
                    true,
                    AppColors.kSuccess,
                  ),
                  Divider(height: 1, color: AppColors.kTextSecondary),
                  _buildModernGoalItem(
                    'Training Streak',
                    '12/14 days',
                    'Almost There!',
                    false,
                    AppColors.kPrimaryTeal,
                  ),
                  Divider(height: 1, color: AppColors.kTextSecondary),
                  _buildModernGoalItem(
                    'Group Master',
                    '15.2mm (Target: 10mm)',
                    'Improving',
                    true,
                    AppColors.kPrimaryTeal,
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildModernGoalItem(String title, String progress, String status,
          bool isOnTrack, Color color) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: color, size: 12),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.kTextPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    progress,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.kTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildSectionHeader(String title) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.kPrimaryTeal,
        ),
      ));
}

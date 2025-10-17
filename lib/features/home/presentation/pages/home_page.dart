import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pulse_skadi/core/theme/app_colors.dart';
import 'package:pulse_skadi/core/utils/constants.dart';
import 'package:pulse_skadi/core/widgets/custom_appbar.dart';
import 'package:pulse_skadi/core/widgets/primary_button.dart';
import 'package:pulse_skadi/features/training/presentation/bloc/ble_scan/ble_scan_bloc.dart';
import 'package:pulse_skadi/features/training/presentation/bloc/ble_scan/ble_scan_state.dart';
import 'package:pulse_skadi/features/training/presentation/pages/training_programs_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

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
    _fadeController.dispose();
    super.dispose();
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
      body: Padding(
        padding: hPadding,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
                child: FadeTransition(
                    opacity: _fadeAnimation, child: _buildWelcomeSection())),
            SliverToBoxAdapter(child: _buildPerformanceMetrics()),
            SliverToBoxAdapter(child: _buildStartTrainingCTA()),
            SliverToBoxAdapter(child: _buildAIInsights())
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() => Container(
        padding: const EdgeInsets.all(16),
        margin: EdgeInsets.symmetric(vertical: 8),
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
                          fontSize: 14,
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
                      : 'RT Sensor Not Connected',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.kTextPrimary),
                ),
                const SizedBox(width: 8),
              ],
            );
          },
        ),
      );

  Widget _buildPerformanceMetrics() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Performance'),
          const SizedBox(height: 8),
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
              ],
            ),
          ),
        ],
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
                fontSize: 12,
                color: AppColors.kTextSecondary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: accentColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );

  Widget _buildStartTrainingCTA() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _buildSectionHeader('Quick Start'),
          const SizedBox(height: 8),
          // GestureDetector(
          //   onTap: () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(builder: (context) => TrainingProgramsPage()),
          //     );
          //   },
          //   child: Container(
          //     padding: const EdgeInsets.all(12),
          //     decoration: BoxDecoration(
          //       color: AppColors.kError,
          //       borderRadius: BorderRadius.circular(12),
          //       border: Border.all(color: AppColors.kError.withOpacity(0.3)),
          //     ),
          //     child: Row(
          //       mainAxisAlignment: MainAxisAlignment.center,
          //       children: [
          //         Icon(
          //           Icons.play_arrow,
          //           color: AppColors.kTextPrimary,
          //           size: 16,
          //         ),
          //         const SizedBox(width: 8),
          //         Column(
          //           crossAxisAlignment: CrossAxisAlignment.start,
          //           children: [
          //             Text(
          //               'Start Training',
          //               style: TextStyle(
          //                 fontSize: 14,
          //                 fontWeight: FontWeight.bold,
          //                 color: AppColors.kTextPrimary,
          //               ),
          //             ),
          //             Text(
          //               'Choose program',
          //               style: TextStyle(
          //                 fontSize: 10,
          //                 color: AppColors.kTextSecondary,
          //               ),
          //             ),
          //           ],
          //         ),
          //         const Spacer(),
          //         Icon(
          //           Icons.arrow_forward_ios,
          //           color: AppColors.kTextPrimary,
          //           size: 12,
          //         ),
          //       ],
          //     ),
          //   ),
          // ),
          Row(children: [
            Expanded(
              child: PrimaryButton(
                title: 'Dry Fire',
                buttonColor: AppColors.kRedColor,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => TrainingProgramsPage()),
                  );
                },
              ),
            ),
            SizedBox(width: 8),
            Expanded(
                child: PrimaryButton(
              title: 'Live Fire',
              buttonColor: AppColors.kRedColor,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => TrainingProgramsPage()),
                );
              },
            ))
          ])
        ],
      );

  Widget _buildAIInsights() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _buildSectionHeader('ShoQ® Insight'),
          const SizedBox(height: 8),
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
                        'ShoQ® Insight',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.kTextPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
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
                      fontSize: 12,
                      color: AppColors.kTextPrimary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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

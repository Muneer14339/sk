import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/services/prefs.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/dialog_utils.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../core/widgets/custom_appbar.dart';
import '../../../core/widgets/custom_dialog.dart';
import '../../../core/widgets/icon_container.dart';
import '../../../armory/presentation/bloc/armory_bloc.dart';
import '../../../armory/presentation/bloc/armory_event.dart';
import '../../../armory/presentation/bloc/armory_state.dart';
import '../../data/datasources/ProgramsDataSource.dart';
import '../../data/model/programs_model.dart';
import '../../../injection_container.dart' as di;
import '../bloc/ble_scan/ble_scan_bloc.dart';
import '../bloc/ble_scan/ble_scan_event.dart';
import '../bloc/ble_scan/ble_scan_state.dart';
import '../bloc/training_session/training_session_bloc.dart';
import '../bloc/training_session/training_session_event.dart';
import '../widgets/device_calibration_dialog.dart';
import '../widgets/matrics_section_card.dart';
import '../widgets/program_stats_card.dart';
import 'steadiness_trainer_page.dart';
import 'training_program_builder.dart';

class TrainingProgramsPage extends StatefulWidget {
  const TrainingProgramsPage({super.key});

  @override
  _TrainingProgramsPageState createState() => _TrainingProgramsPageState();
}

class _TrainingProgramsPageState extends State<TrainingProgramsPage> with TickerProviderStateMixin {
  String selectedFilter = 'beginner';
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  ProgramsModel? _defaultProgram;

  @override
  void initState() {
    super.initState();
    context.read<ArmoryBloc>().add(LoadLoadoutsEvent(userId: userId));
    _loadDefaultProgram();
  }

  Future<void> _loadDefaultProgram() async {
    final programs = await di.sl<ProgramsDataSource>().getPrograms();
    if (programs.isNotEmpty && mounted) {
      setState(() => _defaultProgram = programs.first);
    }
  }

  void _hapticFeedback() {
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildGearStatusBanner(),
                  const SizedBox(height: 24),
                  _buildQuickStartSection(),
                  const SizedBox(height: 24),
                  _buildRecentPrograms(),
                  const SizedBox(height: 24),
                  _buildModernFilterTabs(),
                  const SizedBox(height: 24),
                  FutureBuilder<List<ProgramsModel>>(
                    future: di.sl<ProgramsDataSource>().getPrograms(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        if (snapshot.hasError) {
                          return _buildErrorState('Failed to load programs: ${snapshot.error}');
                        } else {
                          return _buildProgramsList(snapshot.data ?? []);
                        }
                      } else {
                        return _buildLoadingState();
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildCreateCustomButton(),
                  const SizedBox(height: 100),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.transparent, AppColors.kError..withValues(alpha: .05)],
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.kError..withValues(alpha: .2)),
    ),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.kError..withValues(alpha: .1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.error_outline, color: AppColors.kError, size: 32),
        ),
        const SizedBox(height: 16),
        Text('Loading Error', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.kTextPrimary)),
        const SizedBox(height: 8),
        Text(error, style: TextStyle(fontSize: 14, color: AppColors.kTextSecondary, height: 1.4), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => setState(() {}),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.kPrimaryTeal, AppColors.kPrimaryTeal..withValues(alpha: .8)]),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Text('Retry', style: TextStyle(color: AppColors.kTextPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    ),
  );

  Widget _buildLoadingState() => Container(
    padding: const EdgeInsets.all(40),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.kPrimaryTeal..withValues(alpha: .1), Colors.transparent]),
            shape: BoxShape.circle,
          ),
          child: SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.kPrimaryTeal), strokeWidth: 3),
          ),
        ),
        const SizedBox(height: 16),
        Text('Loading Programs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.kTextPrimary)),
        const SizedBox(height: 8),
        Text('Preparing your training catalog...', style: TextStyle(fontSize: 14, color: AppColors.kTextSecondary)),
      ],
    ),
  );

  Widget _buildGearStatusBanner() => BlocBuilder<ArmoryBloc, ArmoryState>(
    builder: (context, state) {
      final loadouts = state is LoadoutsLoaded ? state.loadouts : [];
      final currentLoadout = loadouts.isNotEmpty ? loadouts.first : null;

      return GestureDetector(
        onTap: () {
          _hapticFeedback();
          _openGearSetup();
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.kPrimaryTeal.withValues(alpha: .4),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.kPrimaryTeal.withValues(alpha: .4),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.settings, color: AppColors.kTextPrimary, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current Setup',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.kTextPrimary..withValues(alpha: .9),
                                ),
                              ),
                              Text(
                                currentLoadout?.name ?? 'No Loadout Selected',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.kTextPrimary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentLoadout != null ? '${currentLoadout.notes ?? "Ready to train"}' : 'Configure a loadout to start',
                      style: TextStyle(fontSize: 13, color: AppColors.kTextPrimary..withValues(alpha: .8), height: 1.3),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.kPrimaryTeal.withValues(alpha: .4),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(Icons.arrow_forward_ios, color: AppColors.kTextPrimary, size: 16),
              ),
            ],
          ),
        ),
      );
    },
  );

  Widget _buildQuickStartSection() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppColors.kSurface, borderRadius: BorderRadius.circular(8)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconContainer(icon: Icons.bolt),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quick Start', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.kTextPrimary)),
                  Text(
                    'Jump right into training with your current setup',
                    style: TextStyle(fontSize: 12, color: AppColors.kTextSecondary, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        BlocBuilder<BleScanBloc, BleScanState>(
          builder: (_, state) => _buildModernQuickStartButton(
            'Start Precision Training',
            state.isConnected ? AppColors.kSuccess : AppColors.greyColor,
            state,
          ),
        )
      ],
    ),
  );

  Widget _buildModernQuickStartButton(String title, Color color, BleScanState state) => GestureDetector(
    onTap: () {
      if (_defaultProgram == null) {
        ToastUtils.showError(context, message: 'Please create a program first');
        return;
      }

      if (state.isConnected && state.needsCalibration) {
        _showCalibrationDialog(context, state.connectedDevice!, _defaultProgram!);
      } else if (state.isConnected) {
        Navigator.push(context, MaterialPageRoute(builder: (context) => SteadinessTrainerPage(program: _defaultProgram!)));
      } else {
        _showBleDeviceDialog(context);
      }
    },
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: Center(
        child: Text(title, style: TextStyle(color: AppColors.kTextPrimary, fontSize: 16, fontWeight: FontWeight.w500)),
      ),
    ),
  );

  Widget _buildRecentPrograms() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.kSurface,
      borderRadius: BorderRadius.circular(8),
      boxShadow: [BoxShadow(color: Colors.black..withValues(alpha: .2), blurRadius: 20, offset: const Offset(0, 8))],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconContainer(icon: Icons.history),
            const SizedBox(width: 16),
            Expanded(child: Text('Recently Used', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.kTextPrimary))),
          ],
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<ProgramsModel>>(
          future: di.sl<ProgramsDataSource>().getPrograms(),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              final recentPrograms = snapshot.data!.take(2).toList();
              return Column(
                children: [
                  ...recentPrograms.asMap().entries.map((entry) {
                    final program = entry.value;
                    return Column(
                      children: [
                        if (entry.key > 0) const SizedBox(height: 12),
                        _buildModernRecentProgramItem(
                          '🎯',
                          program.programName ?? 'Training Program',
                          'Tap to start',
                          AppColors.kPrimaryTeal,
                          program,
                        ),
                      ],
                    );
                  }).toList(),
                ],
              );
            } else {
              return Center(
                child: Text(
                  'No recent programs',
                  style: TextStyle(fontSize: 14, color: AppColors.kTextSecondary),
                ),
              );
            }
          },
        ),
      ],
    ),
  );

  Widget _buildModernRecentProgramItem(String icon, String title, String subtitle, Color accentColor, ProgramsModel program) => GestureDetector(
    onTap: () {
      _hapticFeedback();
      _navigateToTrainingPage(context, program);
    },
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: AppColors.kSurface, borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: accentColor..withValues(alpha: .1), borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(icon, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.kTextPrimary))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.kTextPrimary)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(1),
                      decoration: BoxDecoration(color: accentColor..withValues(alpha: .1), shape: BoxShape.circle),
                      child: Icon(Icons.star, size: 12),
                    ),
                    const SizedBox(width: 6),
                    Text(subtitle, style: TextStyle(fontSize: 13, color: AppColors.kTextSecondary)),
                  ],
                ),
              ],
            ),
          ),
          IconContainer(icon: Icons.arrow_forward_ios),
        ],
      ),
    ),
  );

  Widget _buildModernFilterTabs() => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.kSurface, AppColors.kBackground],
      ),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.kTextSecondary..withValues(alpha: .3)),
    ),
    child: Row(
      children: [
        _buildModernFilterTab('Beginner', 'beginner'),
        _buildModernFilterTab('Intermediate', 'intermediate'),
        _buildModernFilterTab('Advanced', 'advanced'),
      ],
    ),
  );

  Widget _buildModernFilterTab(String title, String filter) {
    final isActive = selectedFilter == filter;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _hapticFeedback();
          setState(() => selectedFilter = filter);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          margin: const EdgeInsets.only(right: 2),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                isActive ? AppColors.kPrimaryTeal : AppColors.kTextSecondary,
                isActive ? AppColors.kPrimaryTeal.withValues(alpha: .8) : AppColors.kTextSecondary..withValues(alpha: .8)
              ],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isActive ? AppColors.kPrimaryTeal : AppColors.kTextSecondary..withValues(alpha: .3)),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.kTextPrimary, fontSize: 12, fontWeight: isActive ? FontWeight.w500 : FontWeight.w400),
          ),
        ),
      ),
    );
  }

  Widget _buildProgramsList(List<ProgramsModel> programs) {
    final filteredPrograms = programs.where((program) {
      if (selectedFilter == 'all') return true;
      return program.difficultyLevel?.toLowerCase() == selectedFilter;
    }).toList();

    if (filteredPrograms.isEmpty) {
      return _buildEmptyProgramsState();
    }

    return Column(
      children: filteredPrograms.map((program) => Padding(padding: const EdgeInsets.only(bottom: 16), child: _buildModernProgramCard(program))).toList(),
    );
  }

  Widget _buildEmptyProgramsState() => Container(
    padding: const EdgeInsets.all(40),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.transparent, AppColors.kPrimaryTeal..withValues(alpha: .05)],
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.kPrimaryTeal..withValues(alpha: .2)),
    ),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.kPrimaryTeal..withValues(alpha: .1), Colors.transparent]), shape: BoxShape.circle),
          child: Icon(Icons.library_books_outlined, color: AppColors.kPrimaryTeal, size: 48),
        ),
        const SizedBox(height: 16),
        Text('No Programs Found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.kTextPrimary)),
        const SizedBox(height: 8),
        Text('Try adjusting your filters or create a custom program', style: TextStyle(fontSize: 14, color: AppColors.kTextSecondary), textAlign: TextAlign.center),
      ],
    ),
  );

  Widget _buildModernProgramCard(ProgramsModel program) => Stack(
    children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.kSurface, borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.kPrimaryTeal, AppColors.kPrimaryTeal..withValues(alpha: .7)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.place, color: AppColors.kTextPrimary, size: 28),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(program.programName ?? '', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.kTextPrimary)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [AppColors.kPrimaryTeal, AppColors.kPrimaryTeal..withValues(alpha: .8)]),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text((program.difficultyLevel ?? '').toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.kTextPrimary)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(program.trainingType ?? '', style: TextStyle(fontSize: 13, color: AppColors.kTextSecondary, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(program.programDescription ?? '', style: TextStyle(color: AppColors.kTextSecondary, fontSize: 14, height: 1.5)),
            const SizedBox(height: 20),
            _buildModernProgramSpecs(program),
            const SizedBox(height: 20),
            const MetricsSectionCard(),
            const ProgramStatsCard(),
            const SizedBox(height: 16),
            _buildModernProgramActions(program),
          ],
        ),
      ),
      if (program.badgeColor != null)
        Positioned(
          top: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Color(int.parse(program.badgeColor ?? '0xFF00CED1')), borderRadius: BorderRadius.circular(12)),
            child: Text(program.badge ?? '', style: TextStyle(color: AppColors.kTextPrimary, fontSize: 11, fontWeight: FontWeight.w500)),
          ),
        ),
    ],
  );

  Widget _buildModernProgramSpecs(ProgramsModel program) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.kSurface..withValues(alpha: .5), AppColors.kBackground..withValues(alpha: .5)],
      ),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.kPrimaryTeal.withValues(alpha: .08)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.kPrimaryTeal..withValues(alpha: .2), Colors.transparent]), shape: BoxShape.circle),
              child: Icon(Icons.build, color: AppColors.kPrimaryTeal, size: 18),
            ),
            const SizedBox(width: 12),
            Text('Recommended Setup', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.kTextPrimary)),
          ],
        ),
        const SizedBox(height: 16),
        _buildModernSpecRow('Loadout', program.weaponProfile?.name ?? 'Not specified', Icons.local_fire_department),
        _buildModernSpecRow('Distance', program.recommenedDistance ?? 'Not specified', Icons.straighten),
        _buildModernSpecRow('Notes', program.weaponProfile?.notes ?? 'No notes', Icons.edit),
        _buildModernSpecRow('Threshold', program.successThreshold ?? 'Not set', Icons.check_circle_outline),
      ],
    ),
  );

  Widget _buildModernSpecRow(String label, String value, IconData icon) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: AppColors.kPrimaryTeal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: AppColors.kPrimaryTeal, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: AppColors.kTextSecondary, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(fontSize: 13, color: AppColors.kTextPrimary, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildModernProgramActions(ProgramsModel program) => BlocBuilder<BleScanBloc, BleScanState>(
    builder: (context, state) => Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              if (state.isConnected && state.needsCalibration) {
                _showCalibrationDialog(context, state.connectedDevice!, program);
              } else if (state.isConnected) {
                _navigateToTrainingPage(context, program);
              } else {
                _showBleDeviceDialog(context, program: program);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.kError, AppColors.kError..withValues(alpha: .8)],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.kError..withValues(alpha: .3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [AppColors.kTextPrimary..withValues(alpha: .2), Colors.transparent]),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.play_arrow, color: AppColors.kTextPrimary, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Text('Start Training', style: TextStyle(color: AppColors.kTextPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<ArmoryBloc>(), // if already provided higher up
                child: const TrainingProgramBuilder(),
              ),
            ),
          )
          ,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.kTextSecondary, AppColors.kTextSecondary..withValues(alpha: .8)]),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.kTextSecondary..withValues(alpha: .3)),
            ),
            child: Icon(Icons.edit, color: AppColors.kTextPrimary, size: 18),
          ),
        ),
      ],
    ),
  );

  Widget _buildCreateCustomButton() => BlocBuilder<ArmoryBloc, ArmoryState>(
    builder: (context, state) {
      final loadouts = state is LoadoutsLoaded ? state.loadouts : [];
      return GestureDetector(
        onTap: () {
          if (loadouts.isEmpty) {
            _showNoLoadoutsDialog();
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: context.read<ArmoryBloc>(), // if already provided higher up
                  child: const TrainingProgramBuilder(),
                ),
              ),
            );
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.kSurface, AppColors.kPrimaryTeal..withValues(alpha: .8)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconContainer(icon: Icons.add),
              const SizedBox(width: 12),
              Text('Create Custom Program', style: TextStyle(color: AppColors.kTextPrimary, fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      );
    },
  );

  void _showNoLoadoutsDialog() => showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.kSurface, AppColors.kBackground]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.kTextSecondary..withValues(alpha: .3)),
          boxShadow: [BoxShadow(color: Colors.black..withValues(alpha: .4), blurRadius: 30, spreadRadius: 0)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.kPrimaryTeal, AppColors.kPrimaryTeal..withValues(alpha: .8)]),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: AppColors.kTextPrimary, size: 24),
                  const SizedBox(width: 12),
                  Expanded(child: Text('No Loadouts Configured', style: TextStyle(color: AppColors.kTextPrimary, fontSize: 18, fontWeight: FontWeight.w500))),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    'To create custom training programs, you need to configure at least one loadout.',
                    style: TextStyle(fontSize: 15, color: AppColors.kTextPrimary, height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(color: AppColors.kTextSecondary, borderRadius: BorderRadius.circular(12)),
                            child: Text('Cancel', textAlign: TextAlign.center, style: TextStyle(color: AppColors.kTextSecondary, fontWeight: FontWeight.w500)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            _openGearSetup();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [AppColors.kSuccess, AppColors.kSuccess..withValues(alpha: .8)]),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [BoxShadow(color: AppColors.kSuccess..withValues(alpha: .3), blurRadius: 8, offset: const Offset(0, 2))],
                            ),
                            child: Text('Add Loadout', textAlign: TextAlign.center, style: TextStyle(color: AppColors.kTextPrimary, fontWeight: FontWeight.w500)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  void _openGearSetup() {
    //Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const BottomNavPage(initialIndex: 1)), (route) => false);
  }

  void _showBleDeviceDialog(BuildContext context, {ProgramsModel? program}) async {
    context.read<BleScanBloc>().add(const StartBleScan());
    showDialog(
      context: context,
      builder: (_) => BlocConsumer<BleScanBloc, BleScanState>(
        listener: (ctx, state) {
          if (state.isConnected && state.needsCalibration) {
            context.read<TrainingSessionBloc>().add(SendCommand(
              ditCommand: 2,
              dvcCommand: 1,
              swdCommand: 1,
              swbdCommand: 1,
              avdCommand: 1,
              avdtCommand: 1,
              hapticCommand: 1,
              device: state.connectedDevice!,
            ));
            String sensitivity = '2/1/1/1/1/1/1';
            prefs?.setString(sensitivityKey, sensitivity);
            Navigator.of(context).pop();
            _showCalibrationDialog(context, state.connectedDevice!, program);
          } else if (state.isConnected) {
            context.read<TrainingSessionBloc>().add(SendCommand(
              ditCommand: 2,
              dvcCommand: 1,
              swdCommand: 1,
              swbdCommand: 1,
              avdCommand: 1,
              avdtCommand: 1,
              hapticCommand: 1,
              device: state.connectedDevice!,
            ));
            String sensitivity = '2/1/1/1/1/1/1';
            prefs?.setString(sensitivityKey, sensitivity);
            Navigator.of(context).pop();
            if (program != null) {
              _navigateToTrainingPage(context, program);
            } else if (_defaultProgram != null) {
              DialogUtils.showConfirmationDialog(
                context: context,
                title: 'Device Connected',
                message: 'Battery Level: ${state.deviceInfo?['batteryLevel']}%\n\nCurrent settings: ${state.sensitivity}\n\nContinue with default training program?',
                confirmText: 'Continue',
                cancelText: 'Cancel',
                confirmColor: AppColors.kSuccess,
              ).then((value) {
                if (value) {
                  _navigateToTrainingPage(context, _defaultProgram!);
                }
              });
            } else {
              ToastUtils.showError(context, message: 'Please create a program first');
            }
          } else if (state.error != null && !state.isConnecting) {
            _showConnectionErrorDialog(context, state.error!);
          }
        },
        builder: (__, state) => ModernCustomDialog(
          title: 'Select Device',
          onItemSelected: (device) {
            if (mounted) {
              context.read<BleScanBloc>().add(const StopBleScan());
              context.read<BleScanBloc>().add(ConnectToDevice(device: device));
            }
          },
          state: state,
        ),
      ),
    );
  }

  void _showCalibrationDialog(BuildContext context, BluetoothDevice device, ProgramsModel? program) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => DeviceCalibrationDialog(
        onStartCalibration: () async {
          context.read<TrainingSessionBloc>().add(EnableSensors(device: device));
          await Future.delayed(const Duration(seconds: 6));
          context.read<BleScanBloc>().add(const MarkCalibrationComplete());
          Navigator.of(context).pop();
          if (program != null) {
            _navigateToTrainingPage(context, program);
          } else if (_defaultProgram != null) {
            DialogUtils.showConfirmationDialog(
              context: context,
              title: 'Calibration Complete',
              message: 'Device is ready for training.',
              confirmText: 'Start Training',
              cancelText: 'Cancel',
              confirmColor: AppColors.kSuccess,
            ).then((value) {
              if (value) {
                _navigateToTrainingPage(context, _defaultProgram!);
              }
            });
          }
        },
        onFactoryReset: () async {
          await context.read<TrainingSessionBloc>().bleRepository.factoryReset(device);
          ToastUtils.showSuccess(context, message: 'Factory reset completed');
        },
      ),
    );
  }

  void _showConnectionErrorDialog(BuildContext context, String error) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.kSurface,
        title: Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.kError),
            const SizedBox(width: 8),
            Text('Connection Error', style: TextStyle(color: AppColors.kTextPrimary)),
          ],
        ),
        content: Text(error, style: TextStyle(color: AppColors.kTextSecondary)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.kPrimaryTeal),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _navigateToTrainingPage(BuildContext context, ProgramsModel program) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => SteadinessTrainerPage(program: program)));
  }
}
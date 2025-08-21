import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pulse_skadi/core/theme/app_colors.dart';
import 'package:pulse_skadi/core/utils/dialog_utils.dart';
import 'package:pulse_skadi/core/utils/toast_utils.dart';
import 'package:pulse_skadi/core/widgets/custom_dialog.dart';
import 'package:pulse_skadi/features/bottom_nav/presentation/pages/bottom_nav_page.dart';
import 'package:pulse_skadi/features/firearm/data/remote/service/firebase_service.dart';
import 'package:pulse_skadi/features/gear_setup/presentation/bloc/gear_setup_bloc.dart';
import 'package:pulse_skadi/features/gear_setup/presentation/pages/gear_setup_page.dart';
import 'package:pulse_skadi/features/training/data/model/programs_model.dart';
import 'package:pulse_skadi/features/training/presentation/bloc/ble_scan/ble_scan_bloc.dart';
import 'package:pulse_skadi/features/training/presentation/bloc/ble_scan/ble_scan_event.dart';
import 'package:pulse_skadi/features/training/presentation/bloc/ble_scan/ble_scan_state.dart';
import 'package:pulse_skadi/features/training/presentation/bloc/training_session/training_session_bloc.dart';
import 'package:pulse_skadi/features/training/presentation/bloc/training_session/training_session_event.dart';
import 'package:pulse_skadi/features/training/presentation/pages/live_training.dart';
import 'package:pulse_skadi/features/training/presentation/pages/training_program_builder.dart';
import 'package:pulse_skadi/features/training/presentation/widgets/matrics_section_card.dart';
import 'package:pulse_skadi/features/training/presentation/widgets/program_stats_card.dart';

class TrainingProgramsPage extends StatefulWidget {
  const TrainingProgramsPage({super.key});

  @override
  _TrainingProgramsPageState createState() => _TrainingProgramsPageState();
}

class _TrainingProgramsPageState extends State<TrainingProgramsPage>
    with TickerProviderStateMixin {
  // Service locator is now available globally

  String selectedFilter = 'beginner';
  // late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    context.read<GearSetupBloc>().add(LoadFirearmSetups());
    // _animationController =
    //     AnimationController(duration: Duration(milliseconds: 300), vsync: this);
    // _animationController.forward();
  }

  @override
  void dispose() {
    // _animationController.dispose();
    super.dispose();
  }

  void _hapticFeedback() {
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2C3E50), Color(0xFF2C3E50)])),
        child: SafeArea(
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [_buildHeader(), Expanded(child: _buildContent())],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(color: Color(0xFF2C3E50), boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: 5,
          offset: Offset(0, 2),
        )
      ]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(width: 20),
          Text('Training',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Color(0xFFECF0F1),
                  fontSize: 20,
                  fontWeight: FontWeight.w600)),
          GestureDetector(
              onTap: () {
                _openGearSetup();
              },
              child: Container(
                  padding: EdgeInsets.all(5),
                  child: Text('⚙️', style: TextStyle(fontSize: 20)))),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            _buildGearStatusBanner(),
            SizedBox(height: 20),
            _buildQuickStartSection(),
            SizedBox(height: 20),
            _buildRecentPrograms(),
            SizedBox(height: 20),
            _buildFilterTabs(),
            SizedBox(height: 20),
            FutureBuilder<List<ProgramsModel>>(
                future: FirebaseService().getPrograms(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Error: ${snapshot.error}'),
                      );
                    } else {
                      return _buildProgramsList(snapshot.data!);
                    }
                  } else {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                }),
            SizedBox(height: 20),
            _buildCreateCustomButton(),
            SizedBox(height: 100), // Space for bottom nav
          ],
        ),
      ),
    );
  }

  Widget _buildGearStatusBanner() {
    return GestureDetector(
      onTap: () {
        _hapticFeedback();
        _openGearSetup();
      },
      child: Container(
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF28A745), Color(0xFF20C997)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF28A745).withValues(alpha: 0.3),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '⚙️ Current Setup: Glock 19 + Red Dot',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    '115gr 9mm • Iron Sights + Red Dot • Ready to train',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '→',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStartSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Color(0xFFE9ECEF)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('⚡', style: TextStyle(fontSize: 18)),
              SizedBox(width: 8),
              Text(
                'Quick Start',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Jump right into training with your current setup',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6C757D),
              height: 1.4,
            ),
          ),
          SizedBox(height: 15),
          BlocBuilder<BleScanBloc, BleScanState>(
            builder: (_, state) {
              return _buildQuickStartButton(
                  state.isConnected ? '🎯' : '🔄',
                  state.isConnected
                      ? 'Start Live Training'
                      : 'Connect RT Sensor',
                  state.isConnected ? Color(0xFFE74C3C) : Color(0xFF2C3E50),
                  () {
                // _navigateToTrainingPage(context);

                if (state.isConnected) {
                  // _navigateToTrainingPage(context);
                  DialogUtils.showConfirmationDialog(
                    context: context,
                    title: 'Device Connected',
                    message: 'Contine with default training program?',
                    confirmText: 'Continue',
                    cancelText: 'Cancel',
                    confirmColor: Colors.green,
                  ).then((value) {
                    if (value) {
                      if (context.mounted) {
                        _navigateToTrainingPage(context, systemPrograms.first);
                      }
                    }
                  });
                } else {
                  _showBleDeviceDialog(context);
                }
              });
            },
          )
        ],
      ),
    );
  }

  Widget _buildQuickStartButton(
      String icon, String text, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: Offset(0, 2))
            ]),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: TextStyle(fontSize: 16)),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentPrograms() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Color(0xFFE9ECEF)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('📋', style: TextStyle(fontSize: 18)),
              SizedBox(width: 8),
              Text(
                'Recently Used',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          SizedBox(height: 15),
          _buildRecentProgramItem('🎯', 'Precision Fundamentals',
              'Last used: Yesterday • Avg: 87 pts'),
          _buildRecentProgramItem(
              '⚡', 'Rapid Fire Control', 'Last used: 3 days ago • Avg: 82 pts'),
        ],
      ),
    );
  }

  Widget _buildRecentProgramItem(String icon, String name, String meta) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  icon,
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    meta,
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6C757D),
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

  Widget _buildFilterTabs() {
    return Container(
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // _buildFilterTab('All Programs', 'all'),
          _buildFilterTab('Beginner', 'beginner'),
          _buildFilterTab('Intermediate', 'intermediate'),
          _buildFilterTab('Advanced', 'advanced'),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String title, String filter) {
    bool isActive = selectedFilter == filter;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _hapticFeedback();
          setState(() {
            selectedFilter = filter;
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: isActive ? Color(0xFF2C3E50) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? Colors.white : Color(0xFF6C757D),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgramsList(List<ProgramsModel> programs) {
    programs.addAll(systemPrograms);
    List<ProgramsModel> filteredPrograms = programs.where((program) {
      if (selectedFilter == 'all') return true;
      log('-sel--$selectedFilter');
      return program.difficultyLevel?.toLowerCase() == selectedFilter;
    }).toList();

    return Column(
      children: [
        ...filteredPrograms.map((program) => _buildProgramCard(program))
      ],
    );
  }

  Widget _buildProgramCard(ProgramsModel program) {
    return Stack(
      children: [
        Container(
            padding: EdgeInsets.all(16),
            margin: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Color(0xFFE9ECEF)),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: Offset(0, 2))
              ],
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('⚙️', style: TextStyle(fontSize: 32)),
                      SizedBox(height: 8),
                      Text(program.programName ?? '',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50))),
                      SizedBox(height: 4),
                      Text(program.type ?? '',
                          style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6C757D),
                              fontWeight: FontWeight.w500))
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: AppColors.kPrimaryColor.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12)),
                  child: Text(program.difficultyLevel.toString().toUpperCase(),
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                )
              ]),
              SizedBox(height: 12),
              Text(program.programDescription ?? '',
                  style: TextStyle(
                      color: Color(0xFF6C757D), fontSize: 14, height: 1.4)),
              SizedBox(height: 15),
              _customProgramSpecs(program),
              SizedBox(height: 15),
              MetricsSectionCard(),
              ProgramStatsCard(),
              SizedBox(height: 6),
              _buildProgramActions(program)
            ])),
        if (program.badgeColor != null)
          Positioned(
              top: 0,
              right: 0,
              child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Color(int.parse(program.badgeColor ?? '0xFFE74C3C')),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(program.badge ?? '',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold))))
      ],
    );
  }

  Widget _customProgramSpecs(ProgramsModel program) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📋 Recommended Setup',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          SizedBox(height: 8),
          Column(
            children: [
              _buildSpecRow(
                  'Firearm:',
                  program.weaponProfile?.name ??
                      program.weaponProfile?.firearm.brand ??
                      ''),
              _buildSpecRow('Distance:', program.recommenedDistance ?? ''),
              _buildSpecRow('Ammunition:',
                  program.weaponProfile?.ammoModel.bulletType ?? ''),
              _buildSpecRow(
                  'Success Threshold:', program.successThreshold ?? ''),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF6C757D),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgramActions(ProgramsModel program) {
    return BlocBuilder<BleScanBloc, BleScanState>(
      builder: (context, state) {
        return Row(
          children: [
            Expanded(
              child: GestureDetector(
                  onTap: () {
                    if (state.isConnected) {
                      _navigateToTrainingPage(context, program);
                    } else {
                      _showBleDeviceDialog(context, program: program);
                    }
                  },
                  child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Color(0xFFE74C3C),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFFE74C3C).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text('▶ Start Training',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold)))),
            ),
            if (program.badge != 'System') SizedBox(width: 10),
            if (program.badge != 'System')
              GestureDetector(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const TrainingProgramBuilder()));
                  },
                  child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Color(0xFF6C757D),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('⚙️',
                          style: TextStyle(color: Colors.white, fontSize: 14))))
          ],
        );
      },
    );
  }

  Widget _buildCreateCustomButton() {
    return BlocBuilder<GearSetupBloc, GearSetupState>(
        builder: (context, state) {
      return GestureDetector(
        onTap: () {
          if (state.firearmSetups?.isEmpty ?? true) {
            DialogUtils.showConfirmationDialog(
                    context: context,
                    title: 'No Firearms Found',
                    message: 'Please add a firearm to create a custom program.',
                    confirmText: 'Add Firearms',
                    cancelText: 'Cancel',
                    confirmColor: Colors.green)
                .then((value) {
              if (value) {
                Navigator.pop(context);
                _openGearSetup();
              }
            });
          } else {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const TrainingProgramBuilder()));
          }
        },
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Color(0xFF2C3E50),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF2C3E50).withValues(alpha: 0.3),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('➕', style: TextStyle(fontSize: 16)),
              SizedBox(width: 8),
              Text(
                'Create Custom Program',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  void _openGearSetup() {
    // HapticFeedback.mediumImpact();
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (context) => const BottomNavPage(initialIndex: 1)),
        (route) => false);
  }

  void _showBleDeviceDialog(BuildContext context, {ProgramsModel? program}) {
    context.read<BleScanBloc>().add(const StartBleScan());

    // HapticFeedback.mediumImpact();

    // Create a new instance of the BLoC

    showDialog(
      context: context,
      builder: (_) => BlocConsumer<BleScanBloc, BleScanState>(
          listener: (ctx, state) {
            if (state.isConnected) {
              Navigator.of(context).pop();
              if (program != null) {
                _navigateToTrainingPage(context, program);
              } else {
                DialogUtils.showConfirmationDialog(
                        context: context,
                        title: 'Device Connected',
                        message: 'Contine with default training program?',
                        confirmText: 'Continue',
                        cancelText: 'Cancel',
                        confirmColor: Colors.green)
                    .then((value) {
                  if (value) {
                    _navigateToTrainingPage(context, systemPrograms.first);
                  }
                });
              }
            } else if (state.error != null) {
              final message = state.error
                  .toString()
                  .replaceAll('BleScanFailure(message: ', '')
                  .replaceAll(')', '');
              // Navigator.of(context).pop();
              ToastUtils.showError(context, message: message);
            }
          },
          builder: (__, state) => ModernCustomDialog(
              title: 'Select Device',
              onItemSelected: (device) {
                if (mounted) {
                  context.read<BleScanBloc>().add(StopBleScan());

                  context
                      .read<BleScanBloc>()
                      .add(ConnectToDevice(device: device));
                }
              },
              state: state)),
    );
  }

  void _navigateToTrainingPage(BuildContext context, ProgramsModel program) {
    context.read<TrainingSessionBloc>().add(ClearTarget());
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => LiveTrainingPage(program: program)));
  }

  void _showTrainingSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Training Settings'),
        content:
            Text('Session duration, difficulty scaling, feedback preferences'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}

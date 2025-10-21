import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/toast_utils.dart';
import '../../data/model/programs_model.dart';
import '../widgets/advanced_tab_data.dart';

class TrainingProgramBuilder extends StatefulWidget {
  const TrainingProgramBuilder({super.key});

  @override
  State<TrainingProgramBuilder> createState() => _TrainingProgramBuilderState();
}

class _TrainingProgramBuilderState extends State<TrainingProgramBuilder>
    with SingleTickerProviderStateMixin {
  // State variables to manage the UI
  String currentMode = 'simple';
  Map<String, dynamic> simpleSettings = {
    'trainingType': 'Dry Fire',
    'focus': 'Accuracy',
    'difficulty': 'Beginner',
    'shots': 10,
    'pressure': 'None',
    'weapon': null,
  };

  ProgramsModel programsModel = ProgramsModel();

  final TextEditingController programNameController = TextEditingController();

  String programDescription =
      'Your custom training program designed for optimal performance.';
  bool isTrainingTypeOpen = false;
  bool isFocusOpen = false;
  bool isDifficultyOpen = false;
  bool isShotsOpen = false;
  bool isPressureOpen = false;
  bool isWeaponOpen = false;

  @override
  void initState() {
    super.initState();
    programsModel = ProgramsModel(
        modeName: currentMode,
        trainingType: simpleSettings['trainingType'],
        focusArea: simpleSettings['focus'],
        difficultyLevel: simpleSettings['difficulty'],
        noOfShots: simpleSettings['shots'],
        timePressure: simpleSettings['pressure'],
        weaponProfile: simpleSettings['weapon'],
        programName: programNameController.text,
        programDescription: programDescription);
  }

  @override
  void dispose() {
    programNameController.dispose();
    super.dispose();
  }

  void switchMode(String mode) {
    setState(() {
      currentMode = mode;
    });
  }

  void _updateSimpleSetting(String key, dynamic value) {
    setState(() {
      simpleSettings[key] = value;
      programsModel = ProgramsModel(
        modeName: currentMode,
        trainingType: simpleSettings['trainingType'],
        focusArea: simpleSettings['focus'],
        difficultyLevel: simpleSettings['difficulty'],
        noOfShots: simpleSettings['shots'],
        timePressure: simpleSettings['pressure'],
        weaponProfile: simpleSettings['weapon'],
        programName: programNameController.text,
        programDescription: programDescription,
      );
    });
  }

  Widget _buildCompactOption({
    required String icon,
    required String title,
    required String description,
    String? metrics, // Optional parameter for metrics text (used in Focus Area)
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap, // Callback when the option is tapped
      child: Container(
        padding: EdgeInsets.all(metrics != null ? 15.0 : 12.0),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFE8F4F8)
              : Colors.white, // Background color based on selection
          border: Border(
            bottom: BorderSide(
              color: isSelected
                  ? Colors.transparent
                  : const Color(0xFFF8F9FA), // Separator line
              width: 1.0,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: metrics != null ? 30.0 : 20.0, // Icon width
              alignment: Alignment.center,
              child: Text(
                icon, // Emoji icon
                style: TextStyle(
                    fontSize: metrics != null ? 24.0 : 18.0), // Icon size
              ),
            ),
            const SizedBox(width: 10), // Spacing between icon and content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: metrics != null ? 16.0 : 14.0,
                      color:
                          isSelected ? const Color(0xFF0C5460) : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12.0,
                      color: Color(0xFF6C757D),
                    ),
                  ),
                  if (metrics != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0x330C5460)
                            : const Color(0xFFF8F9FA), // Metrics background
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        metrics,
                        style: TextStyle(
                          fontSize: 11.0,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? const Color(0xFF0C5460)
                              : const Color(0xFF6C757D),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactSelector({
    required String label,
    required String currentIcon,
    required String currentText,
    required bool isOpen,
    required VoidCallback onToggle,
    required List<Widget> options,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.w600,
              color: Color(0xFF495057),
            ),
          ),
        ),
        GestureDetector(
          onTap: onToggle, // Toggle the dropdown when the main row is tapped
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: isOpen
                    ? const Color(0xFF2C3E50)
                    : const Color(
                        0xFFE9ECEF), // Border color based on open state
                width: 2,
              ),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(8),
                topRight: const Radius.circular(8),
                bottomLeft: Radius.circular(
                    isOpen ? 0 : 8), // Rounded corners only when closed
                bottomRight: Radius.circular(isOpen ? 0 : 8),
              ),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 15.0, vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(currentIcon, style: const TextStyle(fontSize: 18.0)),
                    const SizedBox(width: 10),
                    Text(
                      currentText,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Icon(
                  isOpen
                      ? Icons.keyboard_arrow_up
                      : Icons
                          .keyboard_arrow_down, // Arrow icon changes with state
                  size: 16.0,
                  color: const Color(0xFF6C757D),
                ),
              ],
            ),
          ),
        ),
        // Animated container for the dropdown options, animating its height
        Container(
          constraints: BoxConstraints(
            maxHeight:
                isOpen ? 300.0 : 0.0, // Max height when open, 0 when closed
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            border: isOpen
                ? Border.all(
                    color: const Color(0xFF2C3E50),
                    width: 2,
                    style: BorderStyle.none,
                  )
                : null,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
          ),
          child: SingleChildScrollView(
            // Only allow scrolling if the container is open
            physics: isOpen
                ? const AlwaysScrollableScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            child: Column(
              children: options, // List of compact options
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewSection(String title, Map<String, dynamic> items) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 12),
          ...items.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(entry.key,
                      style: const TextStyle(
                          fontSize: 13.0, color: Color(0xFF6C757D))),
                  Text('${entry.value}',
                      style: const TextStyle(
                          fontSize: 13.0,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C3E50))),
                ],
              ),
            );
          })
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 60,
        leadingWidth: 100,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: TextButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            label: const Text('Back', style: TextStyle(color: Colors.black)),
            style: TextButton.styleFrom(foregroundColor: Colors.black),
          ),
        ),
        title: const Text(
          'Custom Program',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.black),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Help functionality coming soon!')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                children: const [
                  Text(
                    'Create Custom Training Program',
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Choose a template or design your own from scratch',
                    style: TextStyle(
                      fontSize: 14.0,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFE9ECEF)),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2))
                  ]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: const [
                    Icon(Icons.rocket_launch, color: Color(0xFF2C3E50)),
                    SizedBox(width: 8),
                    Text('Setup Mode',
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ))
                  ]),
                  const SizedBox(height: 15),
                  Row(children: [
                    Expanded(
                      child: GestureDetector(
                          onTap: () => switchMode('simple'),
                          child: ModeCard(
                              isSelected: currentMode == 'simple',
                              modeEmoji: '⚡',
                              modeName: 'Quick Setup',
                              modeDescription: 'Choose from templates')),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                        child: GestureDetector(
                            onTap: () => switchMode('advanced'),
                            child: ModeCard(
                                isSelected: currentMode == 'advanced',
                                modeEmoji: '🔧',
                                modeName: 'Advanced Options',
                                modeDescription: 'Full customization')))
                  ])
                ],
              ),
            ),
            const SizedBox(height: 20),
            Visibility(
              visible: currentMode == 'simple',
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
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
                        Row(children: const [
                          Icon(Icons.track_changes, color: Color(0xFF2C3E50)),
                          SizedBox(width: 8),
                          Text(
                            'Training Configuration',
                            style: TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 15),
                        _buildCompactSelector(
                          label: 'Training Type',
                          currentIcon:
                              simpleSettings['trainingType'] == 'Dry Fire'
                                  ? '🏠'
                                  : '�',
                          currentText:
                              simpleSettings['trainingType'] == 'Dry Fire'
                                  ? 'Dry Fire'
                                  : 'Live Fire',
                          isOpen: isTrainingTypeOpen,
                          onToggle: () {
                            setState(() {
                              isTrainingTypeOpen = !isTrainingTypeOpen;
                              isFocusOpen = false;
                              isDifficultyOpen = false;
                              isShotsOpen = false;
                              isPressureOpen = false;
                              isWeaponOpen = false;
                            });
                          },
                          options: [
                            _buildCompactOption(
                              icon: '🏠',
                              title: 'Dry Fire',
                              description: 'No ammunition training',
                              isSelected:
                                  simpleSettings['trainingType'] == 'Dry Fire',
                              onTap: () {
                                _updateSimpleSetting(
                                    'trainingType', 'Dry Fire');
                                setState(() {
                                  isTrainingTypeOpen = false;
                                });
                              },
                            ),
                            _buildCompactOption(
                              icon: '🔥',
                              title: 'Live Fire',
                              description: 'Range with ammunition',
                              isSelected:
                                  simpleSettings['trainingType'] == 'Live Fire',
                              onTap: () {
                                _updateSimpleSetting(
                                    'trainingType', 'Live Fire');
                                setState(() {
                                  isTrainingTypeOpen = false;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        _buildCompactSelector(
                          label: 'Focus Area',
                          currentIcon: simpleSettings['focus'] == 'Accuracy'
                              ? '🎯'
                              : simpleSettings['focus'] == 'Speed'
                                  ? '⚡'
                                  : simpleSettings['focus'] == 'Competition'
                                      ? '🏆'
                                      : '📚',
                          currentText: simpleSettings['focus'] == 'Accuracy'
                              ? 'Accuracy Improvement'
                              : simpleSettings['focus'] == 'Speed'
                                  ? 'Speed Training'
                                  : simpleSettings['focus'] == 'Competition'
                                      ? 'Competition Prep'
                                      : 'Fundamentals',
                          isOpen: isFocusOpen,
                          onToggle: () {
                            setState(() {
                              isFocusOpen = !isFocusOpen;
                              isTrainingTypeOpen = false;
                              isDifficultyOpen = false;
                              isShotsOpen = false;
                              isPressureOpen = false;
                              isWeaponOpen = false;
                            });
                          },
                          options: [
                            _buildCompactOption(
                              icon: '🎯',
                              title: 'Accuracy Improvement',
                              description:
                                  'Focus on stability and trigger control',
                              metrics: 'Stability + Trigger Control',
                              isSelected: simpleSettings['focus'] == 'Accuracy',
                              onTap: () {
                                _updateSimpleSetting('focus', 'Accuracy');
                                setState(() {
                                  isFocusOpen = false;
                                });
                              },
                            ),
                            _buildCompactOption(
                              icon: '⚡',
                              title: 'Speed Training',
                              description:
                                  'Improve split times and consistency',
                              metrics: 'Split Time + Consistency',
                              isSelected: simpleSettings['focus'] == 'Speed',
                              onTap: () {
                                _updateSimpleSetting('focus', 'Speed');
                                setState(() {
                                  isFocusOpen = false;
                                });
                              },
                            ),
                            _buildCompactOption(
                              icon: '🏆',
                              title: 'Competition Prep',
                              description: 'All metrics balanced for matches',
                              metrics: 'All Metrics Balanced',
                              isSelected:
                                  simpleSettings['focus'] == 'Competition',
                              onTap: () {
                                _updateSimpleSetting('focus', 'Competition');
                                setState(() {
                                  isFocusOpen = false;
                                });
                              },
                            ),
                            _buildCompactOption(
                              icon: '📚',
                              title: 'Fundamentals',
                              description: 'Master basic stability first',
                              metrics: 'Stability Focus Only',
                              isSelected:
                                  simpleSettings['focus'] == 'Fundamentals',
                              onTap: () {
                                _updateSimpleSetting('focus', 'Fundamentals');
                                setState(() {
                                  isFocusOpen = false;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        _buildCompactSelector(
                          label: 'Difficulty Level',
                          currentIcon: simpleSettings['difficulty'] ==
                                  'Beginner'
                              ? '🌱'
                              : simpleSettings['difficulty'] == 'Intermediate'
                                  ? '🌿'
                                  : '🌳',
                          currentText: simpleSettings['difficulty'] ==
                                  'Beginner'
                              ? 'Beginner'
                              : simpleSettings['difficulty'] == 'Intermediate'
                                  ? 'Intermediate'
                                  : 'Advanced',
                          isOpen: isDifficultyOpen,
                          onToggle: () {
                            setState(() {
                              isDifficultyOpen = !isDifficultyOpen;
                              isTrainingTypeOpen = false;
                              isFocusOpen = false;
                              isShotsOpen = false;
                              isPressureOpen = false;
                              isWeaponOpen = false;
                            });
                          },
                          options: [
                            _buildCompactOption(
                              icon: '🌱',
                              title: 'Beginner',
                              description: 'Learning basics',
                              isSelected:
                                  simpleSettings['difficulty'] == 'Beginner',
                              onTap: () {
                                _updateSimpleSetting('difficulty', 'Beginner');
                                setState(() {
                                  isDifficultyOpen = false;
                                });
                              },
                            ),
                            _buildCompactOption(
                              icon: '🌿',
                              title: 'Intermediate',
                              description: 'Building skills',
                              isSelected: simpleSettings['difficulty'] ==
                                  'Intermediate',
                              onTap: () {
                                _updateSimpleSetting(
                                    'difficulty', 'Intermediate');
                                setState(() {
                                  isDifficultyOpen = false;
                                });
                              },
                            ),
                            _buildCompactOption(
                              icon: '🌳',
                              title: 'Advanced',
                              description: 'Mastering technique',
                              isSelected:
                                  simpleSettings['difficulty'] == 'Advanced',
                              onTap: () {
                                _updateSimpleSetting('difficulty', 'Advanced');
                                setState(() {
                                  isDifficultyOpen = false;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        _buildCompactSelector(
                          label: 'Number of Shots',
                          currentIcon: '🎯',
                          currentText: '${simpleSettings['shots']} shots',
                          isOpen: isShotsOpen,
                          onToggle: () {
                            setState(() {
                              isShotsOpen = !isShotsOpen;
                              isTrainingTypeOpen = false;
                              isFocusOpen = false;
                              isDifficultyOpen = false;
                              isPressureOpen = false;
                              isWeaponOpen = false;
                            });
                          },
                          options: [
                            _buildCompactOption(
                              icon: '🎯',
                              title: '5 shots',
                              description: 'Quick session',
                              isSelected: simpleSettings['shots'] == 5,
                              onTap: () {
                                _updateSimpleSetting('shots', 5);
                                setState(() {
                                  isShotsOpen = false;
                                });
                              },
                            ),
                            _buildCompactOption(
                              icon: '🎯',
                              title: '10 shots',
                              description: 'Standard session',
                              isSelected: simpleSettings['shots'] == 10,
                              onTap: () {
                                _updateSimpleSetting('shots', 10);
                                setState(() {
                                  isShotsOpen = false;
                                });
                              },
                            ),
                            _buildCompactOption(
                              icon: '🎯',
                              title: '15 shots',
                              description: 'Extended session',
                              isSelected: simpleSettings['shots'] == 15,
                              onTap: () {
                                _updateSimpleSetting('shots', 15);
                                setState(() {
                                  isShotsOpen = false;
                                });
                              },
                            ),
                            _buildCompactOption(
                              icon: '🎯',
                              title: '20 shots',
                              description: 'Long session',
                              isSelected: simpleSettings['shots'] == 20,
                              onTap: () {
                                _updateSimpleSetting('shots', 20);
                                setState(() {
                                  isShotsOpen = false;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        _buildCompactSelector(
                          label: 'Time Pressure',
                          currentIcon: simpleSettings['pressure'] == 'None'
                              ? '⏱️'
                              : simpleSettings['pressure'] == 'Some'
                                  ? '⏰'
                                  : '⚡',
                          currentText: simpleSettings['pressure'] == 'None'
                              ? 'None'
                              : simpleSettings['pressure'] == 'Some'
                                  ? 'Some'
                                  : 'High',
                          isOpen: isPressureOpen,
                          onToggle: () {
                            setState(() {
                              isPressureOpen = !isPressureOpen;
                              isTrainingTypeOpen = false;
                              isFocusOpen = false;
                              isDifficultyOpen = false;
                              isShotsOpen = false;
                              isWeaponOpen = false;
                            });
                          },
                          options: [
                            _buildCompactOption(
                              icon: '⏱️',
                              title: 'None',
                              description: 'Take your time',
                              isSelected: simpleSettings['pressure'] == 'None',
                              onTap: () {
                                _updateSimpleSetting('pressure', 'None');
                                setState(() {
                                  isPressureOpen = false;
                                });
                              },
                            ),
                            _buildCompactOption(
                              icon: '⏰',
                              title: 'Some',
                              description: 'Moderate pace',
                              isSelected: simpleSettings['pressure'] == 'Some',
                              onTap: () {
                                _updateSimpleSetting('pressure', 'Some');
                                setState(() {
                                  isPressureOpen = false;
                                });
                              },
                            ),
                            _buildCompactOption(
                              icon: '⚡',
                              title: 'High',
                              description: 'Fast splits required',
                              isSelected: simpleSettings['pressure'] == 'High',
                              onTap: () {
                                _updateSimpleSetting('pressure', 'High');
                                setState(() {
                                  isPressureOpen = false;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        BlocBuilder<GearSetupBloc, GearSetupState>(
                          builder: (context, state) {
                            if (state.isLoadingProfiles) {
                              return const LinearProgressIndicator();
                            }

                            GearSetupModel? selectedWeaponProfile =
                                simpleSettings['weapon'];
                            return _buildCompactSelector(
                              label: 'Weapon Profile',
                              currentIcon:
                                  selectedWeaponProfile?.firearm.type ==
                                          'Pistol'
                                      ? '🔫'
                                      : selectedWeaponProfile?.firearm.type ==
                                              'Rifle'
                                          ? '🎯'
                                          : '🏹',
                              currentText: (selectedWeaponProfile?.name ?? '')
                                      .isNotEmpty
                                  ? selectedWeaponProfile?.name ?? ''
                                  : selectedWeaponProfile?.firearm.brand ?? '',
                              isOpen: isWeaponOpen,
                              onToggle: () {
                                setState(() {
                                  isWeaponOpen = !isWeaponOpen;
                                  isTrainingTypeOpen = false;
                                  isFocusOpen = false;
                                  isDifficultyOpen = false;
                                  isShotsOpen = false;
                                  isPressureOpen = false;
                                });
                              },
                              options: [
                                ...List.generate(
                                  state.firearmSetups?.length ?? 0,
                                  (index) {
                                    final firearmSetup =
                                        state.firearmSetups![index];
                                    return _buildCompactOption(
                                      icon: firearmSetup.firearm.type ==
                                              'Pistol'
                                          ? '🔫'
                                          : firearmSetup.firearm.type == 'Rifle'
                                              ? '🎯'
                                              : '🏹',
                                      title: firearmSetup.name.isNotEmpty
                                          ? firearmSetup.name
                                          : firearmSetup.firearm.brand ?? '',
                                      description:
                                          '${firearmSetup.firearm.model!} ${firearmSetup.firearm.caliber!}, ${firearmSetup.firearm.firingMachanism ?? ''}',
                                      isSelected:
                                          firearmSetup == selectedWeaponProfile,
                                      onTap: () {
                                        _updateSimpleSetting(
                                            'weapon', firearmSetup);
                                        setState(() {
                                          isWeaponOpen = false;
                                        });
                                      },
                                    );
                                  },
                                )
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
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
                        Row(
                          children: const [
                            Icon(Icons.edit_note,
                                color: Color(0xFF2C3E50)), // Edit icon
                            SizedBox(width: 8),
                            Text(
                              'Program Name',
                              style: TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        TextField(
                          controller: programNameController,
                          onChanged: (value) {
                            programsModel =
                                programsModel.copyWith(programName: value);
                            setState(() {});
                          },
                          decoration: InputDecoration(
                            hintText: 'Generated automatically...',
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 15, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                  color: Color(0xFFE9ECEF), width: 2),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                  color: Color(0xFFE9ECEF), width: 2),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                  color: Color(0xFF2C3E50), width: 2),
                            ),
                          ),
                          style: const TextStyle(fontSize: 14.0),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Name will be generated based on your selections, or enter your own',
                          style: TextStyle(
                              fontSize: 12.0, color: Color(0xFF6C757D)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (currentMode == 'advanced')
              AdvancedTabContent(
                programsModel: programsModel,
                onProgramNameChanged: (value) {
                  setState(() {
                    programsModel = programsModel.copyWith(
                        programName: value?.programName,
                        programDescription: value?.programDescription,
                        timeLimit: value?.timeLimit,
                        recommenedDistance: value?.recommenedDistance,
                        successCriteria: value?.successCriteria,
                        successThreshold: value?.successThreshold,
                        performanceMetrics: value?.performanceMetrics,
                        modeName: value?.modeName,
                        trainingType: value?.trainingType,
                        focusArea: value?.focusArea,
                        difficultyLevel: value?.difficultyLevel,
                        noOfShots: value?.noOfShots,
                        timePressure: value?.timePressure,
                        weaponProfile: value?.weaponProfile);
                  });
                },
              ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F4F8),
                border: Border.all(color: const Color(0xFF17A2B8), width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.visibility, color: Color(0xFF0C5460)),
                      SizedBox(width: 8),
                      Text(
                        'Program Preview',
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0C5460),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFB3D7E6)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          programsModel.programName ?? 'Program Name',
                          style: const TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          programsModel.programDescription ??
                              'Program Description',
                          style: const TextStyle(
                            fontSize: 14.0,
                            color: Color(0xFF6C757D),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildPreviewSection('Specs', {
                          'Training Type': programsModel.trainingType ?? '',
                          'Focus Area': programsModel.focusArea ?? '',
                          'Difficulty': programsModel.difficultyLevel ?? '',
                          'Shots': programsModel.noOfShots ?? 0,
                          'Time Pressure': programsModel.timePressure ?? '',
                          if (programsModel.modeName == 'advanced') ...{
                            'Recommended Distance':
                                programsModel.recommenedDistance ?? '',
                            'Success Threshold':
                                programsModel.successThreshold ?? '',
                            'Success Criteria':
                                programsModel.successCriteria ?? ''
                          },
                          'Time Limit': programsModel.timeLimit ?? 'None',
                          'Weapon Profile':
                              programsModel.weaponProfile?.firearm.brand ?? '',
                        }),
                        if (currentMode == 'advanced' &&
                            programsModel.performanceMetrics != null)
                          ...List.generate(
                            programsModel.performanceMetrics!.length,
                            (index) => _buildPreviewSection(
                              'Metrics ${index + 1}',
                              {
                                'Type': programsModel
                                        .performanceMetrics![index].stability ??
                                    '',
                                'Target': programsModel
                                        .performanceMetrics![index].target ??
                                    '',
                                'Unit': programsModel
                                        .performanceMetrics![index].unit ??
                                    '',
                                'Consistency': '-',
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implement Test Program logic
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Testing program...')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC107),
                    foregroundColor: const Color(0xFF333333),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(10), // Rounded corners
                    ),
                    elevation: 2, // Shadow
                    shadowColor: Colors.black.withValues(alpha: 0.2),
                  ),
                  icon: const Text('🧪',
                      style: TextStyle(fontSize: 20)), // Test tube emoji
                  label: const Text(
                    'Test Program',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12), // Spacing between buttons
              Expanded(
                  child: ElevatedButton.icon(
                      onPressed: () async {
                        if (programsModel.programName!.isEmpty) {
                          ToastUtils.showError(context,
                              message: 'Program name is required');
                        } else if (programsModel.weaponProfile == null) {
                          ToastUtils.showError(context,
                              message: 'Weapon profile is required');
                        } else {
                          await FirebaseService()
                              .addPrograms(programsModel: programsModel);

                          if (context.mounted) {
                            Navigator.pop(context);
                            ToastUtils.showSuccess(context,
                                message: 'Program saved successfully');
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF28A745),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          elevation: 2,
                          shadowColor: Colors.black.withValues(alpha: 0.2)),
                      icon: const Text('💾', style: TextStyle(fontSize: 20)),
                      label: const Text('Save Program',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16))))
            ])
          ])),
    );
  }
}

class ModeCard extends StatelessWidget {
  const ModeCard({
    super.key,
    required this.modeEmoji,
    required this.modeName,
    required this.modeDescription,
    required this.isSelected,
  });

  final String modeEmoji;
  final String modeName;
  final String modeDescription;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
        // duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2C3E50) : Colors.white,
            border: Border.all(
                color: isSelected
                    ? const Color(0xFF2C3E50)
                    : const Color(0xFFE9ECEF),
                width: 2),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2))
            ]),
        child: Column(children: [
          Text(modeEmoji,
              style: TextStyle(
                  fontSize: 20.0, color: isSelected ? Colors.white : null)),
          const SizedBox(height: 8),
          Text(modeName,
              style:
                  TextStyle(color: isSelected ? Colors.white : Colors.black)),
          const SizedBox(height: 4),
          Text(modeDescription,
              style: TextStyle(
                  fontSize: 12.0,
                  color: isSelected ? Colors.white70 : const Color(0xCC6C757D)))
        ]));
  }
}

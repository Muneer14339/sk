import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pulse_skadi/core/constants/app_constants.dart';
import 'package:pulse_skadi/core/services/prefs.dart';
import 'package:pulse_skadi/core/theme/app_colors.dart';
import 'package:pulse_skadi/features/gear_setup/data/models/gear_setup_model.dart';
import 'package:pulse_skadi/features/gear_setup/presentation/pages/gear_setup_page.dart';
import 'package:pulse_skadi/features/home/presentation/pages/home_page.dart';
import 'package:pulse_skadi/features/profile/presentation/pages/profile_page.dart';
import 'package:pulse_skadi/features/training/presentation/pages/saved_sessions_page.dart';
import 'package:pulse_skadi/features/training/presentation/pages/training_programs_page.dart';
import 'package:pulse_skadi/core/network/network_connectivity_service.dart';

class BottomNavPage extends StatefulWidget {
  const BottomNavPage({super.key, this.initialIndex = 0});
  final int? initialIndex;
  @override
  State<BottomNavPage> createState() => _BottomNavPageState();
}

class _BottomNavPageState extends State<BottomNavPage> {
  final NetworkConnectivityService _networkService =
      NetworkConnectivityService();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.kPrimaryTeal.withValues(alpha: 0.1),
          border: Border(
            top: BorderSide(
              color: AppColors.kQuaternaryColor.withValues(alpha: 0.1),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.kPrimaryColor.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                '',
                'Home',
                true,
                image: 'assets/icons/home.png',
                hasConnectionDot: true,
                index: 0,
              ),
              _buildNavItem(
                '',
                'Loadout',
                false,
                image: 'assets/icons/armory.png',
                index: 1,
              ),
              _buildNavItem(
                '',
                'Training',
                false,
                image: 'assets/icons/training.png',
                index: 2,
              ),
              _buildNavItem(
                '',
                'History',
                false,
                image: 'assets/icons/history.png',
                hasBadge: true,
                badgeCount: 3,
                index: 3,
              ),
              _buildNavItem(
                '',
                'Profile',
                false,
                image: 'assets/icons/profile.png',
                index: 4,
              ),
              // _buildNavItem('👤', 'Firearm', false, index: 4),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    _networkService.initialize(context);
    _currentIndex = widget.initialIndex ?? 0;
    final gearSetupJson = prefs?.getString(AppConstants.gearSetupKey);
    if (gearSetupJson != null) {
      defaultGearSetup = GearSetupModel.fromJson(json.decode(gearSetupJson));
    }
    super.initState();
  }

  int _currentIndex = 0;

  bool isConnected = true;

  final List<Widget> _pages = [
    const HomePage(),
    const GearSetupPage(),
    const TrainingProgramsPage(),
    // const TrainingHistoryPage(),
    SavedSessionsPage(),
    const ProfilePage(),
    // SelectFirearmScreen(stageEntity: StageEntity()),
  ];

  Widget _buildNavItem(
    String icon,
    String label,
    bool isActive, {
    String? image,
    bool hasConnectionDot = false,
    bool hasBadge = false,
    int badgeCount = 0,
    int index = 0,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: _currentIndex == index
              ? AppColors.kPrimaryTeal.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _currentIndex == index
                ? AppColors.kPrimaryTeal
                : AppColors.kQuaternaryColor.withValues(alpha: 0.1),
          ),
        ),
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (image != null)
                  Image.asset(
                    image,
                    width: 28,
                    height: 28,
                    // color: _currentIndex == index ? Colors.white : Colors.black,
                  ),
                if (image == null)
                  Text(
                    icon,
                    style: TextStyle(
                      fontSize: 22,
                      color: _currentIndex == index
                          ? AppColors.kPrimaryColor
                          : AppColors.white,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

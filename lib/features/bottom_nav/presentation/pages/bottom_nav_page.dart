import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pulse_skadi/core/constants/app_constants.dart';
import 'package:pulse_skadi/core/services/prefs.dart';
import 'package:pulse_skadi/features/gear_setup/data/models/gear_setup_model.dart';
import 'package:pulse_skadi/features/gear_setup/presentation/pages/gear_setup_page.dart';
import 'package:pulse_skadi/features/history/presentation/pages/history_page.dart';
import 'package:pulse_skadi/features/home/presentation/pages/home_page.dart';
import 'package:pulse_skadi/features/profile/presentation/pages/profile_page.dart';
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
          color: Colors.white,
          border: Border(top: BorderSide(color: const Color(0xFFE9ECEF))),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, -2))
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                '🏠',
                'Home',
                true,
                hasConnectionDot: true,
                index: 0,
              ),
              _buildNavItem('', 'Loadout', false,
                  image: 'assets/icons/loadout.jpeg', index: 1),
              _buildNavItem('🎯', 'Training', false, index: 2),
              _buildNavItem(
                '📊',
                'History',
                false,
                hasBadge: true,
                badgeCount: 3,
                index: 3,
              ),
              _buildNavItem('👤', 'Profile', false, index: 4),
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
    const TrainingHistoryPage(),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _currentIndex == index
              ? const Color(0xFF2C3E50)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
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
                  Text(icon,
                      style: TextStyle(
                          fontSize: 22,
                          color: _currentIndex == index
                              ? Colors.white
                              : Colors.black)),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: _currentIndex == index
                        ? FontWeight.w600
                        : FontWeight.w500,
                    color: _currentIndex == index ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),

            // Connection dot
            if (hasConnectionDot)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isConnected
                        ? const Color(0xFF28A745)
                        : const Color(0xFFDC3545),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),

            // Badge
            if (hasBadge)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE74C3C),
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    badgeCount.toString(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

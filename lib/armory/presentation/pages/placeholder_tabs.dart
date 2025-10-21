// lib/user_dashboard/presentation/widgets/placeholder_tabs/home_tab_widget.dart
import 'package:flutter/material.dart';

import '../core/theme/user_app_theme.dart';

class HomeTabWidget extends StatelessWidget {
  const HomeTabWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSizes.pageMargin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuickActionsCard(),
          const SizedBox(height: AppSizes.sectionSpacing),
          _buildRecentItemsCard(),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Container(
      padding: AppSizes.cardPadding,
      decoration: AppDecorations.itemCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Actions', style: AppTextStyles.cardTitle),
          const SizedBox(height: 4),
          Text(
            'Quick actions and recent items.',
            style: AppTextStyles.cardDescription,
          ),
          const SizedBox(height: AppSizes.sectionSpacing),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildActionButton('Open Armory', Icons.radio_button_unchecked),
              _buildActionButton('Start Training', Icons.flash_on_outlined),
              _buildActionButton('View History', Icons.analytics_outlined),
              _buildActionButton('Manage Profile', Icons.account_circle_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentItemsCard() {
    return Container(
      padding: AppSizes.cardPadding,
      decoration: AppDecorations.itemCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recently Added', style: AppTextStyles.cardTitle),
          const SizedBox(height: AppSizes.sectionSpacing),
          _buildEmptyState(),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon) {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: AppSizes.smallIcon),
      label: Text(label),
      style: AppButtonStyles.addButtonStyle,
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 48,
            color: AppColors.secondaryText,
          ),
          const SizedBox(height: 12),
          Text(
            'Nothing added yet.',
            style: AppTextStyles.emptyStateText,
          ),
          const SizedBox(height: 8),
          Text(
            'Start by adding items to your armory.',
            style: AppTextStyles.emptyStateText.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// lib/user_dashboard/presentation/widgets/placeholder_tabs/training_tab_widget.dart
class TrainingTabWidget extends StatelessWidget {
  const TrainingTabWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSizes.pageMargin,
      child: Column(
        children: [
          Container(
            padding: AppSizes.cardPadding,
            decoration: AppDecorations.mainCardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Training', style: AppTextStyles.cardTitle),
                const SizedBox(height: 4),
                Text(
                  'Connect Bluetooth camera/sensors and start a session.',
                  style: AppTextStyles.cardDescription,
                ),
                const SizedBox(height: AppSizes.sectionSpacing),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildFeatureButton('Connect Camera', Icons.camera_alt_outlined),
                    _buildFeatureButton('Connect Sensors', Icons.sensors_outlined),
                  ],
                ),
                const SizedBox(height: AppSizes.sectionSpacing),
                _buildComingSoonBanner(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureButton(String label, IconData icon) {
    return ElevatedButton.icon(
      onPressed: null, // Disabled for now
      icon: Icon(icon, size: AppSizes.smallIcon),
      label: Text(label),
      style: AppButtonStyles.addButtonStyle,
    );
  }

  Widget _buildComingSoonBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentBackgroundWithOpacity.withOpacity(0.1),
        border: Border.all(color: AppColors.accentBorderWithOpacity),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            Icons.construction_outlined,
            size: 32,
            color: AppColors.accentText,
          ),
          const SizedBox(height: 8),
          Text(
            'Coming Soon',
            style: TextStyle(
              color: AppColors.accentText,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Training features are under development.',
            style: AppTextStyles.emptyStateText.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// lib/user_dashboard/presentation/widgets/placeholder_tabs/history_tab_widget.dart
class HistoryTabWidget extends StatelessWidget {
  const HistoryTabWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSizes.pageMargin,
      child: Column(
        children: [
          Container(
            padding: AppSizes.cardPadding,
            decoration: AppDecorations.mainCardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('History', style: AppTextStyles.cardTitle),
                const SizedBox(height: 4),
                Text(
                  'See past sessions and results.',
                  style: AppTextStyles.cardDescription,
                ),
                const SizedBox(height: AppSizes.sectionSpacing),
                _buildHistoryStats(),
                const SizedBox(height: AppSizes.sectionSpacing),
                _buildEmptyHistory(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryStats() {
    return Row(
      children: [
        Expanded(child: _buildStatCard('Sessions', '0')),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Rounds', '0')),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Average', '0.0')),
      ],
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        border: Border.all(color: AppColors.primaryBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: AppColors.accentText,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.emptyStateText.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyHistory() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.history_outlined,
            size: 48,
            color: AppColors.secondaryText,
          ),
          const SizedBox(height: 12),
          Text(
            'No training history yet.',
            style: AppTextStyles.emptyStateText,
          ),
          const SizedBox(height: 8),
          Text(
            'Complete training sessions to see your progress here.',
            style: AppTextStyles.emptyStateText.copyWith(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// lib/user_dashboard/presentation/widgets/placeholder_tabs/profile_tab_widget.dart
class ProfileTabWidget extends StatelessWidget {
  const ProfileTabWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSizes.pageMargin,
      child: Column(
        children: [
          Container(
            padding: AppSizes.cardPadding,
            decoration: AppDecorations.mainCardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Profile', style: AppTextStyles.cardTitle),
                const SizedBox(height: 4),
                Text(
                  'Account and preferences.',
                  style: AppTextStyles.cardDescription,
                ),
                const SizedBox(height: AppSizes.sectionSpacing),
                _buildProfileSettings(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSettings() {
    return Column(
      children: [
        _buildSettingTile(
          'Account Settings',
          'Manage your account details',
          Icons.account_circle_outlined,
        ),
        _buildSettingTile(
          'App Preferences',
          'Customize your app experience',
          Icons.settings_outlined,
        ),
        _buildSettingTile(
          'Data & Privacy',
          'Control your data and privacy',
          Icons.security_outlined,
        ),
        _buildSettingTile(
          'Help & Support',
          'Get help and contact support',
          Icons.help_outline,
        ),
        const SizedBox(height: 16),
        _buildComingSoonBanner(),
      ],
    );
  }

  Widget _buildSettingTile(String title, String subtitle, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        border: Border.all(color: AppColors.primaryBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.sectionBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.itemTitle.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.itemSubtitle.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: AppColors.secondaryText,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildComingSoonBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentBackgroundWithOpacity.withOpacity(0.1),
        border: Border.all(color: AppColors.accentBorderWithOpacity),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            Icons.person_outline,
            size: 32,
            color: AppColors.accentText,
          ),
          const SizedBox(height: 8),
          Text(
            'Profile Features Coming Soon',
            style: TextStyle(
              color: AppColors.accentText,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Advanced profile management is under development.',
            style: AppTextStyles.emptyStateText.copyWith(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
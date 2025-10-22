// lib/user_dashboard/pages/placeholder_tabs.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class HomeTabWidget extends StatelessWidget {
  const HomeTabWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppTheme.paddingLarge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuickActionsCard(context),
          SizedBox(height: AppTheme.spacingXLarge),
          _buildRecentItemsCard(context),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard(BuildContext context) {
    return Container(
      padding: AppTheme.paddingLarge,
      decoration: AppTheme.cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Actions', style: AppTheme.titleLarge(context)),
          const SizedBox(height: 4),
          Text(
            'Quick actions and recent items.',
            style: AppTheme.labelMedium(context),
          ),
          SizedBox(height: AppTheme.spacingLarge),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildActionButton(context, 'Open Armory', Icons.radio_button_unchecked),
              _buildActionButton(context, 'Start Training', Icons.flash_on_outlined),
              _buildActionButton(context, 'View History', Icons.analytics_outlined),
              _buildActionButton(context, 'Manage Profile', Icons.account_circle_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentItemsCard(BuildContext context) {
    return Container(
      padding: AppTheme.paddingLarge,
      decoration: AppTheme.cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recently Added', style: AppTheme.titleLarge(context)),
          SizedBox(height: AppTheme.spacingLarge),
          _buildEmptyState(context),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String label, IconData icon) {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: AppTheme.iconSmall),
      label: Text(label),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 48,
            color: AppTheme.textSecondary(context),
          ),
          const SizedBox(height: 12),
          Text(
            'Nothing added yet.',
            style: AppTheme.bodyMedium(context).copyWith(
              color: AppTheme.textSecondary(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start by adding items to your armory.',
            style: AppTheme.bodySmall(context).copyWith(
              color: AppTheme.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }
}

class TrainingTabWidget extends StatelessWidget {
  const TrainingTabWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppTheme.paddingLarge,
      child: Column(
        children: [
          Container(
            padding: AppTheme.paddingLarge,
            decoration: AppTheme.cardDecoration(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Training', style: AppTheme.titleLarge(context)),
                const SizedBox(height: 4),
                Text(
                  'Connect Bluetooth camera/sensors and start a session.',
                  style: AppTheme.labelMedium(context),
                ),
                SizedBox(height: AppTheme.spacingLarge),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildFeatureButton(context, 'Connect Camera', Icons.camera_alt_outlined),
                    _buildFeatureButton(context, 'Connect Sensors', Icons.sensors_outlined),
                  ],
                ),
                SizedBox(height: AppTheme.spacingLarge),
                _buildComingSoonBanner(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureButton(BuildContext context, String label, IconData icon) {
    return ElevatedButton.icon(
      onPressed: null,
      icon: Icon(icon, size: AppTheme.iconSmall),
      label: Text(label),
    );
  }

  Widget _buildComingSoonBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.secondary(context).withOpacity(0.1),
        border: Border.all(color: AppTheme.secondary(context).withOpacity(0.2)),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Column(
        children: [
          Icon(
            Icons.construction_outlined,
            size: 32,
            color: AppTheme.secondary(context),
          ),
          const SizedBox(height: 8),
          Text(
            'Coming Soon',
            style: AppTheme.titleMedium(context).copyWith(
              color: AppTheme.secondary(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Training features are under development.',
            style: AppTheme.bodySmall(context).copyWith(
              color: AppTheme.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }
}

class HistoryTabWidget extends StatelessWidget {
  const HistoryTabWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppTheme.paddingLarge,
      child: Column(
        children: [
          Container(
            padding: AppTheme.paddingLarge,
            decoration: AppTheme.cardDecoration(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('History', style: AppTheme.titleLarge(context)),
                const SizedBox(height: 4),
                Text(
                  'See past sessions and results.',
                  style: AppTheme.labelMedium(context),
                ),
                SizedBox(height: AppTheme.spacingLarge),
                _buildHistoryStats(context),
                SizedBox(height: AppTheme.spacingLarge),
                _buildEmptyHistory(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryStats(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildStatCard(context, 'Sessions', '0')),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(context, 'Rounds', '0')),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(context, 'Average', '0.0')),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant(context),
        border: Border.all(color: AppTheme.border(context)),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTheme.headingMedium(context).copyWith(
              color: AppTheme.secondary(context),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTheme.labelSmall(context),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyHistory(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.history_outlined,
            size: 48,
            color: AppTheme.textSecondary(context),
          ),
          const SizedBox(height: 12),
          Text(
            'No training history yet.',
            style: AppTheme.bodyMedium(context).copyWith(
              color: AppTheme.textSecondary(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete training sessions to see your progress here.',
            style: AppTheme.bodySmall(context).copyWith(
              color: AppTheme.textSecondary(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class ProfileTabWidget extends StatelessWidget {
  const ProfileTabWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppTheme.paddingLarge,
      child: Column(
        children: [
          Container(
            padding: AppTheme.paddingLarge,
            decoration: AppTheme.cardDecoration(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Profile', style: AppTheme.titleLarge(context)),
                const SizedBox(height: 4),
                Text(
                  'Account and preferences.',
                  style: AppTheme.labelMedium(context),
                ),
                SizedBox(height: AppTheme.spacingLarge),
                _buildProfileSettings(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSettings(BuildContext context) {
    return Column(
      children: [
        _buildSettingTile(
          context,
          'Account Settings',
          'Manage your account details',
          Icons.account_circle_outlined,
        ),
        _buildSettingTile(
          context,
          'App Preferences',
          'Customize your app experience',
          Icons.settings_outlined,
        ),
        _buildSettingTile(
          context,
          'Data & Privacy',
          'Control your data and privacy',
          Icons.security_outlined,
        ),
        _buildSettingTile(
          context,
          'Help & Support',
          'Get help and contact support',
          Icons.help_outline,
        ),
        const SizedBox(height: 16),
        _buildComingSoonBanner(context),
      ],
    );
  }

  Widget _buildSettingTile(BuildContext context, String title, String subtitle, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant(context),
        border: Border.all(color: AppTheme.border(context)),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.surface(context),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Icon(
              icon,
              size: AppTheme.iconMedium,
              color: AppTheme.textPrimary(context),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.titleMedium(context),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTheme.labelSmall(context),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: AppTheme.textSecondary(context),
            size: AppTheme.iconMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildComingSoonBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.secondary(context).withOpacity(0.1),
        border: Border.all(color: AppTheme.secondary(context).withOpacity(0.2)),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Column(
        children: [
          Icon(
            Icons.person_outline,
            size: 32,
            color: AppTheme.secondary(context),
          ),
          const SizedBox(height: 8),
          Text(
            'Profile Features Coming Soon',
            style: AppTheme.titleMedium(context).copyWith(
              color: AppTheme.secondary(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Advanced profile management is under development.',
            style: AppTheme.bodySmall(context).copyWith(
              color: AppTheme.textSecondary(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
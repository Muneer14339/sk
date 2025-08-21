import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pulse_skadi/core/utils/dialog_utils.dart';
import 'package:pulse_skadi/core/utils/toast_utils.dart';
import 'package:pulse_skadi/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pulse_skadi/features/auth/presentation/bloc/auth_event.dart';
import 'package:pulse_skadi/features/auth/presentation/bloc/auth_state.dart';
import 'package:pulse_skadi/features/auth/presentation/pages/login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with TickerProviderStateMixin {
  bool voiceCoaching = true;
  bool hapticFeedback = true;
  bool darkMode = false;
  bool analytics = true;
  String units = 'Metric';
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: Duration(seconds: 4),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Row(children: [
                Expanded(
                  child: Text('Profile',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C3E50))),
                ),
                GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(Icons.more_horiz,
                          size: 20, color: Color(0xFF2C3E50)),
                    ))
              ]),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildProfileHeader(),
                    SizedBox(height: 25),

                    _buildAccountSection(),
                    SizedBox(height: 15),

                    // Settings
                    _buildSettingsSection(),
                    SizedBox(height: 15),

                    // Achievements
                    _buildAchievementsSection(),
                    SizedBox(height: 15),

                    // Quick Actions
                    _buildQuickActionsSection(),
                    SizedBox(height: 15),

                    // Storage Usage
                    _buildStorageSection(),
                    SizedBox(height: 15),

                    // Support & Legal
                    _buildSupportSection(),

                    // App Information
                    _buildAppInfo(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Stack(
        children: [
          // Animated pulse effect
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Positioned(
                top: -50,
                right: -50,
                child: Transform.scale(
                  scale: 1 + (_pulseController.value * 0.1),
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withOpacity(0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          Column(
            children: [
              // Avatar
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withOpacity(0.3), width: 3),
                ),
                child: Center(
                  child: Text(
                    '🎯',
                    style: TextStyle(fontSize: 40),
                  ),
                ),
              ),
              SizedBox(height: 8),

              // Name
              Text(
                'Alex Chen',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  if (state is Authenticated) {
                    return Text(
                      state.user.email,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    );
                  }
                  return SizedBox.shrink();
                },
              ),
              SizedBox(height: 8),

              // Premium Badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFED4E)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Premium Member',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
              ),
              SizedBox(height: 15),

              // Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStat('87.4', 'Avg Score'),
                  _buildStat('156', 'Sessions'),
                  _buildStat('12', 'Streak'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String icon, String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFE9ECEF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: Color(0xFFF8F9FA),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(
                bottom: BorderSide(color: Color(0xFFF8F9FA)),
              ),
            ),
            child: Row(
              children: [
                Text(icon, style: TextStyle(fontSize: 18)),
                SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildAccountSection() {
    return _buildSection('👤', 'Account Information', [
      _buildProfileItem(
        icon: '📝',
        title: 'Edit Profile',
        subtitle: 'Name, email, photo',
        onTap: () {},
      ),
      _buildProfileItem(
        icon: '💎',
        title: 'Subscription',
        subtitle: 'Premium • Expires Dec 2024',
        hasStatus: true,
        onTap: () {},
      ),
      _buildProfileItem(
        icon: '☁️',
        title: 'Data Sync',
        subtitle: 'Last sync: 2 minutes ago',
        hasStatus: true,
        onTap: () {},
        isLast: true,
      ),
    ]);
  }

  Widget _buildSettingsSection() {
    return _buildSection('⚙️', 'Settings', [
      _buildToggleItem(
        icon: '🔊',
        title: 'Voice Coaching',
        subtitle: 'AI voice feedback during training',
        value: voiceCoaching,
        onChanged: (value) => setState(() => voiceCoaching = value),
      ),
      _buildToggleItem(
        icon: '📳',
        title: 'Haptic Feedback',
        subtitle: 'Vibration for interactions',
        value: hapticFeedback,
        onChanged: (value) => setState(() => hapticFeedback = value),
      ),
      _buildProfileItem(
        icon: '📏',
        title: 'Units',
        subtitle: 'Distance, grouping measurements',
        value: units,
        onTap: () {},
      ),
      _buildToggleItem(
        icon: '🌙',
        title: 'Dark Mode',
        subtitle: 'Easier on the eyes',
        value: darkMode,
        onChanged: (value) => setState(() => darkMode = value),
      ),
      _buildToggleItem(
        icon: '📊',
        title: 'Analytics',
        subtitle: 'Usage data for improvements',
        value: analytics,
        onChanged: (value) => setState(() => analytics = value),
      ),
      _buildProfileItem(
        icon: '🔔',
        title: 'Notifications',
        subtitle: 'Training reminders, achievements',
        value: 'Enabled',
        onTap: () {},
        isLast: true,
      ),
    ]);
  }

  Widget _buildAchievementsSection() {
    return _buildSection('🏆', 'Recent Achievements', [
      SizedBox(
        height: 130,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.all(20),
          children: [
            _buildAchievementBadge('🎯', 'Marksman', true),
            SizedBox(width: 10),
            _buildAchievementBadge('🔥', 'Hot Streak', true),
            SizedBox(width: 10),
            _buildAchievementBadge('📈', 'Improving', true),
            SizedBox(width: 10),
            _buildAchievementBadge('👑', 'Expert', false),
          ],
        ),
      ),
    ]);
  }

  Widget _buildAchievementBadge(String icon, String name, bool earned) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: earned ? null : Color(0xFFF8F9FA),
        gradient: earned
            ? LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFED4E)])
            : null,
        border: Border.all(
          color: earned ? Color(0xFFFFC107) : Color(0xFFE9ECEF),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: TextStyle(fontSize: 28)),
          SizedBox(height: 5),
          Text(
            name,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return _buildSection('⚡', 'Quick Actions', [
      Padding(
        padding: EdgeInsets.all(20),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildQuickActionButton('📤', 'Export Data'),
            _buildQuickActionButton('📤', 'Share Profile'),
            _buildQuickActionButton('💾', 'Backup'),
            _buildQuickActionButton('❓', 'Support'),
          ],
        ),
      ),
    ]);
  }

  Widget _buildQuickActionButton(String icon, String label) {
    return Container(
      padding: EdgeInsets.all(8),
      width: 130,
      height: 130,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Color(0xFFE9ECEF)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: TextStyle(fontSize: 24)),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3E50),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStorageSection() {
    return _buildSection('💾', 'Storage Usage', [
      Container(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Training Data',
                  style: TextStyle(fontSize: 14, color: Color(0xFF6C757D)),
                ),
                Text(
                  '2.1 GB of 5 GB',
                  style: TextStyle(fontSize: 14, color: Color(0xFF6C757D)),
                ),
              ],
            ),
            SizedBox(height: 10),
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: Color(0xFFE9ECEF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: 0.42,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF28A745), Color(0xFF20C997)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Includes session recordings, shot analysis, and trace data',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF6C757D),
              ),
            ),
          ],
        ),
      ),
    ]);
  }

  Widget _buildSupportSection() {
    return _buildSection('📋', 'Support & Legal', [
      _buildProfileItem(
        icon: '❓',
        title: 'Help Center',
        subtitle: 'FAQs, tutorials, support',
        onTap: () {},
      ),
      _buildProfileItem(
        icon: '💬',
        title: 'Contact Support',
        subtitle: 'Get help from our team',
        onTap: () {},
      ),
      _buildProfileItem(
        icon: '🔒',
        title: 'Privacy Policy',
        subtitle: 'How we protect your data',
        onTap: () {},
      ),
      _buildProfileItem(
        icon: '📄',
        title: 'Terms of Service',
        subtitle: 'Usage terms and conditions',
        onTap: () {},
        isLast: true,
      ),
    ]);
  }

  Widget _buildAppInfo() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            'PulseSkadi v2.1.0 (Build 247)',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6C757D),
            ),
          ),
          SizedBox(height: 5),
          Text(
            '© 2024 TLC Technologies',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6C757D),
            ),
          ),
          SizedBox(height: 15),
          BlocConsumer<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthError) {
                ToastUtils.showError(context, message: state.message);
              }
              if (state is Unauthenticated) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              }
            },
            builder: (_, state) {
              return ElevatedButton(
                onPressed: () {
                  DialogUtils.showConfirmationDialog(
                    context: context,
                    title: 'Sign Out',
                    message: 'Are you sure you want to sign out?',
                    confirmText: 'Sign Out',
                    cancelText: 'Cancel',
                    confirmColor: Colors.red,
                  ).then((value) {
                    if (value) {
                      context.read<AuthBloc>().add(SignOutEvent());
                      Navigator.pop(context);
                    }
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFDC3545),
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Sign Out',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileItem({
    required String icon,
    required String title,
    required String subtitle,
    String? value,
    bool hasStatus = false,
    bool isLast = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(color: Color(0xFFF8F9FA)),
                ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(icon, style: TextStyle(fontSize: 20)),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6C757D),
                    ),
                  ),
                ],
              ),
            ),
            if (hasStatus) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Color(0xFF28A745),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFFE9ECEF),
                      blurRadius: 1,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 10),
            ],
            if (value != null) ...[
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6C757D),
                ),
              ),
              SizedBox(width: 10),
            ],
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFFADB5BD),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleItem({
    required String icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFF8F9FA)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(icon, style: TextStyle(fontSize: 20)),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6C757D),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Color(0xFF2C3E50),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}

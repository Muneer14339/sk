// lib/user_dashboard/pages/main_app_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../injection_container.dart';
import '../../core/config/app_config.dart';
import '../../authentication/presentation/bloc/login_bloc/auth_bloc.dart';
import '../../authentication/presentation/bloc/login_bloc/auth_event.dart';
import '../../authentication/presentation/bloc/login_bloc/auth_state.dart';
import '../../authentication/presentation/pages/login_page.dart';
import '../../armory/presentation/bloc/armory_bloc.dart';
import '../../armory/presentation/widgets/tab_widgets/enhanced_armory_tab_view.dart';
import '../../core/theme/app_theme.dart';
import '../../training/presentation/pages/training_programs_page.dart';
import 'placeholder_tabs.dart';

class MainAppPage extends StatelessWidget {
  const MainAppPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainAppView();
  }
}

class MainAppView extends StatefulWidget {
  const MainAppView({super.key});

  @override
  State<MainAppView> createState() => _MainAppViewState();
}

class _MainAppViewState extends State<MainAppView> {
  String? userId;
  int _currentIndex = 1;

  final List<BottomNavTab> _tabs = [
    const BottomNavTab(assetPath: 'assets/icons/bottom_navigation/home.png'),
    const BottomNavTab(assetPath: 'assets/icons/bottom_navigation/armory.png'),
    const BottomNavTab(assetPath: 'assets/icons/bottom_navigation/training.png'),
    const BottomNavTab(assetPath: 'assets/icons/bottom_navigation/history.png'),
    const BottomNavTab(assetPath: 'assets/icons/bottom_navigation/profile.png'),
  ];

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.background(context),
        appBar: _buildAppBar(),
        body: userId == null ? _buildUnauthenticatedView() : _buildBody(),
        bottomNavigationBar: _buildBottomNavigation(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.primary(context).withOpacity(0.22),
      elevation: 0,
      title: Text(
        AppConfig.appName,
        style: AppTheme.headingMedium(context),
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.logout,
            color: AppTheme.textPrimary(context),
            size: AppTheme.iconMedium,
          ),
          onPressed: () {
            context.read<AuthBloc>().add(const LogoutRequested());
          },
        ),
      ],
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return const HomeTabWidget();
      case 1:
        return const EnhancedArmoryTabView();
      case 2:
        return const TrainingSessionSetupPage();
      case 3:
        return const HistoryTabWidget();
      case 4:
        return const ProfileTabWidget();
      default:
        return const HomeTabWidget();
    }
  }

  Widget _buildBottomNavigation() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: AppTheme.primary(context).withOpacity(0.1),
        border: Border(
          top: BorderSide(
            color: AppTheme.surfaceVariant(context).withOpacity(0.1),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary(context).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: _tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final tab = entry.value;
          final isActive = _currentIndex == index;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _currentIndex = index;
                });
              },
              child: Container(
                color: Colors.transparent,
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: isActive ? 40 : 35,
                    height: isActive ? 40 : 35,
                    child: Opacity(
                      opacity: isActive ? 1.0 : 0.6,
                      child: Image.asset(
                        tab.assetPath,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUnauthenticatedView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: AppTheme.error(context),
            size: AppTheme.iconXLarge,
          ),
          SizedBox(height: AppTheme.spacingMedium),
          Text(
            'User not authenticated',
            style: AppTheme.bodyMedium(context).copyWith(
              color: AppTheme.error(context),
            ),
          ),
        ],
      ),
    );
  }
}

class BottomNavTab {
  final String assetPath;

  const BottomNavTab({
    required this.assetPath,
  });
}
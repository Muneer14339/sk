// lib/user_dashboard/presentation/pages/armory_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../injection_container.dart';
import '../../../core/config/app_config.dart'; // Add this import
import '../../../authentication/presentation/bloc/login_bloc/auth_bloc.dart';
import '../../../authentication/presentation/bloc/login_bloc/auth_event.dart';
import '../../../authentication/presentation/bloc/login_bloc/auth_state.dart';
import '../../../authentication/presentation/pages/login_page.dart';
import '../bloc/armory_bloc.dart';
import '../core/theme/user_app_theme.dart';
import '../widgets/common/common_widgets.dart';
import '../widgets/tab_widgets/enhanced_armory_tab_view.dart';

class ArmoryPage extends StatelessWidget {
  const ArmoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(create: (_) => sl<AuthBloc>()),
        BlocProvider<ArmoryBloc>(create: (_) => sl<ArmoryBloc>()),
      ],
      child: const ArmoryPageView(),
    );
  }
}

class ArmoryPageView extends StatefulWidget {
  const ArmoryPageView({super.key});

  @override
  State<ArmoryPageView> createState() => _ArmoryPageViewState();
}

class _ArmoryPageViewState extends State<ArmoryPageView> {
  String? userId;

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
      child: OrientationBuilder(
        builder: (context, orientation) {
          return Scaffold(
            backgroundColor: AppColors.primaryBackground,
            appBar: orientation == Orientation.portrait
                ? _buildAppBar()
                : _buildLandscapeAppBar(),
            body: userId == null
                ? _buildUnauthenticatedView()
                : const EnhancedArmoryTabView(), // Remove navigation style parameter
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.cardBackground,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppConfig.appName, // Use config app name
            style: AppTextStyles.pageTitle,
          ),
          Text(
            AppConfig.appSubtitle, // Use config subtitle
            style: AppTextStyles.pageSubtitle,
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.logout,
            color: AppColors.primaryText,
            size: AppSizes.mediumIcon,
          ),
          onPressed: () {
            context.read<AuthBloc>().add(const LogoutRequested());
          },
        ),
      ],
    );
  }

  PreferredSizeWidget _buildLandscapeAppBar() {
    return AppBar(
      backgroundColor: AppColors.cardBackground,
      elevation: 0,
      title: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppConfig.appName, // Use config app name
                style: AppTextStyles.pageTitle.copyWith(fontSize: 18),
              ),
              Text(
                AppConfig.appSubtitle, // Use config subtitle
                style: AppTextStyles.pageSubtitle.copyWith(fontSize: 11),
              ),
            ],
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () {
              context.read<AuthBloc>().add(const LogoutRequested());
            },
            icon: const Icon(
              Icons.logout,
              color: AppColors.primaryText,
              size: 16,
            ),
            label: Text(
              'Logout',
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnauthenticatedView() {
    return Center(
      child: CommonWidgets.buildError('User not authenticated'),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../injection_container.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../authentication/presentation/bloc/login_bloc/auth_bloc.dart';
import '../../../authentication/presentation/bloc/login_bloc/auth_event.dart';
import '../../../authentication/presentation/bloc/login_bloc/auth_state.dart';
import '../../../authentication/presentation/pages/login_page.dart';
import '../bloc/armory_bloc.dart';
import '../widgets/common/armory_constants.dart';
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
            backgroundColor: AppTheme.background(context),
            appBar: orientation == Orientation.portrait
                ? _buildAppBar(context)
                : _buildLandscapeAppBar(context),
            body: userId == null
                ? _buildUnauthenticatedView()
                : const EnhancedArmoryTabView(),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppTheme.surface(context),
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppConfig.appName,
            style: AppTheme.headingMedium(context),
          ),
          Text(
            AppConfig.appSubtitle,
            style: AppTheme.labelMedium(context),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.logout,
            color: AppTheme.textPrimary(context),
            size: ArmoryConstants.mediumIcon,
          ),
          onPressed: () {
            context.read<AuthBloc>().add(const LogoutRequested());
          },
        ),
      ],
    );
  }

  PreferredSizeWidget _buildLandscapeAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppTheme.surface(context),
      elevation: 0,
      title: Row(
        children: [
          Text(
            AppConfig.appName,
            style: AppTheme.headingMedium(context).copyWith(fontSize: 18),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () {
              context.read<AuthBloc>().add(const LogoutRequested());
            },
            icon: Icon(
              Icons.logout,
              color: AppTheme.textPrimary(context),
              size: 16,
            ),
            label: Text(
              'Logout',
              style: AppTheme.bodySmall(context),
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
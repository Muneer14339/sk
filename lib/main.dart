// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'authentication/presentation/bloc/login_bloc/auth_bloc.dart';
import 'authentication/presentation/bloc/login_bloc/auth_event.dart';
import 'authentication/presentation/bloc/login_bloc/auth_state.dart';
import 'authentication/presentation/pages/login_page.dart';
import 'core/theme/app_theme.dart';
import 'injection_container.dart' as di;
import 'injection_container.dart';
import 'training/presentation/bloc/ble_scan/ble_scan_bloc.dart';
import 'training/presentation/bloc/training_session/training_session_bloc.dart';
import 'user_dashboard/pages/main_app_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FlutterBluePlus.setLogLevel(LogLevel.none);
  await di.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => BleScanBloc(bleRepository: sl(), trainingSessionBloc: sl()),
        ),
        BlocProvider(
          create: (_) => di.sl<AuthBloc>()..add(const CheckLoginStatus()),
        ),
        BlocProvider(
          create: (context) => TrainingSessionBloc(bleRepository: sl()),
        ),
      ],
      child: MaterialApp(
        title: 'PulseSkadi',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme(),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthLoading || state is AuthInitial) {
          return Scaffold(
            backgroundColor: AppTheme.background(context),
            body: Center(
              child: CircularProgressIndicator(
                color: AppTheme.primary(context),
              ),
            ),
          );
        } else if (state is AuthAuthenticated) {
          return const MainAppPage();
        } else {
          return const LoginPage();
        }
      },
    );
  }
}
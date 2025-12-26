// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'armory/data/datasources/armory_local_dataresouces.dart';
import 'armory/domain/usecases/initial_data_sync_usecase.dart';
import 'armory/presentation/bloc/armory_bloc.dart';
import 'armory/presentation/bloc/dropdown/dropdown_bloc.dart';
import 'authentication/presentation/bloc/login_bloc/auth_bloc.dart';
import 'authentication/presentation/bloc/login_bloc/auth_event.dart';
import 'authentication/presentation/bloc/login_bloc/auth_state.dart';
import 'authentication/presentation/bloc/signup_bloc/signup_bloc.dart';
import 'authentication/presentation/pages/login_page.dart';
import 'core/theme/app_theme.dart';
import 'core/usecases/usecase.dart';
import 'injection_container.dart' as di;
import 'injection_container.dart';
import 'training/presentation/bloc/ble_scan/ble_scan_bloc.dart';
import 'training/presentation/bloc/training_session/training_session_bloc.dart';
import 'user_dashboard/pages/main_app_page.dart';
import 'core/utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FlutterBluePlus.setLogLevel(LogLevel.none);
  Logger.configure();
  await di.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SignupBloc>(create: (_) => di.sl<SignupBloc>()),
        BlocProvider<AuthBloc>(create: (_) => sl<AuthBloc>()),
        BlocProvider<ArmoryBloc>(create: (_) => sl<ArmoryBloc>()),
        BlocProvider<DropdownBloc>(create: (_) => sl<DropdownBloc>()),
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
            body: Center(child: CircularProgressIndicator(color: AppTheme.primary(context))),
          );
        } else if (state is AuthAuthenticated) {
          return DataSyncWrapper(userId: state.user.uid);
        } else {
          return const LoginPage();
        }
      },
    );
  }
}

class DataSyncWrapper extends StatefulWidget {
  final String userId;
  const DataSyncWrapper({super.key, required this.userId});

  @override
  State<DataSyncWrapper> createState() => _DataSyncWrapperState();
}

class _DataSyncWrapperState extends State<DataSyncWrapper> {
  bool _syncCompleted = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  // lib/main.dart - MODIFY _initializeData
  Future<void> _initializeData() async {
    try {
      final localDataSource = di.sl<ArmoryLocalDataSource>();
      final isEmpty = await localDataSource.isDatabaseEmpty();

      if (isEmpty) {
        log.i('🔄 Fetching system data...');
        final syncUseCase = di.sl<InitialDataSyncUseCase>();
        final result = await syncUseCase(UserIdParams(userId: widget.userId));

        result.fold(
              (failure) {
            log.e('❌ Sync failed: $failure');
            if (mounted) setState(() => _syncCompleted = false);
          },
              (_) {
            log.i('✅ System data synced');
            if (mounted) setState(() => _syncCompleted = true);
          },
        );
      } else {
        final hasUserData = await localDataSource.hasUserData(widget.userId);

        if (!hasUserData) {
          log.i('🔄 Fetching user data for: ${widget.userId}');
          final syncUseCase = di.sl<InitialDataSyncUseCase>();
          final result = await syncUseCase(UserIdParams(userId: widget.userId));

          result.fold(
                (failure) {
              log.e('❌ User sync failed: $failure');
              if (mounted) setState(() => _syncCompleted = false);
            },
                (_) {
              log.i('✅ User data synced');
              if (mounted) setState(() => _syncCompleted = true);
            },
          );
        } else {
          log.i('✅ Data ready');
          if (mounted) setState(() => _syncCompleted = true);
        }
      }
    } catch (e) {
      log.e('❌ Init error: $e');
      if (mounted) setState(() => _syncCompleted = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    if (!_syncCompleted) {
      return Scaffold(
        backgroundColor: AppTheme.background(context),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppTheme.primary(context)),
              SizedBox(height: AppTheme.spacingLarge),
              Text('Loading your armory data...', style: AppTheme.bodyLarge(context)),
              SizedBox(height: AppTheme.spacingMedium),
              TextButton(
                onPressed: () => _initializeData(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return const MainAppPage();
  }
}
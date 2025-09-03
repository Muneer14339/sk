import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulse_skadi/core/injection/service_locator.dart';
import 'package:pulse_skadi/core/theme/app_theme.dart';
import 'package:pulse_skadi/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pulse_skadi/features/firearm/presentation/stage_bloc/stage_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pulse_skadi/features/splash/presentation/pages/splash_page.dart';
import 'package:pulse_skadi/features/training/presentation/bloc/ble_scan/ble_scan_bloc.dart';
import 'package:pulse_skadi/core/services/sqflite_service/db_file_loading_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pulse_skadi/core/utils/firebase_options.dart';
import 'package:pulse_skadi/features/gear_setup/presentation/bloc/gear_setup_bloc.dart';
import 'package:pulse_skadi/core/services/prefs.dart';
import 'package:pulse_skadi/features/training/presentation/bloc/session_details/session_details_bloc.dart';
import 'package:pulse_skadi/features/training/presentation/bloc/training_session/training_session_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await init();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await DbFileLoadingService().openDatabaseFromAssets();
  prefs = await initializeSharedPreference();

  runApp(const PulseSkadiApp());
}

class PulseSkadiApp extends StatelessWidget {
  const PulseSkadiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
            create: (context) => AuthBloc(
                checkAuthStatus: sl(),
                signInWithEmailAndPassword: sl(),
                signUpWithEmailAndPassword: sl(),
                signOut: sl())),
        BlocProvider(create: (context) => BleScanBloc(bleRepository: sl())),
        BlocProvider(create: (context) => StageBloc()),
        BlocProvider(create: (context) => GearSetupBloc()),
        BlocProvider(
            create: (context) => TrainingSessionBloc(bleRepository: sl())),
        BlocProvider(
            create: (context) => SessionDetailsBloc(
                getSessionDetails: sl(),
                exportSessionData: sl(),
                shareSessionResults: sl())),
      ],
      child: MaterialApp(
          title: 'PulseSkadi',
          debugShowCheckedModeBanner: false,
          theme: AppTheme().lightTheme,
          home: const SplashPage()),
    );
  }
}

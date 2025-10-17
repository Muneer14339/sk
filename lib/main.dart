import 'dart:math' show tan, atan;

import 'package:flutter/material.dart';
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
          BlocProvider(
            create: (context) =>
                BleScanBloc(bleRepository: sl(), trainingSessionBloc: sl()),
          ),
          BlocProvider(create: (context) => StageBloc()),
          BlocProvider(create: (context) => GearSetupBloc()),
          BlocProvider(
              create: (context) => TrainingSessionBloc(bleRepository: sl())),
        ],
        child: MaterialApp(
            title: 'PulseSkadi',
            debugShowCheckedModeBanner: false,
            theme: AppTheme().lightTheme,
            home: SplashPage()));
  }
}

class TargetPage extends StatefulWidget {
  const TargetPage({super.key});

  @override
  State<TargetPage> createState() => _TargetPageState();
}

class _TargetPageState extends State<TargetPage> {
  final List<int> yardOptions = [1, 7, 10, 15, 25];
  int selectedYard = 7;

  // real target physical diameter in cm
  final double realTargetSizeCm = 22.0;

  // user eye distance to phone screen in cm (assume ~1 yard = 91 cm)
  final double eyeToScreenDistanceCm = 91.0;

  // converts cm → pixels using device DPI
  double cmToPixels(double cm, BuildContext context) {
    double dpi =
        MediaQuery.of(context).devicePixelRatio * 160; // ~160dpi baseline
    return (cm / 2.54) * dpi;
  }

  // compute screen target size in pixels
  double computeTargetSizePx(int yards, BuildContext context) {
    double distanceCm = yards * 91.44; // yards → cm
    double visualAngle = atan(realTargetSizeCm / distanceCm);
    double onScreenCm = eyeToScreenDistanceCm * tan(visualAngle);
    return cmToPixels(onScreenCm, context);
  }

  @override
  Widget build(BuildContext context) {
    double targetSizePx = computeTargetSizePx(selectedYard, context);

    return Scaffold(
      appBar: AppBar(title: const Text("Target Visual Size")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          DropdownButton<int>(
            value: selectedYard,
            items: yardOptions.map((yard) {
              return DropdownMenuItem(
                value: yard,
                child: Text("$yard yards"),
              );
            }).toList(),
            onChanged: (val) => setState(() => selectedYard = val!),
          ),
          const SizedBox(height: 30),
          Center(
            child: Container(
              width: targetSizePx,
              height: targetSizePx,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.red, width: 3),
              ),
              child: const Center(child: Text("🎯")),
            ),
          ),
          const SizedBox(height: 20),
          Text("Selected: $selectedYard yards",
              style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}

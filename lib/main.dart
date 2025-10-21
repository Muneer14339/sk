// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'armory/presentation/pages/main_app_page.dart';
import 'armory/presentation/widgets/common/enhanced_dialog_widgets.dart';
import 'authentication/presentation/bloc/login_bloc/auth_bloc.dart';
import 'authentication/presentation/bloc/login_bloc/auth_event.dart';
import 'authentication/presentation/bloc/login_bloc/auth_state.dart';
import 'authentication/presentation/pages/login_page.dart';
import 'injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await di.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PulseAim App',
      navigatorKey: EnhancedDialogWidgets.navigatorKey,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: BlocProvider(
        create: (_) => di.sl<AuthBloc>()..add(const CheckLoginStatus()),
        child: const AuthWrapper(),
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
          return const Scaffold(
            backgroundColor: Color(0xFF0F1115),
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF57B7FF),
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
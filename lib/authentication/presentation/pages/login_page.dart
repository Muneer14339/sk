// lib/authentication/presentation/pages/login_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pa_sreens/user_dashboard/pages/main_app_page.dart';
import '../../../armory/presentation/pages/armory_page.dart';
import '../../../core/theme/app_theme.dart';
import '../../../injection_container.dart';
import '../bloc/login_bloc/auth_bloc.dart';
import '../bloc/login_bloc/auth_event.dart';
import '../bloc/login_bloc/auth_state.dart';
import 'signup_page.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background(context),
      body: BlocProvider(
        create: (_) => sl<AuthBloc>(),
        child: const LoginForm(),
      ),
    );
  }
}

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          final route = MaterialPageRoute(builder: (_) => const MainAppPage());
          Navigator.pushReplacement(context, route);
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppTheme.error(context),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Center(
        child: SingleChildScrollView(
          padding: AppTheme.paddingLarge,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Container(
              decoration: AppTheme.cardDecoration(context),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(),
                  _buildForm(),
                  _buildActions(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: AppTheme.paddingLarge,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border(context))),
      ),
      child: Column(
        children: [
          Text('Welcome Back', style: AppTheme.headingMedium(context)),
          const SizedBox(height: 4),
          Text(
            'Sign in to continue to PulseAim',
            style: AppTheme.labelMedium(context),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Padding(
      padding: AppTheme.paddingLarge,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildEmailField(),
            const SizedBox(height: AppTheme.spacingLarge),
            _buildPasswordField(),
            const SizedBox(height: AppTheme.spacingXXLarge),
            _buildLoginButton(),
            const SizedBox(height: AppTheme.spacingLarge),
            _buildDivider(),
            const SizedBox(height: AppTheme.spacingLarge),
            _buildGoogleButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Email', style: AppTheme.labelMedium(context)),
        const SizedBox(height: 6),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: AppTheme.bodyMedium(context),
          decoration: InputDecoration(
            hintText: 'Enter your email',
            hintStyle: AppTheme.labelMedium(context),
          ),
          validator: (value) {
            if (value?.trim().isEmpty ?? true) return 'Email is required';
            if (!value!.contains('@')) return 'Enter a valid email';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Password', style: AppTheme.labelMedium(context)),
        const SizedBox(height: 6),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: AppTheme.bodyMedium(context),
          decoration: InputDecoration(
            hintText: 'Enter your password',
            hintStyle: AppTheme.labelMedium(context),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: AppTheme.textSecondary(context),
                size: AppTheme.iconMedium,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          validator: (value) {
            if (value?.trim().isEmpty ?? true) return 'Password is required';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading ? null : _handleLogin,
            child: isLoading
                ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.textPrimary(context),
              ),
            )
                : const Text('Sign In'),
          ),
        );
      },
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: AppTheme.border(context))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('OR', style: AppTheme.labelMedium(context)),
        ),
        Expanded(child: Divider(color: AppTheme.border(context))),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: isLoading
                ? null
                : () {
              context.read<AuthBloc>().add(const GoogleSignInRequested());
            },
            icon: Image.asset(
              'assets/images/google_logo.png',
              height: 20,
              width: 20,
              errorBuilder: (_, __, ___) => Icon(
                Icons.g_mobiledata,
                size: 20,
                color: AppTheme.textPrimary(context),
              ),
            ),
            label: const Text('Continue with Google'),
          ),
        );
      },
    );
  }

  Widget _buildActions() {
    return Container(
      padding: AppTheme.paddingLarge,
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.border(context))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Don't have an account? ",
            style: AppTheme.labelMedium(context),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SignupPage()),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primary(context),
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Sign Up'),
          ),
        ],
      ),
    );
  }

  void _handleLogin() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
      LoginRequested(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../bloc/login_bloc/auth_bloc.dart';
import '../bloc/login_bloc/auth_event.dart';
import '../bloc/login_bloc/auth_state.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background(context),
      body: const ForgotPasswordForm(),
    );
  }
}

class ForgotPasswordForm extends StatefulWidget {
  const ForgotPasswordForm({super.key});

  @override
  State<ForgotPasswordForm> createState() => _ForgotPasswordFormState();
}

class _ForgotPasswordFormState extends State<ForgotPasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Password reset email sent to ${_emailController.text}'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context);
        }
        else if (state is AuthError) {

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
          Text('Reset Password', style: AppTheme.headingMedium(context)),
          const SizedBox(height: 4),
          Text(
            'Enter your email to receive a password reset link',
            style: AppTheme.labelMedium(context),
            textAlign: TextAlign.center,
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
            const SizedBox(height: AppTheme.spacingXXLarge),
            _buildResetButton(),
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

  Widget _buildResetButton() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading ? null : _handleReset,
            child: isLoading
                ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.textPrimary(context),
              ),
            )
                : const Text('Send Reset Link'),
          ),
        );
      },
    );
  }

  void _handleReset() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
      PasswordResetRequested(email: _emailController.text.trim()),
    );
  }
}
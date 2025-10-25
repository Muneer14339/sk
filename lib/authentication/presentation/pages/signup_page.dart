// lib/authentication/presentation/pages/signup_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:country_picker/country_picker.dart';
import '../../../armory/presentation/pages/armory_page.dart';
import '../../../core/theme/app_theme.dart';
import '../../../injection_container.dart';
import '../bloc/signup_bloc/signup_bloc.dart';
import '../bloc/signup_bloc/signup_event.dart';
import '../bloc/signup_bloc/signup_state.dart';

class SignupPage extends StatelessWidget {
  const SignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background(context),
      body: BlocProvider(
        create: (_) => sl<SignupBloc>(),
        child: const SignupForm(),
      ),
    );
  }
}

class SignupForm extends StatefulWidget {
  const SignupForm({super.key});

  @override
  State<SignupForm> createState() => _SignupFormState();
}

class _SignupFormState extends State<SignupForm> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _selectedCountry;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SignupBloc, SignupState>(
      listener: (context, state) {
        if (state is SignupSuccess) {
          final route = MaterialPageRoute(builder: (_) => const ArmoryPage());
          Navigator.pushReplacement(context, route);
        } else if (state is SignupError) {
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
          Text('Create Account', style: AppTheme.headingMedium(context)),
          const SizedBox(height: 4),
          Text(
            'Join PulseSkadi today',
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
            _buildFirstNameField(),
            const SizedBox(height: AppTheme.spacingLarge),
            _buildEmailField(),
            const SizedBox(height: AppTheme.spacingLarge),
            _buildPasswordField(),
            const SizedBox(height: AppTheme.spacingLarge),
            _buildCountryField(),
            const SizedBox(height: AppTheme.spacingXXLarge),
            _buildSignupButton(),
            const SizedBox(height: AppTheme.spacingLarge),
            _buildDivider(),
            const SizedBox(height: AppTheme.spacingLarge),
            _buildGoogleButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildFirstNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('First Name', style: AppTheme.labelMedium(context)),
        const SizedBox(height: 6),
        TextFormField(
          controller: _firstNameController,
          style: AppTheme.bodyMedium(context),
          decoration: InputDecoration(
            hintText: 'Enter your first name',
            hintStyle: AppTheme.labelMedium(context),
          ),
          validator: (value) {
            if (value?.trim().isEmpty ?? true) return 'First name is required';
            return null;
          },
        ),
      ],
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
            hintText: 'Create a password (min. 6 characters)',
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
            if (value!.length < 6) return 'Password must be at least 6 characters';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCountryField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Country (Optional)', style: AppTheme.labelMedium(context)),
        const SizedBox(height: 6),
        InkWell(
          onTap: _pickCountry,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: AppTheme.inputDecoration(context),
            child: Row(
              children: [
                Icon(
                  Icons.public,
                  color: AppTheme.textSecondary(context),
                  size: AppTheme.iconMedium,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedCountry ?? 'Select your country',
                    style: TextStyle(
                      color: _selectedCountry != null
                          ? AppTheme.textPrimary(context)
                          : AppTheme.textSecondary(context),
                      fontSize: 14,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: AppTheme.textSecondary(context),
                  size: AppTheme.iconMedium,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignupButton() {
    return BlocBuilder<SignupBloc, SignupState>(
      builder: (context, state) {
        final isLoading = state is SignupLoading;
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading ? null : _handleSignup,
            child: isLoading
                ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.textPrimary(context),
              ),
            )
                : const Text('Create Account'),
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
    return BlocBuilder<SignupBloc, SignupState>(
      builder: (context, state) {
        final isLoading = state is SignupLoading;
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: isLoading
                ? null
                : () {
              context.read<SignupBloc>().add(const GoogleSignUpRequested());
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
            'Already have an account? ',
            style: AppTheme.labelMedium(context),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primary(context),
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  void _pickCountry() {
    showCountryPicker(
      context: context,
      showPhoneCode: false,
      countryListTheme: CountryListThemeData(
        backgroundColor: AppTheme.surface(context),
        textStyle: AppTheme.bodyMedium(context),
        searchTextStyle: AppTheme.bodyMedium(context),
        inputDecoration: InputDecoration(
          hintText: 'Search country',
          hintStyle: AppTheme.labelMedium(context),
        ),
      ),
      onSelect: (Country country) {
        setState(() => _selectedCountry = country.name);
      },
    );
  }

  void _handleSignup() {
    if (!_formKey.currentState!.validate()) return;
    context.read<SignupBloc>().add(
      SignupRequested(
        firstName: _firstNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        location: _selectedCountry,
      ),
    );
  }
}
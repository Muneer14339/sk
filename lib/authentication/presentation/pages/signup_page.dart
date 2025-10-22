// lib/authentication/presentation/pages/signup_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:country_picker/country_picker.dart';
import '../../../armory/presentation/pages/armory_page.dart';
import '../../../injection_container.dart';
import '../bloc/signup_bloc/signup_bloc.dart';
import '../bloc/signup_bloc/signup_event.dart';
import '../bloc/signup_bloc/signup_state.dart';

class SignupPage extends StatelessWidget {
  const SignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
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
          final route =  MaterialPageRoute(builder: (_) => const ArmoryPage());
          Navigator.pushReplacement(context, route);
        } else if (state is SignupError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.errorColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Center(
        child: SingleChildScrollView(
          padding: AppSizes.pageMargin,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Container(
              decoration: AppDecorations.mainCardDecoration,
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
      padding: const EdgeInsets.all(AppSizes.dialogPadding * 2),
      decoration: AppDecorations.headerBorderDecoration,
      child: Column(
        children: [
          Text('Create Account', style: AppTextStyles.dialogTitle),
          const SizedBox(height: 4),
          Text(
            'Join PulseAim today',
            style: AppTextStyles.cardDescription,
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.dialogPadding * 2),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildFirstNameField(),
            const SizedBox(height: AppSizes.fieldSpacing),
            _buildEmailField(),
            const SizedBox(height: AppSizes.fieldSpacing),
            _buildPasswordField(),
            const SizedBox(height: AppSizes.fieldSpacing),
            _buildCountryField(),
            const SizedBox(height: AppSizes.sectionSpacing),
            _buildSignupButton(),
            const SizedBox(height: AppSizes.fieldSpacing),
            _buildDivider(),
            const SizedBox(height: AppSizes.fieldSpacing),
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
        Text('First Name', style: AppTextStyles.fieldLabel),
        const SizedBox(height: 6),
        TextFormField(
          controller: _firstNameController,
          style: AppTextStyles.inputText,
          decoration: AppInputDecorations.getInputDecoration(
            hintText: 'Enter your first name',
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
        Text('Email', style: AppTextStyles.fieldLabel),
        const SizedBox(height: 6),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: AppTextStyles.inputText,
          decoration: AppInputDecorations.getInputDecoration(
            hintText: 'Enter your email',
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
        Text('Password', style: AppTextStyles.fieldLabel),
        const SizedBox(height: 6),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: AppTextStyles.inputText,
          decoration: AppInputDecorations.getInputDecoration(
            hintText: 'Create a password (min. 6 characters)',
          ).copyWith(
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: AppColors.secondaryText,
                size: AppSizes.mediumIcon,
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
        Text('Country (Optional)', style: AppTextStyles.fieldLabel),
        const SizedBox(height: 6),
        InkWell(
          onTap: _pickCountry,
          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.inputBackground,
              borderRadius: BorderRadius.circular(AppSizes.borderRadius),
              border: Border.all(color: AppColors.primaryBorder),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.public,
                  color: AppColors.secondaryText,
                  size: AppSizes.mediumIcon,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedCountry ?? 'Select your country',
                    style: TextStyle(
                      color: _selectedCountry != null
                          ? AppColors.primaryText
                          : AppColors.secondaryText,
                      fontSize: 14,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: AppColors.secondaryText,
                  size: AppSizes.mediumIcon,
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
            style: AppButtonStyles.primaryButtonStyle,
            child: isLoading
                ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.buttonText,
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
        const Expanded(child: Divider(color: AppColors.primaryBorder)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('OR', style: AppTextStyles.cardDescription),
        ),
        const Expanded(child: Divider(color: AppColors.primaryBorder)),
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
            onPressed: isLoading ? null : () {
              context.read<SignupBloc>().add(const GoogleSignUpRequested());
            },
            icon: Image.asset(
              'assets/images/google_logo.png',
              height: 20,
              width: 20,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.g_mobiledata,
                size: 20,
                color: AppColors.primaryText,
              ),
            ),
            label: const Text('Continue with Google'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryText,
              side: const BorderSide(color: AppColors.primaryBorder),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.dialogPadding * 2),
      decoration: AppDecorations.footerBorderDecoration,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Already have an account? ',
            style: AppTextStyles.cardDescription,
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.accentText,
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
        backgroundColor: AppColors.cardBackground,
        textStyle: AppTextStyles.inputText,
        searchTextStyle: AppTextStyles.inputText,
        inputDecoration: AppInputDecorations.getInputDecoration(
          hintText: 'Search country',
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
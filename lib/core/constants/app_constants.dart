

class AppConstants {
  // App info
  static const String appName = 'PulseSkadi';
  static const String appVersion = '1.0.0';

  // API endpoints
  static const String baseUrl = 'https://api.pulseskadi.com/v1';

  // Local storage keys
  static const String tokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String themeModeKey = 'theme_mode';
  static const String gearSetupKey = 'gear_setup';

  // Animation durations
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration splashDuration = Duration(seconds: 2);

  // Pagination
  static const int defaultPageSize = 20;
}


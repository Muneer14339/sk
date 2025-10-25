// lib/core/config/app_config.dart
class AppConfig {
  // Build time configuration - change this for different APK builds
  static const NavigationStyle navigationStyle = NavigationStyle.grid; // Change to NavigationStyle.list for list APK

  // App names for different builds
  static const String appName = navigationStyle == NavigationStyle.grid
      ? 'PulseSkadi'
      : 'PulseSkadi';

  static const String appSubtitle = navigationStyle == NavigationStyle.grid
      ? 'Enhanced Grid Navigation'
      : 'Enhanced List Navigation';
}

enum NavigationStyle { grid, list }
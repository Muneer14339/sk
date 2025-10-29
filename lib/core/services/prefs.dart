import 'package:shared_preferences/shared_preferences.dart';

//
const String sensitivityKey = 'sensitivity';

// lib/core/services/prefs.dart - Add these constants
const String hapticEnabledKey = 'haptic_enabled';
const String traceDisplayModeKey = 'trace_display_mode'; // Stores int 0/1/2
const String hapticCustomSettingsKey = 'haptic_custom_settings';
// Add this constant with other keys
const String audioAlertTypeKey = 'audioAlertType'; // NEW

//
SharedPreferences? prefs;
Future<SharedPreferences> initializeSharedPreference() async {
  return await SharedPreferences.getInstance();
}

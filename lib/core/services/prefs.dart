import 'package:shared_preferences/shared_preferences.dart';

//
const String sensitivityKey = 'sensitivity';

//
SharedPreferences? prefs;
Future<SharedPreferences> initializeSharedPreference() async {
  return await SharedPreferences.getInstance();
}

import 'package:shared_preferences/shared_preferences.dart';

class Settings {
  static bool _speakMessageAutomatically = false;

  static bool get speakMessageAutomatically => _speakMessageAutomatically;

  static set speakMessageAutomatically(bool value) {
    _speakMessageAutomatically = value;
    _setBool("speakMessageAutomatically", value);
  }

  static void init() async {
    var prefs = await SharedPreferences.getInstance();
    _speakMessageAutomatically = prefs.getBool("speakMessageAutomatically") ?? false;
  }

  static void _setBool(String name, bool value) async {
    var prefs = await SharedPreferences.getInstance();
    await prefs.setBool(name, value);
  }
}
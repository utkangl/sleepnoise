import 'package:shared_preferences/shared_preferences.dart';

abstract final class OnboardingPrefs {
  static const String seenKey = 'onboarding_seen_v1';

  static Future<bool> isCompleted() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(seenKey) ?? false;
  }

  static Future<void> markCompleted() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(seenKey, true);
  }
}

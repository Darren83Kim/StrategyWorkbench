import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const onboardingCompleteKey = 'onboarding_complete_v1';

class OnboardingController extends ChangeNotifier {
  bool completed = false;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    completed = prefs.getBool(onboardingCompleteKey) ?? false;
    notifyListeners();
  }

  Future<void> complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(onboardingCompleteKey, true);
    completed = true;
    notifyListeners();
  }
}

final onboardingController = OnboardingController();

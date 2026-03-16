import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_strings.dart';

const _langKey = 'app_language';

class LanguageNotifier extends AsyncNotifier<String> {
  @override
  Future<String> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_langKey) ?? 'en';
  }

  Future<void> toggle() async {
    final current = state.value ?? 'en';
    final next = current == 'en' ? 'ko' : 'en';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, next);
    state = AsyncData(next);
  }
}

final languageProvider =
    AsyncNotifierProvider<LanguageNotifier, String>(LanguageNotifier.new);

/// 현재 언어의 문자열 맵 (동기 접근 편의 provider)
final stringsProvider = Provider<AppStrings>((ref) {
  final lang = ref.watch(languageProvider).value ?? 'en';
  return lang == 'ko' ? AppStrings.ko : AppStrings.en;
});

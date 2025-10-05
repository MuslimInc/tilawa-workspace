import 'package:shared_preferences/shared_preferences.dart';

abstract class LocalizationLocalDataSource {
  Future<String> getCurrentLanguage();
  Future<void> setLanguage(String languageCode);
  Future<List<String>> getSupportedLanguages();
}

class LocalizationLocalDataSourceImpl implements LocalizationLocalDataSource {
  const LocalizationLocalDataSourceImpl(this._prefs);

  final SharedPreferences _prefs;

  static const String _languageKey = 'selected_language';
  static const List<String> _supportedLanguages = ['en', 'ar'];

  @override
  Future<String> getCurrentLanguage() async {
    return _prefs.getString(_languageKey) ?? 'en';
  }

  @override
  Future<void> setLanguage(String languageCode) async {
    await _prefs.setString(_languageKey, languageCode);
  }

  @override
  Future<List<String>> getSupportedLanguages() async {
    return _supportedLanguages;
  }
}

import 'package:injectable/injectable.dart';
import 'package:muzakri/core/config/language_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class LocalizationLocalDataSource {
  Future<String> getCurrentLanguage();
  Future<void> setLanguage(String languageCode);
  Future<List<String>> getSupportedLanguages();
}

@LazySingleton(as: LocalizationLocalDataSource)
class LocalizationLocalDataSourceImpl implements LocalizationLocalDataSource {
  const LocalizationLocalDataSourceImpl(this._prefs);

  final SharedPreferencesAsync _prefs;

  @override
  Future<String> getCurrentLanguage() async {
    return await _prefs.getString(LanguageConfig.languageKey) ??
        LanguageConfig.getDefaultLanguageCode();
  }

  @override
  Future<void> setLanguage(String languageCode) async {
    await _prefs.setString(LanguageConfig.languageKey, languageCode);
  }

  @override
  Future<List<String>> getSupportedLanguages() async {
    return LanguageConfig.getSupportedLanguageCodes();
  }
}

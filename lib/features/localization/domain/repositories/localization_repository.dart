import 'package:muzakri/core/utils/typedefs.dart';

abstract class LocalizationRepository {
  ResultFuture<String> getCurrentLanguage();
  ResultVoid setLanguage(String languageCode);
  ResultFuture<List<String>> getSupportedLanguages();
}

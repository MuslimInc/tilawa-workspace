import 'package:injectable/injectable.dart';
import 'package:muzakri/core/utils/typedefs.dart';
import 'package:muzakri/features/localization/domain/repositories/localization_repository.dart';

@Singleton()
class SetLanguageUseCase {
  const SetLanguageUseCase(this._repository);

  final LocalizationRepository _repository;

  ResultVoid call(String languageCode) async {
    return await _repository.setLanguage(languageCode);
  }
}

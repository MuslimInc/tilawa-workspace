import 'package:muzakri/core/utils/typedefs.dart';
import 'package:muzakri/features/localization/domain/repositories/localization_repository.dart';

class SetLanguage {
  const SetLanguage(this._repository);

  final LocalizationRepository _repository;

  ResultVoid call(String languageCode) async {
    return await _repository.setLanguage(languageCode);
  }
}

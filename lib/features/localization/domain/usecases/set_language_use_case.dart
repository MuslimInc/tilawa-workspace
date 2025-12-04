import 'package:injectable/injectable.dart';
import '../../../../core/utils/typedefs.dart';
import '../repositories/localization_repository.dart';

@Singleton()
class SetLanguageUseCase {
  const SetLanguageUseCase(this._repository);

  final LocalizationRepository _repository;

  ResultVoid call(String languageCode) async {
    return _repository.setLanguage(languageCode);
  }
}

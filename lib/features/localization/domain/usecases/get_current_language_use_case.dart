import 'package:muzakri/core/utils/typedefs.dart';
import 'package:muzakri/features/localization/domain/repositories/localization_repository.dart';

class GetCurrentLanguageUseCase {
  const GetCurrentLanguageUseCase(this._repository);

  final LocalizationRepository _repository;

  ResultFuture<String> call() async {
    return await _repository.getCurrentLanguage();
  }
}

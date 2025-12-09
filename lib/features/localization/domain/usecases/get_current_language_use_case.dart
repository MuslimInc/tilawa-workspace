import 'package:injectable/injectable.dart';
import '../../../../core/utils/typedefs.dart';
import '../repositories/localization_repository.dart';

@Singleton()
class GetCurrentLanguageUseCase {
  const GetCurrentLanguageUseCase(this._repository);

  final LocalizationRepository _repository;

  ResultFuture<String> call() async {
    return _repository.getCurrentLanguage();
  }
}

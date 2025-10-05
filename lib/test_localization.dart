import 'package:muzakri/core/di/injection_container.dart' as di;
import 'package:muzakri/features/localization/domain/repositories/localization_repository.dart';

void main() async {
  await di.initDI();

  print('Testing LocalizationRepository registration...');
  print(
    'LocalizationRepository registered: ${di.sl.isRegistered<LocalizationRepository>()}',
  );

  // Test getting the repository
  try {
    final repository = di.sl<LocalizationRepository>();
    print(
      'Successfully retrieved LocalizationRepository: ${repository.runtimeType}',
    );

    // Test getting current language
    final result = await repository.getCurrentLanguage();
    result.fold(
      (failure) => print('Error getting language: ${failure.message}'),
      (language) => print('Current language: $language'),
    );
  } catch (e) {
    print('Error: $e');
  }
}

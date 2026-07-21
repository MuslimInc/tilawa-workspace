import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/features/localization/presentation/bloc/localization_bloc.dart';
import 'package:tilawa/features/onboarding/presentation/screens/language_welcome_screen.dart';
import 'package:tilawa/features/theme/domain/primary_color_preset.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_core/config/language_config.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../../helpers/hydrated_bloc_test_helper.dart';
import '../../../../helpers/noop_sync_user_language_preference_use_case.dart';
import '../../../localization/presentation/bloc/localization_bloc_test.mocks.dart';

void main() {
  late LocalizationBloc localizationBloc;
  late MockGetCurrentLanguageUseCase mockGetCurrentLanguageUseCase;
  late MockSetLanguageUseCase mockSetLanguageUseCase;
  late MockGetRecitersUseCase mockGetRecitersUseCase;

  setUpAll(() async {
    provideDummy<Either<Failure, void>>(const Right(null));
    provideDummy<Either<Failure, String>>(
      const Right(LanguageConfig.defaultLanguageCode),
    );
    await initializeHydratedStorageForTest();
  });

  tearDownAll(() async {
    await clearHydratedStorageForTest();
  });

  setUp(() {
    mockGetCurrentLanguageUseCase = MockGetCurrentLanguageUseCase();
    mockSetLanguageUseCase = MockSetLanguageUseCase();
    mockGetRecitersUseCase = MockGetRecitersUseCase();
    when(
      mockGetCurrentLanguageUseCase(),
    ).thenAnswer((_) async => const Right(LanguageConfig.defaultLanguageCode));
    when(
      mockSetLanguageUseCase(any),
    ).thenAnswer((_) async => const Right(null));
    when(mockGetRecitersUseCase.invalidateCache()).thenReturn(null);

    localizationBloc = LocalizationBloc(
      mockGetCurrentLanguageUseCase,
      mockSetLanguageUseCase,
      mockGetRecitersUseCase,
      noopSyncUserLanguagePreferenceUseCase(),
    );
  });

  tearDown(() async {
    await localizationBloc.close();
  });

  testWidgets('shows funnel step cue and language setup subtitle', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(
          primaryColor: PrimaryColorPreset.defaultPreset.value,
        ),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<LocalizationBloc>.value(
          value: localizationBloc,
          child: const LanguageWelcomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final l10n = lookupAppLocalizations(const Locale('en'));
    expect(find.text(l10n.firstRunFunnelStepProgress(1, 4)), findsOneWidget);
    expect(find.text(l10n.languageWelcomeProgressSubtitle), findsOneWidget);
    expect(find.text(l10n.next), findsOneWidget);
  });
}

import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/core/entities/moshaf_entity.dart';
import 'package:tilawa/core/entities/reciter_entity.dart';
import 'package:tilawa/core/errors/failures.dart';
import 'package:tilawa/core/services/analytics_service.dart';
import 'package:tilawa/core/utils/typedefs.dart';
import 'package:tilawa/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:tilawa/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:tilawa/features/downloads/domain/repositories/downloads_repository.dart';
import 'package:tilawa/features/downloads/domain/usecases/usecases.dart';
import 'package:tilawa/features/downloads/presentation/bloc/downloads_bloc.dart';
import 'package:tilawa/features/localization/presentation/bloc/localization_bloc.dart';
import 'package:tilawa/features/reciters/presentation/bloc/reciter_details_bloc.dart';
import 'package:tilawa/features/reciters/presentation/bloc/reciter_download_bloc.dart';
import 'package:tilawa/features/reciters/presentation/cubit/reciter_details_loader_cubit.dart';
import 'package:tilawa/features/reciters/presentation/cubit/reciter_details_loader_state.dart';
import 'package:tilawa/features/reciters/presentation/screens/reciter_details_loader.dart';
import 'package:tilawa/features/reciters/presentation/screens/reciter_details_screen.dart';
import 'package:tilawa/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';

import '../../../../features/downloads/helpers/mock_helper.mocks.dart'
    as download_mocks;
import '../../../../router/router_mock_helper.mocks.dart';

class MockReciterDownloadBloc extends Mock implements ReciterDownloadBloc {}

class FakeAnalyticsService extends Fake implements AnalyticsService {
  @override
  Future<void> logScreenView(String screenName, {String? screenClass}) async {}
}

void main() {
  late MockReciterDetailsLoaderCubit mockLoaderCubit;
  late MockAuthBloc mockAuthBloc;
  late MockAudioPlayerBloc mockAudioPlayerBloc;
  late MockDownloadsBloc mockDownloadsBloc;
  late MockReciterDetailsBloc mockReciterDetailsBloc;
  late MockReciterDownloadBloc mockReciterDownloadBloc;
  late MockLocalizationBloc mockLocalizationBloc;
  late MockSettingsCubit mockSettingsCubit;
  late FakeAnalyticsService fakeAnalyticsService;
  late download_mocks.MockDownloadsRepository mockDownloadsRepository;
  late download_mocks.MockCheckSurahDownloadedUseCase mockCheckSurahDownloaded;
  late download_mocks.MockDownloadSurahUseCase mockDownloadSurah;
  late download_mocks.MockObserveDownloadProgressUseCase mockObserveProgress;
  late download_mocks.MockCancelDownloadUseCase mockCancelDownload;

  setUpAll(() {
    provideDummy<LocalizationState>(
      const LocalizationState(locale: Locale('en')),
    );
    provideDummy<ReciterDetailsState>(const ReciterDetailsState());
    provideDummy<AuthState>(const AuthState.initial());
    provideDummy<AudioPlayerState>(
      const AudioPlayerState(status: AudioPlayerStatus.initial),
    );
    provideDummy<DownloadsState>(const DownloadsState());
    provideDummy<ReciterDownloadState>(const ReciterDownloadState());
    provideDummy<SettingsState>(const SettingsState());
    provideDummy<ReciterDetailsLoaderState>(
      const ReciterDetailsLoaderLoading(),
    );

    // Results
    provideDummy<Either<Failure, bool>>(const Right(false));
    provideDummy<Either<Failure, void>>(const Right(null));
    provideDummy<ResultFuture<bool>>(Future.value(const Right(false)));
    provideDummy<ResultFuture<void>>(Future.value(const Right(null)));
  });

  setUp(() {
    final GetIt getIt = GetIt.instance;
    getIt.reset();

    mockLoaderCubit = MockReciterDetailsLoaderCubit();
    mockAuthBloc = MockAuthBloc();
    mockAudioPlayerBloc = MockAudioPlayerBloc();
    mockDownloadsBloc = MockDownloadsBloc();
    mockReciterDetailsBloc = MockReciterDetailsBloc();
    mockReciterDownloadBloc = MockReciterDownloadBloc();
    mockLocalizationBloc = MockLocalizationBloc();
    mockSettingsCubit = MockSettingsCubit();
    fakeAnalyticsService = FakeAnalyticsService();

    mockDownloadsRepository = download_mocks.MockDownloadsRepository();
    mockCheckSurahDownloaded = download_mocks.MockCheckSurahDownloadedUseCase();
    mockDownloadSurah = download_mocks.MockDownloadSurahUseCase();
    mockObserveProgress = download_mocks.MockObserveDownloadProgressUseCase();
    mockCancelDownload = download_mocks.MockCancelDownloadUseCase();

    getIt.allowReassignment = true;
    getIt.registerFactory<ReciterDetailsLoaderCubit>(() => mockLoaderCubit);
    getIt.registerFactory<AuthBloc>(() => mockAuthBloc);
    getIt.registerFactory<AudioPlayerBloc>(() => mockAudioPlayerBloc);
    getIt.registerFactory<DownloadsBloc>(() => mockDownloadsBloc);
    getIt.registerFactory<ReciterDetailsBloc>(() => mockReciterDetailsBloc);
    getIt.registerFactory<ReciterDownloadBloc>(() => mockReciterDownloadBloc);
    getIt.registerFactory<LocalizationBloc>(() => mockLocalizationBloc);
    getIt.registerFactory<SettingsCubit>(() => mockSettingsCubit);
    getIt.registerLazySingleton<DownloadsRepository>(
      () => mockDownloadsRepository,
    );
    getIt.registerLazySingleton<AnalyticsService>(() => fakeAnalyticsService);

    getIt.registerFactory<CheckSurahDownloadedUseCase>(
      () => mockCheckSurahDownloaded,
    );
    getIt.registerFactory<DownloadSurahUseCase>(() => mockDownloadSurah);
    getIt.registerFactory<ObserveDownloadProgressUseCase>(
      () => mockObserveProgress,
    );
    getIt.registerFactory<CancelDownloadUseCase>(() => mockCancelDownload);

    // Default state stubs
    _stubBloc(mockLoaderCubit, const ReciterDetailsLoaderLoading());
    _stubBloc(mockAuthBloc, const AuthState.initial());
    _stubBloc(
      mockAudioPlayerBloc,
      const AudioPlayerState(status: AudioPlayerStatus.initial),
    );
    _stubBloc(mockDownloadsBloc, const DownloadsState());
    _stubBloc(mockReciterDetailsBloc, const ReciterDetailsState());
    // _stubBloc(mockReciterDownloadBloc, const ReciterDownloadState());
    _stubBloc(
      mockLocalizationBloc,
      const LocalizationState(locale: Locale('en')),
    );
    _stubBloc(mockSettingsCubit, const SettingsState());

    // Method stubs
    when(mockLoaderCubit.loadReciter(any)).thenAnswer((_) async {});

    when(
      mockCheckSurahDownloaded.call(
        surahId: anyNamed('surahId'),
        reciterName: anyNamed('reciterName'),
      ),
    ).thenAnswer((_) async => const Right(false));

    when(mockObserveProgress.call(any)).thenAnswer((_) => const Stream.empty());
  });

  Widget createWidget() {
    return ScreenUtilPlusInit(
      designSize: const Size(375, 812),
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          BlocProvider<AudioPlayerBloc>.value(value: mockAudioPlayerBloc),
          BlocProvider<DownloadsBloc>.value(value: mockDownloadsBloc),
          BlocProvider<ReciterDetailsBloc>.value(value: mockReciterDetailsBloc),
          BlocProvider<ReciterDownloadBloc>.value(
            value: mockReciterDownloadBloc,
          ),
          BlocProvider<LocalizationBloc>.value(value: mockLocalizationBloc),
          BlocProvider<SettingsCubit>.value(value: mockSettingsCubit),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ReciterDetailsLoader(reciterId: '1'),
        ),
      ),
    );
  }

  testWidgets('shows loading indicator when state is loading', (tester) async {
    await tester.pumpWidget(createWidget());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows error and retry button when state is failure', (
    tester,
  ) async {
    _stubBloc(
      mockLoaderCubit,
      const ReciterDetailsLoaderFailure('Error message'),
    );

    await tester.pumpWidget(createWidget());
    await tester.pump();

    expect(find.text('Error message'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pump();
    verify(mockLoaderCubit.loadReciter('1')).called(2);
  });

  testWidgets('shows ReciterDetailsScreen when state is success', (
    tester,
  ) async {
    const reciter = ReciterEntity(
      id: 1,
      name: 'Test Reciter',
      letter: 'T',
      date: '2023-01-01',
      moshaf: [
        MoshafEntity(
          id: 1,
          name: 'Test Moshaf',
          server: 'test',
          surahTotal: 114,
          moshafType: 1,
          surahList: '1,2,3',
        ),
      ],
    );

    _stubBloc(mockLoaderCubit, const ReciterDetailsLoaderSuccess(reciter));

    await tester.pumpWidget(createWidget());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.byType(MultiBlocProvider),
      findsNWidgets(2),
    ); // One in createWidget, one in Loader
    expect(find.byType(ReciterDetailsScreen), findsOneWidget);
  });
}

void _stubBloc<B, S>(B bloc, S state) {
  when((bloc as dynamic).state).thenReturn(state);
  when((bloc as dynamic).stream).thenAnswer((_) => Stream<S>.empty());
  when((bloc as dynamic).close()).thenAnswer((_) async {});
}

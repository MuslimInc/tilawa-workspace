// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:get_it/get_it.dart';
// import 'package:go_router/go_router.dart';
// import 'package:mockito/mockito.dart';
// import 'package:tilawa/features/athkar/presentation/screens/athkar_categories_screen.dart';
// import 'package:tilawa/features/athkar/presentation/screens/athkar_details_screen.dart';
// import 'package:tilawa/features/audio_player/presentation/bloc/audio_player_bloc.dart';
// import 'package:tilawa/features/auth/presentation/bloc/auth_bloc.dart';
// import 'package:tilawa/features/auth/presentation/screens/login_screen.dart';
// import 'package:tilawa/features/downloads/presentation/bloc/downloads_bloc.dart';
// import 'package:tilawa/features/downloads/presentation/screens/downloads_screen.dart';
// import 'package:tilawa/features/localization/presentation/bloc/localization_bloc.dart';
// import 'package:tilawa/features/onboarding/presentation/screens/onboarding_screen.dart';
// import 'package:tilawa/features/premium/presentation/screens/premium_screen.dart';
// import 'package:tilawa/features/qibla/presentation/screens/qibla_screen.dart';
// import 'package:tilawa/features/reciters/presentation/bloc/reciter_details_bloc.dart';
// import 'package:tilawa/features/reciters/presentation/bloc/reciter_download_bloc.dart';
// import 'package:tilawa/features/reciters/presentation/screens/favorites_screen.dart';
// import 'package:tilawa/features/reciters/presentation/screens/reciter_details_loader.dart';
// import 'package:tilawa/features/reciters/presentation/screens/reciter_details_screen.dart';
// import 'package:tilawa/features/settings/presentation/cubit/settings_cubit.dart';
// import 'package:tilawa/features/settings/presentation/screens/settings_screen.dart';
// import 'package:tilawa/features/splash/presentation/screens/splash_screen.dart';
// import 'package:tilawa/l10n/generated/app_localizations.dart';
// import 'package:tilawa/router/app_router_config.dart';
// import 'package:tilawa/screens/main_screen.dart';
// import 'package:tilawa/screens/route_list_screen.dart';
// import 'package:tilawa_core/entities/moshaf_entity.dart';
// import 'package:tilawa_core/entities/reciter_entity.dart';
// import 'package:tilawa_core/services/analytics_service.dart';

// import 'router_mock_helper.mocks.dart';

// void main() {
//   provideDummy<LocalizationState>(
//     const LocalizationState(locale: Locale('en')),
//   );
//   provideDummy<AudioPlayerState>(
//     const AudioPlayerState(status: AudioPlayerStatus.initial),
//   );

//   late MockGoRouterState mockGoRouterState;
//   late MockAuthBloc mockAuthBloc;
//   late MockAudioPlayerBloc mockAudioPlayerBloc;
//   late MockDownloadsBloc mockDownloadsBloc;
//   late MockReciterDetailsBloc mockReciterDetailsBloc;
//   late MockReciterDownloadBloc mockReciterDownloadBloc;
//   late MockLocalizationBloc mockLocalizationBloc;
//   late MockSettingsCubit mockSettingsCubit;
//   late FakeAnalyticsService fakeAnalyticsService;

//   final GetIt getIt = GetIt.instance;

//   setUp(() {
//     getIt.reset();
//     mockGoRouterState = MockGoRouterState();
//     mockAuthBloc = MockAuthBloc();
//     mockAudioPlayerBloc = MockAudioPlayerBloc();
//     mockDownloadsBloc = MockDownloadsBloc();
//     mockReciterDetailsBloc = MockReciterDetailsBloc();
//     mockReciterDownloadBloc = MockReciterDownloadBloc();
//     mockLocalizationBloc = MockLocalizationBloc();
//     mockSettingsCubit = MockSettingsCubit();
//     fakeAnalyticsService = FakeAnalyticsService();

//     when(mockGoRouterState.pageKey).thenReturn(const ValueKey('test'));
//     when(mockGoRouterState.uri).thenReturn(Uri.parse('/test'));

//     getIt.registerFactory<AuthBloc>(() => mockAuthBloc);
//     getIt.registerFactory<AudioPlayerBloc>(() => mockAudioPlayerBloc);
//     getIt.registerFactory<DownloadsBloc>(() => mockDownloadsBloc);
//     getIt.registerFactory<ReciterDetailsBloc>(() => mockReciterDetailsBloc);
//     getIt.registerFactory<ReciterDownloadBloc>(() => mockReciterDownloadBloc);
//     getIt.registerFactory<LocalizationBloc>(() => mockLocalizationBloc);
//     getIt.registerFactory<SettingsCubit>(() => mockSettingsCubit);
//     getIt.registerFactory<AnalyticsService>(() => fakeAnalyticsService);

//     // Default state stubs
//     when(mockAuthBloc.state).thenReturn(const AuthState.initial());
//     when(
//       mockAudioPlayerBloc.state,
//     ).thenReturn(const AudioPlayerState(status: AudioPlayerStatus.initial));
//     when(mockDownloadsBloc.state).thenReturn(const DownloadsState());
//     when(mockReciterDetailsBloc.state).thenReturn(const ReciterDetailsState());
//     when(
//       mockReciterDownloadBloc.state,
//     ).thenReturn(const ReciterDownloadState());
//     when(
//       mockLocalizationBloc.state,
//     ).thenReturn(const LocalizationState(locale: Locale('en')));
//     when(mockSettingsCubit.state).thenReturn(const SettingsState());

//     // Stream stubs for MultiBlocProvider
//     when(mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());
//     when(mockAudioPlayerBloc.stream).thenAnswer((_) => const Stream.empty());
//     when(mockDownloadsBloc.stream).thenAnswer((_) => const Stream.empty());
//     when(mockReciterDetailsBloc.stream).thenAnswer((_) => const Stream.empty());
//     when(
//       mockReciterDownloadBloc.stream,
//     ).thenAnswer((_) => const Stream.empty());
//     when(mockLocalizationBloc.stream).thenAnswer((_) => const Stream.empty());
//     when(mockSettingsCubit.stream).thenAnswer((_) => const Stream.empty());
//   });

//   group('AppRouterConfig Routes', () {
//     test('HomeRoute builds MainScreen', () {
//       const route = HomeRoute();
//       final Widget widget = route.build(MockBuildContext(), mockGoRouterState);
//       expect(widget, isA<MainScreen>());
//     });

//     test('OnboardingRoute builds OnboardingScreen', () {
//       const route = OnboardingRoute();
//       final Widget widget = route.build(MockBuildContext(), mockGoRouterState);
//       expect(widget, isA<OnboardingScreen>());
//     });

//     group('ReciterDetailsRoute', () {
//       const moshaf = MoshafEntity(
//         id: 1,
//         name: 'Test Moshaf',
//         server: 'https://test.com',
//         surahTotal: 114,
//         moshafType: 1,
//         surahList: '',
//       );
//       const reciter = ReciterEntity(
//         id: 1,
//         name: 'Test Reciter',
//         letter: 'T',
//         date: '2023-01-01',
//         moshaf: [moshaf],
//       );

//       test('builds ReciterDetailsLoader when extra is null', () {
//         const route = ReciterDetailsRoute(reciterId: '1');
//         final Widget widget = route.build(
//           MockBuildContext(),
//           mockGoRouterState,
//         );
//         expect(widget, isA<ReciterDetailsLoader>());
//         expect((widget as ReciterDetailsLoader).reciterId, '1');
//       });

//       testWidgets('builds ReciterDetailsScreen when extra is present', (
//         tester,
//       ) async {
//         const route = ReciterDetailsRoute(reciterId: '1', $extra: reciter);
//         final Widget widget = route.build(
//           MockBuildContext(),
//           mockGoRouterState,
//         );
//         await tester.pumpWidget(
//           MaterialApp(
//             localizationsDelegates: AppLocalizations.localizationsDelegates,
//             supportedLocales: AppLocalizations.supportedLocales,
//             home: MultiBlocProvider(
//               providers: [
//                 BlocProvider<AuthBloc>.value(value: mockAuthBloc),
//                 BlocProvider<AudioPlayerBloc>.value(value: mockAudioPlayerBloc),
//                 BlocProvider<DownloadsBloc>.value(value: mockDownloadsBloc),
//                 BlocProvider<LocalizationBloc>.value(
//                   value: mockLocalizationBloc,
//                 ),
//                 BlocProvider<SettingsCubit>.value(value: mockSettingsCubit),
//               ],
//               child: widget,
//             ),
//           ),
//         );

//         expect(find.byType(ReciterDetailsScreen), findsOneWidget);
//         final ReciterDetailsScreen screen = tester.widget<ReciterDetailsScreen>(
//           find.byType(ReciterDetailsScreen),
//         );
//         expect(screen.reciter, reciter);
//       });
//     });

//     test('ExpandedPlayerRoute builds CustomTransitionPage', () {
//       const route = ExpandedPlayerRoute();
//       final Page<void> page = route.buildPage(
//         MockBuildContext(),
//         mockGoRouterState,
//       );
//       expect(page, isA<CustomTransitionPage>());
//       final transitionPage = page as CustomTransitionPage;
//       expect(transitionPage.child, isA<ExpandedPlayerScreen>());

//       // Test transitionsBuilder (lines 71-72)
//       final Widget transitionWidget = transitionPage.transitionsBuilder(
//         MockBuildContext(),
//         const AlwaysStoppedAnimation(1.0),
//         const AlwaysStoppedAnimation(0.0),
//         const SizedBox(),
//       );
//       expect(transitionWidget, isA<FadeTransition>());
//     });

//     test('PremiumRoute builds PremiumScreen', () {
//       const route = PremiumRoute();
//       final Widget widget = route.build(MockBuildContext(), mockGoRouterState);
//       expect(widget, isA<PremiumScreen>());
//     });

//     test('SettingsRoute builds SettingsScreen', () {
//       const route = SettingsRoute();
//       final Widget widget = route.build(MockBuildContext(), mockGoRouterState);
//       expect(widget, isA<SettingsScreen>());
//     });

//     test('LoginRoute builds LoginScreen', () {
//       const route = LoginRoute();
//       final Widget widget = route.build(MockBuildContext(), mockGoRouterState);
//       expect(widget, isA<LoginScreen>());
//     });

//     test('DownloadsRoute builds DownloadsScreen', () {
//       const route = DownloadsRoute();
//       final Widget widget = route.build(MockBuildContext(), mockGoRouterState);
//       expect(widget, isA<DownloadsScreen>());
//     });

//     test('FavoritesRoute builds FavoritesScreen', () {
//       const route = FavoritesRoute();
//       final Widget widget = route.build(MockBuildContext(), mockGoRouterState);
//       expect(widget, isA<FavoritesScreen>());
//     });

//     test('AthkarCategoriesRoute builds AthkarCategoriesScreen', () {
//       const route = AthkarCategoriesRoute();
//       final Widget widget = route.build(MockBuildContext(), mockGoRouterState);
//       expect(widget, isA<AthkarCategoriesScreen>());
//     });

//     test('AthkarDetailsRoute builds AthkarDetailsScreen', () {
//       const route = AthkarDetailsRoute(categoryId: 1, categoryName: 'Test');
//       final Widget widget = route.build(MockBuildContext(), mockGoRouterState);
//       expect(widget, isA<AthkarDetailsScreen>());
//       expect((widget as AthkarDetailsScreen).categoryId, 1);
//       expect(widget.categoryName, 'Test');
//     });

//     test('QiblaRoute builds QiblaScreen', () {
//       const route = QiblaRoute();
//       final Widget widget = route.build(MockBuildContext(), mockGoRouterState);
//       expect(widget, isA<QiblaScreen>());
//     });

//     test('RouteListRoute builds RouteListScreen', () {
//       const route = RouteListRoute();
//       final Widget widget = route.build(MockBuildContext(), mockGoRouterState);
//       expect(widget, isA<RouteListScreen>());
//     });

//     testWidgets('SplashRoute builds SplashScreen', (tester) async {
//       const route = SplashRoute();
//       final Widget widget = route.build(MockBuildContext(), mockGoRouterState);
//       expect(widget, isA<SplashScreen>());
//     });

//     testWidgets('ErrorRoute builds Scaffold with error information', (
//       tester,
//     ) async {
//       when(mockGoRouterState.uri).thenReturn(Uri.parse('/invalid-path'));

//       await tester.pumpWidget(
//         MaterialApp(
//           localizationsDelegates: AppLocalizations.localizationsDelegates,
//           supportedLocales: AppLocalizations.supportedLocales,
//           home: Builder(
//             builder: (context) {
//               const route = ErrorRoute(error: 'Test Error');
//               return route.build(context, mockGoRouterState);
//             },
//           ),
//         ),
//       );

//       expect(find.byIcon(Icons.error), findsOneWidget);
//       expect(find.byType(ElevatedButton), findsOneWidget);
//     });

//     testWidgets('ErrorRoute navigation works', (tester) async {
//       final router = GoRouter(
//         initialLocation: '/error',
//         routes: [
//           GoRoute(path: '/', builder: (context, state) => const Text('Home')),
//           GoRoute(
//             path: '/error',
//             builder: (context, state) =>
//                 const ErrorRoute().build(context, state),
//           ),
//         ],
//       );

//       await tester.pumpWidget(
//         MaterialApp.router(
//           routerConfig: router,
//           localizationsDelegates: AppLocalizations.localizationsDelegates,
//           supportedLocales: AppLocalizations.supportedLocales,
//         ),
//       );

//       // Tap Go Home button (lines 135-138)
//       await tester.tap(find.byType(ElevatedButton));
//       await tester.pumpAndSettle();

//       expect(find.text('Home'), findsOneWidget);
//     });
//   });
// }

// class MockBuildContext extends Mock implements BuildContext {}

// class FakeAnalyticsService extends Fake implements AnalyticsService {
//   @override
//   Future<void> logScreenView(String screenName, {String? screenClass}) async {}
// }

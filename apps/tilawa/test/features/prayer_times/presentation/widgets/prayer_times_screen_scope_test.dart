import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart' as mocktail;
import 'package:tilawa/features/prayer_times/domain/services/adhan_alarm_player_interface.dart';
import 'package:tilawa/features/prayer_times/domain/usecases/fire_prayer_test_notification_use_case.dart';
import 'package:tilawa/features/prayer_times/presentation/bloc/prayer_permissions_cubit.dart';
import 'package:tilawa/features/prayer_times/presentation/bloc/prayer_times_bloc.dart';
import 'package:tilawa/features/prayer_times/presentation/screens/prayer_times_screen.dart';
import 'package:tilawa/features/prayer_times/presentation/widgets/prayer_times_screen_scope.dart';

import '../../../../support/screen_scope_test_support.dart';

class _MockPrayerTimesBloc extends mocktail.Mock implements PrayerTimesBloc {}

class _MockPrayerPermissionsCubit extends mocktail.Mock
    implements PrayerPermissionsCubit {}

class _MockAdhanAlarmPlayer extends mocktail.Mock implements IAdhanAlarmPlayer {}

class _MockFirePrayerTestNotificationUseCase extends mocktail.Mock
    implements FirePrayerTestNotificationUseCase {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  mocktail.registerFallbackValue(const PrayerTimesEvent.loadPrayerTimes());

  late _MockPrayerTimesBloc mockPrayerTimesBloc;
  late _MockPrayerPermissionsCubit mockPermissionsCubit;

  setUp(() async {
    await resetScopeGetIt();
    mockPrayerTimesBloc = _MockPrayerTimesBloc();
    mockPermissionsCubit = _MockPrayerPermissionsCubit();

    mocktail.when(() => mockPrayerTimesBloc.close()).thenAnswer((_) async {});
    mocktail.when(() => mockPrayerTimesBloc.state).thenReturn(
      const PrayerTimesState(),
    );
    mocktail.when(
      () => mockPrayerTimesBloc.stream,
    ).thenAnswer((_) => const Stream.empty());

    mocktail.when(() => mockPermissionsCubit.close()).thenAnswer((_) async {});
    mocktail.when(() => mockPermissionsCubit.state).thenReturn(
      const PrayerPermissionsState(),
    );
    mocktail.when(
      () => mockPermissionsCubit.stream,
    ).thenAnswer((_) => const Stream.empty());

    scopeGetIt().registerFactory<PrayerTimesBloc>(() => mockPrayerTimesBloc);
    scopeGetIt().registerFactory<PrayerPermissionsCubit>(
      () => mockPermissionsCubit,
    );
    scopeGetIt().registerSingleton<IAdhanAlarmPlayer>(_MockAdhanAlarmPlayer());
    scopeGetIt().registerSingleton<FirePrayerTestNotificationUseCase>(
      _MockFirePrayerTestNotificationUseCase(),
    );
  });

  tearDown(() async {
    await resetScopeGetIt();
  });

  testWidgets('provides PrayerTimesBloc and PrayerPermissionsCubit', (
    tester,
  ) async {
    PrayerTimesBloc? prayerTimesBloc;
    PrayerPermissionsCubit? permissionsCubit;

    await tester.pumpWidget(
      wrapScopeTest(
        home: PrayerTimesScreenScope(
          child: ScopeProbe(
            onBuilt: (context) {
              prayerTimesBloc = readScopeBloc<PrayerTimesBloc>(context);
              permissionsCubit = readScopeBloc<PrayerPermissionsCubit>(
                context,
              );
            },
          ),
        ),
      ),
    );

    expect(prayerTimesBloc, same(mockPrayerTimesBloc));
    expect(permissionsCubit, same(mockPermissionsCubit));
  });

  testWidgets('closes scoped blocs when unmounted', (tester) async {
    await tester.pumpWidget(
      wrapScopeTest(
        home: PrayerTimesScreenScope(
          child: ScopeProbe(
            onBuilt: (context) {
              readScopeBloc<PrayerTimesBloc>(context);
              readScopeBloc<PrayerPermissionsCubit>(context);
            },
          ),
        ),
      ),
    );

    await unmountScope(tester);

    mocktail.verify(() => mockPrayerTimesBloc.close()).called(1);
    mocktail.verify(() => mockPermissionsCubit.close()).called(1);
  });

  testWidgets('resolves fresh bloc instances from getIt on remount', (
    tester,
  ) async {
    var prayerTimesCreateCount = 0;
    var permissionsCreateCount = 0;

    scopeGetIt().unregister<PrayerTimesBloc>();
    scopeGetIt().unregister<PrayerPermissionsCubit>();

    scopeGetIt().registerFactory<PrayerTimesBloc>(() {
      prayerTimesCreateCount++;
      final mock = _MockPrayerTimesBloc();
      mocktail.when(() => mock.close()).thenAnswer((_) async {});
      mocktail.when(() => mock.state).thenReturn(const PrayerTimesState());
      mocktail.when(() => mock.stream).thenAnswer((_) => const Stream.empty());
      return mock;
    });
    scopeGetIt().registerFactory<PrayerPermissionsCubit>(() {
      permissionsCreateCount++;
      final mock = _MockPrayerPermissionsCubit();
      mocktail.when(() => mock.close()).thenAnswer((_) async {});
      mocktail.when(() => mock.state).thenReturn(
        const PrayerPermissionsState(),
      );
      mocktail.when(() => mock.stream).thenAnswer((_) => const Stream.empty());
      return mock;
    });

    await tester.pumpWidget(
      wrapScopeTest(
        home: PrayerTimesScreenScope(
          child: ScopeProbe(
            onBuilt: (context) {
              readScopeBloc<PrayerTimesBloc>(context);
              readScopeBloc<PrayerPermissionsCubit>(context);
            },
          ),
        ),
      ),
    );
    await unmountScope(tester);
    await tester.pumpWidget(
      wrapScopeTest(
        home: PrayerTimesScreenScope(
          child: ScopeProbe(
            onBuilt: (context) {
              readScopeBloc<PrayerTimesBloc>(context);
              readScopeBloc<PrayerPermissionsCubit>(context);
            },
          ),
        ),
      ),
    );

    expect(prayerTimesCreateCount, 2);
    expect(permissionsCreateCount, 2);
  });

  testWidgets('dispatches loadPrayerTimes when scope mounts', (tester) async {
    final loadMock = _MockPrayerTimesBloc();
    mocktail.when(() => loadMock.close()).thenAnswer((_) async {});
    mocktail.when(() => loadMock.state).thenReturn(const PrayerTimesState());
    mocktail.when(() => loadMock.stream).thenAnswer((_) => const Stream.empty());

    scopeGetIt().unregister<PrayerTimesBloc>();
    scopeGetIt().registerFactory<PrayerTimesBloc>(() => loadMock);

    await tester.pumpWidget(
      wrapScopeTest(
        home: PrayerTimesScreenScope(
          child: ScopeProbe(
            onBuilt: (context) {
              readScopeBloc<PrayerTimesBloc>(context);
            },
          ),
        ),
      ),
    );

    mocktail.verify(
      () => loadMock.add(const PrayerTimesEvent.loadPrayerTimes()),
    ).called(1);
  });

  testWidgets('renders probe child instead of PrayerTimesScreen', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrapScopeTest(
        home: PrayerTimesScreenScope(
          child: ScopeProbe(onBuilt: (_) {}),
        ),
      ),
    );

    expect(find.byKey(const Key('scope_probe')), findsOneWidget);
    expect(find.byType(PrayerTimesScreen), findsNothing);
  });

  testWidgets('wires PrayerTimesScreen with adhan dependencies by default', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrapScopeTest(home: const PrayerTimesScreenScope()),
    );

    expect(find.byType(PrayerTimesScreen), findsOneWidget);
  });
}

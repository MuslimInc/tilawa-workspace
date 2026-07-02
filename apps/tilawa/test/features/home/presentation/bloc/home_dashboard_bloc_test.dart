import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/home/data/datasources/home_dashboard_memory_cache.dart';
import 'package:tilawa/features/home/domain/entities/home_dashboard.dart';
import 'package:tilawa/features/home/domain/entities/home_prayer_slot.dart';
import 'package:tilawa/features/home/domain/repositories/home_dashboard_repository.dart';
import 'package:tilawa/features/home/domain/usecases/get_home_dashboard_use_case.dart';
import 'package:tilawa/features/home/presentation/bloc/home_dashboard_bloc.dart';
import 'package:tilawa/features/home/presentation/bloc/home_dashboard_event.dart';
import 'package:tilawa/features/home/presentation/bloc/home_dashboard_state.dart';
import 'package:tilawa/features/prayer_times/application/prayer_location_update_notifier.dart';
import 'package:tilawa/features/prayer_times/domain/entities/prayer_time_entity.dart';
import 'package:tilawa/features/prayer_times/domain/usecases/notify_prayer_location_updated_use_case.dart';

void main() {
  late HomeDashboardMemoryCache cache;
  late _FakeHomeDashboardRepository repository;
  late GetHomeDashboardUseCase useCase;
  late HomeDashboardBloc bloc;

  setUp(() {
    cache = HomeDashboardMemoryCache();
    cache.clear();
    repository = _FakeHomeDashboardRepository();
    useCase = GetHomeDashboardUseCase(repository, cache);
    bloc = HomeDashboardBloc(
      useCase,
      NotifyPrayerLocationUpdatedUseCase(PrayerLocationUpdateNotifier()),
    );
  });

  tearDown(() => bloc.close());

  blocTest<HomeDashboardBloc, HomeDashboardState>(
    'emits loading then loaded on cold start',
    build: () => bloc,
    act: (bloc) => bloc.add(const HomeDashboardStarted(localeIdentifier: 'en')),
    expect: () => [
      const HomeDashboardLoading(),
      isA<HomeDashboardLoaded>(),
    ],
  );

  blocTest<HomeDashboardBloc, HomeDashboardState>(
    'renders cached dashboard immediately then refreshes silently',
    build: () {
      cache.write(_dashboard);
      return bloc;
    },
    act: (bloc) => bloc.add(const HomeDashboardStarted(localeIdentifier: 'en')),
    expect: () => [
      isA<HomeDashboardLoaded>().having(
        (s) => s.dashboard,
        'dashboard',
        _dashboard,
      ),
    ],
    verify: (_) {
      expect(repository.getDashboardCallCount, 1);
    },
  );

  blocTest<HomeDashboardBloc, HomeDashboardState>(
    'pull-to-refresh keeps loaded state without entering loading',
    build: () => bloc,
    seed: () => HomeDashboardLoaded(_dashboard),
    act: (bloc) => bloc.add(
      const HomeDashboardRefreshRequested(localeIdentifier: 'en'),
    ),
    expect: () => [
      isA<HomeDashboardLoaded>()
          .having((s) => s.isRefreshing, 'isRefreshing', isTrue)
          .having((s) => s.dashboard, 'dashboard', _dashboard),
      isA<HomeDashboardLoaded>().having(
        (s) => s.isRefreshing,
        'isRefreshing',
        isFalse,
      ),
    ],
  );

  blocTest<HomeDashboardBloc, HomeDashboardState>(
    'refresh failure keeps stale dashboard and records refresh error',
    build: () {
      repository.shouldThrowOnGetDashboard = true;
      repository.throwMessage =
          'SocketException: Failed host lookup: example.com';
      return bloc;
    },
    seed: () => HomeDashboardLoaded(_dashboard),
    act: (bloc) => bloc.add(
      const HomeDashboardRefreshRequested(localeIdentifier: 'en'),
    ),
    expect: () => [
      isA<HomeDashboardLoaded>().having(
        (s) => s.isRefreshing,
        'isRefreshing',
        isTrue,
      ),
      isA<HomeDashboardLoaded>()
          .having((s) => s.isRefreshing, 'isRefreshing', isFalse)
          .having((s) => s.dashboard, 'dashboard', _dashboard)
          .having(
            (s) => s.refreshError,
            'refreshError',
            HomeDashboardFailureKind.offline,
          ),
    ],
  );

  blocTest<HomeDashboardBloc, HomeDashboardState>(
    'refresh failure never exposes raw exception text in state',
    build: () {
      repository.shouldThrowOnGetDashboard = true;
      repository.throwMessage = 'super secret internal diagnostic';
      return bloc;
    },
    seed: () => HomeDashboardLoaded(_dashboard),
    act: (bloc) => bloc.add(
      const HomeDashboardRefreshRequested(localeIdentifier: 'en'),
    ),
    verify: (bloc) {
      final HomeDashboardState state = bloc.state;
      expect(
        state,
        isA<HomeDashboardLoaded>().having(
          (s) => s.refreshError,
          'refreshError',
          HomeDashboardFailureKind.unknown,
        ),
      );
      // The state must carry no raw error strings at all.
      expect(state.props.whereType<String>(), isEmpty);
    },
  );

  blocTest<HomeDashboardBloc, HomeDashboardState>(
    'timeout errors are classified as timeout refresh error',
    build: () {
      repository.errorToThrow = TimeoutException('dashboard load');
      return bloc;
    },
    seed: () => HomeDashboardLoaded(_dashboard),
    act: (bloc) => bloc.add(
      const HomeDashboardRefreshRequested(localeIdentifier: 'en'),
    ),
    expect: () => [
      isA<HomeDashboardLoaded>().having(
        (s) => s.isRefreshing,
        'isRefreshing',
        isTrue,
      ),
      isA<HomeDashboardLoaded>().having(
        (s) => s.refreshError,
        'refreshError',
        HomeDashboardFailureKind.timeout,
      ),
    ],
  );

  blocTest<HomeDashboardBloc, HomeDashboardState>(
    'offline cold start without cache maps to offline failure',
    build: () {
      repository.shouldThrowOnGetDashboard = true;
      repository.throwMessage =
          'SocketException: Failed host lookup: example.com';
      return bloc;
    },
    act: (bloc) => bloc.add(const HomeDashboardStarted(localeIdentifier: 'en')),
    expect: () => [
      const HomeDashboardLoading(),
      isA<HomeDashboardFailure>().having(
        (s) => s.kind,
        'kind',
        HomeDashboardFailureKind.offline,
      ),
    ],
  );

  test('refreshAndWait completes after refresh finishes', () async {
    bloc.add(const HomeDashboardStarted(localeIdentifier: 'en'));
    await bloc.stream.firstWhere((state) => state is HomeDashboardLoaded);

    final Completer<HomeDashboard> pending = Completer<HomeDashboard>();
    repository.pendingDashboard = pending;

    final Future<void> refreshFuture = bloc.refreshAndWait(
      localeIdentifier: 'en',
    );
    await Future<void>.delayed(Duration.zero);
    expect(
      bloc.state,
      isA<HomeDashboardLoaded>().having(
        (s) => s.isRefreshing,
        'isRefreshing',
        isTrue,
      ),
    );

    pending.complete(_dashboard);
    await refreshFuture;
    expect(
      bloc.state,
      isA<HomeDashboardLoaded>().having(
        (s) => s.isRefreshing,
        'isRefreshing',
        isFalse,
      ),
    );
  });

  test('rapid refreshAndWait calls share one in-flight refresh', () async {
    bloc.add(const HomeDashboardStarted(localeIdentifier: 'en'));
    await bloc.stream.firstWhere((state) => state is HomeDashboardLoaded);
    expect(repository.getDashboardCallCount, 1);

    final Completer<HomeDashboard> pending = Completer<HomeDashboard>();
    repository.pendingDashboard = pending;

    final Future<void> first = bloc.refreshAndWait(localeIdentifier: 'en');
    final Future<void> second = bloc.refreshAndWait(localeIdentifier: 'en');
    await Future<void>.delayed(Duration.zero);

    pending.complete(_dashboard);
    await first;
    await second;
    // Let any (erroneously) queued duplicate refresh event drain.
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    // One call for the cold start plus a single shared refresh.
    expect(repository.getDashboardCallCount, 2);
  });
}

final HomeDashboard _dashboard = HomeDashboard(
  generatedAt: DateTime(2026, 6, 16, 18, 25),
  displayName: 'Muhammad Kamel',
  locationLabel: 'Cairo',
  nextPrayer: HomeNextPrayer(
    type: PrayerType.maghrib,
    time: DateTime(2026, 6, 16, 20, 0),
    timeUntil: const Duration(hours: 1, minutes: 35),
  ),
  todayPrayers: [
    HomePrayerSlot(
      type: PrayerType.maghrib,
      time: DateTime(2026, 6, 16, 20, 0),
      isNext: true,
      hasPassed: false,
    ),
  ],
);

class _FakeHomeDashboardRepository implements HomeDashboardRepository {
  int getDashboardCallCount = 0;
  bool shouldThrowOnGetDashboard = false;
  String throwMessage = 'boom';
  Object? errorToThrow;
  Completer<HomeDashboard>? pendingDashboard;

  @override
  Future<HomeDashboard> getDashboard({String? localeIdentifier}) async {
    getDashboardCallCount++;
    final Object? error = errorToThrow;
    if (error != null) {
      throw error;
    }
    if (shouldThrowOnGetDashboard) {
      throw Exception(throwMessage);
    }
    final Completer<HomeDashboard>? pending = pendingDashboard;
    if (pending != null) {
      return pending.future;
    }
    return _dashboard;
  }

  @override
  Future<HomeDashboard> refreshLocation({String? localeIdentifier}) async =>
      _dashboard;
}

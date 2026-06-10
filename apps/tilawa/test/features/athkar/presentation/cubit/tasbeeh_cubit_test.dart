import 'package:bloc_test/bloc_test.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/athkar/domain/constants/tasbeeh_constants.dart';
import 'package:tilawa/features/athkar/domain/entities/tasbeeh_dhikr.dart';
import 'package:tilawa/features/athkar/domain/repositories/tasbeeh_repository.dart';
import 'package:tilawa/features/athkar/domain/services/tasbeeh_target_feedback_service.dart';
import 'package:tilawa/features/athkar/presentation/cubit/tasbeeh_cubit.dart';
import 'package:tilawa/features/athkar/presentation/cubit/tasbeeh_state.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/utils/typedefs.dart';

import '../../helpers/tasbeeh_test_support.dart';

class _InMemoryTasbeehRepository implements TasbeehRepository {
  final Map<String, TasbeehDhikr> _store = {};
  Duration incrementDelay = Duration.zero;
  bool shouldFailLoad = false;

  @override
  ResultFuture<List<TasbeehDhikr>> getSavedDhikr() async {
    if (shouldFailLoad) {
      return const Left(CacheFailure('hive not ready'));
    }
    final items = _store.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return Right(items);
  }

  @override
  ResultFuture<TasbeehDhikr> saveCustomDhikr({
    required String text,
    required int targetCount,
  }) async {
    final normalized = text.trim();
    if (normalized.isEmpty) {
      return const Left(ValidationFailure('required'));
    }

    final now = DateTime(2026, 1, _store.length + 1);
    final item = TasbeehDhikr(
      id: (_store.length + 1).toString(),
      text: normalized,
      count: 0,
      targetCount: targetCount,
      targetReachedNotified: false,
      createdAt: now,
      updatedAt: now,
    );
    _store[item.id] = item;
    return Right(item);
  }

  @override
  ResultFuture<TasbeehDhikr> incrementCount(String dhikrId) async {
    if (incrementDelay > Duration.zero) {
      await Future<void>.delayed(incrementDelay);
    }
    final current = _store[dhikrId];
    if (current == null) return const Left(CacheFailure('missing'));
    final updated = current.copyWith(
      count: current.count + 1,
      targetReachedNotified:
          current.targetReachedNotified ||
          (!current.targetReachedNotified &&
              current.count < current.targetCount &&
              (current.count + 1) >= current.targetCount),
      updatedAt: DateTime(2026, 2, current.count + 1),
    );
    _store[dhikrId] = updated;
    return Right(updated);
  }

  @override
  ResultFuture<TasbeehDhikr> resetCount(String dhikrId) async {
    final current = _store[dhikrId];
    if (current == null) return const Left(CacheFailure('missing'));
    final updated = current.copyWith(
      count: 0,
      targetReachedNotified: false,
      updatedAt: DateTime(2026, 3, 1),
    );
    _store[dhikrId] = updated;
    return Right(updated);
  }

  @override
  ResultFuture<TasbeehDhikr> setTargetCount({
    required String dhikrId,
    required int targetCount,
  }) async {
    final current = _store[dhikrId];
    if (current == null) return const Left(CacheFailure('missing'));
    final updated = current.copyWith(
      targetCount: targetCount,
      targetReachedNotified: current.count >= targetCount,
      updatedAt: DateTime(2026, 4, 1),
    );
    _store[dhikrId] = updated;
    return Right(updated);
  }

  @override
  ResultVoid deleteDhikr(String dhikrId) async {
    if (!_store.containsKey(dhikrId)) {
      return const Left(CacheFailure('missing'));
    }
    _store.remove(dhikrId);
    return const Right(null);
  }

  @override
  ResultVoid deleteAllDhikr() async {
    _store.clear();
    return const Right(null);
  }

  @override
  ResultFuture<TasbeehDhikr> setReminder({
    required String dhikrId,
    required bool enabled,
    int? hour,
    int? minute,
  }) async {
    final current = _store[dhikrId];
    if (current == null) return const Left(CacheFailure('missing'));
    final updated = current.copyWith(
      reminderEnabled: enabled,
      reminderHour: enabled ? hour : null,
      reminderMinute: enabled ? minute : null,
      updatedAt: DateTime(2026, 5, 1),
    );
    _store[dhikrId] = updated;
    return Right(updated);
  }
}

class _FakeTasbeehTargetFeedbackService
    implements TasbeehTargetFeedbackService {
  int callCount = 0;

  @override
  Future<void> onTargetReached() async {
    callCount += 1;
  }
}

void main() {
  late TasbeehCubit cubit;
  late _InMemoryTasbeehRepository repository;
  late _FakeTasbeehTargetFeedbackService feedbackService;

  setUp(() {
    repository = _InMemoryTasbeehRepository()..shouldFailLoad = false;
    feedbackService = _FakeTasbeehTargetFeedbackService();
    cubit = buildTasbeehCubit(
      repository,
      feedbackService: feedbackService,
    );
  });

  tearDown(() async {
    await cubit.close();
  });

  blocTest<TasbeehCubit, TasbeehState>(
    'loadSavedDhikr emits loading then loaded',
    build: () => cubit,
    act: (cubit) => cubit.loadSavedDhikr(),
    expect: () => [
      const TasbeehState(status: TasbeehStatus.loading),
      TasbeehState(
        status: TasbeehStatus.loaded,
        draftTargetText: TasbeehConstants.defaultTargetCount.toString(),
      ),
    ],
  );

  blocTest<TasbeehCubit, TasbeehState>(
    'loadSavedDhikr with openDhikrId opens counting for matching dhikr',
    build: () => cubit,
    setUp: () async {
      await repository.saveCustomDhikr(text: 'abc', targetCount: 10);
    },
    act: (cubit) => cubit.loadSavedDhikr(openDhikrId: '1'),
    expect: () => [
      const TasbeehState(status: TasbeehStatus.loading),
      isA<TasbeehState>()
          .having((s) => s.status, 'status', TasbeehStatus.loaded)
          .having(
            (s) => s.viewMode,
            'viewMode',
            TasbeehViewMode.selectedCounting,
          )
          .having((s) => s.activeSavedDhikrId, 'activeId', '1')
          .having((s) => s.savedDhikr.length, 'saved count', 1)
          .having((s) => s.savedDhikr.first.text, 'text', 'abc'),
    ],
  );

  blocTest<TasbeehCubit, TasbeehState>(
    'loadSavedDhikr with unknown openDhikrId stays on home view',
    build: () => cubit,
    setUp: () async {
      await repository.saveCustomDhikr(text: 'abc', targetCount: 10);
    },
    act: (cubit) => cubit.loadSavedDhikr(openDhikrId: 'missing'),
    expect: () => [
      const TasbeehState(status: TasbeehStatus.loading),
      isA<TasbeehState>()
          .having((s) => s.status, 'status', TasbeehStatus.loaded)
          .having((s) => s.viewMode, 'viewMode', TasbeehViewMode.home)
          .having((s) => s.activeSavedDhikrId, 'activeId', isNull)
          .having((s) => s.savedDhikr.length, 'saved count', 1),
    ],
  );

  blocTest<TasbeehCubit, TasbeehState>(
    'loadSavedDhikr emits error when repository fails',
    build: () => cubit,
    setUp: () {
      repository.shouldFailLoad = true;
    },
    act: (cubit) => cubit.loadSavedDhikr(),
    expect: () => [
      const TasbeehState(status: TasbeehStatus.loading),
      isA<TasbeehState>()
          .having((s) => s.status, 'status', TasbeehStatus.error)
          .having((s) => s.savedDhikr, 'savedDhikr', isEmpty),
    ],
  );

  blocTest<TasbeehCubit, TasbeehState>(
    'saveDraftDhikr saves draft and selects it',
    build: () => cubit,
    seed: () => const TasbeehState(
      status: TasbeehStatus.loaded,
      draftText: 'Subhan Allah',
      draftTargetText: '33',
    ),
    act: (cubit) => cubit.saveDraftDhikr(),
    expect: () => [
      isA<TasbeehState>()
          .having((s) => s.status, 'status', TasbeehStatus.loaded)
          .having(
            (s) => s.viewMode,
            'viewMode',
            TasbeehViewMode.selectedCounting,
          )
          .having((s) => s.savedDhikr.length, 'saved count', 1)
          .having((s) => s.activeSavedDhikrId, 'selected', '1')
          .having((s) => s.draftText, 'draft', ''),
    ],
  );

  blocTest<TasbeehCubit, TasbeehState>(
    'showHomeView clears selected dhikr and returns to home',
    build: () => cubit,
    seed: () {
      final item = TasbeehDhikr(
        id: '1',
        text: 'Subhan Allah',
        count: 2,
        targetCount: 33,
        targetReachedNotified: false,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      return TasbeehState(
        status: TasbeehStatus.loaded,
        viewMode: TasbeehViewMode.selectedCounting,
        savedDhikr: [item],
        activeSavedDhikrId: '1',
      );
    },
    act: (cubit) => cubit.showHomeView(),
    expect: () => [
      isA<TasbeehState>()
          .having((s) => s.viewMode, 'viewMode', TasbeehViewMode.home)
          .having((s) => s.activeSavedDhikrId, 'selected', isNull),
    ],
  );

  blocTest<TasbeehCubit, TasbeehState>(
    'selectDhikrAndStartCounting opens selected counting mode',
    build: () => cubit,
    seed: () {
      final item = TasbeehDhikr(
        id: '1',
        text: 'Subhan Allah',
        count: 0,
        targetCount: 33,
        targetReachedNotified: false,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      return TasbeehState(
        status: TasbeehStatus.loaded,
        viewMode: TasbeehViewMode.home,
        savedDhikr: [item],
      );
    },
    act: (cubit) => cubit.selectDhikrAndStartCounting('1'),
    expect: () => [
      isA<TasbeehState>()
          .having(
            (s) => s.viewMode,
            'viewMode',
            TasbeehViewMode.selectedCounting,
          )
          .having((s) => s.activeSavedDhikrId, 'selected', '1')
          .having((s) => s.activeSavedDhikr?.text, 'text', 'Subhan Allah'),
    ],
  );

  blocTest<TasbeehCubit, TasbeehState>(
    'showCreateView clears draft text and target',
    build: () => cubit,
    seed: () => const TasbeehState(
      status: TasbeehStatus.loaded,
      viewMode: TasbeehViewMode.home,
      draftText: 'Subhan Allah',
      draftTargetText: '10',
    ),
    act: (cubit) => cubit.showCreateView(),
    expect: () => [
      TasbeehState(
        status: TasbeehStatus.loaded,
        viewMode: TasbeehViewMode.create,
        draftText: '',
        draftTargetText: TasbeehConstants.defaultTargetCount.toString(),
      ),
    ],
  );

  blocTest<TasbeehCubit, TasbeehState>(
    'incrementEphemeralCount never triggers target feedback',
    build: () => cubit,
    seed: () => const TasbeehState(
      status: TasbeehStatus.loaded,
      viewMode: TasbeehViewMode.quickCount,
      ephemeralCount: 10,
    ),
    act: (cubit) {
      cubit.incrementEphemeralCount();
      cubit.incrementEphemeralCount();
    },
    verify: (_) {
      expect(feedbackService.callCount, 0);
    },
  );

  blocTest<TasbeehCubit, TasbeehState>(
    'incrementSelected updates count immediately',
    build: () => cubit,
    seed: () {
      final item = TasbeehDhikr(
        id: '1',
        text: 'Subhan Allah',
        count: 2,
        targetCount: 3,
        targetReachedNotified: false,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      repository._store['1'] = item;
      return TasbeehState(
        status: TasbeehStatus.loaded,
        viewMode: TasbeehViewMode.selectedCounting,
        savedDhikr: [item],
        activeSavedDhikrId: '1',
      );
    },
    act: (cubit) => cubit.incrementSelected(),
    expect: () => [
      isA<TasbeehState>().having((s) => s.activeSavedDhikr!.count, 'count', 3),
      isA<TasbeehState>().having((s) => s.activeSavedDhikr!.count, 'count', 3),
    ],
    verify: (_) {
      expect(feedbackService.callCount, 1);
    },
  );

  blocTest<TasbeehCubit, TasbeehState>(
    'resetSelected resets the current count',
    build: () => cubit,
    seed: () {
      final item = TasbeehDhikr(
        id: '1',
        text: 'Subhan Allah',
        count: 5,
        targetCount: 7,
        targetReachedNotified: false,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      repository._store['1'] = item;
      return TasbeehState(
        status: TasbeehStatus.loaded,
        viewMode: TasbeehViewMode.selectedCounting,
        savedDhikr: [item],
        activeSavedDhikrId: '1',
      );
    },
    act: (cubit) => cubit.resetSelected(),
    expect: () => [
      isA<TasbeehState>().having((s) => s.activeSavedDhikr!.count, 'count', 0),
      isA<TasbeehState>().having((s) => s.activeSavedDhikr!.count, 'count', 0),
    ],
  );

  blocTest<TasbeehCubit, TasbeehState>(
    'setTargetForSelected updates selected target',
    build: () => cubit,
    seed: () {
      final item = TasbeehDhikr(
        id: '1',
        text: 'Subhan Allah',
        count: 1,
        targetCount: 33,
        targetReachedNotified: false,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      repository._store['1'] = item;
      return TasbeehState(
        status: TasbeehStatus.loaded,
        savedDhikr: [item],
        activeSavedDhikrId: '1',
        draftTargetText: '7',
      );
    },
    act: (cubit) => cubit.setTargetForSelected(),
    expect: () => [
      isA<TasbeehState>().having(
        (s) => s.activeSavedDhikr?.targetCount,
        'target',
        7,
      ),
    ],
  );

  blocTest<TasbeehCubit, TasbeehState>(
    'does not vibrate when target was already reached',
    build: () => cubit,
    seed: () {
      final item = TasbeehDhikr(
        id: '1',
        text: 'Subhan Allah',
        count: 3,
        targetCount: 3,
        targetReachedNotified: true,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      repository._store['1'] = item;
      return TasbeehState(
        status: TasbeehStatus.loaded,
        savedDhikr: [item],
        viewMode: TasbeehViewMode.selectedCounting,
        activeSavedDhikrId: '1',
      );
    },
    act: (cubit) => cubit.incrementSelected(),
    verify: (_) {
      expect(feedbackService.callCount, 0);
    },
  );

  blocTest<TasbeehCubit, TasbeehState>(
    'does not vibrate for previous tasbeeh after switching selection',
    build: () => cubit,
    seed: () {
      final first = TasbeehDhikr(
        id: '1',
        text: 'First',
        count: 2,
        targetCount: 3,
        targetReachedNotified: false,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      final second = TasbeehDhikr(
        id: '2',
        text: 'Second',
        count: 0,
        targetCount: 5,
        targetReachedNotified: false,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      repository._store['1'] = first;
      repository._store['2'] = second;
      repository.incrementDelay = const Duration(milliseconds: 20);
      return TasbeehState(
        status: TasbeehStatus.loaded,
        viewMode: TasbeehViewMode.selectedCounting,
        savedDhikr: [first, second],
        activeSavedDhikrId: '1',
      );
    },
    act: (cubit) async {
      final future = cubit.incrementSelected();
      cubit.selectDhikr('2');
      await future;
    },
    verify: (_) {
      expect(feedbackService.callCount, 0);
    },
  );

  blocTest<TasbeehCubit, TasbeehState>(
    'removeSelected removes current item and selects next available',
    build: () => cubit,
    seed: () {
      final item1 = TasbeehDhikr(
        id: '1',
        text: 'First',
        count: 0,
        targetCount: 33,
        targetReachedNotified: false,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026, 1, 2),
      );
      final item2 = TasbeehDhikr(
        id: '2',
        text: 'Second',
        count: 0,
        targetCount: 10,
        targetReachedNotified: false,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026, 1, 1),
      );
      repository._store['1'] = item1;
      repository._store['2'] = item2;
      return TasbeehState(
        status: TasbeehStatus.loaded,
        savedDhikr: [item1, item2],
        activeSavedDhikrId: '1',
      );
    },
    act: (cubit) => cubit.removeSelected(),
    expect: () => [
      isA<TasbeehState>()
          .having((s) => s.savedDhikr.length, 'length', 1)
          .having((s) => s.activeSavedDhikrId, 'selected', isNull),
    ],
  );

  blocTest<TasbeehCubit, TasbeehState>(
    'removeDhikr removes specific item from history',
    build: () => cubit,
    seed: () {
      final item1 = TasbeehDhikr(
        id: '1',
        text: 'First',
        count: 0,
        targetCount: 33,
        targetReachedNotified: false,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      final item2 = TasbeehDhikr(
        id: '2',
        text: 'Second',
        count: 0,
        targetCount: 5,
        targetReachedNotified: false,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      repository._store['1'] = item1;
      repository._store['2'] = item2;
      return TasbeehState(
        status: TasbeehStatus.loaded,
        savedDhikr: [item1, item2],
        activeSavedDhikrId: '2',
      );
    },
    act: (cubit) => cubit.removeDhikr('1'),
    expect: () => [
      isA<TasbeehState>()
          .having((s) => s.savedDhikr.length, 'length', 1)
          .having((s) => s.savedDhikr.first.id, 'remaining id', '2'),
    ],
  );
}

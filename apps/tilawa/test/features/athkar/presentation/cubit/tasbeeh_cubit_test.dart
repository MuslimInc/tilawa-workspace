import 'package:bloc_test/bloc_test.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/athkar/domain/constants/tasbeeh_constants.dart';
import 'package:tilawa/features/athkar/domain/entities/tasbeeh_dhikr.dart';
import 'package:tilawa/features/athkar/domain/repositories/tasbeeh_repository.dart';
import 'package:tilawa/features/athkar/domain/services/tasbeeh_target_feedback_service.dart';
import 'package:tilawa/features/athkar/domain/usecases/delete_tasbeeh_dhikr_use_case.dart';
import 'package:tilawa/features/athkar/domain/usecases/get_saved_tasbeeh_use_case.dart';
import 'package:tilawa/features/athkar/domain/usecases/increment_tasbeeh_count_use_case.dart';
import 'package:tilawa/features/athkar/domain/usecases/reset_tasbeeh_count_use_case.dart';
import 'package:tilawa/features/athkar/domain/usecases/save_custom_tasbeeh_use_case.dart';
import 'package:tilawa/features/athkar/domain/usecases/set_tasbeeh_target_count_use_case.dart';
import 'package:tilawa/features/athkar/presentation/cubit/tasbeeh_cubit.dart';
import 'package:tilawa/features/athkar/presentation/cubit/tasbeeh_state.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/utils/typedefs.dart';

class _InMemoryTasbeehRepository implements TasbeehRepository {
  final Map<String, TasbeehDhikr> _store = {};
  Duration incrementDelay = Duration.zero;

  @override
  ResultFuture<List<TasbeehDhikr>> getSavedDhikr() async {
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
    repository = _InMemoryTasbeehRepository();
    feedbackService = _FakeTasbeehTargetFeedbackService();
    cubit = TasbeehCubit(
      GetSavedTasbeehUseCase(repository),
      SaveCustomTasbeehUseCase(repository),
      IncrementTasbeehCountUseCase(repository),
      ResetTasbeehCountUseCase(repository),
      SetTasbeehTargetCountUseCase(repository),
      DeleteTasbeehDhikrUseCase(repository),
      feedbackService,
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
          .having((s) => s.savedDhikr.length, 'saved count', 1)
          .having((s) => s.selectedDhikrId, 'selected', '1')
          .having((s) => s.draftText, 'draft', ''),
    ],
  );

  blocTest<TasbeehCubit, TasbeehState>(
    'showCreateView clears draft text and target',
    build: () => cubit,
    seed: () => const TasbeehState(
      status: TasbeehStatus.loaded,
      viewMode: TasbeehViewMode.options,
      draftText: 'Subhan Allah',
      draftTargetText: '10',
    ),
    act: (cubit) => cubit.showCreateView(),
    expect: () => [
      const TasbeehState(
        status: TasbeehStatus.loaded,
        viewMode: TasbeehViewMode.create,
        draftText: '',
        draftTargetText: '',
      ),
    ],
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
        savedDhikr: [item],
        selectedDhikrId: '1',
      );
    },
    act: (cubit) => cubit.incrementSelected(),
    expect: () => [
      isA<TasbeehState>().having((s) => s.selectedCount, 'count', 3),
      isA<TasbeehState>().having((s) => s.selectedCount, 'count', 3),
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
        savedDhikr: [item],
        selectedDhikrId: '1',
      );
    },
    act: (cubit) => cubit.resetSelected(),
    expect: () => [
      isA<TasbeehState>().having((s) => s.selectedCount, 'count', 0),
      isA<TasbeehState>().having((s) => s.selectedCount, 'count', 0),
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
        selectedDhikrId: '1',
        draftTargetText: '7',
      );
    },
    act: (cubit) => cubit.setTargetForSelected(),
    expect: () => [
      isA<TasbeehState>().having(
        (s) => s.selectedDhikr?.targetCount,
        'target',
        7,
      ),
    ],
  );

  blocTest<TasbeehCubit, TasbeehState>(
    'vibrates when incrementing beyond target',
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
        selectedDhikrId: '1',
      );
    },
    act: (cubit) => cubit.incrementSelected(),
    verify: (_) {
      expect(feedbackService.callCount, 1);
    },
  );

  blocTest<TasbeehCubit, TasbeehState>(
    'vibrates when incrementing while already above target',
    build: () => cubit,
    seed: () {
      final item = TasbeehDhikr(
        id: '1',
        text: 'Subhan Allah',
        count: 4,
        targetCount: 3,
        targetReachedNotified: true,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      repository._store['1'] = item;
      return TasbeehState(
        status: TasbeehStatus.loaded,
        savedDhikr: [item],
        selectedDhikrId: '1',
      );
    },
    act: (cubit) => cubit.incrementSelected(),
    verify: (_) {
      expect(feedbackService.callCount, 1);
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
        savedDhikr: [first, second],
        selectedDhikrId: '1',
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
        selectedDhikrId: '1',
      );
    },
    act: (cubit) => cubit.removeSelected(),
    expect: () => [
      isA<TasbeehState>()
          .having((s) => s.savedDhikr.length, 'length', 1)
          .having((s) => s.selectedDhikrId, 'selected', '2')
          .having((s) => s.draftTargetText, 'target text', '10'),
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
        selectedDhikrId: '2',
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

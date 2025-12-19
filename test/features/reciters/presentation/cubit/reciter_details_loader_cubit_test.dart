import 'package:bloc_test/bloc_test.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:muzakri/core/entities/reciter_entity.dart';
import 'package:muzakri/core/errors/failures.dart';
import 'package:muzakri/core/utils/typedefs.dart';
import 'package:muzakri/features/reciters/domain/repositories/reciters_repository.dart';
import 'package:muzakri/features/reciters/presentation/cubit/reciter_details_loader_cubit.dart';
import 'package:muzakri/features/reciters/presentation/cubit/reciter_details_loader_state.dart';

import 'reciter_details_loader_cubit_test.mocks.dart';

@GenerateMocks([RecitersRepository])
void main() {
  late MockRecitersRepository mockRepository;
  late ReciterDetailsLoaderCubit cubit;

  setUp(() {
    provideDummy<ResultFuture<ReciterEntity?>>(Future.value(const Right(null)));
    provideDummy<Either<Failure, ReciterEntity?>>(const Right(null));
    mockRepository = MockRecitersRepository();
    cubit = ReciterDetailsLoaderCubit(mockRepository);
  });

  tearDown(() {
    cubit.close();
  });

  const tReciterId = '1';
  const tReciter = ReciterEntity(
    id: 1,
    name: 'Test Reciter',
    letter: 'T',
    date: '2023',
    moshaf: [],
  );

  group('ReciterDetailsLoaderCubit', () {
    test('initial state should be ReciterDetailsLoaderInitial', () {
      expect(cubit.state, const ReciterDetailsLoaderInitial());
    });

    blocTest<ReciterDetailsLoaderCubit, ReciterDetailsLoaderState>(
      'emits [Loading, Success] when data is gotten successfully',
      build: () {
        when(
          mockRepository.getReciterById(tReciterId),
        ).thenAnswer((_) async => const Right(tReciter));
        return cubit;
      },
      act: (cubit) => cubit.loadReciter(tReciterId),
      expect: () => [
        const ReciterDetailsLoaderLoading(),
        const ReciterDetailsLoaderSuccess(tReciter),
      ],
      verify: (_) {
        verify(mockRepository.getReciterById(tReciterId));
      },
    );

    blocTest<ReciterDetailsLoaderCubit, ReciterDetailsLoaderState>(
      'emits [Loading, Failure] when getting data fails',
      build: () {
        when(
          mockRepository.getReciterById(tReciterId),
        ).thenAnswer((_) async => const Left(ServerFailure('Server Error')));
        return cubit;
      },
      act: (cubit) => cubit.loadReciter(tReciterId),
      expect: () => [
        const ReciterDetailsLoaderLoading(),
        const ReciterDetailsLoaderFailure('Server Error'),
      ],
      verify: (_) {
        verify(mockRepository.getReciterById(tReciterId));
      },
    );

    blocTest<ReciterDetailsLoaderCubit, ReciterDetailsLoaderState>(
      'emits [Loading, Failure] when reciter is null (success but not found)',
      build: () {
        when(
          mockRepository.getReciterById(tReciterId),
        ).thenAnswer((_) async => const Right(null));
        return cubit;
      },
      act: (cubit) => cubit.loadReciter(tReciterId),
      expect: () => [
        const ReciterDetailsLoaderLoading(),
        const ReciterDetailsLoaderFailure('Reciter not found'),
      ],
      verify: (_) {
        verify(mockRepository.getReciterById(tReciterId));
      },
    );
    blocTest<ReciterDetailsLoaderCubit, ReciterDetailsLoaderState>(
      'emits [Loading, Failure] when getting data fails with unknown error',
      build: () {
        when(
          mockRepository.getReciterById(tReciterId),
        ).thenAnswer((_) async => const Left(ServerFailure()));
        return cubit;
      },
      act: (cubit) => cubit.loadReciter(tReciterId),
      expect: () => [
        const ReciterDetailsLoaderLoading(),
        const ReciterDetailsLoaderFailure('Unknown error'),
      ],
      verify: (_) {
        verify(mockRepository.getReciterById(tReciterId));
      },
    );
  });
}

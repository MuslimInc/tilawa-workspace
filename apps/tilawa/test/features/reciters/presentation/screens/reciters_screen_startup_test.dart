import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/features/reciters/domain/usecases/get_reciters_use_case.dart';
import 'package:tilawa/features/reciters/presentation/bloc/reciters_bloc.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:dartz_plus/dartz_plus.dart';

import 'reciters_screen_startup_test.mocks.dart';

@GenerateMocks([GetRecitersUseCase])
void main() {
  provideDummy<Either<Failure, List<ReciterEntity>>>(
    const Right<Failure, List<ReciterEntity>>(<ReciterEntity>[]),
  );

  const reciters = <ReciterEntity>[
    ReciterEntity(
      id: 1,
      name: 'Alpha Reciter',
      letter: 'A',
      date: '',
      moshaf: [],
    ),
  ];

  late MockGetRecitersUseCase mockGetReciters;
  late RecitersBloc bloc;

  setUp(() {
    mockGetReciters = MockGetRecitersUseCase();
    bloc = RecitersBloc(mockGetReciters);
  });

  tearDown(() async {
    await bloc.close();
  });

  group('RecitersScreen startup (bloc contract)', () {
    test('splash precache leaves bloc in RecitersLoaded', () async {
      when(mockGetReciters.call()).thenAnswer(
        (_) async => const Right<Failure, List<ReciterEntity>>(reciters),
      );

      bloc.add(const LoadReciters());
      await bloc.stream.firstWhere((s) => s is RecitersLoaded);

      final RecitersLoaded loaded = bloc.state as RecitersLoaded;
      expect(loaded.reciters, reciters);
      verify(mockGetReciters.call()).called(1);
    });

    test('second LoadReciters reuses use case when data already loaded', () async {
      when(mockGetReciters.call()).thenAnswer(
        (_) async => const Right<Failure, List<ReciterEntity>>(reciters),
      );

      bloc.add(const LoadReciters());
      await bloc.stream.firstWhere((s) => s is RecitersLoaded);
      bloc.add(const LoadReciters());
      await bloc.stream.firstWhere((s) => s is RecitersLoaded);

      verify(mockGetReciters.call()).called(2);
    });
  });
}

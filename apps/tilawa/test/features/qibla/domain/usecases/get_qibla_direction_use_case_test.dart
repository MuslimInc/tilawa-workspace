import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa_core/usecases/usecase.dart';
import 'package:tilawa/features/qibla/domain/entities/qibla_direction_entity.dart';
import 'package:tilawa/features/qibla/domain/repositories/qibla_repository.dart';
import 'package:tilawa/features/qibla/domain/usecases/get_qibla_direction_use_case.dart';

import 'get_qibla_direction_use_case_test.mocks.dart';

@GenerateMocks([QiblaRepository])
void main() {
  late GetQiblaDirectionUseCase useCase;
  late MockQiblaRepository mockQiblaRepository;

  setUp(() {
    mockQiblaRepository = MockQiblaRepository();
    useCase = GetQiblaDirectionUseCase(mockQiblaRepository);
  });

  test('should return stream from repository', () {
    const tQiblaDirection = QiblaDirectionEntity(
      qibla: 100,
      direction: 90,
      offset: 10,
    );
    when(
      mockQiblaRepository.getQiblaDirection(),
    ).thenAnswer((_) => Stream.value(tQiblaDirection));

    final Stream<QiblaDirectionEntity> result = useCase(const NoParams());

    expect(result, emits(tQiblaDirection));
    verify(mockQiblaRepository.getQiblaDirection()).called(1);
    verifyNoMoreInteractions(mockQiblaRepository);
  });
}

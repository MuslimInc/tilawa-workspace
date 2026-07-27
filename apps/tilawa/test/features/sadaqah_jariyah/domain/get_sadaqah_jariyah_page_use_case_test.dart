import 'package:checks/checks.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/sadaqah_jariyah/domain/entities/dedication.dart';
import 'package:tilawa/features/sadaqah_jariyah/domain/entities/sadaqah_jariyah_page_data.dart';
import 'package:tilawa/features/sadaqah_jariyah/domain/repositories/dedications_repository.dart';
import 'package:tilawa/features/sadaqah_jariyah/domain/repositories/sadaqah_jariyah_config_repository.dart';
import 'package:tilawa/features/sadaqah_jariyah/domain/usecases/get_sadaqah_jariyah_page_use_case.dart';
import 'package:tilawa_core/errors/failures.dart';

class _MockDedicationsRepository extends Mock
    implements DedicationsRepository {}

class _MockConfigRepository extends Mock
    implements SadaqahJariyahConfigRepository {}

void main() {
  test('config failure disables the public feature', () async {
    final _MockDedicationsRepository dedications = _MockDedicationsRepository();
    final _MockConfigRepository config = _MockConfigRepository();
    when(
      dedications.getPublishedDedications,
    ).thenAnswer((_) async => const Right(<Dedication>[]));
    when(config.getConfig).thenAnswer(
      (_) async => Left(Failure.unexpectedError('config unavailable')),
    );

    final GetSadaqahJariyahPageUseCase useCase = GetSadaqahJariyahPageUseCase(
      dedications,
      config,
    );
    final Either<Failure, SadaqahJariyahPageData> pageResult = await useCase(
      const GetSadaqahJariyahPageParams(),
    );

    check(pageResult.isRight()).isTrue();
    check(
      pageResult
          .getOrElse(
            () => throw StateError('expected page data'),
          )
          .config
          .featureEnabled,
    ).isFalse();
  });
}

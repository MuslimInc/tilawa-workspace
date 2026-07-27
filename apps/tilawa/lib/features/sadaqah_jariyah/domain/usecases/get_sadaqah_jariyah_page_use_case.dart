import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/usecases/usecase.dart';

import '../entities/dedication.dart';
import '../entities/sadaqah_jariyah_config.dart';
import '../entities/sadaqah_jariyah_page_data.dart';
import '../repositories/dedications_repository.dart';
import '../repositories/sadaqah_jariyah_config_repository.dart';
import 'sort_dedications_for_display_use_case.dart';

class GetSadaqahJariyahPageParams {
  const GetSadaqahJariyahPageParams();
}

@lazySingleton
class GetSadaqahJariyahPageUseCase
    implements UseCase<SadaqahJariyahPageData, GetSadaqahJariyahPageParams> {
  GetSadaqahJariyahPageUseCase(
    this._dedicationsRepository,
    this._configRepository,
  );

  final DedicationsRepository _dedicationsRepository;
  final SadaqahJariyahConfigRepository _configRepository;

  @override
  Future<Either<Failure, SadaqahJariyahPageData>> call(
    GetSadaqahJariyahPageParams params,
  ) async {
    final Either<Failure, List<Dedication>> dedicationsResult =
        await _dedicationsRepository.getPublishedDedications();

    return dedicationsResult.foldAsync(
      (Failure failure) async => Left(failure),
      (List<Dedication> dedications) async {
        final Either<Failure, SadaqahJariyahConfig> configResult =
            await _configRepository.getConfig();
        final SadaqahJariyahConfig config = configResult.fold(
          (_) => const SadaqahJariyahConfig(featureEnabled: false),
          (SadaqahJariyahConfig c) => c,
        );
        return Right(
          SadaqahJariyahPageData(
            config: config,
            dedications: sortDedicationsForDisplay(dedications),
          ),
        );
      },
    );
  }
}

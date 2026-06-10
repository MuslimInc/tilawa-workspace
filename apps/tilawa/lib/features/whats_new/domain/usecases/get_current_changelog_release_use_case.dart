import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../entities/changelog_release.dart';
import '../repositories/changelog_repository.dart';

/// Resolves the changelog entry for the installed app version.
@lazySingleton
class GetCurrentChangelogReleaseUseCase {
  GetCurrentChangelogReleaseUseCase(this._changelogRepository);

  final ChangelogRepository _changelogRepository;

  Future<Either<Failure, ChangelogRelease>> call() {
    return _changelogRepository.getReleaseForCurrentApp();
  }
}

import 'package:dartz_plus/dartz_plus.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../entities/changelog_release.dart';

abstract interface class ChangelogRepository {
  Future<Either<Failure, ChangelogRelease>> getReleaseForCurrentApp();
}

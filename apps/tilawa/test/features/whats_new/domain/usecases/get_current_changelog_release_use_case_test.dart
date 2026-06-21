import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/whats_new/domain/entities/changelog_release.dart';
import 'package:tilawa/features/whats_new/domain/repositories/changelog_repository.dart';
import 'package:tilawa/features/whats_new/domain/usecases/get_current_changelog_release_use_case.dart';
import 'package:tilawa_core/errors/failures.dart';

class _FakeChangelogRepository implements ChangelogRepository {
  @override
  Future<Either<Failure, ChangelogRelease>> getReleaseForCurrentApp() async {
    return const Right(
      ChangelogRelease(
        id: '2.0.8+52',
        version: '2.0.8',
        buildNumber: 52,
        highlightsByLocale: <String, List<String>>{
          'en': <String>['Highlight'],
        },
      ),
    );
  }
}

void main() {
  test('returns the repository release for the installed app', () async {
    final result = await GetCurrentChangelogReleaseUseCase(
      _FakeChangelogRepository(),
    )();

    expect(result.isRight(), isTrue);
    expect(result.fold((_) => null, (r) => r.id), '2.0.8+52');
  });
}

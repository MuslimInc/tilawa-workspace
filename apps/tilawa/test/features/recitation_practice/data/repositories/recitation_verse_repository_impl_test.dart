import 'package:flutter_test/flutter_test.dart';
import 'package:quran_qcf/quran_qcf.dart';
import 'package:tilawa/features/recitation_practice/data/repositories/recitation_verse_repository_impl.dart';
import 'package:tilawa/features/recitation_practice/domain/entities/recitation_target.dart';

void main() {
  late RecitationVerseRepositoryImpl repository;

  setUp(() {
    repository = RecitationVerseRepositoryImpl(const VerseServiceImpl());
  });

  test('returns ayah targets for a Mushaf page', () {
    final List<RecitationTarget> targets = repository.getTargetsForPage(1);

    expect(targets, isNotEmpty);
    expect(targets.first.surahNumber, 1);
    expect(targets.first.normalText, isNotEmpty);
    expect(targets.first.displayText, isNotEmpty);
  });
}

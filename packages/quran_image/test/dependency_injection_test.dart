import 'package:flutter_test/flutter_test.dart';
import 'package:quran_image/core/di/dependency_injection.dart';
import 'package:quran_image/data/data.dart';
import 'package:quran_image/domain/domain.dart';

void main() {
  tearDown(sl.reset);

  test('VerseMarkerRepository resolves to the asset repository', () async {
    await initDependencies();

    expect(sl<VerseMarkerRepository>(), isA<AssetVerseMarkerRepository>());
  });
}

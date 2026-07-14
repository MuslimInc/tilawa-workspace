import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:quran_image/core/di/dependency_injection.dart';
import 'package:quran_image/data/data.dart';
import 'package:quran_image/domain/domain.dart';

void main() {
  setUp(() {
    GetIt.noDebugOutput = true;
  });

  tearDown(() async {
    await sl.reset();
  });

  test(
    'VerseMarkerRepository resolves to the asset repository without recursing',
    () async {
      await initDependencies();

      // Guards against factory tear-offs like `sl.call` / untyped `sl.get`,
      // which re-enter getIt for the same type and StackOverflow on reader open.
      final VerseMarkerRepository repo = sl<VerseMarkerRepository>();
      expect(repo, isA<AssetVerseMarkerRepository>());
      expect(identical(repo, sl<AssetVerseMarkerRepository>()), isTrue);
    },
  );
}

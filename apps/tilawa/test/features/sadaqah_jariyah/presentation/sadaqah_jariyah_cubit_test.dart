import 'dart:async';

import 'package:checks/checks.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/sadaqah_jariyah/domain/entities/dedication.dart';
import 'package:tilawa/features/sadaqah_jariyah/domain/entities/sadaqah_jariyah_config.dart';
import 'package:tilawa/features/sadaqah_jariyah/domain/entities/sadaqah_jariyah_page_data.dart';
import 'package:tilawa/features/sadaqah_jariyah/domain/enums/dedication_status.dart';
import 'package:tilawa/features/sadaqah_jariyah/domain/services/dedication_photo_url_resolver.dart';
import 'package:tilawa/features/sadaqah_jariyah/domain/usecases/get_sadaqah_jariyah_page_use_case.dart';
import 'package:tilawa/features/sadaqah_jariyah/presentation/cubit/sadaqah_jariyah_cubit.dart';
import 'package:tilawa/features/sadaqah_jariyah/presentation/cubit/sadaqah_jariyah_state.dart';
import 'package:tilawa_core/services/analytics_service.dart';

class _MockGetPage extends Mock implements GetSadaqahJariyahPageUseCase {}

class _MockPhotoUrlResolver extends Mock
    implements DedicationPhotoUrlResolver {}

class _MockAnalyticsService extends Mock implements AnalyticsService {}

void main() {
  setUpAll(() {
    registerFallbackValue(const GetSadaqahJariyahPageParams());
  });

  test('shows names before photo resolution completes', () async {
    final _MockGetPage getPage = _MockGetPage();
    final _MockPhotoUrlResolver photoResolver = _MockPhotoUrlResolver();
    final _MockAnalyticsService analytics = _MockAnalyticsService();
    final Completer<String?> photoUrl = Completer<String?>();
    const SadaqahJariyahPageData pageData = SadaqahJariyahPageData(
      config: SadaqahJariyahConfig(),
      dedications: <Dedication>[
        Dedication(
          id: 'person',
          displayName: 'Person',
          slug: 'person',
          photoStoragePath: 'photos/dedications/person.webp',
          status: DedicationStatus.published,
          isFounding: false,
          isFeatured: false,
          sortOrder: 0,
        ),
      ],
    );

    when(() => getPage(any())).thenAnswer((_) async => const Right(pageData));
    when(
      () => photoResolver.resolveDownloadUrl(any()),
    ).thenAnswer((_) => photoUrl.future);
    when(() => analytics.logEvent(any())).thenAnswer((_) async {});

    final SadaqahJariyahCubit cubit = SadaqahJariyahCubit(
      getPage,
      photoResolver,
      analytics,
    );
    await cubit.load();

    final SadaqahJariyahLoaded initialLoaded =
        cubit.state as SadaqahJariyahLoaded;
    check(initialLoaded.pageData).equals(pageData);
    check(initialLoaded.photoUrls).isEmpty();

    photoUrl.complete('https://example.com/person.webp');
    await Future<void>.delayed(Duration.zero);

    final SadaqahJariyahLoaded resolvedLoaded =
        cubit.state as SadaqahJariyahLoaded;
    check(
      resolvedLoaded.photoUrls['person'],
    ).equals('https://example.com/person.webp');
    await cubit.close();
  });
}

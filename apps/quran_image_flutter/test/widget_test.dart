import 'package:flutter_test/flutter_test.dart';
import 'package:quran_image_flutter/core/di/dependency_injection.dart';
import 'package:quran_image_flutter/domain/domain.dart';
import 'package:quran_image_flutter/quran_image_app.dart';
import 'package:quran_image_flutter/quran_image_reader.dart';

void main() {
  setUp(() async {
    await sl.reset();
    await initDependencies();
    await sl.unregister<LastVisitedPageRepository>();
    sl.registerLazySingleton<LastVisitedPageRepository>(
      _InMemoryLastVisitedPageRepository.new,
    );
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('Quran image app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const QuranImageApp());
    await tester.pumpAndSettle();

    // Verify that the app builds without errors
    expect(find.byType(QuranImageReader), findsOneWidget);
  });
}

class _InMemoryLastVisitedPageRepository implements LastVisitedPageRepository {
  int? _lastVisitedPage;

  @override
  Future<void> clearLastVisitedPage() async {
    _lastVisitedPage = null;
  }

  @override
  Future<int?> getLastVisitedPage() async {
    return _lastVisitedPage;
  }

  @override
  Future<void> saveLastVisitedPage(int pageNumber) async {
    _lastVisitedPage = pageNumber;
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/downloads/presentation/bloc/downloads_bloc.dart';
import 'package:tilawa/features/downloads/presentation/screens/downloads_screen.dart';
import 'package:tilawa/features/downloads/presentation/widgets/downloads_screen_scope.dart';

import '../../../../helpers/hydrated_bloc_test_helper.dart';
import '../../../../support/screen_scope_test_support.dart';

class _MockDownloadsBloc extends Mock implements DownloadsBloc {}

class _FakeStorage extends Fake implements Storage {
  @override
  dynamic read(String key) => null;

  @override
  Future<void> write(String key, dynamic value) async {}

  @override
  Future<void> delete(String key) async {}

  @override
  Future<void> clear() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockDownloadsBloc mockDownloadsBloc;

  setUpAll(() async {
    HydratedBloc.storage = _FakeStorage();
    await initializeHydratedStorageForTest();
  });

  tearDownAll(() async {
    await clearHydratedStorageForTest();
  });

  setUp(() async {
    await resetScopeGetIt();
    mockDownloadsBloc = _MockDownloadsBloc();
    when(() => mockDownloadsBloc.close()).thenAnswer((_) async {});
    when(() => mockDownloadsBloc.state).thenReturn(const DownloadsState());
    when(
      () => mockDownloadsBloc.stream,
    ).thenAnswer((_) => const Stream.empty());
    scopeGetIt().registerFactory<DownloadsBloc>(() => mockDownloadsBloc);
  });

  tearDown(() async {
    await resetScopeGetIt();
  });

  testWidgets('provides DownloadsBloc to descendants', (tester) async {
    DownloadsBloc? bloc;

    await tester.pumpWidget(
      wrapScopeTest(
        home: DownloadsScreenScope(
          child: ScopeProbe(
            onBuilt: (context) {
              bloc = readScopeBloc<DownloadsBloc>(context);
            },
          ),
        ),
      ),
    );

    expect(bloc, same(mockDownloadsBloc));
  });

  testWidgets('closes DownloadsBloc when unmounted', (tester) async {
    await tester.pumpWidget(
      wrapScopeTest(
        home: DownloadsScreenScope(
          child: ScopeProbe(
            onBuilt: (context) {
              readScopeBloc<DownloadsBloc>(context);
            },
          ),
        ),
      ),
    );

    await unmountScope(tester);

    verify(() => mockDownloadsBloc.close()).called(1);
  });

  testWidgets('resolves DownloadsBloc from getIt on each mount', (
    tester,
  ) async {
    var createCount = 0;
    scopeGetIt().unregister<DownloadsBloc>();
    scopeGetIt().registerFactory<DownloadsBloc>(() {
      createCount++;
      final mock = _MockDownloadsBloc();
      when(() => mock.close()).thenAnswer((_) async {});
      when(() => mock.state).thenReturn(const DownloadsState());
      when(() => mock.stream).thenAnswer((_) => const Stream.empty());
      return mock;
    });

    await tester.pumpWidget(
      wrapScopeTest(
        home: DownloadsScreenScope(
          child: ScopeProbe(
            onBuilt: (context) {
              readScopeBloc<DownloadsBloc>(context);
            },
          ),
        ),
      ),
    );
    await unmountScope(tester);
    await tester.pumpWidget(
      wrapScopeTest(
        home: DownloadsScreenScope(
          child: ScopeProbe(
            onBuilt: (context) {
              readScopeBloc<DownloadsBloc>(context);
            },
          ),
        ),
      ),
    );

    expect(createCount, 2);
  });

  testWidgets('renders probe child instead of DownloadsScreen', (tester) async {
    await tester.pumpWidget(
      wrapScopeTest(
        home: DownloadsScreenScope(
          child: ScopeProbe(onBuilt: (_) {}),
        ),
      ),
    );

    expect(find.byKey(const Key('scope_probe')), findsOneWidget);
    expect(find.byType(DownloadsScreen), findsNothing);
  });
}

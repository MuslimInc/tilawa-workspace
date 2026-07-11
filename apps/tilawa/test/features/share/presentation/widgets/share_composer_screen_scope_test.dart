import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/share/presentation/cubit/share_cubit.dart';
import 'package:tilawa/features/share/presentation/cubit/share_state.dart';
import 'package:tilawa/features/share/presentation/widgets/share_composer_screen_scope.dart';

import '../../../../support/screen_scope_test_support.dart';

class _MockShareCubit extends Mock implements ShareCubit {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockShareCubit mockShareCubit;

  setUp(() async {
    await resetScopeGetIt();
    mockShareCubit = _MockShareCubit();
    when(() => mockShareCubit.close()).thenAnswer((_) async {});
    when(() => mockShareCubit.state).thenReturn(const ShareState());
    when(() => mockShareCubit.stream).thenAnswer((_) => const Stream.empty());
    scopeGetIt().registerFactory<ShareCubit>(() => mockShareCubit);
  });

  tearDown(() async {
    await resetScopeGetIt();
  });

  testWidgets('provides ShareCubit to the wrapped child', (tester) async {
    ShareCubit? cubit;

    await tester.pumpWidget(
      wrapScopeTest(
        home: ShareComposerScreenScope(
          child: ScopeProbe(
            onBuilt: (context) {
              cubit = readScopeBloc<ShareCubit>(context);
            },
          ),
        ),
      ),
    );

    expect(cubit, same(mockShareCubit));
  });

  testWidgets('passes through the supplied child widget', (tester) async {
    const childKey = Key('share_composer_child');

    await tester.pumpWidget(
      wrapScopeTest(
        home: const ShareComposerScreenScope(
          child: SizedBox(key: childKey),
        ),
      ),
    );

    expect(find.byKey(childKey), findsOneWidget);
  });

  testWidgets('closes ShareCubit when unmounted', (tester) async {
    await tester.pumpWidget(
      wrapScopeTest(
        home: ShareComposerScreenScope(
          child: ScopeProbe(
            onBuilt: (context) {
              readScopeBloc<ShareCubit>(context);
            },
          ),
        ),
      ),
    );

    await unmountScope(tester);

    verify(() => mockShareCubit.close()).called(1);
  });

  testWidgets('resolves ShareCubit from getIt on each mount', (tester) async {
    var createCount = 0;
    scopeGetIt().unregister<ShareCubit>();
    scopeGetIt().registerFactory<ShareCubit>(() {
      createCount++;
      final mock = _MockShareCubit();
      when(mock.close).thenAnswer((_) async {});
      when(() => mock.state).thenReturn(const ShareState());
      when(() => mock.stream).thenAnswer((_) => const Stream.empty());
      return mock;
    });

    await tester.pumpWidget(
      wrapScopeTest(
        home: ShareComposerScreenScope(
          child: ScopeProbe(
            onBuilt: (context) {
              readScopeBloc<ShareCubit>(context);
            },
          ),
        ),
      ),
    );
    await unmountScope(tester);
    await tester.pumpWidget(
      wrapScopeTest(
        home: ShareComposerScreenScope(
          child: ScopeProbe(
            onBuilt: (context) {
              readScopeBloc<ShareCubit>(context);
            },
          ),
        ),
      ),
    );

    expect(createCount, 2);
  });
}

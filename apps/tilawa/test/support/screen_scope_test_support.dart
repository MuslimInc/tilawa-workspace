import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:tilawa/core/di/injection.dart';

typedef ScopeProbeCallback = void Function(BuildContext context);

/// Lightweight descendant used to read scope-provided blocs in widget tests.
class ScopeProbe extends StatelessWidget {
  const ScopeProbe({required this.onBuilt, super.key});

  final ScopeProbeCallback onBuilt;

  @override
  Widget build(BuildContext context) {
    onBuilt(context);
    return const KeyedSubtree(
      key: Key('scope_probe'),
      child: SizedBox.shrink(),
    );
  }
}

/// Wraps a scope widget in a minimal [MaterialApp] for widget tests.
Widget wrapScopeTest({required Widget home}) {
  return MaterialApp(home: Scaffold(body: home));
}

/// Resets [getIt] and allows reassignment for isolated scope tests.
Future<void> resetScopeGetIt() async {
  await getIt.reset();
  getIt.allowReassignment = true;
}

/// Reads a bloc/cubit registered above [ScopeProbe] in the tree.
T readScopeBloc<T>(BuildContext context) => context.read<T>();

/// Unmounts the current scope tree so [BlocProvider] disposes scoped blocs.
Future<void> unmountScope(WidgetTester tester) async {
  await tester.pumpWidget(
    const MaterialApp(home: SizedBox.shrink()),
  );
  await tester.pump();
}

/// Unmounts [scopeWithProbe] and verifies [isClosed] becomes true.
Future<void> expectScopeClosesBlocs(
  WidgetTester tester, {
  required Widget scopeWithProbe,
  required bool Function() isClosed,
}) async {
  await tester.pumpWidget(wrapScopeTest(home: scopeWithProbe));
  expect(isClosed(), isFalse);

  await unmountScope(tester);

  expect(isClosed(), isTrue);
}

/// Convenience alias when tests need direct [GetIt] access.
GetIt scopeGetIt() => getIt;

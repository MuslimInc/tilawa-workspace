import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/core/telemetry/tilawa_sentry_route_display.dart';
import 'package:tilawa/router/tilawa_route_data.dart';

class _FakeGoRouterState extends Fake implements GoRouterState {
  _FakeGoRouterState() : path = '/probe';

  @override
  final String path;

  @override
  Uri get uri => Uri.parse(path);

  @override
  String get matchedLocation => path;

  @override
  String? get fullPath => path;

  @override
  Map<String, String> get pathParameters => const <String, String>{};

  @override
  ValueKey<String> get pageKey => const ValueKey<String>('probe');

  @override
  String? get name => null;
}

class _ProbeRoute extends GoRouteData with TilawaRouteData {
  const _ProbeRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const Text('probe');
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeGoRouterState());
  });

  testWidgets('TilawaRouteData wraps destination in TTFD widgets', (
    tester,
  ) async {
    final GoRouterState state = _FakeGoRouterState();

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            final Page<void> page = const _ProbeRoute().buildPage(
              context,
              state,
            );
            expect(page, isA<MaterialPage<void>>());
            return (page as MaterialPage<void>).child;
          },
        ),
      ),
    );

    expect(find.byType(TilawaSentryRouteDisplay), findsOneWidget);
    expect(find.byType(TilawaSentryRouteReporter), findsOneWidget);
    expect(find.text('probe'), findsOneWidget);
  });
}

import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/genui_assistant/genui_assistant.dart';
import 'package:tilawa_core/errors/failures.dart';

const _request = GenUiSurfaceRequest(surface: 'smartQuranPlan');

void main() {
  group('GenUiRepositoryImpl — end to end through the fake transport', () {
    test('valid payload yields a validated document', () async {
      const repo = GenUiRepositoryImpl(transport: GenUiFakeTransport());
      final result = await repo.requestSurface(_request);
      result.fold(
        (f) => throw StateError('expected document, got $f'),
        (doc) {
          check(doc.schemaVersion).equals('1');
          check(doc.nodes).isNotEmpty();
        },
      );
    });

    test(
      'invalid payload surfaces a ValidationFailure, never throws',
      () async {
        const repo = GenUiRepositoryImpl(
          transport: GenUiFakeTransport(document: '{ broken'),
        );
        final result = await repo.requestSurface(_request);
        check(result.isLeft()).isTrue();
        result.fold(
          (f) => check(f).isA<ValidationFailure>(),
          (doc) => throw StateError('expected failure, got $doc'),
        );
      },
    );

    test('unsupported schema version surfaces a ValidationFailure', () async {
      const repo = GenUiRepositoryImpl(
        transport: GenUiFakeTransport(
          document: '{ "schemaVersion": "42", "nodes": [] }',
        ),
      );
      final result = await repo.requestSurface(_request);
      result.fold(
        (f) => check(f).isA<ValidationFailure>(),
        (doc) => throw StateError('expected failure, got $doc'),
      );
    });

    test('transport failure surfaces a ServerFailure', () async {
      const repo = GenUiRepositoryImpl(
        transport: GenUiFakeTransport(
          failure: GenUiTransportFailure('offline'),
        ),
      );
      final result = await repo.requestSurface(_request);
      result.fold(
        (f) => check(f).isA<ServerFailure>(),
        (doc) => throw StateError('expected failure, got $doc'),
      );
    });
  });
}

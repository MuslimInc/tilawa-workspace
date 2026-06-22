import 'dart:convert';

import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tilawa/features/genui_assistant/genui_assistant.dart';

const _request = GenUiSurfaceRequest(surface: 'smartQuranPlan');

void main() {
  group('GenUiGeminiTransport', () {
    test('429 response surfaces Gemini quota message', () async {
      final transport = GenUiGeminiTransport(
        apiKey: 'test-key',
        client: MockClient((_) async {
          return http.Response(
            jsonEncode(<String, Object?>{
              'error': <String, Object?>{
                'code': 429,
                'message':
                    'You exceeded your current quota.\nPlease retry in 30s.',
                'status': 'RESOURCE_EXHAUSTED',
              },
            }),
            429,
          );
        }),
      );

      final result = await transport.requestDocument(_request);
      check(result.isLeft()).isTrue();
      result.fold(
        (failure) {
          check(failure).isA<GenUiTransportFailure>();
          expect(
            failure.message,
            contains('exceeded your current quota'),
          );
        },
        (_) => throw StateError('expected transport failure'),
      );
    });

    test('200 response returns candidate text', () async {
      const payload = '{"schemaVersion":"1","nodes":[]}';
      final transport = GenUiGeminiTransport(
        apiKey: 'test-key',
        client: MockClient((_) async {
          return http.Response(
            jsonEncode(<String, Object?>{
              'candidates': <Object?>[
                <String, Object?>{
                  'content': <String, Object?>{
                    'parts': <Object?>[
                      <String, Object?>{'text': payload},
                    ],
                  },
                },
              ],
            }),
            200,
          );
        }),
      );

      final result = await transport.requestDocument(_request);
      check(result.isRight()).isTrue();
      result.fold(
        (_) => throw StateError('expected success'),
        (text) => check(text).equals(payload),
      );
    });
  });
}

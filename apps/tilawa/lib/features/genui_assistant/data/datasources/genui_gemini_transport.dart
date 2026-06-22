import 'dart:convert';

import 'package:dartz_plus/dartz_plus.dart';
import 'package:http/http.dart' as http;

import '../../domain/entities/genui_schema.dart';
import '../../domain/failures/genui_failure.dart';
import '../../domain/repositories/genui_repository.dart';
import 'genui_transport.dart';

/// Live transport that asks Google Gemini for a UI document via the REST API.
///
/// Deliberately dependency-free beyond `http` — it talks to the public
/// `generativelanguage.googleapis.com` endpoint with an API key from
/// `--dart-define=GEMINI_API_KEY`, so it touches no Firebase config and adds no
/// new integration. It is only ever wired when the launch flag is on *and* a key
/// is present; otherwise the fake transport is used.
///
/// The system instruction hard-constrains the model to (a) emit JSON for the
/// pinned [GenUiSchema.version], (b) use only whitelisted component types, (c)
/// trigger only allowlisted actions, and (d) never author ayah text,
/// translations, rulings, or fatwa — it arranges trusted content by id only.
/// Even so, the client treats every response as untrusted: the parser validates
/// it, and unknown components/actions fail closed.
class GenUiGeminiTransport implements GenUiTransport {
  GenUiGeminiTransport({
    required this.apiKey,
    this.model = 'gemini-2.0-flash',
    http.Client? client,
    this.timeout = const Duration(seconds: 20),
  }) : _client = client ?? http.Client();

  final String apiKey;
  final String model;
  final Duration timeout;
  final http.Client _client;

  static const String _host = 'generativelanguage.googleapis.com';

  @override
  GenUiResult<String> requestDocument(GenUiSurfaceRequest request) async {
    final Uri uri = Uri.https(
      _host,
      '/v1beta/models/$model:generateContent',
      <String, String>{'key': apiKey},
    );

    final Map<String, Object?> body = <String, Object?>{
      'systemInstruction': <String, Object?>{
        'parts': <Object?>[
          <String, Object?>{'text': _systemInstruction},
        ],
      },
      'contents': <Object?>[
        <String, Object?>{
          'role': 'user',
          'parts': <Object?>[
            <String, Object?>{'text': _userPrompt(request)},
          ],
        },
      ],
      'generationConfig': <String, Object?>{
        'responseMimeType': 'application/json',
        'temperature': 0.4,
      },
    };

    try {
      final http.Response res = await _client
          .post(
            uri,
            headers: const <String, String>{
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(timeout);

      if (res.statusCode != 200) {
        return Left(
          GenUiTransportFailure(
            _extractErrorMessage(res.body) ?? 'Gemini HTTP ${res.statusCode}',
          ),
        );
      }

      final String? text = _extractText(res.body);
      if (text == null || text.isEmpty) {
        return const Left(GenUiTransportFailure('Empty Gemini response'));
      }
      return Right(text);
    } on Object catch (e) {
      return Left(GenUiTransportFailure('Gemini request failed: $e'));
    }
  }

  /// Pulls the human-readable message out of a Gemini error envelope.
  String? _extractErrorMessage(String responseBody) {
    try {
      final Object? decoded = jsonDecode(responseBody);
      if (decoded is! Map<String, Object?>) return null;
      final Object? error = decoded['error'];
      if (error is! Map<String, Object?>) return null;
      final Object? message = error['message'];
      if (message is! String || message.isEmpty) return null;
      return message.split('\n').first.trim();
    } on FormatException {
      return null;
    }
  }

  /// Pulls the first candidate's concatenated text parts out of the Gemini
  /// response envelope. Returns null on any unexpected shape.
  String? _extractText(String responseBody) {
    final Object? decoded = jsonDecode(responseBody);
    if (decoded is! Map<String, Object?>) return null;
    final Object? candidates = decoded['candidates'];
    if (candidates is! List || candidates.isEmpty) return null;
    final Object? first = candidates.first;
    if (first is! Map<String, Object?>) return null;
    final Object? content = first['content'];
    if (content is! Map<String, Object?>) return null;
    final Object? parts = content['parts'];
    if (parts is! List) return null;
    final StringBuffer buffer = StringBuffer();
    for (final Object? part in parts) {
      if (part is Map<String, Object?> && part['text'] is String) {
        buffer.write(part['text']);
      }
    }
    final String text = buffer.toString();
    return text.isEmpty ? null : text;
  }

  String _userPrompt(GenUiSurfaceRequest request) {
    final Map<String, Object?> payload = <String, Object?>{
      'surface': request.surface,
      'userPrompt': request.userPrompt,
      'trustedContext': request.trustedContext,
    };
    return 'Build the requested surface. Request:\n${jsonEncode(payload)}';
  }

  static const String _systemInstruction =
      '''
You generate ONLY a JSON UI document for an Islamic app. You are a layout
planner, not a source of religious knowledge.

Hard rules:
- Output JSON only, matching schemaVersion "${GenUiSchema.version}".
- Use ONLY these component types: SectionStack, PlanHeader, WirdCard,
  AyahReferenceCard, InfoNote, ActionButton.
- Use ONLY these actionId values: openQuranReader, startTodayWird, openAthkar,
  setReminder, savePlan.
- Reference Quran/athkar/plan content by id (e.g. surah/ayah numbers, planId).
  NEVER write ayah text, translations, tafsir, rulings, or fatwa. The app
  resolves all religious content from trusted local sources.
- Do not give religious verdicts or unsupported claims. assistantNote may hold
  only a short, neutral encouragement.
- If unsure, prefer fewer nodes. Never invent component types or actions.

Document shape:
{ "schemaVersion": "${GenUiSchema.version}", "assistantNote": "...",
  "nodes": [ { "type": "...", "props": { }, "children": [ ],
  "actionId": "..." } ] }
''';
}

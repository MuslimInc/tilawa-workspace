import 'dart:convert';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../../domain/entities/compared_word.dart';
import '../../domain/entities/recitation_comparison_result.dart';
import '../../domain/entities/recitation_target.dart';
import '../../domain/entities/word_match_status.dart';

/// Calls the acoustic recitation verifier backend.
@lazySingleton
class RecitationAudioVerificationClient {
  RecitationAudioVerificationClient(
    this._functions, {
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  static const String _functionName = String.fromEnvironment(
    'TILAWA_RECITATION_VERIFIER_FUNCTION',
    defaultValue: 'verifyRecitationAudio',
  );
  static const String _functionEndpoint = String.fromEnvironment(
    'TILAWA_RECITATION_VERIFIER_ENDPOINT',
  );
  static const String _region = 'us-central1';

  final FirebaseFunctions _functions;
  final http.Client _httpClient;

  Future<RecitationComparisonResult> verify({
    required RecitationTarget target,
    required String audioPath,
    required int sampleRate,
  }) async {
    final File audioFile = File(audioPath);
    if (!audioFile.existsSync()) {
      throw Failure.validationError('No recitation audio was captured.');
    }

    final List<int> audioBytes = await audioFile.readAsBytes();
    if (audioBytes.isEmpty) {
      throw Failure.validationError('No recitation audio was captured.');
    }

    final Map<String, Object?> verifierPayload = <String, Object?>{
      'surahNumber': target.surahNumber,
      'ayahNumber': target.ayahNumber,
      'pageNumber': target.pageNumber,
      'expectedText': target.normalText,
      'audio': base64Encode(audioBytes),
      'audioFormat': 'wav',
      'sampleRate': sampleRate,
    };

    final http.Response response = await _httpClient.post(
      _callableUri,
      headers: const <String, String>{
        HttpHeaders.contentTypeHeader: 'application/json',
      },
      body: jsonEncode(<String, Object?>{'data': verifierPayload}),
    );

    final Map<String, dynamic> payload = _parseCallableResponse(response);
    return RecitationComparisonResult(
      words: _parseWords(payload, target),
      score: _parseScore(payload['score'] ?? payload['overallScore']),
      spokenText: payload['feedbackText']?.toString() ?? '',
    );
  }

  Uri get _callableUri {
    if (_functionEndpoint.isNotEmpty) {
      return Uri.parse(_functionEndpoint);
    }
    final String projectId = _functions.app.options.projectId;
    return Uri.parse(
      'https://$_region-$projectId.cloudfunctions.net/$_functionName',
    );
  }

  Map<String, dynamic> _parseCallableResponse(http.Response response) {
    final Object? decodedBody = jsonDecode(response.body);
    final Map<String, dynamic> envelope = _asMap(decodedBody);

    if (response.statusCode >= 400 || envelope.containsKey('error')) {
      final Map<String, dynamic> error = _asMap(envelope['error']);
      final String status = error['status']?.toString().toLowerCase() ?? '';
      final String message =
          error['message']?.toString() ?? 'Recitation verifier failed.';
      throw Failure.serverError(_messageForCallableStatus(status, message));
    }

    return _asMap(envelope['result']);
  }

  Map<String, dynamic> _asMap(Object? data) {
    if (data is Map) {
      return data.map(
        (Object? key, Object? value) => MapEntry(key.toString(), value),
      );
    }
    throw Failure.serverError('Unexpected recitation verifier response.');
  }

  double _parseScore(Object? rawScore) {
    if (rawScore is num) {
      final double value = rawScore.toDouble();
      return value > 1 ? (value / 100).clamp(0, 1) : value.clamp(0, 1);
    }
    throw Failure.serverError('Recitation verifier did not return a score.');
  }

  List<ComparedWord> _parseWords(
    Map<String, dynamic> payload,
    RecitationTarget target,
  ) {
    final Object? rawWords = payload['words'];
    if (rawWords is Iterable) {
      final List<ComparedWord> words = rawWords
          .whereType<Map>()
          .map(_parseWord)
          .whereType<ComparedWord>()
          .toList(growable: false);
      if (words.isNotEmpty) {
        return words;
      }
    }

    final bool passed =
        _parseScore(payload['score'] ?? payload['overallScore']) >= 0.8;
    return target.normalText
        .split(RegExp(r'\s+'))
        .where((String word) => word.isNotEmpty)
        .map(
          (String word) => ComparedWord(
            word: word,
            status: passed ? WordMatchStatus.correct : WordMatchStatus.missing,
          ),
        )
        .toList(growable: false);
  }

  ComparedWord? _parseWord(Map<dynamic, dynamic> data) {
    final Object? rawText = data['word'] ?? data['text'];
    if (rawText == null || rawText.toString().trim().isEmpty) {
      return null;
    }

    return ComparedWord(
      word: rawText.toString(),
      status: _parseStatus(data['status']),
    );
  }

  WordMatchStatus _parseStatus(Object? rawStatus) {
    return switch (rawStatus?.toString()) {
      'correct' || 'matched' || 'pass' => WordMatchStatus.correct,
      'incorrect' || 'wrong' => WordMatchStatus.incorrect,
      _ => WordMatchStatus.missing,
    };
  }

  String _messageForCallableStatus(String status, String message) {
    return switch (status) {
      'failed-precondition' =>
        message == 'Recitation verifier service is not configured.'
            ? message
            : 'Recitation verifier is not configured.',
      'unauthenticated' =>
        'Recitation verifier rejected this app. Check Firebase App Check.',
      'not-found' => 'Recitation verifier function was not found.',
      'unavailable' => 'Recitation verifier is unavailable.',
      _ => message,
    };
  }
}

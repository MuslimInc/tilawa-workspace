import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:tilawa/features/recitation_practice/core/voice_recitation_log.dart';

/// Debug-session NDJSON ingest (debug builds only).
abstract final class RecitationAgentDebug {
  static const String _sessionId = 'b34c36';
  static const String _ingestId = 'bbbf0204-215c-4477-92e7-9e08b76a9f83';
  static final HttpClient _client = HttpClient();

  static void log({
    required String hypothesisId,
    required String location,
    required String message,
    Map<String, Object?> data = const <String, Object?>{},
    String runId = 'pre-fix',
  }) {
    if (!kDebugMode) {
      return;
    }

    // #region agent log
    VoiceRecitationLog.d(
      'DBG[$hypothesisId] $message ${data.isEmpty ? '' : jsonEncode(data)}',
    );

    final String host = Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
    final Uri uri = Uri.parse('http://$host:7878/ingest/$_ingestId');
    final Map<String, Object?> payload = <String, Object?>{
      'sessionId': _sessionId,
      'runId': runId,
      'hypothesisId': hypothesisId,
      'location': location,
      'message': message,
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    _client
        .postUrl(uri)
        .then((HttpClientRequest request) {
          request.headers.set('Content-Type', 'application/json');
          request.headers.set('X-Debug-Session-Id', _sessionId);
          request.write(jsonEncode(payload));
          return request.close();
        })
        .then((HttpClientResponse response) => response.drain<void>())
        .catchError((_) {});
    // #endregion
  }
}

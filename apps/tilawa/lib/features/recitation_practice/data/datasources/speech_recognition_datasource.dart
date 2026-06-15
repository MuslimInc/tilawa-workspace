import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:tilawa/core/logging/app_logger.dart';

/// Platform speech-to-text adapter for Arabic recitation.
@injectable
class SpeechRecognitionDatasource {
  SpeechRecognitionDatasource() : _speech = SpeechToText();

  final SpeechToText _speech;
  final StreamController<String> _transcriptController =
      StreamController<String>.broadcast();

  String _latestTranscript = '';
  bool _isInitialized = false;

  Stream<String> get transcriptStream => _transcriptController.stream;

  Future<bool> initialize() async {
    if (_isInitialized) {
      return _speech.isAvailable;
    }

    _isInitialized = await _speech.initialize(
      onError: (SpeechRecognitionError error) {
        logger.d('[SpeechRecognitionDatasource] error=${error.errorMsg}');
      },
      onStatus: (String status) {
        logger.d('[SpeechRecognitionDatasource] status=$status');
      },
    );
    return _isInitialized && _speech.isAvailable;
  }

  Future<void> startListening() async {
    _latestTranscript = '';
    final String? localeId = await _resolveLocaleId();
    await _speech.listen(
      onResult: (SpeechRecognitionResult result) {
        _latestTranscript = result.recognizedWords;
        _transcriptController.add(_latestTranscript);
      },
      listenOptions: SpeechListenOptions(
        localeId: localeId,
        listenMode: ListenMode.confirmation,
        cancelOnError: true,
        partialResults: true,
      ),
    );
  }

  Future<String> stopListening() async {
    await _speech.stop();
    return _latestTranscript;
  }

  Future<void> dispose() async {
    await _speech.cancel();
  }

  Future<String?> _resolveLocaleId() async {
    final List<LocaleName> locales = await _speech.locales();
    const List<String> preferredLocales = <String>[
      'ar-SA',
      'ar_SA',
      'ar',
    ];
    for (final String preferred in preferredLocales) {
      final bool found = locales.any(
        (LocaleName locale) => locale.localeId == preferred,
      );
      if (found) {
        return preferred;
      }
    }
    for (final LocaleName locale in locales) {
      if (locale.localeId.toLowerCase().startsWith('ar')) {
        return locale.localeId;
      }
    }
    return null;
  }
}

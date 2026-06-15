import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:tilawa/core/logging/app_logger.dart';
import 'package:tilawa/features/recitation_practice/domain/entities/speech_recognition_update.dart';

/// Platform speech-to-text adapter tuned for continuous Arabic recitation.
@injectable
class SpeechRecognitionDatasource {
  SpeechRecognitionDatasource() : _speech = SpeechToText();

  static const Duration _listenFor = Duration(minutes: 30);
  static const Duration _pauseFor = Duration(seconds: 4);
  static const Duration _restartDelay = Duration(milliseconds: 350);

  /// Always passed to the recognizer — never null, never device default.
  ///
  /// Android's speech_to_text plugin only sets [RecognizerIntent.EXTRA_LANGUAGE]
  /// when this tag differs from the system locale; using a fixed Saudi Arabic
  /// tag forces Arabic input even on English-system devices.
  static const String forcedArabicLocaleId = 'ar-SA';

  static const List<String> _offlineArabicLocaleHints = <String>[
    'ar-SA',
    'ar_SA',
    'ar-EG',
    'ar_EG',
    'ar',
  ];

  static const Set<String> _recoverableErrors = <String>{
    'error_no_match',
    'error_speech_timeout',
    'error_retry',
    'error_network',
    'error_network_timeout',
    'error_audio',
    'error_client',
    'error_language_not_supported',
    'error_language_unavailable',
  };

  final SpeechToText _speech;
  final StreamController<SpeechRecognitionUpdate> _updateController =
      StreamController<SpeechRecognitionUpdate>.broadcast();

  String _latestTranscript = '';
  bool _isInitialized = false;
  bool _shouldRestartOnDone = false;
  bool _restartPending = false;
  bool _loggedLocales = false;

  Stream<SpeechRecognitionUpdate> get recognitionUpdateStream =>
      _updateController.stream;

  Future<bool> initialize() async {
    if (_isInitialized) {
      return _speech.isAvailable;
    }

    _isInitialized = await _speech.initialize(
      onError: _onSpeechError,
      onStatus: _onSpeechStatus,
      debugLogging: false,
    );

    if (_isInitialized) {
      await _logArabicLocaleAvailability();
    }

    return _isInitialized && _speech.isAvailable;
  }

  void _onSpeechError(SpeechRecognitionError error) {
    logger.d(
      '[SpeechRecognitionDatasource] error=${error.errorMsg} '
      'permanent=${error.permanent}',
    );
    if (!_shouldRestartOnDone) {
      return;
    }
    if (!_recoverableErrors.contains(error.errorMsg)) {
      return;
    }
    unawaited(_scheduleRestart());
  }

  void _onSpeechStatus(String status) {
    logger.d('[SpeechRecognitionDatasource] status=$status');
    if (!_shouldRestartOnDone) {
      return;
    }
    if (status == SpeechToText.doneStatus && !_speech.isListening) {
      unawaited(_scheduleRestart());
    }
  }

  Future<void> startListening({bool continuous = true}) async {
    if (!_isInitialized) {
      final bool ready = await initialize();
      if (!ready) {
        return;
      }
    }

    _shouldRestartOnDone = continuous;
    _latestTranscript = '';
    await _listen();
  }

  Future<void> _listen() async {
    if (_speech.isListening) {
      return;
    }

    const String localeId = forcedArabicLocaleId;
    logger.d(
      '[SpeechRecognitionDatasource] listen locale=$localeId '
      '(forced Arabic, onDevice=false)',
    );

    await _speech.listen(
      onResult: (SpeechRecognitionResult result) {
        _latestTranscript = result.recognizedWords;
        _updateController.add(
          SpeechRecognitionUpdate(
            transcript: _latestTranscript,
            isFinal: result.finalResult,
          ),
        );
      },
      listenOptions: SpeechListenOptions(
        localeId: localeId,
        listenMode: ListenMode.dictation,
        onDevice: false,
        cancelOnError: false,
        partialResults: true,
        pauseFor: _pauseFor,
        listenFor: _listenFor,
      ),
    );
  }

  Future<void> _scheduleRestart() async {
    if (!_shouldRestartOnDone || _speech.isListening || _restartPending) {
      return;
    }

    _restartPending = true;
    await Future<void>.delayed(_restartDelay);
    _restartPending = false;

    if (!_shouldRestartOnDone || _speech.isListening) {
      return;
    }

    await _listen();
  }

  Future<String> stopListening() async {
    _shouldRestartOnDone = false;
    _restartPending = false;
    if (_speech.isListening) {
      await _speech.stop();
    }
    return _latestTranscript;
  }

  Future<void> dispose() async {
    _shouldRestartOnDone = false;
    _restartPending = false;
    await _speech.cancel();
  }

  Future<void> _logArabicLocaleAvailability() async {
    if (_loggedLocales) {
      return;
    }
    _loggedLocales = true;

    final List<LocaleName> locales = await _speech.locales();
    final String ids = locales.map((LocaleName l) => l.localeId).join(', ');
    logger.w('[SpeechRecognitionDatasource] available speech locales: $ids');

    final bool hasOfflineArabic = locales.any((LocaleName locale) {
      final String normalized = _normalizeLocaleId(locale.localeId);
      return _offlineArabicLocaleHints.any(
        (String hint) => normalized == _normalizeLocaleId(hint),
      ) || normalized.startsWith('ar');
    });

    if (!hasOfflineArabic) {
      logger.w(
        '[SpeechRecognitionDatasource] No Arabic offline pack detected; '
        'using forced $forcedArabicLocaleId via network recognition. '
        'Install Arabic offline speech in system settings if results are poor.',
      );
    }
  }

  String _normalizeLocaleId(String localeId) {
    return localeId.replaceAll('-', '_').toLowerCase();
  }
}

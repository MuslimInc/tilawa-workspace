import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:tilawa/features/recitation_practice/core/voice_recitation_log.dart';
import 'package:tilawa/features/recitation_practice/domain/entities/speech_recognition_update.dart';
import 'package:tilawa/features/recitation_practice/domain/services/recitation_transcript_stitcher.dart';

/// Platform speech-to-text adapter tuned for continuous Arabic recitation.
@injectable
class SpeechRecognitionDatasource {
  SpeechRecognitionDatasource() : _speech = SpeechToText();

  static const Duration _listenFor = Duration(minutes: 30);
  static const Duration _pauseFor = Duration(seconds: 3);
  static const Duration _restartDelay = Duration(milliseconds: 500);
  static const Duration _minListenDuration = Duration(milliseconds: 1200);

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

  String _committedTranscript = '';
  String _liveTranscript = '';
  DateTime? _listenStartedAt;
  bool _isInitialized = false;
  bool _shouldRestartOnDone = false;
  bool _restartPending = false;
  bool _loggedLocales = false;
  bool _pinnedCommitted = false;
  bool _ignoreResults = false;
  bool _handoffInProgress = false;

  Stream<SpeechRecognitionUpdate> get recognitionUpdateStream =>
      _updateController.stream;

  Future<bool> initialize() async {
    if (_isInitialized) {
      final bool available = _speech.isAvailable;
      VoiceRecitationLog.d('initialize cached available=$available');
      return available;
    }

    _isInitialized = await _speech.initialize(
      onError: _onSpeechError,
      onStatus: _onSpeechStatus,
      debugLogging: false,
    );

    VoiceRecitationLog.i(
      'initialize done initialized=$_isInitialized '
      'available=${_speech.isAvailable}',
    );

    if (_isInitialized) {
      await _logArabicLocaleAvailability();
    }

    return _isInitialized && _speech.isAvailable;
  }

  void _onSpeechError(SpeechRecognitionError error) {
    VoiceRecitationLog.w(
      'speech error=${error.errorMsg} permanent=${error.permanent} '
      'listening=${_speech.isListening} restartEnabled=$_shouldRestartOnDone',
    );
    if (!_shouldRestartOnDone || _handoffInProgress) {
      return;
    }
    if (!_recoverableErrors.contains(error.errorMsg)) {
      return;
    }
    unawaited(_scheduleRestart(reason: error.errorMsg));
  }

  void _onSpeechStatus(String status) {
    VoiceRecitationLog.d(
      'speech status=$status listening=${_speech.isListening} '
      'restartEnabled=$_shouldRestartOnDone handoff=$_handoffInProgress',
    );
    if (_handoffInProgress || !_shouldRestartOnDone) {
      return;
    }
    if (!_speech.isListening &&
        (status == SpeechToText.doneStatus ||
            status == SpeechToText.notListeningStatus)) {
      unawaited(_scheduleRestart(reason: 'status_$status'));
    }
  }

  Future<void> startListening({
    bool continuous = true,
    bool resetTranscript = true,
  }) async {
    if (!_isInitialized) {
      final bool ready = await initialize();
      if (!ready) {
        VoiceRecitationLog.w('startListening aborted speech unavailable');
        return;
      }
    }

    if (_speech.isListening) {
      _shouldRestartOnDone = continuous;
      VoiceRecitationLog.d(
        'startListening skipped already listening '
        'resetTranscript=$resetTranscript continuous=$continuous',
      );
      return;
    }

    _shouldRestartOnDone = continuous;
    _restartPending = false;
    _handoffInProgress = false;
    if (resetTranscript) {
      _committedTranscript = '';
      _liveTranscript = '';
    }

    VoiceRecitationLog.i(
      'startListening resetTranscript=$resetTranscript '
      'continuous=$continuous',
    );
    await _listen();
  }

  Future<void> _listen({bool isMicRestart = false}) async {
    if (_speech.isListening) {
      return;
    }

    if (_pinnedCommitted || isMicRestart) {
      _liveTranscript = '';
      _pinnedCommitted = false;
      // #region agent log
      VoiceRecitationLog.d(
        'listen cleared stale live isMicRestart=$isMicRestart',
      );
      // #endregion
    } else {
      _commitLiveTranscript();
    }

    const String localeId = forcedArabicLocaleId;
    _listenStartedAt = DateTime.now();
    VoiceRecitationLog.i(
      'listen locale=$localeId onDevice=false pauseFor=${_pauseFor.inSeconds}s '
      'listenFor=${_listenFor.inMinutes}m committed="${_clip(_committedTranscript)}"',
    );

    _ignoreResults = false;

    await _speech.listen(
      onResult: (SpeechRecognitionResult result) {
        if (_ignoreResults) {
          return;
        }

        final String previousLive = _liveTranscript;
        _liveTranscript = RecitationTranscriptStitcher.extendPartial(
          previousLive,
          result.recognizedWords,
        );
        final String effective = _effectiveTranscript;
        VoiceRecitationLog.d(
          'asr result isFinal=${result.finalResult} '
          'incoming="${_clip(result.recognizedWords)}" '
          'live="${_clip(_liveTranscript)}" '
          'effective="${_clip(effective)}"',
        );
        _updateController.add(
          SpeechRecognitionUpdate(
            transcript: effective,
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

  Future<void> _scheduleRestart({required String reason}) async {
    if (!_shouldRestartOnDone || _speech.isListening || _restartPending) {
      VoiceRecitationLog.d(
        'restart skipped reason=$reason listening=${_speech.isListening} '
        'pending=$_restartPending enabled=$_shouldRestartOnDone',
      );
      return;
    }

    VoiceRecitationLog.d('restart scheduled reason=$reason');
    _restartPending = true;

    final DateTime startedAt = _listenStartedAt ?? DateTime.now();
    final Duration listenedFor = DateTime.now().difference(startedAt);
    if (listenedFor < _minListenDuration) {
      await Future<void>.delayed(_minListenDuration - listenedFor);
    }
    await Future<void>.delayed(_restartDelay);
    _restartPending = false;

    if (!_shouldRestartOnDone || _speech.isListening) {
      VoiceRecitationLog.d('restart cancelled after delay reason=$reason');
      return;
    }

    VoiceRecitationLog.i('restart listening reason=$reason');
    await _listen(isMicRestart: true);
  }

  Future<String> stopListening({
    bool clearTranscript = true,
    bool discardPendingLive = false,
  }) async {
    _ignoreResults = true;

    if (discardPendingLive) {
      _liveTranscript = '';
      _handoffInProgress = true;
    } else {
      _commitLiveTranscript();
    }

    final String transcript = _effectiveTranscript;
    VoiceRecitationLog.i(
      'stopListening clearTranscript=$clearTranscript '
      'discardPendingLive=$discardPendingLive '
      'transcript="${_clip(transcript)}"',
    );
    if (!discardPendingLive) {
      _shouldRestartOnDone = false;
      _restartPending = false;
    }
    if (_speech.isListening) {
      await _speech.stop();
    }
    if (clearTranscript) {
      _committedTranscript = '';
      _liveTranscript = '';
    }
    return transcript;
  }

  /// Replaces the committed transcript after an ayah pass boundary trim.
  void alignCommittedTranscript(String sanitizedPrefix) {
    _committedTranscript = sanitizedPrefix.trim();
    _liveTranscript = '';
    _pinnedCommitted = true;
    if (_committedTranscript.isNotEmpty) {
      VoiceRecitationLog.d(
        'aligned committed="${_clip(_committedTranscript)}"',
      );
    }
  }

  Future<void> dispose() async {
    VoiceRecitationLog.d('dispose');
    _shouldRestartOnDone = false;
    _restartPending = false;
    await _speech.cancel();
  }

  void _commitLiveTranscript() {
    if (_liveTranscript.trim().isEmpty) {
      return;
    }
    final String previous = _committedTranscript;
    _committedTranscript = RecitationTranscriptStitcher.stitch(
      _committedTranscript,
      _liveTranscript,
    );
    _liveTranscript = '';
    if (_committedTranscript != previous) {
      VoiceRecitationLog.d(
        'committed transcript="${_clip(_committedTranscript)}"',
      );
    }
  }

  String get _effectiveTranscript {
    if (_liveTranscript.trim().isEmpty) {
      return _committedTranscript;
    }
    return RecitationTranscriptStitcher.stitch(
      _committedTranscript,
      _liveTranscript,
    );
  }

  Future<void> _logArabicLocaleAvailability() async {
    if (_loggedLocales) {
      return;
    }
    _loggedLocales = true;

    final List<LocaleName> locales = await _speech.locales();
    final String ids = locales.map((LocaleName l) => l.localeId).join(', ');
    VoiceRecitationLog.w('available speech locales: $ids');

    final bool hasOfflineArabic = locales.any((LocaleName locale) {
      final String normalized = _normalizeLocaleId(locale.localeId);
      return _offlineArabicLocaleHints.any(
            (String hint) => normalized == _normalizeLocaleId(hint),
          ) ||
          normalized.startsWith('ar');
    });

    if (!hasOfflineArabic) {
      VoiceRecitationLog.w(
        'no Arabic offline pack detected; using forced $forcedArabicLocaleId '
        'via network recognition',
      );
    }
  }

  String _normalizeLocaleId(String localeId) {
    return localeId.replaceAll('-', '_').toLowerCase();
  }

  String _clip(String value, {int maxLength = 120}) {
    if (value.length <= maxLength) {
      return value;
    }
    return '${value.substring(0, maxLength)}…';
  }
}

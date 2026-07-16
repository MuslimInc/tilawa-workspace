import 'dart:async';
import 'dart:io' show Platform;

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:tilawa/core/logging/app_logger.dart';
import 'package:tilawa/core/telemetry/session_diagnostics_snapshot.dart';
import 'package:tilawa/core/telemetry/session_diagnostics_store.dart';
import 'package:tilawa/router/app_router.dart';
import 'package:tilawa/shared/audio/audio_player_handler.dart';
import 'package:tilawa_core/entities/audio_extras_keys.dart';

/// Production-safe hub that keeps a rolling diagnostics snapshot, Sentry scope
/// contexts, and breadcrumbs for background-audio / ANR forensics.
///
/// AppExitInfo ANRs are reported on the *next* launch with a useless idle
/// stack. Persisting this snapshot before death is the only reliable way to
/// recover surah/ayah/reciter/lifecycle context for those events.
abstract final class SessionDiagnosticsHub {
  static const String playbackContextKey = 'tilawa.playback';
  static const String sessionContextKey = 'tilawa.session';
  static const String priorSessionContextKey = 'tilawa.prior_session';
  static const MethodChannel _androidChannel = MethodChannel(
    'com.tilawa.app/app_context',
  );

  static const Duration _persistThrottle = Duration(seconds: 8);
  static const Duration _positionBreadcrumbMinGap = Duration(seconds: 30);

  static SessionDiagnosticsSnapshot _live = SessionDiagnosticsSnapshot(
    updatedAtIso: DateTime.now().toUtc().toIso8601String(),
  );
  static SessionDiagnosticsSnapshot? _priorSession;
  static bool _started = false;
  static bool _restored = false;
  static DateTime? _lastPersistAt;
  static DateTime? _lastPositionBreadcrumbAt;
  static String? _lastPlaybackFingerprint;
  static final List<StreamSubscription<dynamic>> _subscriptions =
      <StreamSubscription<dynamic>>[];
  static WidgetsBindingObserver? _lifecycleObserver;

  @visibleForTesting
  static SessionDiagnosticsSnapshot get liveSnapshot => _live;

  @visibleForTesting
  static SessionDiagnosticsSnapshot? get priorSessionSnapshot => _priorSession;

  /// Loads the previous process snapshot (for next-launch AppExitInfo) and
  /// attaches lifecycle observation. Safe to call once from [TilawaApp].
  static Future<void> startSession() async {
    if (_started) {
      return;
    }
    _started = true;
    await restorePriorSession();
    _attachLifecycleObserver();
    noteEvent('session_start');
    unawaited(_refreshAndroidProcessDiagnostics(reason: 'session_start'));
    await _publishToSentry(forcePersist: true);
  }

  /// Restores last-process snapshot without starting observers (used at
  /// Sentry init / beforeSend for AppExitInfo enrichment).
  static Future<void> restorePriorSession() async {
    if (_restored) {
      return;
    }
    _restored = true;
    _priorSession = await SessionDiagnosticsStore.load();
    if (_priorSession != null) {
      logger.d(
        '[SessionDiagnostics] restored prior session '
        'last_event=${_priorSession!.lastEvent} '
        'route=${_priorSession!.route} '
        'playing=${_priorSession!.playing} '
        'surah=${_priorSession!.surahId}',
      );
      await _applyPriorSessionToSentry();
    }
  }

  /// Binds audio_service streams after [AudioService.init].
  static void bindAudioHandler(AudioPlayerHandler handler) {
    for (final StreamSubscription<dynamic> sub in _subscriptions) {
      unawaited(sub.cancel());
    }
    _subscriptions
      ..clear()
      ..add(handler.playbackState.listen(_onPlaybackState))
      ..add(handler.mediaItem.listen(_onMediaItem))
      ..add(handler.queue.listen(_onQueue));
    noteEvent('audio_handler_bound');
    unawaited(_publishToSentry());
  }

  static void noteRoute(String? location) {
    if (location == null || location.isEmpty) {
      return;
    }
    if (_live.route == location) {
      return;
    }
    _live = _live.copyWith(
      updatedAtIso: _nowIso(),
      route: location,
      lastEvent: 'route_changed',
    );
    _breadcrumb(
      category: 'navigation',
      message: 'route=$location',
      data: <String, Object?>{'route': location},
    );
    unawaited(_publishToSentry());
  }

  static void noteEvent(String event, {Map<String, Object?>? data}) {
    _live = _live.copyWith(
      updatedAtIso: _nowIso(),
      lastEvent: event,
    );
    _breadcrumb(
      category: 'tilawa.session',
      message: event,
      data: data,
    );
    unawaited(_publishToSentry(forcePersist: true));
  }

  static void noteLifecycle(AppLifecycleState state) {
    final String name = state.name;
    _live = _live.copyWith(
      updatedAtIso: _nowIso(),
      lifecycle: name,
      lastEvent: 'lifecycle_$name',
    );
    _breadcrumb(
      category: 'app.lifecycle',
      message: name,
      data: <String, Object?>{'state': name},
      level: state == AppLifecycleState.detached
          ? SentryLevel.warning
          : SentryLevel.info,
    );
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      unawaited(_refreshAndroidProcessDiagnostics(reason: 'lifecycle_$name'));
      unawaited(_publishToSentry(forcePersist: true));
    } else {
      unawaited(_publishToSentry());
    }
  }

  /// Attaches live + prior snapshots onto every outbound Sentry event.
  static SentryEvent enrichEvent(SentryEvent event) {
    // ignore: deprecated_member_use
    final Contexts contexts = event.contexts.clone();
    contexts[playbackContextKey] = _playbackContext(_live);
    contexts[sessionContextKey] = _sessionContext(_live);
    final SessionDiagnosticsSnapshot? prior = _priorSession;
    if (prior != null) {
      contexts[priorSessionContextKey] = prior.toSentryContext();
    }

    final Map<String, String> tags = Map<String, String>.from(event.tags ?? {});
    void putTag(String key, String? value) {
      if (value != null && value.isNotEmpty) {
        tags[key] = value;
      }
    }

    putTag('tilawa.route', _live.route ?? prior?.route);
    putTag('tilawa.lifecycle', _live.lifecycle ?? prior?.lifecycle);
    putTag('tilawa.playing', (_live.playing ?? prior?.playing)?.toString());
    putTag('tilawa.surah_id', _live.surahId ?? prior?.surahId);
    putTag('tilawa.reciter_id', _live.reciterId ?? prior?.reciterId);
    putTag('tilawa.source_kind', _live.sourceKind ?? prior?.sourceKind);
    if (isAnrLikeEvent(event)) {
      tags['tilawa.anr_enriched'] = 'true';
      if (prior != null) {
        tags['tilawa.prior_playing'] = prior.playing?.toString() ?? 'unknown';
      }
    }

    return event.copyWith(
      contexts: contexts,
      tags: tags,
    );
  }

  static bool isAnrLikeEvent(SentryEvent event) {
    for (final SentryException exception in event.exceptions ?? const []) {
      final String type = exception.type ?? '';
      final String value = exception.value ?? '';
      final String mechanism = exception.mechanism?.type ?? '';
      if (type.contains('ApplicationNotResponding') ||
          type.contains('ANR') ||
          value.contains('ANR') ||
          mechanism == 'AppExitInfo' ||
          mechanism.toLowerCase().contains('anr')) {
        return true;
      }
    }
    final String message = event.message?.formatted ?? '';
    return message.contains('ApplicationNotResponding') || message == 'ANR';
  }

  static void dispose() {
    for (final StreamSubscription<dynamic> sub in _subscriptions) {
      unawaited(sub.cancel());
    }
    _subscriptions.clear();
    final WidgetsBindingObserver? observer = _lifecycleObserver;
    if (observer != null) {
      WidgetsBinding.instance.removeObserver(observer);
      _lifecycleObserver = null;
    }
    _started = false;
  }

  @visibleForTesting
  static void resetForTesting() {
    dispose();
    _live = SessionDiagnosticsSnapshot(updatedAtIso: _nowIso());
    _priorSession = null;
    _restored = false;
    _lastPersistAt = null;
    _lastPositionBreadcrumbAt = null;
    _lastPlaybackFingerprint = null;
  }

  static void _attachLifecycleObserver() {
    if (_lifecycleObserver != null) {
      return;
    }
    final _LifecycleBridge observer = _LifecycleBridge();
    _lifecycleObserver = observer;
    WidgetsBinding.instance.addObserver(observer);
  }

  static void _onPlaybackState(PlaybackState state) {
    final String fingerprint =
        '${state.playing}|${state.processingState}|${state.queueIndex}|'
        '${state.updatePosition.inSeconds}';
    final bool meaningfulChange =
        fingerprint.split('|').take(3).join('|') !=
        (_lastPlaybackFingerprint?.split('|').take(3).join('|') ?? '');
    _live = _live.copyWith(
      updatedAtIso: _nowIso(),
      playing: state.playing,
      processingState: state.processingState.name,
      playingPositionMs: state.updatePosition.inMilliseconds,
      queueIndex: state.queueIndex,
      speed: state.speed,
      lastEvent: meaningfulChange ? 'playback_state' : _live.lastEvent,
    );
    if (meaningfulChange) {
      _lastPlaybackFingerprint = fingerprint;
      _breadcrumb(
        category: 'tilawa.playback',
        message:
            'playing=${state.playing} state=${state.processingState.name} '
            'index=${state.queueIndex}',
        data: <String, Object?>{
          'playing': state.playing,
          'processing_state': state.processingState.name,
          'queue_index': state.queueIndex,
          'position_ms': state.updatePosition.inMilliseconds,
          'speed': state.speed,
        },
      );
      unawaited(_publishToSentry(forcePersist: true));
    } else {
      final DateTime now = DateTime.now();
      if (_lastPositionBreadcrumbAt == null ||
          now.difference(_lastPositionBreadcrumbAt!) >=
              _positionBreadcrumbMinGap) {
        _lastPositionBreadcrumbAt = now;
        unawaited(_publishToSentry());
      }
    }
  }

  static void _onMediaItem(MediaItem? item) {
    if (item == null) {
      return;
    }
    final Map<String, dynamic>? extras = item.extras;
    final String url = extras?['url']?.toString() ?? item.id;
    final ({String kind, String? host}) source = _classifySource(url);
    _live = _live.copyWith(
      updatedAtIso: _nowIso(),
      audioId: item.id,
      audioTitle: item.title,
      reciterName: item.artist,
      durationMs: item.duration?.inMilliseconds,
      surahId: extras.getString(AudioExtrasKeys.surahId),
      ayahNumber: extras.getInt(AudioExtrasKeys.ayahNumber),
      reciterId: extras.getString(AudioExtrasKeys.reciterId),
      moshafId:
          extras.getString(AudioExtrasKeys.moshafId) ??
          extras.getInt(AudioExtrasKeys.moshafId)?.toString(),
      sourceKind: source.kind,
      audioUrlHost: source.host,
      lastEvent: 'media_item',
    );
    _breadcrumb(
      category: 'tilawa.playback',
      message:
          'media title=${item.title} surah=${_live.surahId} '
          'reciter=${_live.reciterId} source=${source.kind}',
      data: <String, Object?>{
        'audio_id': item.id,
        'title': item.title,
        'artist': item.artist,
        'surah_id': _live.surahId,
        'ayah_number': _live.ayahNumber,
        'reciter_id': _live.reciterId,
        'source_kind': source.kind,
        'host': source.host,
      },
    );
    unawaited(_publishToSentry(forcePersist: true));
  }

  static void _onQueue(List<MediaItem> queue) {
    _live = _live.copyWith(
      updatedAtIso: _nowIso(),
      queueLength: queue.length,
      lastEvent: 'queue_changed',
    );
    unawaited(_publishToSentry());
  }

  static ({String kind, String? host}) _classifySource(String? raw) {
    if (raw == null || raw.isEmpty) {
      return (kind: 'unknown', host: null);
    }
    final Uri? uri = Uri.tryParse(raw);
    if (uri == null) {
      return (kind: 'unknown', host: null);
    }
    if (uri.scheme == 'file' || uri.scheme == 'content') {
      return (kind: 'local', host: uri.scheme);
    }
    if (uri.scheme == 'http' || uri.scheme == 'https') {
      return (kind: 'stream', host: uri.host);
    }
    return (kind: uri.scheme, host: uri.host.isEmpty ? null : uri.host);
  }

  static Future<void> _publishToSentry({bool forcePersist = false}) async {
    if (!Sentry.isEnabled && !kDebugMode) {
      // Still persist locally in debug when Sentry disabled.
    }
    // Prefer an explicit [noteRoute] value; only fill gaps from GoRouter.
    if (_live.route == null || _live.route!.isEmpty) {
      final String? route = _currentRoute();
      if (route != null && route.isNotEmpty) {
        _live = _live.copyWith(route: route, updatedAtIso: _nowIso());
      }
    }

    await Sentry.configureScope((Scope scope) async {
      await scope.setContexts(playbackContextKey, _playbackContext(_live));
      await scope.setContexts(sessionContextKey, _sessionContext(_live));
      final String? surah = _live.surahId;
      if (surah != null) {
        await scope.setTag('tilawa.surah_id', surah);
      }
      final String? reciter = _live.reciterId;
      if (reciter != null) {
        await scope.setTag('tilawa.reciter_id', reciter);
      }
      if (_live.playing != null) {
        await scope.setTag('tilawa.playing', _live.playing.toString());
      }
      if (_live.sourceKind != null) {
        await scope.setTag('tilawa.source_kind', _live.sourceKind!);
      }
      if (_live.lifecycle != null) {
        await scope.setTag('tilawa.lifecycle', _live.lifecycle!);
      }
    });

    final DateTime now = DateTime.now();
    if (forcePersist ||
        _lastPersistAt == null ||
        now.difference(_lastPersistAt!) >= _persistThrottle) {
      _lastPersistAt = now;
      try {
        await SessionDiagnosticsStore.save(_live);
      } on Object catch (error) {
        logger.d('[SessionDiagnostics] persist failed: $error');
      }
    }
  }

  static Future<void> _applyPriorSessionToSentry() async {
    final SessionDiagnosticsSnapshot? prior = _priorSession;
    if (prior == null || !Sentry.isEnabled) {
      return;
    }
    await Sentry.configureScope((Scope scope) async {
      await scope.setContexts(priorSessionContextKey, prior.toSentryContext());
    });
  }

  static Future<void> _refreshAndroidProcessDiagnostics({
    required String reason,
  }) async {
    if (kIsWeb || !Platform.isAndroid) {
      return;
    }
    try {
      final Object? raw = await _androidChannel.invokeMethod<Object>(
        'getProcessDiagnostics',
      );
      if (raw is! Map) {
        return;
      }
      final Map<Object?, Object?> map = raw;
      _live = _live.copyWith(
        updatedAtIso: _nowIso(),
        androidProcessImportance: (map['importance'] as num?)?.toInt(),
        availMemBytes: (map['availMemBytes'] as num?)?.toInt(),
        totalMemBytes: (map['totalMemBytes'] as num?)?.toInt(),
        lowMemory: map['lowMemory'] as bool?,
        ignoringBatteryOptimizations:
            map['ignoringBatteryOptimizations'] as bool?,
        manufacturer: map['manufacturer']?.toString(),
        lastEvent: 'android_process_$reason',
      );
      _breadcrumb(
        category: 'tilawa.android',
        message: 'process diagnostics ($reason)',
        data: <String, Object?>{
          'importance': map['importance'],
          'avail_mem_bytes': map['availMemBytes'],
          'total_mem_bytes': map['totalMemBytes'],
          'low_memory': map['lowMemory'],
          'ignoring_battery_optimizations': map['ignoringBatteryOptimizations'],
          'manufacturer': map['manufacturer'],
        },
        level: (map['lowMemory'] == true)
            ? SentryLevel.warning
            : SentryLevel.info,
      );
    } on Object catch (error) {
      logger.d('[SessionDiagnostics] android diagnostics failed: $error');
    }
  }

  static Map<String, Object> _playbackContext(SessionDiagnosticsSnapshot s) {
    final Map<String, Object> ctx = <String, Object>{};
    void put(String key, Object? value) {
      if (value != null) {
        ctx[key] = value;
      }
    }

    put('updated_at', s.updatedAtIso);
    put('playing', s.playing);
    put('processing_state', s.processingState);
    put('position_ms', s.playingPositionMs);
    put('duration_ms', s.durationMs);
    put('queue_index', s.queueIndex);
    put('queue_length', s.queueLength);
    put('surah_id', s.surahId);
    put('ayah_number', s.ayahNumber);
    put('reciter_id', s.reciterId);
    put('reciter_name', s.reciterName);
    put('moshaf_id', s.moshafId);
    put('audio_id', s.audioId);
    put('audio_title', s.audioTitle);
    put('source_kind', s.sourceKind);
    put('audio_url_host', s.audioUrlHost);
    put('speed', s.speed);
    return ctx;
  }

  static Map<String, Object> _sessionContext(SessionDiagnosticsSnapshot s) {
    final Map<String, Object> ctx = <String, Object>{};
    void put(String key, Object? value) {
      if (value != null) {
        ctx[key] = value;
      }
    }

    put('updated_at', s.updatedAtIso);
    put('lifecycle', s.lifecycle);
    put('route', s.route);
    put('last_event', s.lastEvent);
    put('android_process_importance', s.androidProcessImportance);
    put('avail_mem_bytes', s.availMemBytes);
    put('total_mem_bytes', s.totalMemBytes);
    put('low_memory', s.lowMemory);
    put('ignoring_battery_optimizations', s.ignoringBatteryOptimizations);
    put('manufacturer', s.manufacturer);
    put('startup_elapsed_ms', s.startupElapsedMs);
    return ctx;
  }

  static String? _currentRoute() {
    try {
      return AppRouter.router.routerDelegate.currentConfiguration.uri
          .toString();
    } on Object {
      return null;
    }
  }

  static void _breadcrumb({
    required String category,
    required String message,
    Map<String, Object?>? data,
    SentryLevel level = SentryLevel.info,
  }) {
    final Breadcrumb crumb = Breadcrumb(
      category: category,
      message: message,
      level: level,
      timestamp: DateTime.now().toUtc(),
      data: data == null
          ? null
          : <String, dynamic>{
              for (final MapEntry<String, Object?> e in data.entries)
                if (e.value != null) e.key: e.value,
            },
    );
    Sentry.addBreadcrumb(crumb);
    logger.d('[SessionDiagnostics][$category] $message data=$data');
  }

  static String _nowIso() => DateTime.now().toUtc().toIso8601String();
}

class _LifecycleBridge extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    SessionDiagnosticsHub.noteLifecycle(state);
  }

  @override
  void didHaveMemoryPressure() {
    SessionDiagnosticsHub.noteEvent('flutter_memory_pressure');
  }
}

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';

/// Rolling production snapshot of playback + session state for ANR / AppExitInfo
/// forensics. Survives process death via [SessionDiagnosticsStore].
@immutable
class SessionDiagnosticsSnapshot {
  const SessionDiagnosticsSnapshot({
    required this.updatedAtIso,
    this.lifecycle,
    this.route,
    this.playing,
    this.processingState,
    this.playingPositionMs,
    this.durationMs,
    this.queueIndex,
    this.queueLength,
    this.surahId,
    this.ayahNumber,
    this.reciterId,
    this.reciterName,
    this.moshafId,
    this.audioId,
    this.audioTitle,
    this.sourceKind,
    this.audioUrlHost,
    this.speed,
    this.androidProcessImportance,
    this.availMemBytes,
    this.totalMemBytes,
    this.lowMemory,
    this.ignoringBatteryOptimizations,
    this.manufacturer,
    this.startupElapsedMs,
    this.lastEvent,
  });

  final String updatedAtIso;
  final String? lifecycle;
  final String? route;
  final bool? playing;
  final String? processingState;
  final int? playingPositionMs;
  final int? durationMs;
  final int? queueIndex;
  final int? queueLength;
  final String? surahId;
  final int? ayahNumber;
  final String? reciterId;
  final String? reciterName;
  final String? moshafId;
  final String? audioId;
  final String? audioTitle;
  final String? sourceKind;
  final String? audioUrlHost;
  final double? speed;
  final int? androidProcessImportance;
  final int? availMemBytes;
  final int? totalMemBytes;
  final bool? lowMemory;
  final bool? ignoringBatteryOptimizations;
  final String? manufacturer;
  final int? startupElapsedMs;
  final String? lastEvent;

  SessionDiagnosticsSnapshot copyWith({
    String? updatedAtIso,
    String? lifecycle,
    String? route,
    bool? playing,
    String? processingState,
    int? playingPositionMs,
    int? durationMs,
    int? queueIndex,
    int? queueLength,
    String? surahId,
    int? ayahNumber,
    String? reciterId,
    String? reciterName,
    String? moshafId,
    String? audioId,
    String? audioTitle,
    String? sourceKind,
    String? audioUrlHost,
    double? speed,
    int? androidProcessImportance,
    int? availMemBytes,
    int? totalMemBytes,
    bool? lowMemory,
    bool? ignoringBatteryOptimizations,
    String? manufacturer,
    int? startupElapsedMs,
    String? lastEvent,
  }) {
    return SessionDiagnosticsSnapshot(
      updatedAtIso: updatedAtIso ?? this.updatedAtIso,
      lifecycle: lifecycle ?? this.lifecycle,
      route: route ?? this.route,
      playing: playing ?? this.playing,
      processingState: processingState ?? this.processingState,
      playingPositionMs: playingPositionMs ?? this.playingPositionMs,
      durationMs: durationMs ?? this.durationMs,
      queueIndex: queueIndex ?? this.queueIndex,
      queueLength: queueLength ?? this.queueLength,
      surahId: surahId ?? this.surahId,
      ayahNumber: ayahNumber ?? this.ayahNumber,
      reciterId: reciterId ?? this.reciterId,
      reciterName: reciterName ?? this.reciterName,
      moshafId: moshafId ?? this.moshafId,
      audioId: audioId ?? this.audioId,
      audioTitle: audioTitle ?? this.audioTitle,
      sourceKind: sourceKind ?? this.sourceKind,
      audioUrlHost: audioUrlHost ?? this.audioUrlHost,
      speed: speed ?? this.speed,
      androidProcessImportance:
          androidProcessImportance ?? this.androidProcessImportance,
      availMemBytes: availMemBytes ?? this.availMemBytes,
      totalMemBytes: totalMemBytes ?? this.totalMemBytes,
      lowMemory: lowMemory ?? this.lowMemory,
      ignoringBatteryOptimizations:
          ignoringBatteryOptimizations ?? this.ignoringBatteryOptimizations,
      manufacturer: manufacturer ?? this.manufacturer,
      startupElapsedMs: startupElapsedMs ?? this.startupElapsedMs,
      lastEvent: lastEvent ?? this.lastEvent,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'updated_at': updatedAtIso,
    'lifecycle': lifecycle,
    'route': route,
    'playing': playing,
    'processing_state': processingState,
    'position_ms': playingPositionMs,
    'duration_ms': durationMs,
    'queue_index': queueIndex,
    'queue_length': queueLength,
    'surah_id': surahId,
    'ayah_number': ayahNumber,
    'reciter_id': reciterId,
    'reciter_name': reciterName,
    'moshaf_id': moshafId,
    'audio_id': audioId,
    'audio_title': audioTitle,
    'source_kind': sourceKind,
    'audio_url_host': audioUrlHost,
    'speed': speed,
    'android_process_importance': androidProcessImportance,
    'avail_mem_bytes': availMemBytes,
    'total_mem_bytes': totalMemBytes,
    'low_memory': lowMemory,
    'ignoring_battery_optimizations': ignoringBatteryOptimizations,
    'manufacturer': manufacturer,
    'startup_elapsed_ms': startupElapsedMs,
    'last_event': lastEvent,
  };

  /// Sentry context payload (omit nulls for readability).
  Map<String, Object> toSentryContext() {
    final Map<String, Object> out = <String, Object>{};
    for (final MapEntry<String, Object?> entry in toJson().entries) {
      final Object? value = entry.value;
      if (value != null) {
        out[entry.key] = value;
      }
    }
    return out;
  }

  String encode() => jsonEncode(toJson());

  static SessionDiagnosticsSnapshot? tryDecode(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return null;
      }
      final Map<String, dynamic> map = Map<String, dynamic>.from(decoded);
      return SessionDiagnosticsSnapshot(
        updatedAtIso: map['updated_at']?.toString() ?? '',
        lifecycle: map['lifecycle']?.toString(),
        route: map['route']?.toString(),
        playing: map['playing'] as bool?,
        processingState: map['processing_state']?.toString(),
        playingPositionMs: (map['position_ms'] as num?)?.toInt(),
        durationMs: (map['duration_ms'] as num?)?.toInt(),
        queueIndex: (map['queue_index'] as num?)?.toInt(),
        queueLength: (map['queue_length'] as num?)?.toInt(),
        surahId: map['surah_id']?.toString(),
        ayahNumber: (map['ayah_number'] as num?)?.toInt(),
        reciterId: map['reciter_id']?.toString(),
        reciterName: map['reciter_name']?.toString(),
        moshafId: map['moshaf_id']?.toString(),
        audioId: map['audio_id']?.toString(),
        audioTitle: map['audio_title']?.toString(),
        sourceKind: map['source_kind']?.toString(),
        audioUrlHost: map['audio_url_host']?.toString(),
        speed: (map['speed'] as num?)?.toDouble(),
        androidProcessImportance: (map['android_process_importance'] as num?)
            ?.toInt(),
        availMemBytes: (map['avail_mem_bytes'] as num?)?.toInt(),
        totalMemBytes: (map['total_mem_bytes'] as num?)?.toInt(),
        lowMemory: map['low_memory'] as bool?,
        ignoringBatteryOptimizations:
            map['ignoring_battery_optimizations'] as bool?,
        manufacturer: map['manufacturer']?.toString(),
        startupElapsedMs: (map['startup_elapsed_ms'] as num?)?.toInt(),
        lastEvent: map['last_event']?.toString(),
      );
    } on Object {
      return null;
    }
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:tilawa/core/telemetry/startup_telemetry.dart';

import 'first_frame_log.dart';

/// Coordinates the launch splash overlay until the routed Flutter app paints
/// its first frame after [BootGate] swaps in the real app tree.
abstract final class SplashLaunchHandoff {
  static const String _debugSessionId = '1a7a28';
  static const String _debugServerEndpoint =
      'http://127.0.0.1:7878/ingest/bbbf0204-215c-4477-92e7-9e08b76a9f83';
  static const String _debugServerEndpointEmulator =
      'http://10.0.2.2:7878/ingest/bbbf0204-215c-4477-92e7-9e08b76a9f83';

  /// Becomes true after the first routed app frame paints.
  ///
  /// The initial route may be `/splash` or a resolved launch target such as
  /// `/`, so this is intentionally broader than the splash route itself.
  static final ValueNotifier<bool> splashRouteHasPainted = ValueNotifier(false);

  /// Resets handoff state for a new process launch or hot restart.
  static void resetForNewLaunch() {
    // #region agent log
    fixBlackFrameLog(
      runId: 'flutter-handoff-baseline',
      hypothesisId: 'H1',
      location: 'splash_launch_handoff.dart:resetForNewLaunch',
      message: 'Reset splash handoff state',
      data: <String, Object?>{'previous': splashRouteHasPainted.value},
    );
    // #endregion
    splashRouteHasPainted.value = false;
    firstFrameLog('handoff reset (splashRouteHasPainted=false)');
  }

  /// Called when the routed app has completed its first frame.
  static void markSplashRoutePainted() {
    if (splashRouteHasPainted.value) {
      firstFrameLog('handoff mark skipped (already painted)');
      return;
    }
    splashRouteHasPainted.value = true;
    firstFrameLog('handoff complete (splashRouteHasPainted=true)');
    unawaited(StartupTelemetry.phase('first_route_painted'));
    unawaited(StartupTelemetry.completed());
  }
}

void fixBlackFrameLog({
  required String runId,
  required String hypothesisId,
  required String location,
  required String message,
  Map<String, Object?> data = const <String, Object?>{},
}) {
  final payload = <String, Object?>{
    'sessionId': SplashLaunchHandoff._debugSessionId,
    'id':
        'log_${DateTime.now().microsecondsSinceEpoch}_${hypothesisId}_'
        '${message.hashCode}',
    'timestamp': DateTime.now().millisecondsSinceEpoch,
    'location': location,
    'message': message,
    'data': data,
    'runId': runId,
    'hypothesisId': hypothesisId,
  };
  debugPrint(
    '[FixBlackFrame] '
    'runId=$runId '
    'hypothesisId=$hypothesisId '
    'location=$location '
    'message=$message '
    'data=${jsonEncode(data)}',
  );
  if (Platform.environment.containsKey('FLUTTER_TEST')) {
    return;
  }
  Future<void>(() async {
    final body = utf8.encode(jsonEncode(payload));
    final uris = <Uri>[
      Uri.parse(SplashLaunchHandoff._debugServerEndpoint),
      Uri.parse(SplashLaunchHandoff._debugServerEndpointEmulator),
    ];
    for (final uri in uris) {
      HttpClient? client;
      try {
        client = HttpClient();
        final request = await client.postUrl(uri);
        request.headers.contentType = ContentType.json;
        request.headers.set(
          'X-Debug-Session-Id',
          SplashLaunchHandoff._debugSessionId,
        );
        request.add(body);
        final response = await request.close();
        await response.drain<void>();
        if (response.statusCode >= 200 && response.statusCode < 300) {
          client.close(force: true);
          return;
        }
      } catch (_) {
      } finally {
        client?.close(force: true);
      }
    }
  });
}

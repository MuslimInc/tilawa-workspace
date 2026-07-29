import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter_downloader/flutter_downloader.dart';

class DownloadIsolateManager {
  static const String _portName = 'downloader_send_port';
  ReceivePort? _port;
  final StreamController<(String, DownloadTaskStatus, int)> _updateController =
      StreamController.broadcast();

  Stream<(String, DownloadTaskStatus, int)> get updateStream =>
      _updateController.stream;

  /// Register an isolate port for receiving download updates from the platform layer.
  void registerPort() {
    IsolateNameServer.removePortNameMapping(_portName);

    _port = ReceivePort();
    IsolateNameServer.registerPortWithName(_port!.sendPort, _portName);

    _port!.listen((dynamic data) {
      if (data is List && data.length >= 3) {
        final taskId = data[0] as String;
        final statusInt = data[1] as int;
        final progress = data[2] as int;
        final status = DownloadTaskStatus.fromInt(statusInt);

        _updateController.add((taskId, status, progress));
      }
    });
  }

  /// Static callback registered with FlutterDownloader.
  /// Called by the platform layer when download status/progress changes.
  @pragma('vm:entry-point')
  static void downloadCallback(String id, int status, int progress) {
    forwardDownloadUpdate(id, status, progress);
  }

  /// Forward status update to the main isolate.
  static void forwardDownloadUpdate(String id, int status, int progress) {
    final SendPort? send = IsolateNameServer.lookupPortByName(_portName);
    send?.send([id, status, progress]);
  }

  void dispose() {
    _port?.close();
    IsolateNameServer.removePortNameMapping(_portName);
  }
}

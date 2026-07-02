import 'dart:async';

import 'package:tilawa_core/network/network_info.dart';

class FakeNetworkInfo implements NetworkInfo {
  FakeNetworkInfo({this.connected = true, this.delay, this.error});

  bool connected;
  Duration? delay;
  Object? error;
  int isConnectedCalls = 0;
  final StreamController<bool> _connectivityController =
      StreamController<bool>.broadcast();

  @override
  Future<bool> get isConnected async {
    isConnectedCalls++;
    final wait = delay;
    if (wait != null) {
      await Future<void>.delayed(wait);
    }
    final thrown = error;
    if (thrown != null) {
      throw thrown;
    }
    return connected;
  }

  @override
  Stream<bool> get onConnectivityChanged => _connectivityController.stream;

  void emitConnectivity(bool connected) {
    this.connected = connected;
    _connectivityController.add(connected);
  }

  Future<void> dispose() => _connectivityController.close();
}

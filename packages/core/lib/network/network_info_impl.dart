import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:injectable/injectable.dart';

import 'network_info.dart';

typedef InternetLookup =
    Future<List<InternetAddress>> Function(
      String host, {
      InternetAddressType type,
    });

@Injectable(as: NetworkInfo)
class NetworkInfoImpl implements NetworkInfo {
  NetworkInfoImpl(
    this._connectivity, {
    @factoryParam InternetLookup? internetLookup,
    @ignoreParam DateTime Function()? now,
  }) : internetLookup = internetLookup ?? InternetAddress.lookup,
       _now = now ?? DateTime.now;

  final Connectivity _connectivity;
  final InternetLookup internetLookup;
  final DateTime Function() _now;

  /// Checks run inside tap-triggered guards (login/logout/delete), so the
  /// DNS probe must stay short.
  static const Duration lookupTimeout = Duration(seconds: 3);

  /// Rapid consecutive checks reuse the last result instead of re-probing.
  static const Duration resultCacheTtl = Duration(seconds: 3);

  bool? _lastResult;
  DateTime? _lastCheckedAt;
  Future<bool>? _inFlightCheck;

  @override
  Future<bool> get isConnected {
    final bool? cached = _cachedResult();
    if (cached != null) {
      return Future<bool>.value(cached);
    }

    final Future<bool>? inFlight = _inFlightCheck;
    if (inFlight != null) {
      return inFlight;
    }

    final Future<bool> check = _checkConnected()
        .then((bool result) {
          _lastResult = result;
          _lastCheckedAt = _now();
          return result;
        })
        .whenComplete(() {
          _inFlightCheck = null;
        });
    _inFlightCheck = check;
    return check;
  }

  bool? _cachedResult() {
    final bool? lastResult = _lastResult;
    final DateTime? lastCheckedAt = _lastCheckedAt;
    if (lastResult == null || lastCheckedAt == null) {
      return null;
    }
    if (_now().difference(lastCheckedAt) >= resultCacheTtl) {
      return null;
    }
    return lastResult;
  }

  Future<bool> _checkConnected() async {
    try {
      final List<ConnectivityResult> result = await _connectivity
          .checkConnectivity();
      if (result.contains(ConnectivityResult.none)) {
        return false;
      }
      // Double check with actual internet lookup (with timeout to avoid long waits)
      final List<InternetAddress> lookupResult = await internetLookup(
        'google.com',
      ).timeout(lookupTimeout);
      return lookupResult.isNotEmpty && lookupResult[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } on TimeoutException catch (_) {
      return false;
    }
  }

  @override
  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map((results) {
      return !results.contains(ConnectivityResult.none);
    });
  }
}

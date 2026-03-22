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
  }) : internetLookup = internetLookup ?? InternetAddress.lookup;

  final Connectivity _connectivity;
  final InternetLookup internetLookup;

  @override
  Future<bool> get isConnected async {
    try {
      final List<ConnectivityResult> result = await _connectivity
          .checkConnectivity();
      if (result.contains(ConnectivityResult.none)) {
        return false;
      }
      // Double check with actual internet lookup (with timeout to avoid long waits)
      final List<InternetAddress> lookupResult = await internetLookup(
        'google.com',
      ).timeout(const Duration(seconds: 5));
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

import 'dart:async';

import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/network/network_info.dart';

/// App actions that require network/server availability.
enum ServerActionType {
  logout,
  deleteAccount,
  googleSignIn,
  refreshUserProfile,
  syncData,
  verifySentrySetup,
  testLiveKitCall,
}

/// Guards actions that must not run while the device cannot reach the network.
@lazySingleton
class ServerActionGuard {
  ServerActionGuard(this._networkInfo);

  final NetworkInfo _networkInfo;
  final Map<ServerActionType, Future<Either<Failure, void>>> _pendingChecks =
      <ServerActionType, Future<Either<Failure, void>>>{};

  static const Set<ServerActionType> _onlineRequiredActions =
      <ServerActionType>{
        ServerActionType.logout,
        ServerActionType.deleteAccount,
        ServerActionType.googleSignIn,
        ServerActionType.refreshUserProfile,
        ServerActionType.syncData,
        ServerActionType.verifySentrySetup,
        ServerActionType.testLiveKitCall,
      };

  Future<Either<Failure, void>> ensureCanRun(ServerActionType action) {
    if (!_onlineRequiredActions.contains(action)) {
      return Future<Either<Failure, void>>.value(const Right(null));
    }

    final pending = _pendingChecks[action];
    if (pending != null) {
      return pending;
    }

    final check = _ensureOnline().whenComplete(() {
      _pendingChecks.remove(action);
    });
    _pendingChecks[action] = check;
    return check;
  }

  Future<Either<Failure, void>> _ensureOnline() async {
    try {
      final bool isOnline = await _networkInfo.isConnected;
      if (isOnline) {
        return const Right(null);
      }
    } on TimeoutException {
      return const Left(ServerActionFailure.offline());
    } on NetworkException {
      return const Left(ServerActionFailure.offline());
    } on Object {
      return const Left(ServerActionFailure.offline());
    }

    return const Left(ServerActionFailure.offline());
  }
}

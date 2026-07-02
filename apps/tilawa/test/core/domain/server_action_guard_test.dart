import 'dart:async';
import 'dart:io';

import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/core/domain/server_action_guard.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../../support/fake_network_info.dart';

void main() {
  late FakeNetworkInfo networkInfo;
  late ServerActionGuard guard;

  setUp(() {
    networkInfo = FakeNetworkInfo();
    guard = ServerActionGuard(networkInfo);
  });

  tearDown(() async {
    await networkInfo.dispose();
  });

  test('allows server action when online', () async {
    final result = await guard.ensureCanRun(ServerActionType.logout);

    check(result.isRight()).isTrue();
    check(networkInfo.isConnectedCalls).equals(1);
  });

  test('blocks server action when offline', () async {
    networkInfo.connected = false;

    final result = await guard.ensureCanRun(ServerActionType.deleteAccount);

    check(result.isLeft()).isTrue();
    result.fold(
      (failure) {
        check(failure).isA<ServerActionFailure>();
        check(failure.message).equals(ServerActionFailureKey.offline);
      },
      (_) => fail('expected offline failure'),
    );
  });

  test('blocks when internet reachability check throws socket error', () async {
    networkInfo.error = const SocketException('unreachable');

    final result = await guard.ensureCanRun(ServerActionType.googleSignIn);

    check(result.isLeft()).isTrue();
    result.fold(
      (failure) => check(failure).isA<ServerActionFailure>(),
      (_) => fail('expected offline failure'),
    );
  });

  test('blocks when internet reachability check times out', () async {
    networkInfo.error = TimeoutException('server timeout');

    final result = await guard.ensureCanRun(ServerActionType.syncData);

    check(result.isLeft()).isTrue();
    result.fold(
      (failure) => check(failure).isA<ServerActionFailure>(),
      (_) => fail('expected offline failure'),
    );
  });

  test('shares rapid repeated checks for the same action', () async {
    networkInfo
      ..connected = false
      ..delay = const Duration(milliseconds: 20);

    final results = await Future.wait([
      guard.ensureCanRun(ServerActionType.logout),
      guard.ensureCanRun(ServerActionType.logout),
    ]);

    check(networkInfo.isConnectedCalls).equals(1);
    check(results).length.equals(2);
    for (final result in results) {
      check(result.isLeft()).isTrue();
      result.fold(
        (Failure failure) => check(failure).isA<ServerActionFailure>(),
        (_) => fail('expected offline failure'),
      );
    }
  });
}

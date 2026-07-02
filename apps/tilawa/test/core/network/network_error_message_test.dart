import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/core/network/network_error_message.dart';

void main() {
  test('detects Firebase gRPC network copy', () {
    expect(
      isNetworkConnectivityErrorMessage(
        'A network error (such as timeout, interrupted connection or '
        'unreachable host) has occurred.',
      ),
      isTrue,
    );
  });

  test('detects Dart socket failures', () {
    expect(
      isNetworkConnectivityErrorMessage(
        'SocketException: Failed host lookup: example.com',
      ),
      isTrue,
    );
  });

  test('ignores unrelated errors', () {
    expect(isNetworkConnectivityErrorMessage('boom'), isFalse);
    expect(isNetworkConnectivityErrorMessage(''), isFalse);
  });
}

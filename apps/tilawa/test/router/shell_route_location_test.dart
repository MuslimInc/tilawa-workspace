import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tilawa/router/shell_route_location.dart';

void main() {
  group('ShellRouteLocation.activeMatchedLocation', () {
    test('returns home when the match list is empty', () {
      final RouteMatchList empty = RouteMatchList(
        matches: const <RouteMatchBase>[],
        uri: Uri.parse('/'),
        pathParameters: const <String, String>{},
      );

      expect(ShellRouteLocation.activeMatchedLocation(empty), '/');
    });
  });

  group('ShellRouteLocation.safeUriPath', () {
    test('returns null when the match list is empty', () {
      final RouteMatchList empty = RouteMatchList(
        matches: const <RouteMatchBase>[],
        uri: Uri.parse('/'),
        pathParameters: const <String, String>{},
      );

      expect(ShellRouteLocation.safeUriPath(empty), isNull);
    });
  });
}

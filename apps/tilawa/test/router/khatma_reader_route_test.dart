import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/router/app_router_config.dart';

void main() {
  test('Khatma reader route owns its exact initial page', () {
    expect(
      const KhatmaReaderRoute(initialPage: 42).location,
      '/khatma-reader/42',
    );
  });

  test('Khatma reader route encodes plan page bounds as query params', () {
    expect(
      const KhatmaReaderRoute(
        initialPage: 1,
        firstPage: 1,
        lastPage: 5,
      ).location,
      '/khatma-reader/1?first-page=1&last-page=5',
    );
  });
}

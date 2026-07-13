import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/router/app_router_config.dart';

void main() {
  test('Khatma reader route owns its exact initial page', () {
    expect(
      const KhatmaReaderRoute(initialPage: 42).location,
      '/khatma-reader/42',
    );
  });
}

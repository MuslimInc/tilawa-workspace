import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tilawa/features/tour_guide/domain/services/tour_target_registry.dart';

void main() {
  late TourTargetRegistry registry;

  setUp(() {
    registry = TourTargetRegistry();
  });

  test('registers and resolves target keys', () {
    final GlobalKey key = GlobalKey();

    registry.register('search', key);

    expect(registry.keyFor('search'), same(key));
    expect(registry.hasTarget('search'), isTrue);
  });

  test('unregister removes only matching key instance', () {
    final GlobalKey first = GlobalKey();
    final GlobalKey second = GlobalKey();

    registry.register('search', first);
    registry.unregister('search', second);
    expect(registry.hasTarget('search'), isTrue);

    registry.unregister('search', first);
    expect(registry.hasTarget('search'), isFalse);
  });
}

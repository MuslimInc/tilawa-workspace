import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/core/bootstrap/cold_start_navigation_metrics.dart';

void main() {
  setUp(ColdStartNavigationMetrics.resetForTesting);

  test('tracks boot gate splash once per process metrics reset', () {
    expect(ColdStartNavigationMetrics.splashScreenCount, 0);
    ColdStartNavigationMetrics.recordBootGateSplash();
    ColdStartNavigationMetrics.recordRouterSplash();
    expect(ColdStartNavigationMetrics.splashScreenCount, 2);
  });
}

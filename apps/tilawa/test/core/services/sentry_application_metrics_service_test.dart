import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:tilawa/core/services/sentry_application_metrics_service.dart';
import 'package:tilawa_core/services/application_metrics_service.dart';

void main() {
  group('SentryApplicationMetricsService', () {
    test('forwards counter metrics with primitive attributes', () {
      final _FakeSentryMetrics sentryMetrics = _FakeSentryMetrics();
      final SentryApplicationMetricsService service =
          SentryApplicationMetricsService.withMetrics(sentryMetrics);

      service.count(
        'audio.play',
        value: 2,
        attributes: const <String, Object>{
          'source': 'mini_player',
          'offline': false,
          'queue_size': 3,
          'progress': 0.5,
        },
      );

      expect(sentryMetrics.calls, hasLength(1));
      final _MetricCall call = sentryMetrics.calls.single;
      expect(call.type, _MetricType.count);
      expect(call.name, 'audio.play');
      expect(call.value, 2);
      expect(call.attributes?['source']?.value, 'mini_player');
      expect(call.attributes?['offline']?.value, false);
      expect(call.attributes?['queue_size']?.value, 3);
      expect(call.attributes?['progress']?.value, 0.5);
    });

    test('forwards gauge metrics with units', () {
      final _FakeSentryMetrics sentryMetrics = _FakeSentryMetrics();
      final SentryApplicationMetricsService service =
          SentryApplicationMetricsService.withMetrics(sentryMetrics);

      service.gauge(
        'cache.size',
        4096,
        unit: ApplicationMetricUnit.byte,
      );

      final _MetricCall call = sentryMetrics.calls.single;
      expect(call.type, _MetricType.gauge);
      expect(call.name, 'cache.size');
      expect(call.value, 4096);
      expect(call.unit, ApplicationMetricUnit.byte);
    });

    test('forwards distribution metrics with units', () {
      final _FakeSentryMetrics sentryMetrics = _FakeSentryMetrics();
      final SentryApplicationMetricsService service =
          SentryApplicationMetricsService.withMetrics(sentryMetrics);

      service.distribution(
        'startup.elapsed',
        187,
        unit: ApplicationMetricUnit.millisecond,
      );

      final _MetricCall call = sentryMetrics.calls.single;
      expect(call.type, _MetricType.distribution);
      expect(call.name, 'startup.elapsed');
      expect(call.value, 187);
      expect(call.unit, ApplicationMetricUnit.millisecond);
    });

    test('does not throw when the Sentry SDK rejects a metric', () {
      final SentryApplicationMetricsService service =
          SentryApplicationMetricsService.withMetrics(
            _ThrowingSentryMetrics(),
          );

      expect(() => service.count('broken.metric'), returnsNormally);
      expect(() => service.gauge('broken.metric', 1), returnsNormally);
      expect(() => service.distribution('broken.metric', 1), returnsNormally);
    });
  });
}

enum _MetricType { count, gauge, distribution }

class _MetricCall {
  const _MetricCall({
    required this.type,
    required this.name,
    required this.value,
    this.unit,
    this.attributes,
  });

  final _MetricType type;
  final String name;
  final num value;
  final String? unit;
  final Map<String, SentryAttribute>? attributes;
}

class _FakeSentryMetrics implements SentryMetrics {
  final List<_MetricCall> calls = <_MetricCall>[];

  @override
  void count(
    String name,
    int value, {
    Map<String, SentryAttribute>? attributes,
  }) {
    calls.add(
      _MetricCall(
        type: _MetricType.count,
        name: name,
        value: value,
        attributes: attributes,
      ),
    );
  }

  @override
  void gauge(
    String name,
    num value, {
    String? unit,
    Map<String, SentryAttribute>? attributes,
  }) {
    calls.add(
      _MetricCall(
        type: _MetricType.gauge,
        name: name,
        value: value,
        unit: unit,
        attributes: attributes,
      ),
    );
  }

  @override
  void distribution(
    String name,
    num value, {
    String? unit,
    Map<String, SentryAttribute>? attributes,
  }) {
    calls.add(
      _MetricCall(
        type: _MetricType.distribution,
        name: name,
        value: value,
        unit: unit,
        attributes: attributes,
      ),
    );
  }
}

class _ThrowingSentryMetrics implements SentryMetrics {
  @override
  void count(
    String name,
    int value, {
    Map<String, SentryAttribute>? attributes,
  }) {
    throw StateError('count failed');
  }

  @override
  void gauge(
    String name,
    num value, {
    String? unit,
    Map<String, SentryAttribute>? attributes,
  }) {
    throw StateError('gauge failed');
  }

  @override
  void distribution(
    String name,
    num value, {
    String? unit,
    Map<String, SentryAttribute>? attributes,
  }) {
    throw StateError('distribution failed');
  }
}

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:tilawa/core/logging/app_logger.dart';
import 'package:tilawa_core/services/application_metrics_service.dart';

/// Sentry implementation of [ApplicationMetricsService].
///
/// Sentry's SDK is kept behind this adapter so app and feature layers can emit
/// metrics without importing `sentry_flutter`.
@Singleton(as: ApplicationMetricsService)
class SentryApplicationMetricsService implements ApplicationMetricsService {
  /// Creates a Sentry-backed metrics service.
  SentryApplicationMetricsService() : _metrics = Sentry.metrics;

  /// Creates a metrics service with an injected Sentry metrics client.
  @visibleForTesting
  SentryApplicationMetricsService.withMetrics(SentryMetrics metrics)
    : _metrics = metrics;

  final SentryMetrics _metrics;

  @override
  void count(
    String name, {
    int value = 1,
    ApplicationMetricAttributes? attributes,
  }) {
    try {
      _metrics.count(
        name,
        value,
        attributes: _sentryAttributes(attributes),
      );
    } catch (e) {
      logger.d('Sentry metric count failed: $e');
    }
  }

  @override
  void gauge(
    String name,
    num value, {
    String? unit,
    ApplicationMetricAttributes? attributes,
  }) {
    try {
      _metrics.gauge(
        name,
        value,
        unit: unit,
        attributes: _sentryAttributes(attributes),
      );
    } catch (e) {
      logger.d('Sentry metric gauge failed: $e');
    }
  }

  @override
  void distribution(
    String name,
    num value, {
    String? unit,
    ApplicationMetricAttributes? attributes,
  }) {
    try {
      _metrics.distribution(
        name,
        value,
        unit: unit,
        attributes: _sentryAttributes(attributes),
      );
    } catch (e) {
      logger.d('Sentry metric distribution failed: $e');
    }
  }

  static Map<String, SentryAttribute>? _sentryAttributes(
    ApplicationMetricAttributes? attributes,
  ) {
    if (attributes == null || attributes.isEmpty) {
      return null;
    }
    return attributes.map(
      (String key, Object value) => MapEntry(
        key,
        _sentryAttribute(value),
      ),
    );
  }

  static SentryAttribute _sentryAttribute(Object value) {
    return switch (value) {
      final String value => SentryAttribute.string(value),
      final bool value => SentryAttribute.bool(value),
      final int value => SentryAttribute.int(value),
      final double value => SentryAttribute.double(value),
      _ => SentryAttribute.string(value.toString()),
    };
  }
}

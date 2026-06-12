import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Forwards [Logger] output to [Sentry.logger] in production release builds.
///
/// Only warning-level and above are sent to avoid flooding Sentry with debug
/// chatter. Development and profile builds keep console logging only.
class SentryLogOutput extends LogOutput {
  static const Level minimumLevel = Level.warning;
  static const int maxStackTraceLines = 10;

  /// Whether [Sentry.logger] forwarding is active for this build.
  static bool get forwardingEnabled => kReleaseMode && Sentry.isEnabled;

  @override
  void output(OutputEvent event) {
    if (!forwardingEnabled || event.level < minimumLevel) {
      return;
    }

    final LogEvent origin = event.origin;
    _sendToSentry(
      level: origin.level,
      body: _formatBody(origin),
      attributes: _buildAttributes(origin),
    );
  }

  static void _sendToSentry({
    required Level level,
    required String body,
    required Map<String, SentryAttribute> attributes,
  }) {
    switch (level) {
      case Level.trace ||
          // ignore: deprecated_member_use
          Level.verbose:
        Sentry.logger.trace(body, attributes: attributes);
      case Level.debug:
        Sentry.logger.debug(body, attributes: attributes);
      case Level.info:
        Sentry.logger.info(body, attributes: attributes);
      case Level.warning:
        Sentry.logger.warn(body, attributes: attributes);
      case Level.error:
        Sentry.logger.error(body, attributes: attributes);
      case Level.fatal ||
          // ignore: deprecated_member_use
          Level.wtf:
        Sentry.logger.fatal(body, attributes: attributes);
      case Level.all || Level.off:
        break;
      // ignore: deprecated_member_use
      case Level.nothing:
        break;
    }
  }

  @visibleForTesting
  static String formatBody(LogEvent event) => _formatBody(event);

  static String _formatBody(LogEvent event) {
    final String message = event.message?.toString() ?? '';
    return switch ((message.isEmpty, event.error)) {
      (_, null) => message,
      (true, final Object error) => error.toString(),
      (false, final Object error) => '$message: $error',
    };
  }

  @visibleForTesting
  static Map<String, SentryAttribute> buildAttributes(LogEvent event) =>
      _buildAttributes(event);

  static Map<String, SentryAttribute> _buildAttributes(LogEvent event) {
    final Map<String, SentryAttribute> attributes = <String, SentryAttribute>{};
    final Object? error = event.error;
    if (error != null) {
      attributes['error_type'] = SentryAttribute.string(error.runtimeType.toString());
    }
    final StackTrace? stackTrace = event.stackTrace;
    if (stackTrace != null) {
      attributes['stack_trace'] = SentryAttribute.string(
        truncateStackTrace(stackTrace),
      );
    }
    return attributes;
  }

  @visibleForTesting
  static String truncateStackTrace(StackTrace stackTrace) {
    final List<String> lines = stackTrace.toString().split('\n');
    if (lines.length <= maxStackTraceLines) {
      return stackTrace.toString();
    }
    final int omitted = lines.length - maxStackTraceLines;
    return '${lines.take(maxStackTraceLines).join('\n')}\n… ($omitted more frames)';
  }
}

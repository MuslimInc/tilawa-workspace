import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:tilawa/core/telemetry/sentry_log_output.dart';

final Logger logger = Logger(
  filter: _TilawaLogFilter(),
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 5,
    lineLength: 80,
    colors: false,
    printEmojis: true,
    dateTimeFormat: DateTimeFormat.dateAndTime,
  ),
  output: MultiOutput(<LogOutput>[
    if (!kReleaseMode) ConsoleOutput(),
    if (kReleaseMode) SentryLogOutput(),
  ]),
);

/// Console logging in debug/profile; in release only levels forwarded to Sentry
/// pass the filter (warning and above).
class _TilawaLogFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    if (!kReleaseMode) {
      return true;
    }
    return event.level >= SentryLogOutput.minimumLevel;
  }
}

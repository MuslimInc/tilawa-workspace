import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

final Logger logger = Logger(
  filter: _ProfileLogFilter(),
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 8,
    lineLength: 120,
    colors: true,
    printEmojis: true,
    dateTimeFormat: DateTimeFormat.dateAndTime,
  ),
);

class _ProfileLogFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    return !kReleaseMode;
  }
}

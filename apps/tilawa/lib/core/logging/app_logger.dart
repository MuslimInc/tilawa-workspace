import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

final Logger logger = Logger(
  filter: _ProfileLogFilter(),
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 5,
    lineLength: 80,
    colors: false,
    printEmojis: true,
    dateTimeFormat: DateTimeFormat.onlyDate,
  ),
);

class _ProfileLogFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    return !kReleaseMode;
  }
}

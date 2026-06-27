import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

@immutable
class NotificationDebugLogEntry {
  const NotificationDebugLogEntry({
    required this.timestamp,
    required this.event,
    this.detail,
  });

  final DateTime timestamp;
  final String event;
  final String? detail;
}

/// In-memory log for the Notification Debug Lab only.
@lazySingleton
class NotificationDebugLogStore extends ChangeNotifier {
  NotificationDebugLogStore();

  static const int maxEntries = 100;

  final List<NotificationDebugLogEntry> _entries =
      <NotificationDebugLogEntry>[];

  List<NotificationDebugLogEntry> get entries =>
      List<NotificationDebugLogEntry>.unmodifiable(_entries);

  void log(String event, {String? detail}) {
    if (!kDebugMode) {
      return;
    }
    _entries.insert(
      0,
      NotificationDebugLogEntry(
        timestamp: DateTime.now(),
        event: event,
        detail: detail,
      ),
    );
    while (_entries.length > maxEntries) {
      _entries.removeLast();
    }
    notifyListeners();
  }

  void clear() {
    _entries.clear();
    notifyListeners();
  }
}

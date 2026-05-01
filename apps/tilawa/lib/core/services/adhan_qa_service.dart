import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tilawa_core/di/injection.dart';
import 'android_adhan_alarm_player.dart';

/// Service for managing Adhan QA tools and logging.
/// Only active in debug/profile modes or if ENABLE_ADHAN_QA_TOOLS is defined.
class AdhanQAService {
  static const MethodChannel _channel = MethodChannel('com.tilawa.app/prayer_adhan');

  static bool get isEnabled {
    if (kDebugMode || kProfileMode) return true;
    return const bool.fromEnvironment('ENABLE_ADHAN_QA_TOOLS', defaultValue: false);
  }

  /// Initialize QA tools (enable native logging if allowed).
  Future<void> init() async {
    if (!isEnabled) return;
    try {
      await _channel.invokeMethod('setQALoggingEnabled', {'enabled': true});
      await logEvent('QA_TOOLS_INITIALIZED');
    } catch (e) {
      debugPrint('[AdhanQAService] Failed to init native logging: $e');
    }
  }

  /// Log an event to the persistent QA log file.
  Future<void> logEvent(String event, {String? prayer, String? details}) async {
    if (!isEnabled) return;
    try {
      await _channel.invokeMethod('logQAEvent', {
        'event': event,
        'prayer': prayer,
        'details': details,
      });
    } catch (e) {
      debugPrint('[AdhanQAService] Failed to log event: $e');
    }
  }

  /// Schedule a test Adhan using the production native pipeline.
  Future<void> scheduleTestAdhan({required int delayMinutes}) async {
    if (!isEnabled) return;
    
    // Unique ID for QA test (using a large constant to avoid collisions)
    const testId = 999999;
    final scheduledTime = DateTime.now().add(Duration(minutes: delayMinutes));
    
    await logEvent(
      'QA_TEST_ADHAN_SCHEDULE_REQUESTED',
      details: 'delay=${delayMinutes}m, time=$scheduledTime',
    );

    try {
      // Use the real native method via testAdhanNotification (which calls scheduler.schedule)
      await _channel.invokeMethod('testAdhanNotification', {
        'id': testId,
        'name': 'qa_test_adhan',
        'sound': 'adhan',
        'delayMs': delayMinutes * 60 * 1000,
      });
      
      await logEvent('QA_TEST_ADHAN_SCHEDULED_SUCCESS');
    } catch (e) {
      await logEvent('QA_TEST_ADHAN_SCHEDULED_FAILED', details: e.toString());
      rethrow;
    }
  }

  /// Cancel any pending QA test Adhan.
  Future<void> cancelTestAdhan() async {
    if (!isEnabled) return;
    const testId = 999999;
    
    await logEvent('QA_TEST_ADHAN_CANCEL_REQUESTED');
    try {
      await _channel.invokeMethod('cancelAdhan', {'id': testId});
      await logEvent('QA_TEST_ADHAN_CANCELLED');
    } catch (e) {
      await logEvent('QA_TEST_ADHAN_CANCEL_FAILED', details: e.toString());
      rethrow;
    }
  }

  /// Retrieve all persistent QA logs from the device.
  Future<String> getLogs() async {
    if (!isEnabled) return 'QA Tools Disabled';
    try {
      return await _channel.invokeMethod<String>('getQALogs') ?? 'No logs';
    } catch (e) {
      return 'Error reading logs: $e';
    }
  }

  /// Clear all persistent QA logs.
  Future<void> clearLogs() async {
    if (!isEnabled) return;
    try {
      await _channel.invokeMethod('clearQALogs');
    } catch (e) {
      debugPrint('[AdhanQAService] Failed to clear logs: $e');
    }
  }
}

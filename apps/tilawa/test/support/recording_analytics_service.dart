import 'package:tilawa_core/services/analytics_service.dart';

final class RecordingAnalyticsService implements AnalyticsService {
  RecordingAnalyticsService();

  final List<String> events = <String>[];

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    events.add(name);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

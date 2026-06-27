import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/features/quran_sessions/presentation/quran_sessions_analytics.dart';
import 'package:tilawa_core/constants/analytics_constants.dart';
import 'package:tilawa_core/services/analytics_service.dart';

typedef _Event = ({String name, Map<String, Object>? params});

final class _RecordingAnalyticsService implements AnalyticsService {
  final List<_Event> events = <_Event>[];

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    events.add((name: name, params: parameters));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _RecordingAnalyticsService analytics;

  setUp(() async {
    await getIt.reset();
    getIt.allowReassignment = true;
    analytics = _RecordingAnalyticsService();
    getIt.registerSingleton<AnalyticsService>(analytics);
  });

  tearDown(() async => getIt.reset());

  test('teacher_profile_viewed logs teacher_id only', () {
    quranSessionsAnalyticsCallbacks().onTeacherProfileViewed!('t1');

    expect(analytics.events.single.name, AnalyticsEvents.teacherProfileViewed);
    expect(analytics.events.single.params, {AnalyticsParams.teacherId: 't1'});
  });

  test('booking_started logs teacher_id only', () {
    quranSessionsAnalyticsCallbacks().onBookingStarted!('t1');

    expect(analytics.events.single.name, AnalyticsEvents.bookingStarted);
    expect(analytics.events.single.params, {AnalyticsParams.teacherId: 't1'});
  });

  test('booking_completed logs only safe ids, enums and the paid flag', () {
    quranSessionsAnalyticsCallbacks().onBookingCompleted!(
      teacherId: 't1',
      bookingId: 'b1',
      isPaid: true,
      pricingType: 'fixedPerSession',
      callType: 'voiceCall',
    );

    final event = analytics.events.single;
    expect(event.name, AnalyticsEvents.bookingCompleted);
    expect(event.params, {
      AnalyticsParams.teacherId: 't1',
      AnalyticsParams.bookingId: 'b1',
      AnalyticsParams.isPaid: true,
      AnalyticsParams.pricingType: 'fixedPerSession',
      AnalyticsParams.callType: 'voiceCall',
    });
  });

  test('session_joined logs ids only', () {
    quranSessionsAnalyticsCallbacks().onSessionJoined!(
      bookingId: 'b1',
      sessionId: 's1',
    );

    final event = analytics.events.single;
    expect(event.name, AnalyticsEvents.sessionJoined);
    expect(event.params, {
      AnalyticsParams.bookingId: 'b1',
      AnalyticsParams.sessionId: 's1',
    });
  });

  test('review_submitted logs rating and ids but no free text', () {
    quranSessionsAnalyticsCallbacks().onReviewSubmitted!(
      sessionId: 's1',
      rating: 5,
    );

    final event = analytics.events.single;
    expect(event.name, AnalyticsEvents.reviewSubmitted);
    expect(event.params, {
      AnalyticsParams.sessionId: 's1',
      AnalyticsParams.ratingValue: 5,
    });
  });

  test('list and my-sessions view events log without parameters', () {
    final callbacks = quranSessionsAnalyticsCallbacks();
    callbacks.onTeacherListViewed!();
    callbacks.onMySessionsOpened!();

    expect(analytics.events.map((e) => e.name).toList(), [
      AnalyticsEvents.teacherListViewed,
      AnalyticsEvents.mySessionsOpened,
    ]);
    expect(analytics.events.every((e) => e.params == null), isTrue);
  });
}

import 'package:checks/checks.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/features/auth/domain/services/callable_session_payload_builder.dart';
import 'package:tilawa/features/auth/domain/services/session_epoch_provider.dart';
import 'package:tilawa/features/quran_sessions/data/firebase/firebase_session_mutation_gateway.dart';
import 'package:tilawa/features/quran_sessions/data/firebase/firestore_paths.dart';

class _FakePayloadBuilder extends CallableSessionPayloadBuilder {
  _FakePayloadBuilder() : super(_FakeEpochProvider());
}

class _FakeEpochProvider implements SessionEpochProvider {
  @override
  Future<int> getSessionEpoch() async => 0;
}

class MockFirebaseFunctions extends Mock implements FirebaseFunctions {}

class MockHttpsCallable extends Mock implements HttpsCallable {}

class MockHttpsCallableResult extends Mock
    implements HttpsCallableResult<Map<String, dynamic>> {}

void main() {
  late FakeFirebaseFirestore firestore;
  late MockFirebaseFunctions functions;
  late MockHttpsCallable callable;
  late MockHttpsCallableResult callableResult;
  late FirebaseSessionMutationGateway gateway;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    functions = MockFirebaseFunctions();
    callable = MockHttpsCallable();
    callableResult = MockHttpsCallableResult();

    gateway = FirebaseSessionMutationGateway(
      firestore,
      functions,
      _FakePayloadBuilder(),
      null,
    );

    registerFallbackValue(const <String, dynamic>{});
  });

  group('FirebaseSessionMutationGateway mutations', () {
    test('cancelSession returns aggregate', () async {
      // Seed booking in FakeFirestore so _loadAggregate succeeds
      const bookingId = 'booking_123';
      await firestore
          .collection(FirestoreQuranSessionsPaths.bookings)
          .doc(bookingId)
          .set({
            'bookingId': bookingId,
            'teacherId': 'teacher1',
            'studentId': 'student1',
            'startsAt': Timestamp.fromDate(DateTime.now()),
            'pricingType': 'free',
            'lifecycleStatus': 'scheduled',
            'createdAt': Timestamp.fromDate(DateTime.now()),
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });

      // Stub functions callable
      when(
        () => functions.httpsCallable('cancelSessionBooking'),
      ).thenReturn(callable);
      when(
        () => callable.call<Map<String, dynamic>>(any()),
      ).thenAnswer((_) async => callableResult);
      when(() => callableResult.data).thenReturn(<String, dynamic>{});

      final result = await gateway.cancelSession(
        bookingId: bookingId,
        reason: 'No longer needed',
        actorRole: ActorRole.student,
      );

      check(result.isRight()).isTrue();
    });

    test('completeSession returns aggregate', () async {
      const sessionId = 'session_456';
      const bookingId = 'booking_456';

      // Seed session in FakeFirestore so _sessions.doc(sessionId).get() succeeds
      await firestore
          .collection(FirestoreQuranSessionsPaths.sessions)
          .doc(sessionId)
          .set({
            'bookingId': bookingId,
          });

      // Seed booking in FakeFirestore so _loadAggregate succeeds
      await firestore
          .collection(FirestoreQuranSessionsPaths.bookings)
          .doc(bookingId)
          .set({
            'bookingId': bookingId,
            'teacherId': 'teacher1',
            'studentId': 'student1',
            'startsAt': Timestamp.fromDate(DateTime.now()),
            'pricingType': 'free',
            'lifecycleStatus': 'completed',
            'createdAt': Timestamp.fromDate(DateTime.now()),
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });

      when(
        () => functions.httpsCallable('completeSession'),
      ).thenReturn(callable);
      when(
        () => callable.call<Map<String, dynamic>>(any()),
      ).thenAnswer((_) async => callableResult);
      when(() => callableResult.data).thenReturn(<String, dynamic>{});

      final result = await gateway.completeSession(
        sessionId: sessionId,
        actorRole: ActorRole.teacher,
      );

      check(result.isRight()).isTrue();
    });
  });
}

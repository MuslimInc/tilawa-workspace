import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:quran_sessions/quran_sessions.dart';

import 'firestore_exception_mapper.dart';
import 'firestore_paths.dart';

class FirestoreBookingDataSource implements BookingRemoteDataSource {
  FirestoreBookingDataSource(
    this._firestore,
    this._authSession,
    this._functions,
  );

  final FirebaseFirestore _firestore;
  final AuthSessionProvider _authSession;
  final FirebaseFunctions _functions;

  CollectionReference<Map<String, dynamic>> get _bookings =>
      _firestore.collection(FirestoreQuranSessionsPaths.bookings);

  DocumentReference<Map<String, dynamic>> _scheduleRef(String teacherId) =>
      _firestore
          .collection(FirestoreQuranSessionsPaths.teacherProfiles)
          .doc(teacherId)
          .collection(FirestoreQuranSessionsPaths.availabilityConfig)
          .doc(FirestoreQuranSessionsPaths.scheduleDoc);

  String _requireStudentId() {
    final studentId = _authSession.currentUserId;
    if (studentId == null || studentId.isEmpty) {
      throw const HttpException(401);
    }
    return studentId;
  }

  @override
  Future<QuranBookingDto> createBooking({
    required String teacherId,
    required String slotId,
    required String requestedCallTypeId,
    String? paymentReference,
    String? studentNote,
  }) async {
    final studentId = _requireStudentId();
    final slotStart = GeneratedSlot.parseStartUtc(
      teacherId: teacherId,
      slotId: slotId,
    );
    if (slotStart == null) {
      throw ConflictException(isSlotUnavailable: true, slotId: slotId);
    }

    try {
      final scheduleSnap = await _scheduleRef(teacherId).get();
      final durationMinutes =
          scheduleSnap.data()?['slot_duration_minutes'] as int? ?? 30;
      final startsAt = slotStart.toUtc();
      final endsAt = startsAt.add(Duration(minutes: durationMinutes));

      final callable = _functions.httpsCallable('createSessionBooking');
      final response = await callable.call<Map<String, dynamic>>({
        'teacherId': teacherId,
        'slotId': slotId,
        'startsAt': startsAt.toIso8601String(),
        'endsAt': endsAt.toIso8601String(),
        'callType': requestedCallTypeId,
        'pricingType': paymentReference == null ? 'free' : 'fixedPerSession',
        'paymentReference': paymentReference,
        'studentNote': studentNote,
      });
      final payload = response.data;
      final bookingId = payload['bookingId'] as String? ?? '';
      final sessionId = payload['sessionId'] as String?;

      return QuranBookingDto(
        id: bookingId,
        teacherId: teacherId,
        studentId: studentId,
        slotId: slotId,
        requestedCallType: _mapCallTypeId(requestedCallTypeId),
        pricingType: paymentReference == null ? 'free' : 'fixedPerSession',
        status: payload['status'] as String? ?? 'pending',
        createdAt: DateTime.now().toUtc().toIso8601String(),
        paymentReference: paymentReference,
        sessionId: sessionId,
        studentNote: studentNote,
      );
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'already-exists') {
        throw ConflictException(isSlotUnavailable: true, slotId: slotId);
      }
      throw HttpException(500);
    } on FirebaseException catch (e) {
      throw mapFirebaseException(e);
    }
  }

  @override
  Future<QuranBookingDto> cancelBooking(
    String bookingId, {
    required String reason,
  }) async {
    try {
      final callable = _functions.httpsCallable('cancelSessionBooking');
      await callable.call<Map<String, dynamic>>({
        'bookingId': bookingId,
        'reason': reason,
        'actorRole': 'student',
      });
      final bookingSnap = await _bookings.doc(bookingId).get();
      if (!bookingSnap.exists) {
        throw NotFoundException('QuranBooking($bookingId)');
      }
      return _mapBooking(bookingSnap.id, bookingSnap.data() ?? const {});
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'not-found') {
        throw NotFoundException('QuranBooking($bookingId)');
      }
      throw HttpException(500);
    } on FirebaseException catch (e) {
      throw mapFirebaseException(e);
    }
  }

  @override
  Future<QuranBookingDto> rescheduleBooking(
    String bookingId, {
    required String newSlotId,
  }) async {
    try {
      final doc = await _bookings.doc(bookingId).get();
      if (!doc.exists) {
        throw NotFoundException('QuranBooking($bookingId)');
      }
      final data = doc.data() ?? const {};
      final callable = _functions.httpsCallable('requestSessionReschedule');
      await callable.call<Map<String, dynamic>>({
        'bookingId': bookingId,
        'newSlotId': newSlotId,
        'newStartsAt': readRequiredDateTime(
          data['startsAt'],
        ).toUtc().toIso8601String(),
        'reason': 'requested_by_student',
      });
      final refreshed = await _bookings.doc(bookingId).get();
      return _mapBooking(refreshed.id, refreshed.data() ?? const {});
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'not-found') {
        throw NotFoundException('QuranBooking($bookingId)');
      }
      throw HttpException(500);
    } on FirebaseException catch (e) {
      throw mapFirebaseException(e);
    }
  }

  @override
  Future<List<QuranBookingDto>> getStudentBookings(String studentId) async {
    try {
      final snapshot = await _bookings
          .where('studentId', isEqualTo: studentId)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => _mapBooking(doc.id, doc.data()))
          .toList();
    } on FirebaseException catch (e) {
      throw mapFirebaseException(e);
    }
  }

  @override
  Future<SessionReviewDto> submitReview({
    required String sessionId,
    required int rating,
    String? comment,
  }) async {
    return SessionReviewDto(
      id: 'review_$sessionId',
      sessionId: sessionId,
      teacherId: '',
      studentId: _requireStudentId(),
      rating: rating,
      comment: comment,
      createdAt: DateTime.now().toUtc().toIso8601String(),
    );
  }

  QuranBookingDto _mapBooking(String id, Map<String, dynamic> data) =>
      QuranBookingDto(
        id: id,
        teacherId: data['teacherId'] as String? ?? '',
        studentId: data['studentId'] as String? ?? '',
        slotId: data['slotId'] as String? ?? '',
        requestedCallType: _mapCallTypeId(data['callType'] as String?),
        pricingType: data['pricingType'] as String? ?? 'free',
        status: data['status'] as String? ?? 'pending',
        createdAt: readRequiredDateTime(
          data['createdAt'],
        ).toUtc().toIso8601String(),
        paymentReference: data['paymentReference'] as String?,
        sessionId: data['sessionId'] as String?,
        studentNote: data['studentNote'] as String?,
      );

  String _mapCallTypeId(String? raw) => switch (raw) {
    'voiceCall' => 'voice_call',
    'videoCall' => 'video_call',
    'externalMeeting' => 'external_meeting',
    _ => raw ?? 'external_meeting',
  };
}

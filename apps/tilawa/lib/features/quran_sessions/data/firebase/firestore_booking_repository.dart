import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quran_sessions/quran_sessions.dart';

import 'firestore_exception_mapper.dart';
import 'firestore_paths.dart';

class FirestoreBookingDataSource implements BookingRemoteDataSource {
  FirestoreBookingDataSource(this._firestore, this._authSession);

  final FirebaseFirestore _firestore;
  final AuthSessionProvider _authSession;

  CollectionReference<Map<String, dynamic>> get _bookings =>
      _firestore.collection(FirestoreQuranSessionsPaths.bookings);

  CollectionReference<Map<String, dynamic>> get _sessions =>
      _firestore.collection(FirestoreQuranSessionsPaths.sessions);

  DocumentReference<Map<String, dynamic>> _slotRef(
    String teacherId,
    String slotId,
  ) => _firestore
      .collection(FirestoreQuranSessionsPaths.teacherProfiles)
      .doc(teacherId)
      .collection(FirestoreQuranSessionsPaths.availability)
      .doc(slotId);

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
    try {
      final bookingRef = _bookings.doc();
      final sessionRef = _sessions.doc();
      final slotRef = _slotRef(teacherId, slotId);

      final result = await _firestore.runTransaction((transaction) async {
        final slotSnap = await transaction.get(slotRef);
        if (!slotSnap.exists) {
          throw ConflictException(isSlotUnavailable: true, slotId: slotId);
        }
        final slotData = slotSnap.data() ?? const {};
        if (slotData['isBooked'] as bool? ?? false) {
          throw ConflictException(isSlotUnavailable: true, slotId: slotId);
        }

        final startsAt = readRequiredDateTime(slotData['startsAt']);
        final endsAt = readRequiredDateTime(slotData['endsAt']);
        final now = DateTime.now();

        transaction.update(slotRef, {
          'isBooked': true,
          'status': 'booked',
          'updatedAt': writeDateTime(now),
        });

        transaction.set(bookingRef, {
          'studentId': studentId,
          'teacherId': teacherId,
          'slotId': slotId,
          'startsAt': writeDateTime(startsAt),
          'endsAt': writeDateTime(endsAt),
          'callType': requestedCallTypeId,
          'status': 'confirmed',
          'pricingType': 'free',
          'createdAt': writeDateTime(now),
          'updatedAt': writeDateTime(now),
          'paymentReference': ?paymentReference,
          'studentNote': ?studentNote,
        });

        transaction.set(sessionRef, {
          'bookingId': bookingRef.id,
          'studentId': studentId,
          'teacherId': teacherId,
          'startsAt': writeDateTime(startsAt),
          'endsAt': writeDateTime(endsAt),
          'callType': requestedCallTypeId,
          'status': 'scheduled',
          'meetingLink': 'https://meet.example.com/room/${bookingRef.id}',
          'createdAt': writeDateTime(now),
          'updatedAt': writeDateTime(now),
        });

        return (
          bookingId: bookingRef.id,
          sessionId: sessionRef.id,
          startsAt: startsAt,
        );
      });

      return QuranBookingDto(
        id: result.bookingId,
        teacherId: teacherId,
        studentId: studentId,
        slotId: slotId,
        requestedCallType: _mapCallTypeId(requestedCallTypeId),
        pricingType: 'free',
        status: 'confirmed',
        createdAt: DateTime.now().toUtc().toIso8601String(),
        paymentReference: paymentReference,
        sessionId: result.sessionId,
        studentNote: studentNote,
      );
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
      final bookingRef = _bookings.doc(bookingId);
      final bookingSnap = await bookingRef.get();
      if (!bookingSnap.exists) {
        throw NotFoundException('QuranBooking($bookingId)');
      }
      final data = bookingSnap.data() ?? const {};
      final now = DateTime.now();
      await bookingRef.set({
        'status': 'cancelled',
        'cancelledAt': writeDateTime(now),
        'cancellationReason': reason,
        'updatedAt': writeDateTime(now),
      }, SetOptions(merge: true));

      final teacherId = data['teacherId'] as String? ?? '';
      final slotId = data['slotId'] as String? ?? '';
      if (teacherId.isNotEmpty && slotId.isNotEmpty) {
        await _slotRef(teacherId, slotId).set({
          'isBooked': false,
          'status': 'open',
          'updatedAt': writeDateTime(now),
        }, SetOptions(merge: true));
      }

      await _sessions.where('bookingId', isEqualTo: bookingId).get().then((
        snapshot,
      ) async {
        for (final doc in snapshot.docs) {
          await doc.reference.set({
            'status': 'cancelled_by_student',
            'updatedAt': writeDateTime(now),
          }, SetOptions(merge: true));
        }
      });

      return _mapBooking(bookingSnap.id, {
        ...data,
        'status': 'cancelled',
      });
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
      return _mapBooking(doc.id, doc.data() ?? const {});
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

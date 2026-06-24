import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quran_sessions/quran_sessions.dart';

import 'firestore_exception_mapper.dart';
import 'firestore_paths.dart';

class FirestoreTeacherDataSource implements TeacherRemoteDataSource {
  FirestoreTeacherDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _profiles =>
      _firestore.collection(FirestoreQuranSessionsPaths.teacherProfiles);

  QuranTeacherDto _mapProfile(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    SessionPriceDto? marketPrice,
  }) {
    final data = doc.data() ?? const {};
    final rawDisplayName = data['displayName'] as String? ?? '';
    return QuranTeacherDto(
      id: doc.id,
      displayName: TeacherProfileDisplayNameResolver.resolveStored(
        displayName: rawDisplayName,
      ),
      bio: data['publicBio'] as String? ?? '',
      avatarUrl: data['avatarUrl'] as String? ?? '',
      gender: data['gender'] as String? ?? 'male',
      verificationStatus: data['verificationStatus'] as String? ?? 'pending',
      supportedCallTypes: _supportedCallTypes(
        data['externalMeetingUrl'] as String?,
      ),
      pricingType: marketPrice == null ? 'free' : 'fixed_per_session',
      marketPrice: marketPrice,
      specializations: List<String>.from(
        data['specializations'] as List? ?? const [],
      ),
      languages: List<String>.from(
        data['teachingLanguages'] as List? ?? const [],
      ),
      averageRating: (data['averageRating'] as num?)?.toDouble() ?? 0,
      totalReviews: data['reviewCount'] as int? ?? 0,
      totalSessionsCompleted: data['totalSessionsCompleted'] as int? ?? 0,
    );
  }

  static List<String> _supportedCallTypes(String? externalMeetingUrl) {
    final types = <String>['voice_call', 'video_call'];
    final trimmed = externalMeetingUrl?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      types.insert(0, 'external_meeting');
    }
    return types;
  }

  static const _pageSize = 20;

  @override
  Future<({List<QuranTeacherDto> teachers, String? nextCursor})> getTeachers({
    String? specialization,
    String? language,
    String? cursor,
  }) async {
    try {
      final hasSpecialization =
          specialization != null && specialization.isNotEmpty;
      final hasLanguage = language != null && language.isNotEmpty;

      Query<Map<String, dynamic>> query = _profiles
          .where('profileCompleteness', isEqualTo: 'complete')
          .where('isPubliclyVisible', isEqualTo: true);

      // Firestore allows one array-contains per query — specialization wins.
      if (hasSpecialization) {
        query = query.where('specializations', arrayContains: specialization);
      } else if (hasLanguage) {
        query = query.where('teachingLanguages', arrayContains: language);
      }

      query = query.orderBy('displayName').limit(_pageSize);
      if (cursor != null && cursor.isNotEmpty) {
        final cursorDoc = await _profiles.doc(cursor).get();
        if (cursorDoc.exists) {
          query = query.startAfterDocument(cursorDoc);
        }
      }
      final snapshot = await query.get();
      var teachers = snapshot.docs.map((d) => _mapProfile(d)).toList();
      teachers = teachers
          .where((t) => ValidateTeacherPublicName.isValid(t.displayName))
          .toList();

      // Secondary filter when both specialization and language are active.
      if (hasSpecialization && hasLanguage) {
        teachers = teachers
            .where((t) => t.languages.contains(language))
            .toList();
      }

      final nextCursor = snapshot.docs.length == _pageSize
          ? snapshot.docs.last.id
          : null;
      return (teachers: teachers, nextCursor: nextCursor);
    } on FirebaseException catch (e) {
      throw mapFirebaseException(e);
    }
  }

  @override
  Future<QuranTeacherDto> getTeacherById(String teacherId) async {
    try {
      final doc = await _profiles.doc(teacherId).get();
      if (!doc.exists) {
        throw NotFoundException('QuranTeacher($teacherId)');
      }
      return _mapProfile(doc);
    } on FirebaseException catch (e) {
      throw mapFirebaseException(e);
    }
  }

  @override
  Future<List<TeacherAvailabilityDto>> getAvailableSlots(
    String teacherId, {
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final snapshot = await _profiles
          .doc(teacherId)
          .collection(FirestoreQuranSessionsPaths.availability)
          .where('startsAt', isGreaterThanOrEqualTo: writeDateTime(from))
          .where('startsAt', isLessThan: writeDateTime(to))
          .get();
      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            return TeacherAvailabilityDto(
              slotId: doc.id,
              teacherId: teacherId,
              startsAt: readRequiredDateTime(
                data['startsAt'],
              ).toUtc().toIso8601String(),
              endsAt: readRequiredDateTime(
                data['endsAt'],
              ).toUtc().toIso8601String(),
              isBooked: data['isBooked'] as bool? ?? false,
            );
          })
          .where((s) => !s.isBooked)
          .toList();
    } on FirebaseException catch (e) {
      throw mapFirebaseException(e);
    }
  }

  @override
  Future<List<SessionReviewDto>> getTeacherReviews(
    String teacherId, {
    String? cursor,
  }) async {
    return const [];
  }

  @override
  Future<SessionPriceDto?> resolveTeacherPrice(
    String teacherId, {
    required String countryCode,
    required String cityId,
  }) async {
    try {
      final marketId = '${countryCode}_$cityId';
      final doc = await _profiles
          .doc(teacherId)
          .collection('pricing')
          .doc(marketId)
          .get();
      if (!doc.exists) return null;
      final data = doc.data() ?? const {};
      return SessionPriceDto(
        amount: (data['amount'] as num?)?.toDouble() ?? 0,
        currencyCode: data['currencyCode'] as String? ?? 'USD',
        countryCode: countryCode,
        cityId: cityId,
      );
    } on FirebaseException catch (e) {
      throw mapFirebaseException(e);
    }
  }
}

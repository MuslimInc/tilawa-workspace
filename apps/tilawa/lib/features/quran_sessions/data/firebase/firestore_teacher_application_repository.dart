import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quran_sessions/quran_sessions.dart';

import 'firestore_exception_mapper.dart';
import 'firestore_paths.dart';

class FirestoreTeacherApplicationDto {
  const FirestoreTeacherApplicationDto({
    required this.id,
    required this.userId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.phoneNumber,
    this.phoneCountryCode,
    this.preferredContactMethod,
    this.teachingLanguages = const [],
    this.specializations = const [],
    this.bio,
    this.submittedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.rejectionReason,
  });

  final String id;
  final String userId;
  final String status;
  final String? phoneNumber;
  final String? phoneCountryCode;
  final String? preferredContactMethod;
  final List<String> teachingLanguages;
  final List<String> specializations;
  final String? bio;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory FirestoreTeacherApplicationDto.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const {};
    return FirestoreTeacherApplicationDto(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      status: data['status'] as String? ?? 'none',
      phoneNumber: data['phoneNumber'] as String?,
      phoneCountryCode: data['phoneCountryCode'] as String?,
      preferredContactMethod: data['preferredContactMethod'] as String?,
      teachingLanguages: List<String>.from(
        data['teachingLanguages'] as List? ?? const [],
      ),
      specializations: List<String>.from(
        data['specializations'] as List? ?? const [],
      ),
      bio: data['bio'] as String?,
      submittedAt: readDateTime(data['submittedAt']),
      reviewedAt: readDateTime(data['reviewedAt']),
      reviewedBy: data['reviewedBy'] as String?,
      rejectionReason: data['rejectionReason'] as String?,
      createdAt: readRequiredDateTime(data['createdAt']),
      updatedAt: readRequiredDateTime(data['updatedAt']),
    );
  }

  TeacherApplicationDto toTransportDto() => TeacherApplicationDto(
    id: id,
    userId: userId,
    status: status,
    phoneNumber: phoneNumber,
    phoneCountryCode: phoneCountryCode,
    preferredContactMethod: preferredContactMethod,
    teachingLanguages: teachingLanguages,
    specializations: specializations,
    bio: bio,
    submittedAt: submittedAt,
    reviewedAt: reviewedAt,
    reviewedBy: reviewedBy,
    rejectionReason: rejectionReason,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'status': status,
    if (phoneNumber != null) 'phoneNumber': phoneNumber,
    if (phoneCountryCode != null) 'phoneCountryCode': phoneCountryCode,
    if (preferredContactMethod != null)
      'preferredContactMethod': preferredContactMethod,
    'teachingLanguages': teachingLanguages,
    'specializations': specializations,
    if (bio != null) 'bio': bio,
    if (submittedAt != null) 'submittedAt': writeDateTime(submittedAt!),
    if (reviewedAt != null) 'reviewedAt': writeDateTime(reviewedAt!),
    if (reviewedBy != null) 'reviewedBy': reviewedBy,
    if (rejectionReason != null) 'rejectionReason': rejectionReason,
    'createdAt': writeDateTime(createdAt),
    'updatedAt': writeDateTime(updatedAt),
  };

  static FirestoreTeacherApplicationDto fromTransportDto(
    TeacherApplicationDto dto,
  ) => FirestoreTeacherApplicationDto(
    id: dto.id,
    userId: dto.userId,
    status: dto.status,
    phoneNumber: dto.phoneNumber,
    phoneCountryCode: dto.phoneCountryCode,
    preferredContactMethod: dto.preferredContactMethod,
    teachingLanguages: dto.teachingLanguages,
    specializations: dto.specializations,
    bio: dto.bio,
    submittedAt: dto.submittedAt,
    reviewedAt: dto.reviewedAt,
    reviewedBy: dto.reviewedBy,
    rejectionReason: dto.rejectionReason,
    createdAt: dto.createdAt,
    updatedAt: dto.updatedAt,
  );
}

class FirestoreTeacherApplicationDataSource
    implements TeacherApplicationRemoteDataSource {
  FirestoreTeacherApplicationDataSource(this._firestore);

  final FirebaseFirestore _firestore;
  static const _cooldownDays = 30;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirestoreQuranSessionsPaths.teacherApplications);

  Future<DocumentSnapshot<Map<String, dynamic>>?> _findByUserId(
    String userId,
  ) async {
    final query = await _collection
        .where('userId', isEqualTo: userId)
        .orderBy('updatedAt', descending: true)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return query.docs.first;
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _requireById(
    String applicationId,
  ) async {
    final doc = await _collection.doc(applicationId).get();
    if (!doc.exists) {
      throw NotFoundException('TeacherApplication($applicationId)');
    }
    return doc;
  }

  @override
  Future<TeacherApplicationDto> getByUserId(String userId) async {
    try {
      final doc = await _findByUserId(userId);
      if (doc == null) {
        throw NotFoundException('TeacherApplication(userId=$userId)');
      }
      return FirestoreTeacherApplicationDto.fromDoc(doc).toTransportDto();
    } on FirebaseException catch (e) {
      throw mapFirebaseException(e);
    }
  }

  @override
  Future<TeacherApplicationDto> createDraft(String userId) async {
    try {
      final existing = await _findByUserId(userId);
      if (existing != null) {
        final current = FirestoreTeacherApplicationDto.fromDoc(existing);
        if (current.status == 'pending' || current.status == 'approved') {
          throw const ConflictException();
        }
        if (current.status == 'draft') {
          return current.toTransportDto();
        }
        if (current.status == 'rejected') {
          final rejectedAt = current.reviewedAt;
          if (rejectedAt != null) {
            final cooldownEnd = rejectedAt.add(
              const Duration(days: _cooldownDays),
            );
            if (DateTime.now().isBefore(cooldownEnd)) {
              throw const ConflictException();
            }
          }
        }
      }

      final now = DateTime.now();
      final ref = _collection.doc();
      final dto = FirestoreTeacherApplicationDto(
        id: ref.id,
        userId: userId,
        status: 'draft',
        createdAt: now,
        updatedAt: now,
      );
      await ref.set(dto.toMap());
      return dto.toTransportDto();
    } on FirebaseException catch (e) {
      throw mapFirebaseException(e);
    }
  }

  @override
  Future<TeacherApplicationDto> saveDraft(TeacherApplicationDto draft) async {
    try {
      final now = DateTime.now();
      final firestoreDto = FirestoreTeacherApplicationDto.fromTransportDto(
        draft,
      );
      await _collection.doc(draft.id).set({
        ...firestoreDto.toMap(),
        'updatedAt': writeDateTime(now),
      }, SetOptions(merge: true));
      final updated = await _collection.doc(draft.id).get();
      return FirestoreTeacherApplicationDto.fromDoc(updated).toTransportDto();
    } on FirebaseException catch (e) {
      throw mapFirebaseException(e);
    }
  }

  @override
  Future<TeacherApplicationDto> submit(
    TeacherApplicationDto application,
  ) async {
    try {
      final now = DateTime.now();
      final submitted = FirestoreTeacherApplicationDto.fromTransportDto(
        TeacherApplicationDto(
          id: application.id,
          userId: application.userId,
          status: 'pending',
          phoneNumber: application.phoneNumber,
          phoneCountryCode: application.phoneCountryCode,
          preferredContactMethod: application.preferredContactMethod,
          teachingLanguages: application.teachingLanguages,
          specializations: application.specializations,
          bio: application.bio,
          submittedAt: now,
          reviewedAt: application.reviewedAt,
          reviewedBy: application.reviewedBy,
          rejectionReason: application.rejectionReason,
          createdAt: application.createdAt,
          updatedAt: now,
        ),
      );
      await _collection
          .doc(application.id)
          .set(
            submitted.toMap(),
            SetOptions(merge: true),
          );
      final doc = await _collection.doc(application.id).get();
      return FirestoreTeacherApplicationDto.fromDoc(doc).toTransportDto();
    } on FirebaseException catch (e) {
      throw mapFirebaseException(e);
    }
  }

  @override
  Future<TeacherApplicationDto> approve({
    required String applicationId,
    required String reviewedBy,
  }) async {
    return _review(
      applicationId: applicationId,
      reviewedBy: reviewedBy,
      status: 'approved',
    );
  }

  @override
  Future<TeacherApplicationDto> reject({
    required String applicationId,
    required String reviewedBy,
    required String reason,
  }) async {
    return _review(
      applicationId: applicationId,
      reviewedBy: reviewedBy,
      status: 'rejected',
      reason: reason,
    );
  }

  @override
  Future<TeacherApplicationDto> suspend({
    required String applicationId,
    required String reviewedBy,
    required String reason,
  }) async {
    return _review(
      applicationId: applicationId,
      reviewedBy: reviewedBy,
      status: 'suspended',
      reason: reason,
    );
  }

  @override
  Future<TeacherApplicationDto> revoke({
    required String applicationId,
    required String reviewedBy,
    required String reason,
  }) async {
    return _review(
      applicationId: applicationId,
      reviewedBy: reviewedBy,
      status: 'revoked',
      reason: reason,
    );
  }

  Future<TeacherApplicationDto> _review({
    required String applicationId,
    required String reviewedBy,
    required String status,
    String? reason,
  }) async {
    try {
      await _requireById(applicationId);
      final now = DateTime.now();
      await _collection.doc(applicationId).set({
        'status': status,
        'reviewedAt': writeDateTime(now),
        'reviewedBy': reviewedBy,
        'rejectionReason': ?reason,
        'updatedAt': writeDateTime(now),
      }, SetOptions(merge: true));
      final doc = await _collection.doc(applicationId).get();
      return FirestoreTeacherApplicationDto.fromDoc(doc).toTransportDto();
    } on FirebaseException catch (e) {
      throw mapFirebaseException(e);
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quran_sessions/quran_sessions.dart';

import 'firestore_exception_mapper.dart';
import 'firestore_paths.dart';

class FirestoreTeacherProfileDto {
  const FirestoreTeacherProfileDto({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.verificationStatus,
    required this.teachingLanguages,
    required this.specializations,
    required this.averageRating,
    required this.reviewCount,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.avatarUrl,
    this.publicBio,
    this.allowedStudentGender,
    this.canTeachChildren = true,
  });

  final String id;
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final String? publicBio;
  final String verificationStatus;
  final List<String> teachingLanguages;
  final List<String> specializations;
  final double averageRating;
  final int reviewCount;
  final bool isActive;
  final String? allowedStudentGender;
  final bool canTeachChildren;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory FirestoreTeacherProfileDto.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const {};
    return FirestoreTeacherProfileDto(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      avatarUrl: data['avatarUrl'] as String?,
      publicBio: data['publicBio'] as String?,
      verificationStatus: data['verificationStatus'] as String? ?? 'pending',
      teachingLanguages: List<String>.from(
        data['teachingLanguages'] as List? ?? const [],
      ),
      specializations: List<String>.from(
        data['specializations'] as List? ?? const [],
      ),
      averageRating: (data['averageRating'] as num?)?.toDouble() ?? 0,
      reviewCount: data['reviewCount'] as int? ?? 0,
      isActive: data['isActive'] as bool? ?? false,
      allowedStudentGender: data['allowedStudentGender'] as String?,
      canTeachChildren: data['canTeachChildren'] as bool? ?? true,
      createdAt: readRequiredDateTime(data['createdAt']),
      updatedAt: readRequiredDateTime(data['updatedAt']),
    );
  }

  TeacherProfileDto toTransportDto() => TeacherProfileDto(
    id: id,
    userId: userId,
    displayName: displayName,
    avatarUrl: avatarUrl,
    publicBio: publicBio,
    verificationStatus: verificationStatus,
    teachingLanguages: teachingLanguages,
    specializations: specializations,
    averageRating: averageRating,
    reviewCount: reviewCount,
    isActive: isActive,
    allowedStudentGender: allowedStudentGender,
    canTeachChildren: canTeachChildren,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'displayName': displayName,
    if (avatarUrl != null) 'avatarUrl': avatarUrl,
    if (publicBio != null) 'publicBio': publicBio,
    'verificationStatus': verificationStatus,
    'teachingLanguages': teachingLanguages,
    'specializations': specializations,
    'averageRating': averageRating,
    'reviewCount': reviewCount,
    'isActive': isActive,
    if (allowedStudentGender != null)
      'allowedStudentGender': allowedStudentGender,
    'canTeachChildren': canTeachChildren,
    'createdAt': writeDateTime(createdAt),
    'updatedAt': writeDateTime(updatedAt),
  };

  static FirestoreTeacherProfileDto fromTransportDto(TeacherProfileDto dto) =>
      FirestoreTeacherProfileDto(
        id: dto.id,
        userId: dto.userId,
        displayName: dto.displayName,
        avatarUrl: dto.avatarUrl,
        publicBio: dto.publicBio,
        verificationStatus: dto.verificationStatus,
        teachingLanguages: dto.teachingLanguages,
        specializations: dto.specializations,
        averageRating: dto.averageRating,
        reviewCount: dto.reviewCount,
        isActive: dto.isActive,
        allowedStudentGender: dto.allowedStudentGender,
        canTeachChildren: dto.canTeachChildren,
        createdAt: dto.createdAt,
        updatedAt: dto.updatedAt,
      );
}

class FirestoreTeacherProfileDataSource
    implements TeacherProfileRemoteDataSource {
  FirestoreTeacherProfileDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirestoreQuranSessionsPaths.teacherProfiles);

  @override
  Future<TeacherProfileDto> getByUserId(String userId) async {
    try {
      final query = await _collection
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();
      if (query.docs.isEmpty) {
        throw NotFoundException('TeacherProfile(userId=$userId)');
      }
      return FirestoreTeacherProfileDto.fromDoc(
        query.docs.first,
      ).toTransportDto();
    } on FirebaseException catch (e) {
      throw mapFirebaseException(e);
    }
  }

  @override
  Future<TeacherProfileDto> getById(String id) async {
    try {
      final doc = await _collection.doc(id).get();
      if (!doc.exists) {
        throw NotFoundException('TeacherProfile($id)');
      }
      return FirestoreTeacherProfileDto.fromDoc(doc).toTransportDto();
    } on FirebaseException catch (e) {
      throw mapFirebaseException(e);
    }
  }

  @override
  Future<TeacherProfileDto> create(TeacherProfileDto profile) async {
    try {
      final ref = profile.id.isEmpty
          ? _collection.doc()
          : _collection.doc(profile.id);
      final now = DateTime.now();
      final dto = FirestoreTeacherProfileDto.fromTransportDto(
        TeacherProfileDto(
          id: ref.id,
          userId: profile.userId,
          displayName: profile.displayName,
          avatarUrl: profile.avatarUrl,
          publicBio: profile.publicBio,
          verificationStatus: profile.verificationStatus,
          teachingLanguages: profile.teachingLanguages,
          specializations: profile.specializations,
          averageRating: profile.averageRating,
          reviewCount: profile.reviewCount,
          isActive: profile.isActive,
          allowedStudentGender: profile.allowedStudentGender,
          canTeachChildren: profile.canTeachChildren,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await ref.set(dto.toMap());
      final created = await ref.get();
      return FirestoreTeacherProfileDto.fromDoc(created).toTransportDto();
    } on FirebaseException catch (e) {
      throw mapFirebaseException(e);
    }
  }

  @override
  Future<TeacherProfileDto> update(TeacherProfileDto profile) async {
    try {
      final now = DateTime.now();
      final dto = FirestoreTeacherProfileDto.fromTransportDto(profile);
      await _collection.doc(profile.id).set({
        ...dto.toMap(),
        'updatedAt': writeDateTime(now),
      }, SetOptions(merge: true));
      final updated = await _collection.doc(profile.id).get();
      return FirestoreTeacherProfileDto.fromDoc(updated).toTransportDto();
    } on FirebaseException catch (e) {
      throw mapFirebaseException(e);
    }
  }

  @override
  Future<TeacherProfileDto> deactivate(String id) async {
    return _setActive(id, isActive: false);
  }

  @override
  Future<TeacherProfileDto> reactivate(String id) async {
    return _setActive(id, isActive: true);
  }

  Future<TeacherProfileDto> _setActive(
    String id, {
    required bool isActive,
  }) async {
    try {
      final now = DateTime.now();
      await _collection.doc(id).set({
        'isActive': isActive,
        'updatedAt': writeDateTime(now),
      }, SetOptions(merge: true));
      final doc = await _collection.doc(id).get();
      if (!doc.exists) {
        throw NotFoundException('TeacherProfile($id)');
      }
      return FirestoreTeacherProfileDto.fromDoc(doc).toTransportDto();
    } on FirebaseException catch (e) {
      throw mapFirebaseException(e);
    }
  }
}

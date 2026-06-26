import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa_core/services/performance_monitoring_service.dart';

import 'firestore_exception_mapper.dart';
import 'firestore_paths.dart';
import 'firestore_performance_wrapper.dart';

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
    required this.profileCompleteness,
    required this.isPubliclyVisible,
    required this.createdAt,
    required this.updatedAt,
    this.avatarUrl,
    this.publicBio,
    this.allowedStudentGender,
    this.canTeachChildren = true,
    this.externalMeetingUrl,
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
  final String profileCompleteness;
  final bool isPubliclyVisible;
  final String? allowedStudentGender;
  final bool canTeachChildren;
  final String? externalMeetingUrl;
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
      profileCompleteness:
          data['profileCompleteness'] as String? ?? 'incomplete',
      isPubliclyVisible: data['isPubliclyVisible'] as bool? ?? false,
      allowedStudentGender: data['allowedStudentGender'] as String?,
      canTeachChildren: data['canTeachChildren'] as bool? ?? true,
      externalMeetingUrl: data['externalMeetingUrl'] as String?,
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
    profileCompleteness: profileCompleteness,
    isPubliclyVisible: isPubliclyVisible,
    allowedStudentGender: allowedStudentGender,
    canTeachChildren: canTeachChildren,
    externalMeetingUrl: externalMeetingUrl,
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
    'profileCompleteness': profileCompleteness,
    'isPubliclyVisible': isPubliclyVisible,
    if (allowedStudentGender != null)
      'allowedStudentGender': allowedStudentGender,
    'canTeachChildren': canTeachChildren,
    if (externalMeetingUrl != null && externalMeetingUrl!.isNotEmpty)
      'externalMeetingUrl': externalMeetingUrl,
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
        profileCompleteness: dto.profileCompleteness,
        isPubliclyVisible: dto.isPubliclyVisible,
        allowedStudentGender: dto.allowedStudentGender,
        canTeachChildren: dto.canTeachChildren,
        externalMeetingUrl: dto.externalMeetingUrl,
        createdAt: dto.createdAt,
        updatedAt: dto.updatedAt,
      );
}

class FirestoreTeacherProfileDataSource
    implements TeacherProfileRemoteDataSource {
  FirestoreTeacherProfileDataSource(
    this._firestore, [
    this._perf,
    this._prefs,
  ]);

  final FirebaseFirestore _firestore;
  final PerformanceMonitoringService? _perf;
  final SharedPreferencesAsync? _prefs;
  final Map<String, TeacherProfileDto> _cacheById = {};
  final Map<String, TeacherProfileDto> _cacheByUserId = {};

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirestoreQuranSessionsPaths.teacherProfiles);

  TeacherProfileDto? _readCachedById(String id) => _cacheById[id];

  TeacherProfileDto? _readCachedByUserId(String userId) =>
      _cacheByUserId[userId];

  void _putInCache(TeacherProfileDto profile) {
    _cacheById[profile.id] = profile;
    if (profile.userId.isNotEmpty) {
      _cacheByUserId[profile.userId] = profile;
    }
  }

  void _invalidateForId(String id) {
    final cached = _cacheById.remove(id);
    if (cached != null) {
      _cacheByUserId.remove(cached.userId);
    }
  }

  @override
  Future<TeacherProfileDto> getByUserId(String userId) async {
    final memoryCached = _readCachedByUserId(userId);
    if (memoryCached != null) {
      return memoryCached;
    }

    final prefs = _prefs;
    if (prefs != null) {
      final cachedProfileId = await prefs.getString('tp_id_mapping_$userId');
      if (cachedProfileId != null && cachedProfileId.isNotEmpty) {
        try {
          final profile = await getById(cachedProfileId);
          return profile;
        } catch (_) {
          await prefs.remove('tp_id_mapping_$userId');
        }
      }
    }

    final profile = await _perf.trace(
      'firestore_getTeacherProfileByUserId',
      () async {
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
      },
    );

    if (prefs != null) {
      await prefs.setString('tp_id_mapping_$userId', profile.id);
    }

    _putInCache(profile);
    return profile;
  }

  @override
  Future<TeacherProfileDto> getById(String id) async {
    final memoryCached = _readCachedById(id);
    if (memoryCached != null) {
      return memoryCached;
    }

    final profile = await _perf.trace(
      'firestore_getTeacherProfileById',
      () async {
        try {
          final doc = await _collection.doc(id).get();
          if (!doc.exists) {
            throw NotFoundException('TeacherProfile($id)');
          }
          return FirestoreTeacherProfileDto.fromDoc(doc).toTransportDto();
        } on FirebaseException catch (e) {
          throw mapFirebaseException(e);
        }
      },
    );
    _putInCache(profile);
    return profile;
  }

  @override
  Future<TeacherProfileDto> create(TeacherProfileDto profile) async {
    return _perf.trace('firestore_createTeacherProfile', () async {
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
            profileCompleteness: profile.profileCompleteness,
            isPubliclyVisible: profile.isPubliclyVisible,
            allowedStudentGender: profile.allowedStudentGender,
            canTeachChildren: profile.canTeachChildren,
            externalMeetingUrl: profile.externalMeetingUrl,
            createdAt: now,
            updatedAt: now,
          ),
        );
        await ref.set(dto.toMap());
        final created = await ref.get();
        final result = FirestoreTeacherProfileDto.fromDoc(
          created,
        ).toTransportDto();
        _putInCache(result);
        return result;
      } on FirebaseException catch (e) {
        throw mapFirebaseException(e);
      }
    });
  }

  @override
  Future<TeacherProfileDto> update(TeacherProfileDto profile) async {
    _invalidateForId(profile.id);
    return _perf.trace('firestore_updateTeacherProfile', () async {
      try {
        final now = DateTime.now();
        final dto = FirestoreTeacherProfileDto.fromTransportDto(profile);
        await _collection.doc(profile.id).set({
          ...dto.toMap(),
          'updatedAt': writeDateTime(now),
        }, SetOptions(merge: true));
        final updated = await _collection.doc(profile.id).get();
        final result = FirestoreTeacherProfileDto.fromDoc(
          updated,
        ).toTransportDto();
        _putInCache(result);
        return result;
      } on FirebaseException catch (e) {
        throw mapFirebaseException(e);
      }
    });
  }

  /// Writes only fields a verified profile owner may edit client-side.
  ///
  /// Trust fields (`profileCompleteness`, `isPubliclyVisible`, etc.) are
  /// recomputed by the `syncTeacherProfileVisibility` Cloud Function trigger.
  @override
  Future<TeacherProfileDto> updatePublicProfile(
    TeacherProfileDto profile,
  ) async {
    _invalidateForId(profile.id);
    return _perf.trace('firestore_updateTeacherPublicProfile', () async {
      try {
        final now = DateTime.now();
        final payload = <String, dynamic>{
          'displayName': profile.displayName,
          'publicBio': profile.publicBio,
          'teachingLanguages': profile.teachingLanguages,
          'specializations': profile.specializations,
          'updatedAt': writeDateTime(now),
        };
        final trimmedMeetingUrl = profile.externalMeetingUrl?.trim();
        if (trimmedMeetingUrl != null && trimmedMeetingUrl.isNotEmpty) {
          payload['externalMeetingUrl'] = trimmedMeetingUrl;
        } else {
          payload['externalMeetingUrl'] = FieldValue.delete();
        }
        if (profile.avatarUrl != null) {
          payload['avatarUrl'] = profile.avatarUrl;
        }
        await _collection.doc(profile.id).set(payload, SetOptions(merge: true));
        final updated = await _collection.doc(profile.id).get();
        final result = FirestoreTeacherProfileDto.fromDoc(
          updated,
        ).toTransportDto();
        return result;
      } on FirebaseException catch (e) {
        throw mapFirebaseException(e);
      }
    });
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
    _invalidateForId(id);
    return _perf.trace('firestore_setTeacherProfileActive', () async {
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
        final result = FirestoreTeacherProfileDto.fromDoc(doc).toTransportDto();
        _putInCache(result);
        return result;
      } on FirebaseException catch (e) {
        throw mapFirebaseException(e);
      }
    });
  }
}

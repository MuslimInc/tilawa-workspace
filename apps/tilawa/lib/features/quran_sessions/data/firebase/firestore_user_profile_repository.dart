import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quran_sessions/quran_sessions.dart';

import 'firestore_exception_mapper.dart';
import 'firestore_paths.dart';

/// Firestore document shape for `users/{uid}.quranSessionsProfile`.
class FirestoreUserProfileDto {
  const FirestoreUserProfileDto({
    required this.userId,
    required this.role,
    required this.accountStatus,
    this.displayName,
    this.gender,
    this.dateOfBirth,
    this.countryCode,
    this.countryName,
    this.cityId,
    this.cityName,
    this.currencyCode,
    this.timezone,
    this.guardianId,
    this.restrictionReason,
    this.profileCompleted = false,
  });

  final String userId;
  final String role;
  final String accountStatus;
  final String? displayName;
  final String? gender;
  final DateTime? dateOfBirth;
  final String? countryCode;
  final String? countryName;
  final String? cityId;
  final String? cityName;
  final String? currencyCode;
  final String? timezone;
  final String? guardianId;
  final String? restrictionReason;
  final bool profileCompleted;

  factory FirestoreUserProfileDto.fromUserDoc(
    String userId,
    Map<String, dynamic> userData,
  ) {
    final profile =
        userData[FirestoreQuranSessionsPaths.quranSessionsProfileField]
            as Map<String, dynamic>? ??
        const {};
    return FirestoreUserProfileDto(
      userId: userId,
      displayName: userData['displayName'] as String?,
      role: profile['role'] as String? ?? 'student',
      accountStatus: profile['accountStatus'] as String? ?? 'active',
      gender: profile['gender'] as String?,
      dateOfBirth: readDateTime(profile['dateOfBirth']),
      countryCode: profile['countryCode'] as String?,
      countryName: profile['countryName'] as String?,
      cityId: profile['cityId'] as String?,
      cityName: profile['cityName'] as String?,
      currencyCode: profile['currencyCode'] as String?,
      timezone: profile['timezone'] as String?,
      guardianId: profile['guardianId'] as String?,
      restrictionReason: profile['restrictionReason'] as String?,
      profileCompleted: profile['profileCompleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toProfileMap({required DateTime updatedAt}) => {
    'role': role,
    'accountStatus': accountStatus,
    if (gender != null) 'gender': gender,
    if (dateOfBirth != null) 'dateOfBirth': writeDateTime(dateOfBirth!),
    if (countryCode != null) 'countryCode': countryCode,
    if (countryName != null) 'countryName': countryName,
    if (cityId != null) 'cityId': cityId,
    if (cityName != null) 'cityName': cityName,
    if (currencyCode != null) 'currencyCode': currencyCode,
    if (timezone != null) 'timezone': timezone,
    if (guardianId != null) 'guardianId': guardianId,
    if (restrictionReason != null) 'restrictionReason': restrictionReason,
    'profileCompleted': profileCompleted,
    'updatedAt': writeDateTime(updatedAt),
  };

  UserProfileDto toTransportDto() => UserProfileDto(
    userId: userId,
    role: role,
    accountStatus: accountStatus,
    displayName: displayName,
    gender: gender,
    dateOfBirth: dateOfBirth,
    countryCode: countryCode,
    countryName: countryName,
    cityId: cityId,
    cityName: cityName,
    currencyCode: currencyCode,
    timezone: timezone,
    guardianId: guardianId,
    restrictionReason: restrictionReason,
  );

  static FirestoreUserProfileDto fromTransportDto(UserProfileDto dto) {
    final complete =
        dto.gender != null &&
        dto.dateOfBirth != null &&
        dto.countryCode != null &&
        dto.cityId != null;
    return FirestoreUserProfileDto(
      userId: dto.userId,
      role: dto.role,
      accountStatus: dto.accountStatus,
      displayName: dto.displayName,
      gender: dto.gender,
      dateOfBirth: dto.dateOfBirth,
      countryCode: dto.countryCode,
      countryName: dto.countryName,
      cityId: dto.cityId,
      cityName: dto.cityName,
      currencyCode: dto.currencyCode,
      timezone: dto.timezone,
      guardianId: dto.guardianId,
      restrictionReason: dto.restrictionReason,
      profileCompleted: complete,
    );
  }

  static Map<String, dynamic> shellProfileMap({required DateTime now}) => {
    'role': 'student',
    'accountStatus': 'active',
    'profileCompleted': false,
    'createdAt': writeDateTime(now),
    'updatedAt': writeDateTime(now),
  };
}

/// Reads and writes `users/{uid}.quranSessionsProfile` in Firestore.
class FirestoreUserProfileDataSource implements UserProfileRemoteDataSource {
  FirestoreUserProfileDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _userRef(String userId) =>
      _firestore.collection(FirestoreQuranSessionsPaths.users).doc(userId);

  @override
  Future<UserProfileDto> getOrCreateProfile(String userId) async {
    try {
      final ref = _userRef(userId);
      final snapshot = await ref.get();
      if (!snapshot.exists) {
        final now = DateTime.now();
        await ref.set({
          FirestoreQuranSessionsPaths.quranSessionsProfileField:
              FirestoreUserProfileDto.shellProfileMap(now: now),
        }, SetOptions(merge: true));
        final created = await ref.get();
        return FirestoreUserProfileDto.fromUserDoc(
          userId,
          created.data() ?? const {},
        ).toTransportDto();
      }
      final data = snapshot.data() ?? const {};
      if (!data.containsKey(
        FirestoreQuranSessionsPaths.quranSessionsProfileField,
      )) {
        final now = DateTime.now();
        await ref.set({
          FirestoreQuranSessionsPaths.quranSessionsProfileField:
              FirestoreUserProfileDto.shellProfileMap(now: now),
        }, SetOptions(merge: true));
        final updated = await ref.get();
        return FirestoreUserProfileDto.fromUserDoc(
          userId,
          updated.data() ?? const {},
        ).toTransportDto();
      }
      return FirestoreUserProfileDto.fromUserDoc(userId, data).toTransportDto();
    } on FirebaseException catch (e) {
      throw mapFirebaseException(e);
    }
  }

  @override
  Future<UserProfileDto> updateProfile(UserProfileDto profile) async {
    try {
      final now = DateTime.now();
      final firestoreDto = FirestoreUserProfileDto.fromTransportDto(profile);
      await _userRef(profile.userId).set({
        FirestoreQuranSessionsPaths.quranSessionsProfileField: firestoreDto
            .toProfileMap(updatedAt: now),
      }, SetOptions(merge: true));
      final snapshot = await _userRef(profile.userId).get();
      return FirestoreUserProfileDto.fromUserDoc(
        profile.userId,
        snapshot.data() ?? const {},
      ).toTransportDto();
    } on FirebaseException catch (e) {
      throw mapFirebaseException(e);
    }
  }

  @override
  Future<void> blockAccount({
    required String userId,
    required String restrictionReason,
  }) async {
    try {
      final now = DateTime.now();
      await _userRef(userId).set({
        FirestoreQuranSessionsPaths.quranSessionsProfileField: {
          'accountStatus': 'blocked',
          'restrictionReason': restrictionReason,
          'updatedAt': writeDateTime(now),
        },
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw mapFirebaseException(e);
    }
  }
}

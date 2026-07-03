import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quran_sessions/quran_sessions.dart';

import 'firestore_exception_mapper.dart';
import 'firestore_paths.dart';

class FirestoreSessionPolicyDataSource
    implements SessionPolicyRemoteDataSource {
  FirestoreSessionPolicyDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> get _globalRef => _firestore
      .collection(FirestoreQuranSessionsPaths.platformConfig)
      .doc(FirestoreQuranSessionsPaths.globalPolicyDoc);

  @override
  Future<SessionPolicyDto> getGlobalPolicy() async {
    try {
      final snapshot = await _globalRef.get();
      if (!snapshot.exists) {
        return const SessionPolicyDto(
          childAgeThreshold: 14,
          minimumStudentAgeYears: 3,
          minimumTeacherAgeYears: 18,
          globalAllowMaleTeacherFemaleStudent: true,
          globalAllowFemaleTeacherMaleStudent: true,
          videoCallAllowedForChildren: false,
          recordingEnabled: false,
          quranTutorBookingMode: null,
        );
      }
      final data = snapshot.data() ?? const {};
      return SessionPolicyDto(
        childAgeThreshold: data['childAgeThreshold'] as int? ?? 14,
        minimumStudentAgeYears: data['minimumStudentAgeYears'] as int? ?? 3,
        minimumTeacherAgeYears: data['minimumTeacherAgeYears'] as int? ?? 18,
        globalAllowMaleTeacherFemaleStudent:
            data['globalAllowMaleTeacherFemaleStudent'] as bool? ?? true,
        globalAllowFemaleTeacherMaleStudent:
            data['globalAllowFemaleTeacherMaleStudent'] as bool? ?? true,
        videoCallAllowedForChildren:
            data['videoCallAllowedForChildren'] as bool? ?? false,
        recordingEnabled: data['recordingEnabled'] as bool? ?? false,
        quranTutorBookingMode: data['quranTutorBookingMode'] as String?,
      );
    } on FirebaseException catch (e) {
      throw mapFirebaseException(e);
    }
  }

  @override
  Future<TeacherEligibilityPolicyDto> getTeacherEligibilityPolicy(
    String teacherId,
  ) async {
    try {
      final doc = await _firestore
          .collection(FirestoreQuranSessionsPaths.teacherProfiles)
          .doc(teacherId)
          .get();
      if (!doc.exists) {
        return const TeacherEligibilityPolicyDto(
          allowedStudentGender: 'both',
          canTeachChildren: true,
        );
      }
      final data = doc.data() ?? const {};
      return TeacherEligibilityPolicyDto(
        allowedStudentGender: data['allowedStudentGender'] as String? ?? 'both',
        canTeachChildren: data['canTeachChildren'] as bool? ?? true,
      );
    } on FirebaseException catch (e) {
      throw mapFirebaseException(e);
    }
  }

  @override
  Future<void> updateGlobalPolicy(SessionPolicyDto policy) async {
    try {
      await _globalRef.set({
        'childAgeThreshold': policy.childAgeThreshold,
        'minimumStudentAgeYears': policy.minimumStudentAgeYears,
        'minimumTeacherAgeYears': policy.minimumTeacherAgeYears,
        'globalAllowMaleTeacherFemaleStudent':
            policy.globalAllowMaleTeacherFemaleStudent,
        'globalAllowFemaleTeacherMaleStudent':
            policy.globalAllowFemaleTeacherMaleStudent,
        'videoCallAllowedForChildren': policy.videoCallAllowedForChildren,
        'recordingEnabled': policy.recordingEnabled,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw mapFirebaseException(e);
    }
  }

  @override
  Future<void> updateTeacherEligibilityPolicy({
    required String teacherId,
    required TeacherEligibilityPolicyDto policy,
  }) async {
    try {
      await _firestore
          .collection(FirestoreQuranSessionsPaths.teacherProfiles)
          .doc(teacherId)
          .set({
            'allowedStudentGender': policy.allowedStudentGender,
            'canTeachChildren': policy.canTeachChildren,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw mapFirebaseException(e);
    }
  }
}

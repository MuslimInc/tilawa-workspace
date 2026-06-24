import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quran_sessions/quran_sessions.dart';

import 'firestore_exception_mapper.dart';
import 'firestore_paths.dart';

class FirestoreTeacherApplicationAccessDataSource
    implements TeacherApplicationAccessRemoteDataSource {
  FirestoreTeacherApplicationAccessDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  static const _policyField = 'teacherApplicationAccess';

  DocumentReference<Map<String, dynamic>> get _globalPolicyRef => _firestore
      .collection(FirestoreQuranSessionsPaths.platformConfig)
      .doc(FirestoreQuranSessionsPaths.globalPolicyDoc);

  @override
  Future<TeacherApplicationAccessSnapshotDto> getAccessSnapshot(
    String userId,
  ) async {
    try {
      final results = await Future.wait([
        _globalPolicyRef.get(),
        _firestore
            .collection(FirestoreQuranSessionsPaths.users)
            .doc(userId)
            .get(),
      ]);

      final policyDoc = results[0];
      final userDoc = results[1];
      final policyData =
          (policyDoc.data()?[_policyField] as Map<String, dynamic>?) ??
          const {};
      final userData = userDoc.data() ?? const {};
      final profile =
          userData[FirestoreQuranSessionsPaths.quranSessionsProfileField]
              as Map<String, dynamic>? ??
          const {};

      return TeacherApplicationAccessSnapshotDto(
        policy: _policyFromMap(policyData),
        userOverride: profile['canApplyAsTeacher'] as bool?,
        userEmail: userData['email'] as String?,
        userPhone:
            profile['phoneNumber'] as String? ??
            userData['phoneNumber'] as String?,
        userCountryCode: profile['countryCode'] as String?,
        userRole: profile['role'] as String? ?? 'student',
      );
    } on FirebaseException catch (e) {
      throw mapFirebaseException(e);
    }
  }

  TeacherApplicationAccessPolicyDto _policyFromMap(Map<String, dynamic> data) {
    final rulesRaw = data['rules'] as Map<String, dynamic>? ?? const {};
    return TeacherApplicationAccessPolicyDto(
      mode: data['mode'] as String? ?? 'none',
      allowlistUserIds: _stringList(data['allowlistUserIds']),
      rules: TeacherApplicationAccessRulesDto(
        countryCodes: _stringList(rulesRaw['countryCodes']),
        roles: _stringList(rulesRaw['roles']),
        emails: _stringList(rulesRaw['emails']),
        phones: _stringList(rulesRaw['phones']),
      ),
    );
  }

  List<String> _stringList(Object? raw) {
    if (raw is! List) {
      return const [];
    }
    return raw.whereType<String>().toList(growable: false);
  }
}

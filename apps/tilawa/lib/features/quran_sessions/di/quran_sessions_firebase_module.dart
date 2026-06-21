import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:quran_sessions/quran_sessions.dart';

import '../data/firebase/firebase_auth_session_provider.dart';
import '../data/firebase/firestore_availability_repository.dart';
import '../data/firebase/firestore_booking_repository.dart';
import '../data/firebase/firestore_market_config_repository.dart';
import '../data/firebase/firestore_session_policy_repository.dart';
import '../data/firebase/firestore_session_repository.dart';
import '../data/firebase/firestore_teacher_application_repository.dart';
import '../data/firebase/firestore_teacher_profile_repository.dart';
import '../data/firebase/firestore_teacher_repository.dart';
import '../data/firebase/firestore_user_profile_repository.dart';
import 'quran_sessions_mvp_module.dart';

/// Wires Firestore-backed Quran Sessions repositories via [QuranSessionsModule].
class QuranSessionsFirebaseModule {
  QuranSessionsFirebaseModule._();

  static void register(GetIt sl) {
    final firestore = FirebaseFirestore.instance;
    final authSession = FirebaseAuthSessionProvider(FirebaseAuth.instance);

    sl.registerLazySingleton<AuthSessionProvider>(() => authSession);

    QuranSessionsModule.register(
      <T extends Object>(T instance, {String? instanceName}) {
        sl.registerSingleton<T>(instance, instanceName: instanceName);
      },
      teacherDataSource: FirestoreTeacherDataSource(firestore),
      sessionDataSource: FirestoreSessionDataSource(firestore),
      bookingDataSource: FirestoreBookingDataSource(firestore, authSession),
      userProfileDataSource: FirestoreUserProfileDataSource(firestore),
      marketConfigDataSource: FirestoreMarketConfigDataSource(firestore),
      sessionPolicyDataSource: FirestoreSessionPolicyDataSource(firestore),
      teacherApplicationDataSource: FirestoreTeacherApplicationDataSource(
        firestore,
      ),
      teacherProfileDataSource: FirestoreTeacherProfileDataSource(firestore),
      availabilityDataSource: FirestoreAvailabilityDataSource(firestore),
    );

    QuranSessionsMvpModule.registerBlocs(sl);
  }
}

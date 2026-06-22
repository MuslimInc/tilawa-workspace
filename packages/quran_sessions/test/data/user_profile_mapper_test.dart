import 'package:checks/checks.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:quran_sessions/src/data/mappers/teacher_application_mapper.dart';
import 'package:quran_sessions/src/data/mappers/user_profile_mapper.dart';
import 'package:quran_sessions/src/data/repositories/repository_error_mapper.dart';
import 'package:test/test.dart';

void main() {
  group('UserProfileDto mapper', () {
    test('maps enums and DateTime without Firebase types', () {
      final dto = UserProfileDto(
        userId: 'uid_1',
        role: 'student',
        accountStatus: 'active',
        gender: 'female',
        dateOfBirth: DateTime.utc(2010, 5, 1),
        countryCode: 'EG',
        countryName: 'مصر',
        cityId: 'cairo',
        cityName: 'القاهرة',
        currencyCode: 'EGP',
        timezone: 'Africa/Cairo',
      );

      final profile = dto.toDomain();

      check(profile.userId).equals('uid_1');
      check(profile.role).equals(UserRole.student);
      check(profile.gender).equals(UserGender.female);
      check(profile.dateOfBirth).equals(DateTime.utc(2010, 5, 1));
      check(profile.isComplete).isTrue();
    });
  });

  group('TeacherApplicationDto mapper', () {
    test('serializes lifecycle status strings', () {
      final dto = TeacherApplicationDto(
        id: 'app_1',
        userId: 'uid_1',
        status: 'pending',
        createdAt: _t0,
        updatedAt: _t0,
        phoneNumber: '+201234567890',
        publicDisplayName: 'Ustadha Fatima',
        teachingLanguages: const ['ar'],
        specializations: const ['tajweed'],
        bio: 'bio',
      );

      final domain = dto.toDomain();
      check(domain.status).equals(TeacherApplicationStatus.pending);
      check(domain.isReadyToSubmit).isTrue();
    });
  });

  group('mapRemoteException', () {
    test('maps permission denied to UnauthorizedFailure', () {
      final failure = mapRemoteException(const PermissionDeniedException());
      check(failure).isA<UnauthorizedFailure>();
    });

    test('maps slot conflict to SlotUnavailableFailure', () {
      final failure = mapRemoteException(
        const ConflictException(isSlotUnavailable: true, slotId: 'slot_1'),
      );
      check(failure).isA<SlotUnavailableFailure>();
    });
  });
}

final _t0 = DateTime.utc(2026, 1, 1);

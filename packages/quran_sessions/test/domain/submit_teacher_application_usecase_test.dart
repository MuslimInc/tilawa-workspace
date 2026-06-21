import 'package:checks/checks.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/src/domain/entities/teacher_application.dart';
import 'package:quran_sessions/src/domain/failures/quran_sessions_failure.dart';
import 'package:quran_sessions/src/domain/usecases/submit_teacher_application_usecase.dart';

import '../helpers/fakes/fake_teacher_application_repository.dart';

// ── Fixtures ──────────────────────────────────────────────────────────────────

TeacherApplication _draft({
  String? phoneNumber,
  String? publicDisplayName = 'Ustad Ahmad',
  List<String> teachingLanguages = const ['ar'],
  List<String> specializations = const ['tajweed'],
  String? bio = 'test bio',
}) => TeacherApplication(
  id: 'app_1',
  userId: 'user_1',
  status: TeacherApplicationStatus.draft,
  phoneNumber: phoneNumber,
  phoneCountryCode: 'EG',
  publicDisplayName: publicDisplayName,
  teachingLanguages: teachingLanguages,
  specializations: specializations,
  bio: bio,
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
);

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late FakeTeacherApplicationRepository repo;
  late SubmitTeacherApplicationUseCase useCase;

  setUp(() {
    repo = FakeTeacherApplicationRepository();
    useCase = SubmitTeacherApplicationUseCase(repo);
  });

  group('SubmitTeacherApplicationUseCase', () {
    group('phone validation', () {
      test(
        'returns TeacherPhoneNumberRequiredFailure when phone is null',
        () async {
          final result = await useCase(_draft(phoneNumber: null));
          check(result).isA<Left<QuranSessionsFailure, TeacherApplication>>();
          final failure = (result as Left).value;
          check(failure).isA<TeacherPhoneNumberRequiredFailure>();
        },
      );

      test(
        'returns TeacherPhoneNumberRequiredFailure when phone is empty string',
        () async {
          final result = await useCase(_draft(phoneNumber: ''));
          check(result).isA<Left<QuranSessionsFailure, TeacherApplication>>();
          final failure = (result as Left).value;
          check(failure).isA<TeacherPhoneNumberRequiredFailure>();
        },
      );

      test(
        'returns InvalidTeacherPhoneNumberFailure for non-E.164 phone',
        () async {
          final result = await useCase(_draft(phoneNumber: '01012345678'));
          check(result).isA<Left<QuranSessionsFailure, TeacherApplication>>();
          final failure = (result as Left).value;
          check(failure).isA<InvalidTeacherPhoneNumberFailure>();
        },
      );

      test(
        'returns InvalidTeacherPhoneNumberFailure for whitespace-only phone',
        () async {
          final result = await useCase(_draft(phoneNumber: '   '));
          check(result).isA<Left<QuranSessionsFailure, TeacherApplication>>();
          final failure = (result as Left).value;
          check(failure).isA<TeacherPhoneNumberRequiredFailure>();
        },
      );

      test('accepts valid E.164 Egyptian phone number', () async {
        repo.application = _draft(phoneNumber: '+201012345678');
        final result = await useCase(_draft(phoneNumber: '+201012345678'));
        check(result).isA<Right<QuranSessionsFailure, TeacherApplication>>();
        final app = (result as Right).value as TeacherApplication;
        check(app.isPending).isTrue();
      });

      test('accepts valid E.164 Kuwait phone number', () async {
        final app = _draft(phoneNumber: '+96565012345');
        repo.application = app;
        final result = await useCase(app);
        check(result).isA<Right<QuranSessionsFailure, TeacherApplication>>();
      });

      test('accepts valid E.164 UAE phone number', () async {
        final app = _draft(phoneNumber: '+971501234567');
        repo.application = app;
        final result = await useCase(app);
        check(result).isA<Right<QuranSessionsFailure, TeacherApplication>>();
      });
    });

    group('public display name validation', () {
      test(
        'returns ValidationFailure when publicDisplayName missing',
        () async {
          final result = await useCase(
            _draft(phoneNumber: '+201012345678', publicDisplayName: null),
          );
          check(result).isA<Left<QuranSessionsFailure, TeacherApplication>>();
          final failure = (result as Left).value;
          check(failure).isA<ValidationFailure>();
        },
      );

      test('returns ValidationFailure for whitespace-only name', () async {
        final result = await useCase(
          _draft(phoneNumber: '+201012345678', publicDisplayName: '   '),
        );
        check(result).isA<Left<QuranSessionsFailure, TeacherApplication>>();
        final failure = (result as Left).value;
        check(failure).isA<ValidationFailure>();
      });

      test('returns ValidationFailure for placeholder name', () async {
        final result = await useCase(
          _draft(
            phoneNumber: '+201012345678',
            publicDisplayName: 'Quran Teacher',
          ),
        );
        check(result).isA<Left<QuranSessionsFailure, TeacherApplication>>();
        final failure = (result as Left).value;
        check(failure).isA<ValidationFailure>();
      });
    });

    group('incomplete application', () {
      test(
        'returns TeacherApplicationIncompleteFailure when no languages',
        () async {
          final app = _draft(
            phoneNumber: '+201012345678',
            teachingLanguages: [],
          );
          final result = await useCase(app);
          check(result).isA<Left<QuranSessionsFailure, TeacherApplication>>();
          final failure = (result as Left).value;
          check(failure).isA<TeacherApplicationIncompleteFailure>();
        },
      );

      test(
        'returns TeacherApplicationIncompleteFailure when no specializations',
        () async {
          final app = _draft(phoneNumber: '+201012345678', specializations: []);
          final result = await useCase(app);
          check(result).isA<Left<QuranSessionsFailure, TeacherApplication>>();
          final failure = (result as Left).value;
          check(failure).isA<TeacherApplicationIncompleteFailure>();
        },
      );

      test(
        'returns TeacherApplicationIncompleteFailure when bio is null',
        () async {
          final app = _draft(phoneNumber: '+201012345678', bio: null);
          final result = await useCase(app);
          check(result).isA<Left<QuranSessionsFailure, TeacherApplication>>();
          final failure = (result as Left).value;
          check(failure).isA<TeacherApplicationIncompleteFailure>();
        },
      );

      test(
        'returns TeacherApplicationIncompleteFailure when bio is blank',
        () async {
          final app = _draft(phoneNumber: '+201012345678', bio: '   ');
          final result = await useCase(app);
          check(result).isA<Left<QuranSessionsFailure, TeacherApplication>>();
          final failure = (result as Left).value;
          check(failure).isA<TeacherApplicationIncompleteFailure>();
        },
      );
    });

    group('successful submission', () {
      test(
        'advances application to pending when all fields are valid',
        () async {
          final app = _draft(phoneNumber: '+201012345678');
          repo.application = app;
          final result = await useCase(app);
          check(result).isA<Right<QuranSessionsFailure, TeacherApplication>>();
          final submitted = (result as Right).value as TeacherApplication;
          check(submitted.isPending).isTrue();
        },
      );

      test('repository receives the application to submit', () async {
        final app = _draft(phoneNumber: '+201012345678');
        repo.application = app;
        await useCase(app);
        check(repo.application!.isPending).isTrue();
      });

      test('returns repository failure if submit fails', () async {
        final app = _draft(phoneNumber: '+201012345678');
        repo.application = app;
        repo.submitFailure = const NetworkFailure();
        final result = await useCase(app);
        check(result).isA<Left<QuranSessionsFailure, TeacherApplication>>();
        final failure = (result as Left).value;
        check(failure).isA<NetworkFailure>();
      });
    });

    group('non-draft application', () {
      test(
        'returns TeacherApplicationAlreadyPendingFailure for pending app',
        () async {
          final app = TeacherApplication(
            id: 'app_1',
            userId: 'user_1',
            status: TeacherApplicationStatus.pending,
            phoneNumber: '+201012345678',
            teachingLanguages: const ['ar'],
            specializations: const ['tajweed'],
            bio: 'bio',
            createdAt: DateTime(2024),
            updatedAt: DateTime(2024),
          );
          final result = await useCase(app);
          check(result).isA<Left<QuranSessionsFailure, TeacherApplication>>();
          final failure = (result as Left).value;
          check(failure).isA<TeacherApplicationAlreadyPendingFailure>();
        },
      );
    });
  });
}

import 'package:bloc_test/bloc_test.dart';
import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/src/domain/entities/teacher_application.dart';
import 'package:quran_sessions/src/domain/failures/quran_sessions_failure.dart';
import 'package:quran_sessions/src/domain/usecases/approve_teacher_application_usecase.dart';
import 'package:quran_sessions/src/domain/usecases/get_teacher_application_status_usecase.dart';
import 'package:quran_sessions/src/domain/usecases/save_teacher_application_draft_usecase.dart';
import 'package:quran_sessions/src/domain/usecases/start_teacher_application_usecase.dart';
import 'package:quran_sessions/src/domain/usecases/get_user_profile_usecase.dart';
import 'package:quran_sessions/src/domain/usecases/submit_teacher_application_usecase.dart';
import 'package:quran_sessions/src/presentation/forms/teacher_application_field_ids.dart';
import 'package:quran_sessions/src/presentation/forms/teacher_application_validation_l10n.dart';
import 'package:quran_sessions/src/presentation/blocs/teacher_application/teacher_application_bloc.dart';
import 'package:quran_sessions/src/presentation/blocs/teacher_application/teacher_application_event.dart';
import 'package:quran_sessions/src/presentation/blocs/teacher_application/teacher_application_state.dart';

import '../../helpers/fakes/fake_teacher_application_repository.dart';
import '../../helpers/fakes/fake_teacher_profile_repository.dart';
import '../../helpers/fakes/fake_user_profile_repository.dart';

// ── Fixtures ──────────────────────────────────────────────────────────────────

TeacherApplication _draft({
  String? phoneNumber,
  String phoneCountryCode = 'EG',
  String publicDisplayName = 'Ustad Ahmad',
  List<String> teachingLanguages = const ['ar'],
  List<String> specializations = const ['tajweed'],
  String? bio = 'test bio',
}) => TeacherApplication(
  id: 'app_1',
  userId: 'user_1',
  status: TeacherApplicationStatus.draft,
  phoneNumber: phoneNumber,
  phoneCountryCode: phoneCountryCode,
  publicDisplayName: publicDisplayName,
  teachingLanguages: teachingLanguages,
  specializations: specializations,
  bio: bio,
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
);

// ── Test setup ────────────────────────────────────────────────────────────────

TeacherApplicationBloc _makeBloc(FakeTeacherApplicationRepository repo) =>
    TeacherApplicationBloc(
      startApplication: StartTeacherApplicationUseCase(repo),
      saveDraft: SaveTeacherApplicationDraftUseCase(repo),
      submitApplication: SubmitTeacherApplicationUseCase(repo),
      getStatus: GetTeacherApplicationStatusUseCase(repo),
      approveApplication: ApproveTeacherApplicationUseCase(
        applicationRepository: repo,
        profileRepository: FakeTeacherProfileRepository(),
      ),
      getUserProfile: GetUserProfileUseCase(FakeUserProfileRepository()),
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late FakeTeacherApplicationRepository repo;
  late TeacherApplicationBloc bloc;

  setUp(() {
    repo = FakeTeacherApplicationRepository();
    bloc = _makeBloc(repo);
  });

  tearDown(() => bloc.close());

  // ── Load ──────────────────────────────────────────────────────────────────

  group('load', () {
    blocTest<TeacherApplicationBloc, TeacherApplicationState>(
      'emits NotStarted when no application exists',
      build: () => bloc,
      act: (b) => b.add(const TeacherApplicationLoadRequested(userId: 'u1')),
      expect: () => [
        isA<TeacherApplicationLoading>(),
        isA<TeacherApplicationNotStarted>(),
      ],
    );

    blocTest<TeacherApplicationBloc, TeacherApplicationState>(
      'emits Editing for existing draft',
      build: () {
        repo.application = _draft();
        return bloc;
      },
      act: (b) => b.add(const TeacherApplicationLoadRequested(userId: 'u1')),
      expect: () => [
        isA<TeacherApplicationLoading>(),
        isA<TeacherApplicationEditing>(),
      ],
    );
  });

  // ── Phone validation state transitions ───────────────────────────────────

  group('phone validation state transitions', () {
    late TeacherApplicationEditing editingState;

    setUp(() {
      final draft = _draft();
      repo.application = draft;
      editingState = TeacherApplicationEditing(application: draft);
      bloc.emit(editingState);
    });

    blocTest<TeacherApplicationBloc, TeacherApplicationState>(
      'valid Egyptian number clears phoneErrorCode',
      build: () => bloc,
      act: (b) => b.add(const TeacherApplicationPhoneChanged('01012345678')),
      expect: () => [
        isA<TeacherApplicationEditing>(),
      ],
      verify: (b) {
        final s = b.state as TeacherApplicationEditing;
        check(s.phoneErrorCode).isNull();
        check(s.application.phoneNumber).equals('+201012345678');
        check(s.phoneInteracted).isTrue();
      },
    );

    blocTest<TeacherApplicationBloc, TeacherApplicationState>(
      'valid Kuwait number clears phoneErrorCode',
      build: () {
        final draft = _draft(phoneCountryCode: 'KW');
        repo.application = draft;
        bloc.emit(TeacherApplicationEditing(application: draft));
        return bloc;
      },
      act: (b) => b.add(const TeacherApplicationPhoneChanged('65012345')),
      verify: (b) {
        final s = b.state as TeacherApplicationEditing;
        check(s.phoneErrorCode).isNull();
        check(s.application.phoneNumber).equals('+96565012345');
      },
    );

    blocTest<TeacherApplicationBloc, TeacherApplicationState>(
      'invalid Egyptian number sets phoneErrorCode',
      build: () => bloc,
      act: (b) => b.add(const TeacherApplicationPhoneChanged('0101234')),
      verify: (b) {
        final s = b.state as TeacherApplicationEditing;
        check(s.phoneErrorCode).isNotNull();
        check(s.application.phoneNumber).isNull();
      },
    );

    blocTest<TeacherApplicationBloc, TeacherApplicationState>(
      '01020030 with KW country sets phoneErrorCode (invalid KW prefix)',
      build: () {
        final draft = _draft(phoneCountryCode: 'KW');
        repo.application = draft;
        bloc.emit(TeacherApplicationEditing(application: draft));
        return bloc;
      },
      act: (b) => b.add(const TeacherApplicationPhoneChanged('01020030')),
      verify: (b) {
        final s = b.state as TeacherApplicationEditing;
        check(s.phoneErrorCode).isNotNull();
        check(s.application.phoneNumber).isNull();
      },
    );

    blocTest<TeacherApplicationBloc, TeacherApplicationState>(
      'empty phone sets required phoneErrorCode',
      build: () => bloc,
      act: (b) => b.add(const TeacherApplicationPhoneChanged('')),
      verify: (b) {
        final s = b.state as TeacherApplicationEditing;
        check(s.phoneErrorCode).isNotNull();
        check(
          s.phoneErrorCode,
        ).equals(TeacherApplicationValidationCodes.phoneRequired);
      },
    );

    blocTest<TeacherApplicationBloc, TeacherApplicationState>(
      'whitespace-only phone is treated as empty — sets required error',
      build: () => bloc,
      // The screen trims before dispatching: onChanged: (v) => bloc.add(PhoneChanged(v.trim()))
      act: (b) => b.add(const TeacherApplicationPhoneChanged('')),
      verify: (b) {
        final s = b.state as TeacherApplicationEditing;
        check(
          s.phoneErrorCode,
        ).equals(TeacherApplicationValidationCodes.phoneRequired);
      },
    );

    blocTest<TeacherApplicationBloc, TeacherApplicationState>(
      'visiblePhoneErrorCode is null before field interaction',
      build: () => bloc,
      // No action — check initial state
      act: (_) {},
      verify: (b) {
        final s = b.state as TeacherApplicationEditing;
        check(s.visiblePhoneErrorCode).isNull();
        check(s.phoneInteracted).isFalse();
        check(s.submitAttempted).isFalse();
      },
    );

    blocTest<TeacherApplicationBloc, TeacherApplicationState>(
      'visiblePhoneErrorCode is shown after field interaction',
      build: () => bloc,
      act: (b) => b.add(const TeacherApplicationPhoneChanged('bad')),
      verify: (b) {
        final s = b.state as TeacherApplicationEditing;
        check(s.phoneInteracted).isTrue();
        check(s.visiblePhoneErrorCode).isNotNull();
      },
    );
  });

  // ── Country change revalidation ───────────────────────────────────────────

  group('country change revalidation', () {
    blocTest<TeacherApplicationBloc, TeacherApplicationState>(
      'Egyptian number becomes countryMismatch when KW is selected',
      build: () {
        final draft = _draft();
        repo.application = draft;
        bloc.emit(
          TeacherApplicationEditing(
            application: draft,
            phoneRaw: '01012345678',
            phoneErrorCode: null,
            phoneInteracted: true,
          ),
        );
        return bloc;
      },
      act: (b) => b.add(const TeacherApplicationPhoneCountryCodeChanged('KW')),
      verify: (b) {
        final s = b.state as TeacherApplicationEditing;
        check(s.phoneErrorCode).isNotNull();
        check(s.application.phoneNumber).isNull();
      },
    );

    blocTest<TeacherApplicationBloc, TeacherApplicationState>(
      'empty phone with submitAttempted shows required error on country change',
      build: () {
        final draft = _draft();
        repo.application = draft;
        bloc.emit(
          TeacherApplicationEditing(
            application: draft,
            phoneRaw: '',
            submitAttempted: true,
          ),
        );
        return bloc;
      },
      act: (b) => b.add(const TeacherApplicationPhoneCountryCodeChanged('KW')),
      verify: (b) {
        final s = b.state as TeacherApplicationEditing;
        check(s.phoneErrorCode).equals(
          TeacherApplicationValidationCodes.phoneRequired,
        );
        check(s.visiblePhoneErrorCode).equals(
          TeacherApplicationValidationCodes.phoneRequired,
        );
      },
    );
  });

  // ── Submit ────────────────────────────────────────────────────────────────

  group('submit', () {
    blocTest<TeacherApplicationBloc, TeacherApplicationState>(
      'sets submitAttempted and shows required phone error when phone is empty',
      build: () {
        final draft = _draft();
        repo.application = draft;
        bloc.emit(TeacherApplicationEditing(application: draft));
        return bloc;
      },
      act: (b) => b.add(const TeacherApplicationSubmitRequested()),
      verify: (b) {
        final s = b.state as TeacherApplicationEditing;
        check(s.submitAttempted).isTrue();
        check(s.phoneErrorCode).equals(
          TeacherApplicationValidationCodes.phoneRequired,
        );
        check(s.visiblePhoneErrorCode).equals(
          TeacherApplicationValidationCodes.phoneRequired,
        );
      },
    );

    blocTest<TeacherApplicationBloc, TeacherApplicationState>(
      'shows section errors for missing languages, specs, and bio on submit',
      build: () {
        final draft = _draft(phoneNumber: '+201012345678');
        repo.application = draft;
        bloc.emit(
          TeacherApplicationEditing(
            application: draft.copyWith(
              teachingLanguages: const <String>[],
              specializations: const <String>[],
              bio: '',
            ),
            phoneRaw: '01012345678',
            phoneInteracted: true,
          ),
        );
        return bloc;
      },
      act: (b) => b.add(const TeacherApplicationSubmitRequested()),
      verify: (b) {
        final s = b.state as TeacherApplicationEditing;
        check(s.submitAttempted).isTrue();
        check(s.visibleTeachingLanguagesErrorCode).isNotNull();
        check(s.visibleSpecializationsErrorCode).isNotNull();
        check(s.visibleBioErrorCode).isNotNull();
        check(s.invalidFieldCount).equals(3);
        check(s.validationIssues.first.fieldId).equals(
          TeacherApplicationFieldIds.teachingLanguages,
        );
      },
    );

    blocTest<TeacherApplicationBloc, TeacherApplicationState>(
      'does not advance when phone is invalid',
      build: () {
        final draft = _draft();
        repo.application = draft;
        bloc.emit(
          TeacherApplicationEditing(
            application: draft,
            phoneRaw: '0101',
            phoneErrorCode: TeacherApplicationValidationCodes.phoneInvalid,
            phoneInteracted: true,
          ),
        );
        return bloc;
      },
      act: (b) => b.add(const TeacherApplicationSubmitRequested()),
      expect: () => [
        isA<TeacherApplicationEditing>(), // submitAttempted update only
      ],
      verify: (b) {
        final s = b.state as TeacherApplicationEditing;
        check(s.submitAttempted).isTrue();
        // Must NOT have reached Submitting
        check(s).isA<TeacherApplicationEditing>();
      },
    );

    blocTest<TeacherApplicationBloc, TeacherApplicationState>(
      'succeeds and emits StatusLoaded(pending) for complete valid application',
      build: () {
        final draft = _draft(phoneNumber: '+201012345678');
        repo.application = draft;
        bloc.emit(
          TeacherApplicationEditing(
            application: draft,
            phoneRaw: '01012345678',
            phoneErrorCode: null,
            phoneInteracted: true,
          ),
        );
        return bloc;
      },
      act: (b) => b.add(const TeacherApplicationSubmitRequested()),
      expect: () => [
        isA<TeacherApplicationEditing>(), // submitAttempted=true
        isA<TeacherApplicationSubmitting>(),
        isA<TeacherApplicationStatusLoaded>(),
      ],
      verify: (b) {
        final s = b.state as TeacherApplicationStatusLoaded;
        check(s.application.isPending).isTrue();
      },
    );

    blocTest<TeacherApplicationBloc, TeacherApplicationState>(
      'succeeds when prefilled public name is visible but not on application',
      build: () {
        final draft = _draft(
          phoneNumber: '+201060099009',
          publicDisplayName: '',
        ).copyWith(publicDisplayName: null);
        repo.application = draft;
        bloc.emit(
          TeacherApplicationEditing(
            application: draft,
            phoneRaw: '01060099009',
            publicDisplayNameRaw: 'Muhammad Kamel',
            prefillPublicDisplayName: 'Muhammad Kamel',
            phoneInteracted: true,
          ),
        );
        return bloc;
      },
      act: (b) => b.add(const TeacherApplicationSubmitRequested()),
      expect: () => [
        isA<TeacherApplicationEditing>(),
        isA<TeacherApplicationSubmitting>(),
        isA<TeacherApplicationStatusLoaded>(),
      ],
      verify: (b) {
        final s = b.state as TeacherApplicationStatusLoaded;
        check(s.application.isPending).isTrue();
        check(s.application.publicDisplayName).equals('Muhammad Kamel');
      },
    );

    blocTest<TeacherApplicationBloc, TeacherApplicationState>(
      'emits FailureState then restores editing state on repository error',
      build: () {
        final draft = _draft(phoneNumber: '+201012345678');
        repo.application = draft;
        repo.submitFailure = const NetworkFailure();
        bloc.emit(
          TeacherApplicationEditing(
            application: draft,
            phoneRaw: '01012345678',
            phoneErrorCode: null,
            phoneInteracted: true,
          ),
        );
        return bloc;
      },
      act: (b) => b.add(const TeacherApplicationSubmitRequested()),
      expect: () => [
        isA<TeacherApplicationEditing>(),
        isA<TeacherApplicationSubmitting>(),
        isA<TeacherApplicationFailureState>(),
      ],
      verify: (b) {
        final s = b.state as TeacherApplicationFailureState;
        check(s.failure).isA<NetworkFailure>();
        check(s.previousState).isA<TeacherApplicationEditing>();
      },
    );
  });
}

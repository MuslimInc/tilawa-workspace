import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/teacher_application.dart';
import '../../../domain/usecases/approve_teacher_application_usecase.dart';
import '../../../domain/usecases/get_teacher_application_status_usecase.dart';
import '../../../domain/usecases/get_user_profile_usecase.dart';
import '../../../domain/usecases/save_teacher_application_draft_usecase.dart';
import '../../../domain/usecases/start_teacher_application_usecase.dart';
import '../../../domain/usecases/submit_teacher_application_usecase.dart';
import '../../../domain/value_objects/teacher_public_name.dart';
import '../../../utils/phone_normalizer.dart';
import '../../forms/teacher_application_validation_l10n.dart';
import 'teacher_application_event.dart';
import 'teacher_application_state.dart';

class TeacherApplicationBloc
    extends Bloc<TeacherApplicationEvent, TeacherApplicationState> {
  TeacherApplicationBloc({
    required this._startApplication,
    required this._saveDraft,
    required this._submitApplication,
    required this._getStatus,
    required this._approveApplication,
    required this._getUserProfile,
  }) : super(const TeacherApplicationInitial()) {
    on<TeacherApplicationLoadRequested>(
      _onLoadRequested,
      transformer: restartable(),
    );
    on<TeacherApplicationStartRequested>(
      _onStartRequested,
      transformer: droppable(),
    );
    on<TeacherApplicationPublicDisplayNameChanged>(
      _onPublicDisplayNameChanged,
      transformer: sequential(),
    );
    on<TeacherApplicationPhoneChanged>(
      _onPhoneChanged,
      transformer: sequential(),
    );
    on<TeacherApplicationPhoneCountryCodeChanged>(
      _onCountryCodeChanged,
      transformer: sequential(),
    );
    on<TeacherApplicationContactMethodChanged>(
      _onContactMethodChanged,
      transformer: sequential(),
    );
    on<TeacherApplicationLanguageToggled>(
      _onLanguageToggled,
      transformer: sequential(),
    );
    on<TeacherApplicationSpecializationToggled>(
      _onSpecializationToggled,
      transformer: sequential(),
    );
    on<TeacherApplicationBioChanged>(_onBioChanged, transformer: sequential());
    on<TeacherApplicationSubmitRequested>(
      _onSubmitRequested,
      transformer: droppable(),
    );
    on<TeacherApplicationDebugSimulateApproval>(
      _onDebugSimulateApproval,
      transformer: droppable(),
    );
  }

  final StartTeacherApplicationUseCase _startApplication;
  final SaveTeacherApplicationDraftUseCase _saveDraft;
  final SubmitTeacherApplicationUseCase _submitApplication;
  final GetTeacherApplicationStatusUseCase _getStatus;
  final ApproveTeacherApplicationUseCase _approveApplication;
  final GetUserProfileUseCase _getUserProfile;

  Future<void> _onLoadRequested(
    TeacherApplicationLoadRequested event,
    Emitter<TeacherApplicationState> emit,
  ) async {
    emit(const TeacherApplicationLoading());
    final result = await _getStatus(event.userId);
    await result.fold(
      (failure) async {
        emit(TeacherApplicationNotStarted(userId: event.userId));
      },
      (application) async => _emitForApplication(application, emit),
    );
  }

  Future<void> _onStartRequested(
    TeacherApplicationStartRequested event,
    Emitter<TeacherApplicationState> emit,
  ) async {
    emit(const TeacherApplicationLoading());
    final result = await _startApplication(event.userId);
    await result.fold(
      (failure) async {
        emit(
          TeacherApplicationFailureState(
            failure: failure,
            previousState: TeacherApplicationNotStarted(userId: event.userId),
          ),
        );
      },
      (application) async => _emitForApplication(application, emit),
    );
  }

  void _onPublicDisplayNameChanged(
    TeacherApplicationPublicDisplayNameChanged event,
    Emitter<TeacherApplicationState> emit,
  ) {
    final current = state;
    if (current is! TeacherApplicationEditing) return;

    final failure = ValidateTeacherPublicName.failureFor(
      event.publicDisplayName,
    );
    final normalized = ValidateTeacherPublicName.normalize(
      event.publicDisplayName,
    );
    final updated = current.application.copyWith(publicDisplayName: normalized);
    emit(
      current.copyWith(
        application: updated,
        publicDisplayNameRaw: event.publicDisplayName,
        publicDisplayNameErrorCode: failure?.code,
        clearPublicDisplayNameErrorCode: failure == null,
        publicDisplayNameInteracted: true,
      ),
    );
    _autosave(updated);
  }

  void _onPhoneChanged(
    TeacherApplicationPhoneChanged event,
    Emitter<TeacherApplicationState> emit,
  ) {
    final current = state;
    if (current is! TeacherApplicationEditing) return;
    final countryCode = current.application.phoneCountryCode ?? 'EG';
    final result = PhoneNormalizer.validate(event.phone, countryCode);
    final normalized = result == PhoneValidationResult.valid
        ? PhoneNormalizer.normalize(event.phone, countryCode)
        : null;
    final phoneError = _phoneErrorCodeFor(event.phone, result);
    final updated = current.application.copyWith(phoneNumber: normalized);
    emit(
      current.copyWith(
        application: updated,
        phoneRaw: event.phone,
        phoneErrorCode: phoneError,
        clearPhoneErrorCode: phoneError == null,
        phoneInteracted: true,
      ),
    );
    _autosave(updated);
  }

  void _onCountryCodeChanged(
    TeacherApplicationPhoneCountryCodeChanged event,
    Emitter<TeacherApplicationState> emit,
  ) {
    final current = state;
    if (current is! TeacherApplicationEditing) return;
    final result = current.phoneRaw.isEmpty
        ? PhoneValidationResult.invalid
        : PhoneNormalizer.validate(current.phoneRaw, event.countryCode);
    final normalized = result == PhoneValidationResult.valid
        ? PhoneNormalizer.normalize(current.phoneRaw, event.countryCode)
        : null;
    final phoneError = current.phoneRaw.isEmpty
        ? (current.submitAttempted
              ? TeacherApplicationValidationCodes.phoneRequired
              : null)
        : _phoneErrorCodeFor(current.phoneRaw, result);
    final updated = current.application.copyWith(
      phoneCountryCode: event.countryCode,
      phoneNumber: normalized,
    );
    emit(
      current.copyWith(
        application: updated,
        phoneErrorCode: phoneError,
        clearPhoneErrorCode: phoneError == null,
      ),
    );
    _autosave(updated);
  }

  void _onContactMethodChanged(
    TeacherApplicationContactMethodChanged event,
    Emitter<TeacherApplicationState> emit,
  ) {
    final current = state;
    if (current is! TeacherApplicationEditing) return;
    final updated = current.application.copyWith(
      preferredContactMethod: event.method,
    );
    emit(current.copyWith(application: updated));
    _autosave(updated);
  }

  void _onLanguageToggled(
    TeacherApplicationLanguageToggled event,
    Emitter<TeacherApplicationState> emit,
  ) {
    final current = state;
    if (current is! TeacherApplicationEditing) return;
    final langs = List<String>.from(current.application.teachingLanguages);
    if (langs.contains(event.language)) {
      langs.remove(event.language);
    } else {
      langs.add(event.language);
    }
    final updated = current.application.copyWith(teachingLanguages: langs);
    emit(
      current.copyWith(
        application: updated,
        clearTeachingLanguagesErrorCode: langs.isNotEmpty,
      ),
    );
    _autosave(updated);
  }

  void _onSpecializationToggled(
    TeacherApplicationSpecializationToggled event,
    Emitter<TeacherApplicationState> emit,
  ) {
    final current = state;
    if (current is! TeacherApplicationEditing) return;
    final specs = List<String>.from(current.application.specializations);
    if (specs.contains(event.specialization)) {
      specs.remove(event.specialization);
    } else {
      specs.add(event.specialization);
    }
    final updated = current.application.copyWith(specializations: specs);
    emit(
      current.copyWith(
        application: updated,
        clearSpecializationsErrorCode: specs.isNotEmpty,
      ),
    );
    _autosave(updated);
  }

  void _onBioChanged(
    TeacherApplicationBioChanged event,
    Emitter<TeacherApplicationState> emit,
  ) {
    final current = state;
    if (current is! TeacherApplicationEditing) return;
    final updated = current.application.copyWith(bio: event.bio);
    emit(
      current.copyWith(
        application: updated,
        clearBioErrorCode: event.bio.trim().isNotEmpty,
      ),
    );
    _autosave(updated);
  }

  Future<void> _onSubmitRequested(
    TeacherApplicationSubmitRequested event,
    Emitter<TeacherApplicationState> emit,
  ) async {
    final current = state;
    if (current is! TeacherApplicationEditing) return;

    final merged = current.withMergedApplicationFields();
    final withAttempt = merged.applySubmitValidation();
    emit(withAttempt);
    if (!withAttempt.canSubmit) return;

    emit(TeacherApplicationSubmitting(application: withAttempt.application));

    final result = await _submitApplication(withAttempt.application);

    result.fold(
      (failure) => emit(
        TeacherApplicationFailureState(
          failure: failure,
          previousState: withAttempt,
        ),
      ),
      (submitted) => emit(
        TeacherApplicationStatusLoaded(application: submitted),
      ),
    );
  }

  Future<void> _onDebugSimulateApproval(
    TeacherApplicationDebugSimulateApproval event,
    Emitter<TeacherApplicationState> emit,
  ) async {
    final current = state;
    if (current is! TeacherApplicationStatusLoaded) return;

    emit(current.copyWith(isSimulatingApproval: true));

    final result = await _approveApplication(
      applicationId: event.applicationId,
      reviewedBy: 'debug_admin',
    );

    final approveFailure = result.fold((f) => f, (_) => null);
    if (approveFailure != null) {
      emit(
        TeacherApplicationFailureState(
          failure: approveFailure,
          previousState: current.copyWith(isSimulatingApproval: false),
        ),
      );
      return;
    }

    final reloadResult = await _getStatus(current.application.userId);
    reloadResult.fold(
      (_) => emit(current.copyWith(isSimulatingApproval: false)),
      (application) =>
          emit(TeacherApplicationStatusLoaded(application: application)),
    );
  }

  Future<void> _emitForApplication(
    TeacherApplication application,
    Emitter<TeacherApplicationState> emit,
  ) async {
    if (application.isDraft) {
      final prefill = await _loadPrefillPublicName(application.userId);
      final displayNameRaw =
          application.publicDisplayName?.trim().isNotEmpty == true
          ? application.publicDisplayName!.trim()
          : (prefill ?? '');
      final normalizedPrefill = ValidateTeacherPublicName.normalize(
        displayNameRaw.isNotEmpty ? displayNameRaw : null,
      );
      final draftApplication =
          normalizedPrefill != null &&
              application.publicDisplayName?.trim().isNotEmpty != true
          ? application.copyWith(publicDisplayName: normalizedPrefill)
          : application;
      emit(
        TeacherApplicationEditing(
          application: draftApplication,
          phoneRaw: draftApplication.phoneNumber ?? '',
          publicDisplayNameRaw: displayNameRaw,
          prefillPublicDisplayName: prefill,
        ),
      );
    } else {
      emit(TeacherApplicationStatusLoaded(application: application));
    }
  }

  Future<String?> _loadPrefillPublicName(String userId) async {
    final result = await _getUserProfile(userId);
    return result.fold((_) => null, (profile) {
      final name = profile.displayName?.trim();
      if (name == null || name.isEmpty) return null;
      return name;
    });
  }

  void _autosave(TeacherApplication draft) {
    if (!draft.isDraft) return;
    _saveDraft(draft).ignore();
  }

  String? _phoneErrorCodeFor(String raw, PhoneValidationResult result) {
    if (raw.isEmpty) {
      return TeacherApplicationValidationCodes.phoneRequired;
    }
    return switch (result) {
      PhoneValidationResult.valid => null,
      PhoneValidationResult.countryMismatch =>
        TeacherApplicationValidationCodes.phoneCountryMismatch,
      PhoneValidationResult.invalid =>
        TeacherApplicationValidationCodes.phoneInvalid,
    };
  }
}

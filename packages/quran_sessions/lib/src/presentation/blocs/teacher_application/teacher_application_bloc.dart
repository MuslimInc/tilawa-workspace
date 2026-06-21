import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/teacher_application.dart';
import '../../../domain/usecases/approve_teacher_application_usecase.dart';
import '../../../domain/usecases/get_teacher_application_status_usecase.dart';
import '../../../domain/usecases/save_teacher_application_draft_usecase.dart';
import '../../../domain/usecases/start_teacher_application_usecase.dart';
import '../../../domain/usecases/submit_teacher_application_usecase.dart';
import '../../../utils/phone_normalizer.dart';
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
  }) : super(const TeacherApplicationInitial()) {
    on<TeacherApplicationLoadRequested>(
      _onLoadRequested,
      transformer: restartable(),
    );
    on<TeacherApplicationStartRequested>(
      _onStartRequested,
      transformer: droppable(),
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

  Future<void> _onLoadRequested(
    TeacherApplicationLoadRequested event,
    Emitter<TeacherApplicationState> emit,
  ) async {
    emit(const TeacherApplicationLoading());
    final result = await _getStatus(event.userId);
    result.fold(
      (failure) {
        // TeacherApplicationNotFoundFailure = no application yet
        emit(TeacherApplicationNotStarted(userId: event.userId));
      },
      (application) => _emitForApplication(application, emit),
    );
  }

  Future<void> _onStartRequested(
    TeacherApplicationStartRequested event,
    Emitter<TeacherApplicationState> emit,
  ) async {
    emit(const TeacherApplicationLoading());
    final result = await _startApplication(event.userId);
    result.fold(
      (failure) => emit(
        TeacherApplicationFailureState(
          failure: failure,
          previousState: TeacherApplicationNotStarted(userId: event.userId),
        ),
      ),
      (application) =>
          emit(TeacherApplicationEditing(application: application)),
    );
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
    final phoneError = _errorFor(event.phone, result);
    final updated = current.application.copyWith(phoneNumber: normalized);
    emit(
      current.copyWith(
        application: updated,
        phoneRaw: event.phone,
        phoneError: phoneError,
        clearPhoneError: phoneError == null,
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
    // Re-validate the existing raw input against the new country code.
    final result = current.phoneRaw.isEmpty
        ? PhoneValidationResult.invalid
        : PhoneNormalizer.validate(current.phoneRaw, event.countryCode);
    final normalized = result == PhoneValidationResult.valid
        ? PhoneNormalizer.normalize(current.phoneRaw, event.countryCode)
        : null;
    // Only show required error if user already attempted to submit.
    final phoneError = current.phoneRaw.isEmpty
        ? (current.submitAttempted ? 'رقم الهاتف مطلوب' : null)
        : _errorFor(current.phoneRaw, result);
    final updated = current.application.copyWith(
      phoneCountryCode: event.countryCode,
      phoneNumber: normalized,
    );
    emit(
      current.copyWith(
        application: updated,
        phoneError: phoneError,
        clearPhoneError: phoneError == null,
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
    emit(current.copyWith(application: updated));
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
    emit(current.copyWith(application: updated));
    _autosave(updated);
  }

  void _onBioChanged(
    TeacherApplicationBioChanged event,
    Emitter<TeacherApplicationState> emit,
  ) {
    final current = state;
    if (current is! TeacherApplicationEditing) return;
    final updated = current.application.copyWith(bio: event.bio);
    emit(current.copyWith(application: updated));
    _autosave(updated);
  }

  Future<void> _onSubmitRequested(
    TeacherApplicationSubmitRequested event,
    Emitter<TeacherApplicationState> emit,
  ) async {
    final current = state;
    if (current is! TeacherApplicationEditing) return;
    // Mark submitAttempted so all errors become visible, then re-check.
    var withAttempt = current.copyWith(submitAttempted: true);
    // If phone was never touched, compute the required error now so the field
    // shows feedback after the first submit attempt.
    if (withAttempt.phoneRaw.isEmpty && withAttempt.phoneError == null) {
      withAttempt = withAttempt.copyWith(phoneError: 'رقم الهاتف مطلوب');
    }
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

    // Avoid async lambdas inside fold — Either.fold does not await them,
    // so any emit inside would fire after the handler completes.
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

    // Reload to pick up the approved status from the repository.
    final reloadResult = await _getStatus(current.application.userId);
    reloadResult.fold(
      (_) => emit(current.copyWith(isSimulatingApproval: false)),
      (application) =>
          emit(TeacherApplicationStatusLoaded(application: application)),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  void _emitForApplication(
    TeacherApplication application,
    Emitter<TeacherApplicationState> emit,
  ) {
    if (application.isDraft) {
      emit(TeacherApplicationEditing(application: application));
    } else {
      emit(TeacherApplicationStatusLoaded(application: application));
    }
  }

  /// Fire-and-forget autosave for draft fields — UI does not await this.
  void _autosave(TeacherApplication draft) {
    if (!draft.isDraft) return;
    _saveDraft(draft).ignore();
  }

  String? _errorFor(String raw, PhoneValidationResult result) {
    if (raw.isEmpty) return 'رقم الهاتف مطلوب';
    return switch (result) {
      PhoneValidationResult.valid => null,
      PhoneValidationResult.countryMismatch =>
        'رقم الهاتف لا يطابق الدولة المختارة',
      PhoneValidationResult.invalid => 'رقم الهاتف غير صحيح',
    };
  }
}

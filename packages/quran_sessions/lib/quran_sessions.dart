// ── Domain: entities ──────────────────────────────────────────────────────────
// ── Localization helpers ─────────────────────────────────────────────────────
export 'core/l10n_extensions.dart';
// ── Boundaries: call ──────────────────────────────────────────────────────────
export 'src/boundaries/call/agora_call_provider.dart';
export 'src/boundaries/call/call_provider.dart';
export 'src/boundaries/call/call_room.dart';
export 'src/boundaries/call/call_token_provider.dart';
export 'src/boundaries/call/external_meeting_call_provider.dart';
export 'src/boundaries/call/web_rtc_call_provider.dart';
// ── Boundaries: payment ───────────────────────────────────────────────────────
export 'src/boundaries/payment/payment_provider.dart';
export 'src/boundaries/payment/teacher_payout_provider.dart';
// ── Boundaries: scheduling ────────────────────────────────────────────────────
export 'src/boundaries/scheduling/availability_provider.dart';
export 'src/boundaries/scheduling/booking_policy.dart';
export 'src/boundaries/scheduling/cancellation_policy.dart';
export 'src/boundaries/scheduling/reschedule_policy.dart';
// ── Data: typed exceptions (for datasource implementors) ─────────────────────
export 'src/data/exceptions/remote_exception.dart';
// ── Data: DI registration module ─────────────────────────────────────────────
// Host app uses QuranSessionsModule.register() — never imports *Impl directly.
export 'src/di/quran_sessions_module.dart';
export 'src/domain/entities/market_config.dart';
export 'src/domain/entities/quran_booking.dart';
export 'src/domain/entities/quran_session.dart';
export 'src/domain/entities/quran_teacher.dart';
export 'src/domain/entities/session_call_type.dart';
export 'src/domain/entities/session_policy.dart';
export 'src/domain/entities/session_price.dart';
export 'src/domain/entities/session_pricing_type.dart';
export 'src/domain/entities/session_review.dart';
export 'src/domain/entities/teacher_application.dart';
export 'src/domain/entities/teacher_availability.dart';
export 'src/domain/entities/teacher_profile.dart';
export 'src/domain/entities/teacher_verification_status.dart';
export 'src/domain/entities/user_profile.dart';
// ── Domain: failure types ─────────────────────────────────────────────────────
export 'src/domain/failures/quran_sessions_failure.dart';
// ── Domain: repository interfaces ────────────────────────────────────────────
export 'src/domain/repositories/booking_repository.dart';
export 'src/domain/repositories/market_config_repository.dart';
export 'src/domain/repositories/session_policy_repository.dart';
export 'src/domain/repositories/session_repository.dart';
export 'src/domain/repositories/teacher_application_repository.dart';
export 'src/domain/repositories/teacher_profile_repository.dart';
export 'src/domain/repositories/teacher_repository.dart'
    show TeacherRepository, TeacherPage;
export 'src/domain/repositories/user_profile_repository.dart';
// ── Domain: use cases ─────────────────────────────────────────────────────────
export 'src/domain/usecases/approve_teacher_application_usecase.dart';
export 'src/domain/usecases/block_account_usecase.dart';
export 'src/domain/usecases/cancel_booking_usecase.dart';
export 'src/domain/usecases/complete_student_profile_usecase.dart';
export 'src/domain/usecases/complete_teacher_profile_usecase.dart';
export 'src/domain/usecases/create_booking_usecase.dart';
export 'src/domain/usecases/get_market_config_usecase.dart';
export 'src/domain/usecases/get_session_policy_usecase.dart';
export 'src/domain/usecases/get_student_sessions_usecase.dart';
export 'src/domain/usecases/get_teacher_application_status_usecase.dart';
export 'src/domain/usecases/get_teacher_availability_usecase.dart';
export 'src/domain/usecases/get_teacher_profile_usecase.dart';
export 'src/domain/usecases/get_teacher_sessions_usecase.dart';
export 'src/domain/usecases/get_teachers_usecase.dart';
export 'src/domain/usecases/get_user_profile_usecase.dart';
export 'src/domain/usecases/reject_teacher_application_usecase.dart';
export 'src/domain/usecases/revoke_teacher_profile_usecase.dart';
export 'src/domain/usecases/save_teacher_application_draft_usecase.dart';
export 'src/domain/usecases/start_teacher_application_usecase.dart';
export 'src/domain/usecases/submit_review_usecase.dart';
export 'src/domain/usecases/submit_teacher_application_usecase.dart';
export 'src/domain/usecases/suspend_teacher_profile_usecase.dart';
export 'src/domain/usecases/update_teacher_eligibility_policy_usecase.dart';
export 'src/domain/usecases/validate_booking_eligibility_usecase.dart';
export 'src/presentation/blocs/booking/booking_bloc.dart';
export 'src/presentation/blocs/booking/booking_event.dart';
export 'src/presentation/blocs/booking/booking_state.dart';
export 'src/presentation/blocs/my_sessions/my_sessions_bloc.dart';
export 'src/presentation/blocs/my_sessions/my_sessions_event.dart';
export 'src/presentation/blocs/my_sessions/my_sessions_state.dart';
export 'src/presentation/blocs/profile_completion/profile_completion_bloc.dart';
export 'src/presentation/blocs/profile_completion/profile_completion_event.dart';
export 'src/presentation/blocs/profile_completion/profile_completion_state.dart';
// ── Presentation: BLoCs ───────────────────────────────────────────────────────
export 'src/presentation/blocs/teacher_application/teacher_application_bloc.dart';
export 'src/presentation/blocs/teacher_application/teacher_application_event.dart';
export 'src/presentation/blocs/teacher_application/teacher_application_state.dart';
export 'src/presentation/blocs/teacher_dashboard/teacher_dashboard_bloc.dart';
export 'src/presentation/blocs/teacher_dashboard/teacher_dashboard_event.dart';
export 'src/presentation/blocs/teacher_dashboard/teacher_dashboard_state.dart';
export 'src/presentation/blocs/teacher_list/teacher_list_bloc.dart';
export 'src/presentation/blocs/teacher_list/teacher_list_event.dart';
export 'src/presentation/blocs/teacher_list/teacher_list_state.dart';
export 'src/presentation/blocs/teacher_profile/teacher_profile_bloc.dart';
export 'src/presentation/blocs/teacher_profile/teacher_profile_event.dart';
export 'src/presentation/blocs/teacher_profile/teacher_profile_state.dart';
// ── Presentation: failure UI extension ───────────────────────────────────────
export 'src/presentation/failure_ui/quran_sessions_failure_ui.dart';
// ── Presentation: router ──────────────────────────────────────────────────────
export 'src/presentation/router/quran_sessions_routes.dart';
export 'src/presentation/screens/booking_screen.dart';
export 'src/presentation/screens/my_sessions_screen.dart';
export 'src/presentation/screens/profile_completion_screen.dart';
export 'src/presentation/screens/quran_sessions_home_screen.dart';
// ── Presentation: screens ─────────────────────────────────────────────────────
export 'src/presentation/screens/teacher_application_screen.dart';
export 'src/presentation/screens/teacher_application_status_screen.dart';
export 'src/presentation/screens/teacher_dashboard_screen.dart';
export 'src/presentation/screens/teacher_list_screen.dart';
export 'src/presentation/screens/teacher_profile_screen.dart';
// ── Presentation: widgets ─────────────────────────────────────────────────────
export 'src/presentation/widgets/availability_slot_picker.dart';
export 'src/presentation/widgets/date_grouped_slot_picker.dart';
export 'src/presentation/widgets/session_card.dart';
export 'src/presentation/widgets/teacher_card.dart';
export 'src/presentation/widgets/teacher_initials_avatar.dart';
// ── Utils ─────────────────────────────────────────────────────────────────────
export 'src/utils/phone_normalizer.dart';
export 'src/utils/price_formatter.dart';
export 'src/utils/specialization_labels.dart';

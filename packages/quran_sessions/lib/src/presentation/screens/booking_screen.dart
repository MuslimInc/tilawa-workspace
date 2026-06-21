import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/quran_booking.dart';
import '../../domain/entities/session_call_type.dart';
import '../../domain/failures/quran_sessions_failure.dart';
import '../blocs/booking/booking_bloc.dart';
import '../blocs/booking/booking_event.dart';
import '../blocs/booking/booking_state.dart';
import '../failure_ui/quran_sessions_failure_ui.dart';
import '../widgets/availability_slot_picker.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({
    super.key,
    required this.teacherId,
    required this.studentId,
    this.preSelectedSlotId,
    this.onBookingSuccess,
    this.onCompleteProfile,
  });

  final String teacherId;
  final String studentId;
  final String? preSelectedSlotId;

  /// Called after a booking is confirmed. When provided, the host app handles
  /// navigation; otherwise the screen pops itself.
  final void Function(QuranBooking booking)? onBookingSuccess;

  /// Called when the student needs to complete their profile.
  /// Host app navigates to [ProfileCompletionScreen] and, on return,
  /// the screen retries eligibility automatically.
  final Future<void> Function()? onCompleteProfile;

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  bool _autoSelectedSlot = false;

  @override
  void initState() {
    super.initState();
    _dispatchOpen();
  }

  void _dispatchOpen() {
    final now = DateTime.now();
    context.read<BookingBloc>().add(
      BookingScreenOpened(
        teacherId: widget.teacherId,
        studentId: widget.studentId,
        from: now,
        to: now.add(const Duration(days: 14)),
      ),
    );
  }

  void _retryEligibility() {
    _autoSelectedSlot = false;
    final now = DateTime.now();
    context.read<BookingBloc>().add(
      BookingEligibilityRetried(
        teacherId: widget.teacherId,
        studentId: widget.studentId,
        from: now,
        to: now.add(const Duration(days: 14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('احجز جلسة')),
      body: BlocConsumer<BookingBloc, BookingState>(
        listener: (context, state) {
          // Auto-select the pre-selected slot the first time BookingSelecting loads.
          if (!_autoSelectedSlot &&
              widget.preSelectedSlotId != null &&
              state is BookingSelecting) {
            _autoSelectedSlot = true;
            final slot = state.availableSlots
                .where((s) => s.slotId == widget.preSelectedSlotId)
                .firstOrNull;
            if (slot != null) {
              context.read<BookingBloc>().add(SlotSelected(slot));
            }
          }

          if (state is BookingSuccess) {
            TilawaFeedback.showToast(
              context,
              message: 'تم تأكيد الحجز!',
              variant: TilawaFeedbackVariant.success,
            );
            if (widget.onBookingSuccess != null) {
              widget.onBookingSuccess!(state.booking);
            } else {
              Navigator.of(context).pop();
            }
          }
          if (state is BookingFailure) {
            // Only show a snackbar for non-eligibility failures — eligibility
            // failures are rendered inline so the user can act on them.
            final f = state.failure;
            if (f is! ProfileIncompleteFailure &&
                f is! GenderNotAllowedFailure &&
                f is! AgeNotAllowedFailure &&
                f is! AccountBlockedFailure &&
                f is! TeacherNotVerifiedFailure &&
                f is! GuardianApprovalRequiredFailure) {
              TilawaFeedback.showToast(
                context,
                message: f.toLocalizedMessage(context),
                variant: TilawaFeedbackVariant.error,
              );
            }
          }
        },
        builder: (context, state) => switch (state) {
          BookingInitial() || BookingEligibilityChecking() => const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('جارٍ التحقق من أهليتك…'),
              ],
            ),
          ),
          BookingSlotsLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          BookingSubmitting() => const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('جارٍ تأكيد الحجز…'),
              ],
            ),
          ),
          BookingFailure(:final failure) => _EligibilityBlockedView(
            failure: failure,
            onCompleteProfile: widget.onCompleteProfile != null
                ? () async {
                    await widget.onCompleteProfile!();
                    if (context.mounted) _retryEligibility();
                  }
                : null,
            onRetry: _retryEligibility,
          ),
          BookingSuccess() => const SizedBox.shrink(),
          BookingSelecting(
            :final availableSlots,
            :final selectedSlot,
            :final selectedCallType,
            :final canSubmit,
          ) =>
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'اختر موعداً',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AvailabilitySlotPicker(
                            slots: availableSlots,
                            selectedSlotId: selectedSlot?.slotId,
                            initialSlotId: widget.preSelectedSlotId,
                            onSlotSelected: (slot) => context
                                .read<BookingBloc>()
                                .add(SlotSelected(slot)),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'نوع الجلسة',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          _CallTypePicker(
                            selected: selectedCallType,
                            onChanged: (ct) => context.read<BookingBloc>().add(
                              CallTypeSelected(ct),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TilawaButton(
                    text: 'تأكيد الحجز',
                    onPressed: canSubmit ? _submit : null,
                    isFullWidth: true,
                    size: TilawaButtonSize.large,
                  ),
                ],
              ),
            ),
        },
      ),
    );
  }

  void _submit() {
    final state = context.read<BookingBloc>().state;
    if (state is! BookingSelecting) return;
    final slot = state.selectedSlot;
    if (slot == null) return;

    context.read<BookingBloc>().add(
      BookingSubmitted(
        teacherId: widget.teacherId,
        slotId: slot.slotId,
        callType: state.selectedCallType,
      ),
    );
  }
}

// ── Eligibility blocked view ──────────────────────────────────────────────────

class _EligibilityBlockedView extends StatelessWidget {
  const _EligibilityBlockedView({
    required this.failure,
    required this.onRetry,
    this.onCompleteProfile,
  });

  final QuranSessionsFailure failure;
  final VoidCallback onRetry;
  final VoidCallback? onCompleteProfile;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isProfileIncomplete = failure is ProfileIncompleteFailure;
    final isBlocked = failure is AccountBlockedFailure;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: .center,
        crossAxisAlignment: .stretch,
        children: [
          Icon(
            isProfileIncomplete
                ? Icons.person_add_outlined
                : isBlocked
                ? Icons.block_outlined
                : Icons.cancel_outlined,
            size: 64,
            color: isBlocked ? scheme.error : scheme.primary,
          ),
          const SizedBox(height: 20),
          Text(
            failure.toLocalizedMessage(context),
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (isProfileIncomplete && onCompleteProfile != null)
            TilawaButton(
              text: 'إكمال الملف الشخصي',
              leadingIcon: const Icon(Icons.edit_outlined),
              onPressed: onCompleteProfile,
              isFullWidth: true,
              size: TilawaButtonSize.large,
            )
          else if (!isBlocked) ...[
            TilawaButton(
              text: 'إعادة المحاولة',
              onPressed: onRetry,
              isFullWidth: true,
              variant: TilawaButtonVariant.secondary,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Call type picker ──────────────────────────────────────────────────────────

class _CallTypePicker extends StatelessWidget {
  const _CallTypePicker({required this.selected, required this.onChanged});

  final SessionCallType selected;
  final ValueChanged<SessionCallType> onChanged;

  @override
  Widget build(BuildContext context) {
    return TilawaSegmentedControl<SessionCallType>(
      segments: const [
        TilawaSegment(
          value: SessionCallType.externalMeeting,
          label: 'رابط خارجي',
        ),
        TilawaSegment(
          value: SessionCallType.voiceCall,
          label: 'صوتي',
        ),
        TilawaSegment(
          value: SessionCallType.videoCall,
          label: 'مرئي',
        ),
      ],
      selectedValue: selected,
      onValueChanged: onChanged,
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }
}

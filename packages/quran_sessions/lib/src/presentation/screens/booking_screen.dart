import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_sessions/core/l10n_extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/quran_booking.dart';
import '../../domain/entities/session_call_type.dart';
import '../../domain/failures/quran_sessions_failure.dart';
import '../blocs/booking/booking_bloc.dart';
import '../blocs/booking/booking_event.dart';
import '../blocs/booking/booking_state.dart';
import '../failure_ui/quran_sessions_failure_ui.dart';
import '../widgets/availability_slot_picker.dart';
import '../widgets/payment_checkout_sheet.dart';

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
    final l10n = context.quranSessionsL10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.bookSessionTitle)),
      bottomNavigationBar: BlocBuilder<BookingBloc, BookingState>(
        buildWhen: (previous, current) =>
            previous is BookingSelecting != current is BookingSelecting ||
            (previous is BookingSelecting &&
                current is BookingSelecting &&
                previous.canSubmit != current.canSubmit),
        builder: (context, state) {
          if (state is! BookingSelecting) {
            return const SizedBox.shrink();
          }
          return TilawaBottomActionArea(
            child: TilawaButton(
              text: l10n.confirmBooking,
              onPressed: state.canSubmit ? () => _submit(context) : null,
              isFullWidth: true,
              size: TilawaButtonSize.large,
            ),
          );
        },
      ),
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
              message: l10n.bookingConfirmed,
              variant: TilawaFeedbackVariant.success,
            );
            if (widget.onBookingSuccess != null) {
              widget.onBookingSuccess!(state.booking);
            } else {
              Navigator.of(context).pop();
            }
          }
          if (state is BookingPaymentRequired) {
            unawaited(_showPaymentCheckout(context, state));
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
          BookingInitial() || BookingEligibilityChecking() => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 12),
                Text(l10n.checkingEligibility),
              ],
            ),
          ),
          BookingSlotsLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          BookingSubmitting() => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 12),
                Text(l10n.confirmingBooking),
              ],
            ),
          ),
          BookingPaymentRequired() => const Center(
            child: CircularProgressIndicator(),
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
          ) =>
            Padding(
              padding: EdgeInsets.all(Theme.of(context).tokens.spaceLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.selectSlot,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: Theme.of(context).tokens.spaceMedium),
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
                          SizedBox(
                            height: Theme.of(context).tokens.spaceExtraLarge,
                          ),
                          Text(
                            l10n.sessionType,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          SizedBox(height: Theme.of(context).tokens.spaceSmall),
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
                ],
              ),
            ),
        },
      ),
    );
  }

  void _submit(BuildContext context) {
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

  Future<void> _showPaymentCheckout(
    BuildContext context,
    BookingPaymentRequired state,
  ) async {
    final l10n = context.quranSessionsL10n;
    final bloc = context.read<BookingBloc>();

    await PaymentCheckoutSheet.show(
      context,
      amountLabel: l10n.paymentCheckoutAmountPending,
      onConfirm: () async {
        bloc.add(BookingConfirmPayment(state.outcome));
        final next = await bloc.stream.firstWhere(
          (s) => s is BookingSuccess || s is BookingFailure,
        );
        if (next is BookingFailure && context.mounted) {
          TilawaFeedback.showToast(
            context,
            message: next.failure.toLocalizedMessage(context),
            variant: TilawaFeedbackVariant.error,
          );
        }
        return next is BookingSuccess;
      },
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
    final l10n = context.quranSessionsL10n;
    final scheme = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).tokens;
    final isProfileIncomplete = failure is ProfileIncompleteFailure;
    final isBlocked = failure is AccountBlockedFailure;

    return Padding(
      padding: EdgeInsets.all(tokens.spaceExtraLarge + tokens.spaceSmall),
      child: Column(
        mainAxisAlignment: .center,
        crossAxisAlignment: .stretch,
        children: [
          TilawaStateVisual(
            icon: isProfileIncomplete
                ? Icons.person_add_outlined
                : isBlocked
                ? Icons.block_outlined
                : Icons.cancel_outlined,
            tone: isBlocked
                ? TilawaStateVisualTone.error
                : TilawaStateVisualTone.primary,
            size: tokens.iconSizeExtraLarge + tokens.spaceExtraLarge,
            iconColor: isBlocked ? scheme.error : scheme.primary,
          ),
          SizedBox(height: tokens.spaceLarge + tokens.spaceSmall),
          Text(
            failure.toLocalizedMessage(context),
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: tokens.spaceExtraLarge),
          if (isProfileIncomplete && onCompleteProfile != null)
            TilawaButton(
              text: l10n.profileCompletionTitle,
              leadingIcon: const Icon(Icons.edit_outlined),
              onPressed: onCompleteProfile,
              isFullWidth: true,
              size: TilawaButtonSize.large,
            )
          else if (!isBlocked) ...[
            TilawaButton(
              text: l10n.retry,
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
    final l10n = context.quranSessionsL10n;

    return TilawaSegmentedControl<SessionCallType>(
      segments: [
        TilawaSegment(
          value: SessionCallType.externalMeeting,
          label: l10n.callTypeExternalMeeting,
        ),
        TilawaSegment(
          value: SessionCallType.voiceCall,
          label: l10n.callTypeVoice,
        ),
        TilawaSegment(
          value: SessionCallType.videoCall,
          label: l10n.callTypeVideo,
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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_sessions/core/l10n_extensions.dart';
import 'package:quran_sessions/l10n/quran_sessions_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/session_lifecycle_status.dart';
import '../../domain/entities/quran_booking.dart';
import '../../domain/entities/session_call_provider_kind.dart';
import '../../domain/entities/session_call_type.dart';
import '../../domain/failures/quran_sessions_failure.dart';
import '../../domain/policies/quran_tutor_booking_mode.dart';
import '../../domain/policies/session_mode_policy.dart';
import '../blocs/booking/booking_bloc.dart';
import '../blocs/booking/booking_event.dart';
import '../blocs/booking/booking_state.dart';
import '../config/quran_sessions_analytics_callbacks.dart';
import '../failure_ui/quran_sessions_failure_ui.dart';
import '../widgets/availability_slot_picker.dart';
import '../widgets/paid_session_notice.dart';
import '../widgets/payment_checkout_sheet.dart';
import '../widgets/quran_sessions_scaffold.dart';
import '../../domain/entities/session_price.dart';
import '../../domain/entities/session_pricing_type.dart';
import '../../utils/price_formatter.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({
    super.key,
    required this.teacherId,
    required this.studentId,
    this.analytics = const QuranSessionsAnalyticsCallbacks(),
    this.preSelectedSlotId,
    this.sessionModePolicy = SessionModePolicy.freeBeta,
    this.bookingModeHint = QuranTutorBookingMode.autoConfirm,
    this.voiceVideoProviderHint,
    this.onBookingSuccess,
    this.onCompleteProfile,
    this.onGuardianApprovalRequested,
    this.onGuardianDashboardRequested,
  });

  final String teacherId;
  final String studentId;
  final QuranSessionsAnalyticsCallbacks analytics;
  final String? preSelectedSlotId;
  final SessionModePolicy sessionModePolicy;
  final QuranTutorBookingMode bookingModeHint;
  final SessionCallProviderKind? voiceVideoProviderHint;

  /// Host navigates to guardian approval; retry eligibility on return.
  final Future<bool> Function()? onGuardianApprovalRequested;

  /// Host opens light guardian hub (pending approvals overview).
  final VoidCallback? onGuardianDashboardRequested;

  /// Called after a booking is confirmed.
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
  bool _loggedBookingCompleted = false;

  @override
  void initState() {
    super.initState();
    widget.analytics.onBookingStarted?.call(widget.teacherId);
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = theme.tokens;

    return QuranSessionsScaffold(
      title: l10n.bookSessionTitle,
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
              text: widget.bookingModeHint.requiresTutorApproval
                  ? l10n.sendBookingRequest
                  : l10n.confirmBooking,
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
            final booking = state.booking;
            if (!_loggedBookingCompleted) {
              _loggedBookingCompleted = true;
              widget.analytics.onBookingCompleted?.call(
                teacherId: booking.teacherId,
                bookingId: booking.id,
                isPaid: booking.pricingType != SessionPricingType.free,
                pricingType: booking.pricingType.name,
                callType: booking.requestedCallType.name,
              );
            }
            final isPending =
                booking.effectiveLifecycleStatus ==
                SessionLifecycleStatus.pendingTutorApproval;
            TilawaFeedback.showToast(
              context,
              message: isPending
                  ? '${l10n.bookingUnderReviewTitle}\n${l10n.bookingUnderReviewPaymentHint}'
                  : l10n.bookingConfirmed,
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
            studentId: widget.studentId,
            onCompleteProfile: widget.onCompleteProfile != null
                ? () async {
                    await widget.onCompleteProfile!();
                    if (context.mounted) _retryEligibility();
                  }
                : null,
            onGuardianApproval:
                failure is GuardianApprovalRequiredFailure &&
                    widget.onGuardianApprovalRequested != null
                ? () async {
                    final approved =
                        await widget.onGuardianApprovalRequested!();
                    if (approved && context.mounted) {
                      _retryEligibility();
                    }
                  }
                : null,
            onGuardianDashboard: widget.onGuardianDashboardRequested,
            onRetry: _retryEligibility,
          ),
          BookingSuccess() => const SizedBox.shrink(),
          BookingSelecting(
            :final availableSlots,
            :final selectedSlot,
            :final selectedCallType,
            :final teacherExternalMeetingUrl,
            :final pricingType,
            :final sessionPrice,
            :final manualPaymentPrice,
          ) =>
            Padding(
              padding: EdgeInsets.all(tokens.spaceMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (manualPaymentPrice != null)
                    Padding(
                      padding: EdgeInsets.only(bottom: tokens.spaceSmall),
                      child: PaidSessionNotice(price: manualPaymentPrice),
                    )
                  else if (pricingType != null)
                    Padding(
                      padding: EdgeInsets.only(bottom: tokens.spaceSmall),
                      child: _BookingPriceSummary(
                        pricingType: pricingType,
                        sessionPrice: sessionPrice,
                      ),
                    ),
                  Text(
                    l10n.selectSlot,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                  SizedBox(height: tokens.spaceSmall),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TilawaCard(
                            padding: EdgeInsets.all(tokens.spaceSmall),
                            child: AvailabilitySlotPicker(
                              slots: availableSlots,
                              selectedSlotId: selectedSlot?.slotId,
                              initialSlotId: widget.preSelectedSlotId,
                              onSlotSelected: (slot) => context
                                  .read<BookingBloc>()
                                  .add(SlotSelected(slot)),
                            ),
                          ),
                          SizedBox(height: tokens.spaceSmall),
                          Text(
                            l10n.sessionType,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurface,
                            ),
                          ),
                          SizedBox(height: tokens.spaceExtraSmall),
                          TilawaCard(
                            padding: EdgeInsets.all(tokens.spaceSmall),
                            child: _CallTypePicker(
                              hostPolicy: widget.sessionModePolicy,
                              teacherExternalMeetingUrl:
                                  teacherExternalMeetingUrl,
                              selected: selectedCallType,
                              voiceVideoProviderHint:
                                  widget.voiceVideoProviderHint,
                              onChanged: (ct) =>
                                  context.read<BookingBloc>().add(
                                    CallTypeSelected(ct),
                                  ),
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
    final pricingType =
        state.pricingType ?? state.outcome.aggregate.pricingType;
    final isFree = pricingType == SessionPricingType.free;
    final amountLabel = isFree
        ? l10n.priceFree
        : state.sessionPrice != null
        ? PriceFormatter.format(state.sessionPrice!, l10n)
        : l10n.paymentCheckoutAmountPending;

    await PaymentCheckoutSheet.show(
      context,
      amountLabel: amountLabel,
      isFreeSession: isFree,
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

class _BookingPriceSummary extends StatelessWidget {
  const _BookingPriceSummary({
    required this.pricingType,
    required this.sessionPrice,
  });

  final SessionPricingType pricingType;
  final SessionPrice? sessionPrice;

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = theme.tokens;
    final isFree = pricingType == SessionPricingType.free;
    final priceLabel = PriceFormatter.formatOrFree(
      l10n: l10n,
      pricingType: pricingType,
      price: sessionPrice,
    );

    return TilawaCard(
      padding: EdgeInsets.all(tokens.spaceMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.bookingPriceSummaryTitle,
            style: theme.textTheme.labelLarge?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: tokens.spaceExtraSmall),
          Text(
            priceLabel.isEmpty ? l10n.paymentCheckoutAmountPending : priceLabel,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: isFree ? scheme.primary : scheme.onSurface,
            ),
          ),
          if (!isFree) ...[
            SizedBox(height: tokens.spaceExtraSmall),
            Text(
              l10n.bookingPricePerSessionHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EligibilityBlockedView extends StatelessWidget {
  const _EligibilityBlockedView({
    required this.failure,
    required this.onRetry,
    this.onCompleteProfile,
    this.onGuardianApproval,
    this.onGuardianDashboard,
    this.studentId,
  });

  final QuranSessionsFailure failure;
  final VoidCallback onRetry;
  final VoidCallback? onCompleteProfile;
  final VoidCallback? onGuardianApproval;
  final VoidCallback? onGuardianDashboard;
  final String? studentId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = theme.tokens;
    final isProfileIncomplete = failure is ProfileIncompleteFailure;
    final isBlocked = failure is AccountBlockedFailure;
    final needsGuardianApproval = failure is GuardianApprovalRequiredFailure;

    return Padding(
      padding: EdgeInsets.all(tokens.spaceExtraLarge + tokens.spaceSmall),
      child: Column(
        mainAxisAlignment: .center,
        crossAxisAlignment: .stretch,
        children: [
          TilawaStateVisual(
            icon: isProfileIncomplete
                ? Icons.person_add_outlined
                : needsGuardianApproval
                ? Icons.family_restroom_outlined
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
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
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
          else if (needsGuardianApproval) ...[
            if (onGuardianApproval != null)
              TilawaButton(
                text: l10n.guardianApprovalSetupAction,
                leadingIcon: const Icon(Icons.family_restroom_outlined),
                onPressed: onGuardianApproval,
                isFullWidth: true,
                size: TilawaButtonSize.large,
              ),
            if (onGuardianDashboard != null) ...[
              SizedBox(height: tokens.spaceSmall),
              TilawaButton(
                text: l10n.guardianDashboardOpenAction,
                variant: TilawaButtonVariant.secondary,
                onPressed: onGuardianDashboard,
                isFullWidth: true,
              ),
            ],
          ] else if (!isBlocked) ...[
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
  const _CallTypePicker({
    required this.hostPolicy,
    required this.teacherExternalMeetingUrl,
    required this.selected,
    required this.onChanged,
    this.voiceVideoProviderHint,
  });

  final SessionModePolicy hostPolicy;
  final String? teacherExternalMeetingUrl;
  final SessionCallType selected;
  final ValueChanged<SessionCallType> onChanged;
  final SessionCallProviderKind? voiceVideoProviderHint;

  bool get _hasExternalMeetingUrl =>
      SessionModePolicy.hasExternalMeetingUrl(teacherExternalMeetingUrl);

  SessionModePolicy get _effectivePolicy =>
      hostPolicy.forTeacherExternalMeetingUrl(teacherExternalMeetingUrl);

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = theme.tokens;
    final policy = _effectivePolicy;
    final externalMissing =
        hostPolicy.isEnabled(SessionCallType.externalMeeting) &&
        !_hasExternalMeetingUrl;

    final segments = [
      TilawaSegment(
        value: SessionCallType.externalMeeting,
        label: l10n.callTypeExternalMeeting,
        enabled:
            hostPolicy.isEnabled(SessionCallType.externalMeeting) &&
            _hasExternalMeetingUrl,
        semanticsHint:
            hostPolicy.isEnabled(SessionCallType.externalMeeting) &&
                _hasExternalMeetingUrl
            ? null
            : externalMissing
            ? l10n.sessionModeExternalDisabled
            : l10n.unsupportedSessionMode,
      ),
      TilawaSegment(
        value: SessionCallType.voiceCall,
        label: l10n.callTypeVoice,
        enabled: policy.isEnabled(SessionCallType.voiceCall),
        semanticsHint: policy.isEnabled(SessionCallType.voiceCall)
            ? null
            : l10n.sessionModeVoiceDisabled,
      ),
      TilawaSegment(
        value: SessionCallType.videoCall,
        label: l10n.callTypeVideo,
        enabled: policy.isEnabled(SessionCallType.videoCall),
        semanticsHint: policy.isEnabled(SessionCallType.videoCall)
            ? null
            : l10n.sessionModeVideoDisabled,
      ),
    ];

    final enabledSegments = segments
        .where((segment) => segment.enabled)
        .toList();
    final effectiveSelected =
        policy.isEnabled(selected) &&
            (selected != SessionCallType.externalMeeting ||
                _hasExternalMeetingUrl)
        ? selected
        : SessionModePolicy.defaultCallType(
            policy: hostPolicy,
            externalMeetingUrl: teacherExternalMeetingUrl,
          );

    if (enabledSegments.isEmpty) {
      return Text(
        l10n.unsupportedSessionMode,
        style: theme.textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
          height: 1.3,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TilawaSegmentedControl<SessionCallType>(
          segments: segments,
          selectedValue: effectiveSelected,
          onValueChanged: onChanged,
        ),
        if (_helperText(l10n, effectiveSelected) case final note?)
          Padding(
            padding: EdgeInsets.only(top: tokens.spaceSmall),
            child: Text(
              note,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.3,
              ),
            ),
          ),
      ],
    );
  }

  String? _helperText(QuranSessionsLocalizations l10n, SessionCallType type) {
    final externalMissing =
        hostPolicy.isEnabled(SessionCallType.externalMeeting) &&
        !_hasExternalMeetingUrl;
    if (externalMissing) {
      return l10n.sessionModeExternalDisabled;
    }
    final policy = _effectivePolicy;
    final voiceOff = !policy.isEnabled(SessionCallType.voiceCall);
    final videoOff = !policy.isEnabled(SessionCallType.videoCall);
    if (voiceOff || videoOff) {
      if (voiceOff && videoOff) {
        return l10n.sessionModeVoiceDisabled;
      }
      if (voiceOff) return l10n.sessionModeVoiceDisabled;
      if (videoOff) return l10n.sessionModeVideoDisabled;
    }
    if (!policy.voiceVideoUseMockProvider) {
      if (voiceVideoProviderHint != null &&
          (type == SessionCallType.voiceCall ||
              type == SessionCallType.videoCall)) {
        return l10n.bookingVoiceVideoProviderNote(
          l10n.callProviderKindLabel(voiceVideoProviderHint!),
        );
      }
      return null;
    }
    return switch (type) {
      SessionCallType.voiceCall => l10n.sessionModeVoiceBetaNote,
      SessionCallType.videoCall => l10n.sessionModeVideoBetaNote,
      SessionCallType.externalMeeting => null,
    };
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:quran_sessions/quran_sessions.dart';

import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../failure_ui/quran_sessions_failure_body.dart';
import '../widgets/date_grouped_slots_layout.dart';
import '../widgets/friday_review_reminder_banner.dart';
import '../widgets/teacher_dashboard_inline_empty_state.dart';
import '../widgets/teacher_dashboard_schedule_section.dart';
import '../widgets/teacher_dashboard_summary_stats.dart';
import '../widgets/tutor_dashboard_section.dart';
import '../widgets/tutor_session_compact_card.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({
    super.key,
    required this.teacherId,
    this.onManageSchedule,
    this.onSessionDetailRequested,
    this.resolveStudentName,
    this.schedulingAnalytics,
    this.meetingUrlSettingsBuilder,
    this.viewerAuthUserId,
    this.analytics = const QuranSessionsAnalyticsCallbacks(),
    this.createCallControlGateway,
    this.createCallTelemetry,
  });

  final String teacherId;

  /// Opens the recurring weekly availability editor. Wired by the host router;
  /// when null the schedule entry points are hidden. When the returned future
  /// completes, the dashboard reloads so newly saved working hours appear.
  final Future<void> Function()? onManageSchedule;

  /// Opens session detail for a booked session (booking aggregate id).
  ///
  /// Return [true] when the session was mutated (e.g. tutor cancel) so the
  /// dashboard reloads upcoming sessions on pop.
  final Future<bool?> Function(String bookingId)? onSessionDetailRequested;

  /// Resolves a student display name for dashboard session rows.
  final String? Function(String studentId)? resolveStudentName;

  /// Optional scheduling experiment analytics (week views, Friday banner).
  final QuranSessionsSchedulingAnalyticsCallbacks? schedulingAnalytics;

  /// Builds the external meeting URL editor shown from the app bar settings
  /// sheet. When null, the settings entry point is hidden.
  final WidgetBuilder? meetingUrlSettingsBuilder;

  /// Signed-in teacher auth uid — staging QA join-window bypass in UI.
  final String? viewerAuthUserId;

  final QuranSessionsAnalyticsCallbacks analytics;

  final SessionCallControlGatewayFactory? createCallControlGateway;
  final CallTelemetryCoordinatorFactory? createCallTelemetry;

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  String? _lastUndoSnackSlotId;
  int? _lastAnnouncedDiscardedCount;
  final Set<String> _enterAnimatedSlotIds = {};
  bool _loggedWeekView = false;
  bool _loggedFridayBanner = false;

  static const _undoSnackDuration = Duration(seconds: 4);
  static const _slotUndoDedupeKey = 'teacher-dashboard-slot-undo';

  @override
  void initState() {
    super.initState();
    context.read<TeacherDashboardBloc>().add(
      TeacherDashboardLoadRequested(teacherId: widget.teacherId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final dashboardState = context.watch<TeacherDashboardBloc>().state;

    return QuranSessionsScaffold(
      title: l10n.teacherDashboardTitle,
      actions: [
        if (widget.meetingUrlSettingsBuilder != null)
          IconButton(
            icon: const Icon(Icons.link_outlined),
            tooltip: l10n.teacherExternalMeetingUrlLabel,
            onPressed: _openMeetingLinkSettings,
          ),
        if (widget.onManageSchedule != null &&
            dashboardState is TeacherDashboardSuccess)
          IconButton(
            icon: const Icon(Icons.edit_calendar_outlined),
            tooltip: l10n.editWeeklyTemplate,
            onPressed: () => _openManageSchedule(source: 'app_bar'),
          ),
      ],
      body: MultiBlocListener(
        listeners: [
          BlocListener<TeacherDashboardBloc, TeacherDashboardState>(
            listenWhen: (previous, current) =>
                current is TeacherDashboardSuccess &&
                current.joinCompletedSessionId != null &&
                (previous is! TeacherDashboardSuccess ||
                    previous.joinCompletedSessionId !=
                        current.joinCompletedSessionId),
            listener: (context, state) async {
              if (state is! TeacherDashboardSuccess) return;

              final sessionId = state.joinCompletedSessionId;
              if (sessionId == null) return;

              final session = _findSession(state, sessionId);
              widget.analytics.onSessionJoined?.call(
                bookingId: session?.bookingId,
                sessionId: sessionId,
              );
              context.read<TeacherDashboardBloc>().add(
                const TeacherDashboardJoinCompletedAcknowledged(),
              );

              if (session == null || _isExternalMeeting(session)) {
                return;
              }

              if (!context.mounted) return;
              await pushInAppCallShell(
                context,
                sessionId: sessionId,
                callType: session.callType,
                callProviderKind: session.callProviderKind,
                participantName: _studentDisplayName(
                  context,
                  session.studentId,
                ),
                participantSubtitle: l10n.callTypeLabel(session.callType),
                createCallControlGateway: widget.createCallControlGateway,
                createCallTelemetry: widget.createCallTelemetry,
              );
            },
          ),
        ],
        child: BlocConsumer<TeacherDashboardBloc, TeacherDashboardState>(
          listenWhen: (previous, current) {
            if (current is! TeacherDashboardSuccess) {
              return previous is TeacherDashboardSuccess;
            }
            if (previous is! TeacherDashboardSuccess) return true;
            return previous.bookingRequestFailure !=
                    current.bookingRequestFailure ||
                previous.sessionCancelFailure != current.sessionCancelFailure ||
                previous.sessionCancelSucceeded !=
                    current.sessionCancelSucceeded ||
                previous.slotFailure != current.slotFailure ||
                previous.refreshDiscardedPendingCount !=
                    current.refreshDiscardedPendingCount ||
                previous.undoableSlotId != current.undoableSlotId ||
                previous.joinFailure != current.joinFailure;
          },
          listener: (context, state) {
            if (state is! TeacherDashboardSuccess) {
              _lastUndoSnackSlotId = null;
              _loggedWeekView = false;
              _loggedFridayBanner = false;
              return;
            }

            _maybeLogWeekView(state);
            _maybeLogFridayBanner(state);

            if (state.bookingRequestFailure != null) {
              TilawaFeedback.showToast(
                context,
                message: state.bookingRequestFailure!.toLocalizedMessage(
                  context,
                ),
                variant: TilawaFeedbackVariant.error,
              );
            }

            if (state.sessionCancelFailure != null) {
              TilawaFeedback.showToast(
                context,
                message: l10n.tutorCancelSessionError,
                variant: TilawaFeedbackVariant.error,
                dedupeKey: 'teacher-dashboard-session-cancel-error',
              );
            }

            if (state.sessionCancelSucceeded) {
              TilawaFeedback.showToast(
                context,
                message: l10n.tutorCancelSessionSuccess,
                variant: TilawaFeedbackVariant.success,
                dedupeKey: 'teacher-dashboard-session-cancel-success',
              );
            }

            if (state.joinFailure != null) {
              TilawaFeedback.showToast(
                context,
                message: state.joinFailure!.toLocalizedMessage(context),
                variant: TilawaFeedbackVariant.error,
              );
            }

            if (state.slotFailure != null) {
              TilawaFeedback.showToast(
                context,
                message: state.slotFailure!.toLocalizedMessage(context),
                variant: TilawaFeedbackVariant.error,
              );
            }

            final discarded = state.refreshDiscardedPendingCount;
            if (discarded != null &&
                discarded > 0 &&
                discarded != _lastAnnouncedDiscardedCount) {
              _dismissSlotUndoToast(context);
              _lastUndoSnackSlotId = null;
              _lastAnnouncedDiscardedCount = discarded;
              TilawaFeedback.showToast(
                context,
                message: context.quranSessionsL10n.deleteSlotRefreshDiscarded(
                  discarded,
                ),
                variant: TilawaFeedbackVariant.info,
                dedupeKey: 'teacher-dashboard-slot-refresh-discarded',
              );
            }

            final undoId = state.undoableSlotId;
            if (undoId == null) {
              if (_lastUndoSnackSlotId != null) {
                _dismissSlotUndoToast(context);
              }
              _lastUndoSnackSlotId = null;
              return;
            }
            if (undoId == _lastUndoSnackSlotId) {
              return;
            }

            final pending = state.pendingDeletes[undoId];
            if (pending == null) return;

            _lastUndoSnackSlotId = undoId;
            _showDeleteUndoToast(
              context,
              pending.snapshot,
              pendingDeleteCount: state.pendingDeletes.length,
            );
          },
          builder: (context, state) => switch (state) {
            TeacherDashboardInitial() || TeacherDashboardLoading() =>
              const Center(child: CircularProgressIndicator()),
            TeacherDashboardEmpty() => Center(
              child: Padding(
                padding: EdgeInsets.all(Theme.of(context).tokens.spaceLarge),
                child: TilawaEmptyState(
                  icon: Icons.event_available_outlined,
                  title: l10n.availabilitySetupHeadline,
                  subtitle:
                      '${l10n.availabilitySetupBenefitRecurring}  ·  '
                      '${l10n.availabilitySetupBenefitTimezone}  ·  '
                      '${l10n.availabilitySetupBenefitSelfBooking}',
                  action: TilawaButton(
                    text: l10n.availabilitySetupCta,
                    leadingIcon: const Icon(Icons.calendar_month_outlined),
                    onPressed: _openManageSchedule,
                  ),
                ),
              ),
            ),
            TeacherDashboardFailure(:final failure) =>
              buildQuranSessionsFailureBody(
                context,
                failure: failure,
                onRetry: _reload,
              ),
            TeacherDashboardSuccess success => RefreshIndicator(
              onRefresh: () async => _reload(),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: TeacherDashboardSummaryStats(
                      pendingRequestsCount:
                          success.pendingBookingRequests.length,
                      upcomingSessionsCount: success.upcomingSessions.length,
                      bookableSlotsCount: _bookableOpenSlotsCount(success),
                      pendingRequestsLabel:
                          l10n.teacherDashboardStatPendingRequests,
                      upcomingSessionsLabel:
                          l10n.teacherDashboardStatUpcomingSessions,
                      bookableSlotsLabel: success.weekScopedDashboard
                          ? l10n.teacherDashboardStatBookableSlotsThisWeek
                          : l10n.teacherDashboardStatBookableSlotsHorizon,
                    ),
                  ),

                  // ── Pending booking requests (actionable lists only) ───
                  if (success.pendingBookingRequests.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: TutorDashboardSection(
                        title: l10n.teacherPendingBookingRequestsSectionTitle,
                      ),
                    ),
                    SliverList.builder(
                      itemCount: success.pendingBookingRequests.length,
                      itemBuilder: (_, i) {
                        final session = success.pendingBookingRequests[i];
                        final inProgress =
                            success.bookingRequestActionInProgress ==
                            session.bookingId;
                        return TutorSessionCompactCard(
                          session: session,
                          studentDisplayName: _studentDisplayName(
                            context,
                            session.studentId,
                          ),
                          now: DateTime.now(),
                          isLoading: inProgress,
                          viewerUserId: widget.viewerAuthUserId,
                          onAccept: () =>
                              context.read<TeacherDashboardBloc>().add(
                                TeacherBookingRequestAccepted(
                                  bookingId: session.bookingId,
                                ),
                              ),
                          onReject: () => _confirmRejectBookingRequest(
                            session.bookingId,
                          ),
                        );
                      },
                    ),
                  ],

                  // ── Upcoming sessions (actionable lists only) ──────────
                  if (success.upcomingSessions.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: TutorDashboardSection(
                        title: l10n.upcomingSessionsSectionTitle,
                      ),
                    ),
                    SliverList.builder(
                      itemCount: success.upcomingSessions.length,
                      itemBuilder: (_, i) {
                        final session = success.upcomingSessions[i];
                        final canJoin =
                            session.effectiveLifecycleStatus.canJoinSession;
                        final cancelInProgress =
                            success.sessionCancelInProgress ==
                            session.bookingId;
                        final acceptInProgress =
                            success.bookingRequestActionInProgress ==
                            session.bookingId;
                        final joinInProgress =
                            success.joinInProgress == session.id;
                        return TutorSessionCompactCard(
                          session: session,
                          studentDisplayName: _studentDisplayName(
                            context,
                            session.studentId,
                          ),
                          now: DateTime.now(),
                          isLoading: cancelInProgress,
                          isJoinLoading: joinInProgress,
                          viewerUserId: widget.viewerAuthUserId,
                          onTap: widget.onSessionDetailRequested == null
                              ? null
                              : () => _openSessionDetail(session.bookingId),
                          onJoin: canJoin ? () => _requestJoin(session) : null,
                          showCancelInOverflowMenu: true,
                          onCancel:
                              canTeacherCancelQuranSession(session) &&
                                  !cancelInProgress &&
                                  !acceptInProgress
                              ? () => _confirmTutorCancelSession(session)
                              : null,
                        );
                      },
                    ),
                  ],

                  // ── Bookable times ─────────────────────────────────────
                  if (success.showFridayReviewBanner)
                    SliverToBoxAdapter(
                      child: FridayReviewReminderBanner(
                        onReview: () {
                          widget.schedulingAnalytics?.onFridayReviewBannerTapped
                              ?.call(
                                _schedulingAnalyticsBase(
                                  success,
                                  extra: const {'action': 'review'},
                                ),
                              );
                          _openManageSchedule(source: 'friday_banner');
                        },
                        onDismiss: () {
                          widget
                              .schedulingAnalytics
                              ?.onFridayReviewBannerDismissed
                              ?.call(
                                _schedulingAnalyticsBase(
                                  success,
                                  extra: const {'action': 'dismiss'},
                                ),
                              );
                          context.read<TeacherDashboardBloc>().add(
                            FridayReviewBannerDismissed(
                              teacherId: widget.teacherId,
                            ),
                          );
                        },
                      ),
                    ),
                  if (success.weekScopedDashboard)
                    _BookableTimesWeekScopedSection(
                      thisWeekSlots: success.thisWeekAvailability,
                      nextWeekSlots: success.nextWeekAvailability,
                      isUpdatingAvailability: success.isUpdatingAvailability,
                      scheduleActionLabel: widget.onManageSchedule != null
                          ? l10n.editWeeklyTemplate
                          : null,
                      onManageSchedule: widget.onManageSchedule != null
                          ? () => _openManageSchedule(source: 'bookable_header')
                          : null,
                      buildSlot: (context, slot, showDivider) => _buildSlotTile(
                        context,
                        slot,
                        showDivider: showDivider,
                      ),
                      onWeekScopeChanged: (section, slotCount) {
                        widget.schedulingAnalytics?.onWeekViewOpened?.call(
                          _schedulingAnalyticsBase(
                            success,
                            extra: {
                              'section': section,
                              'slot_count': slotCount,
                              'interaction': 'scope_selected',
                            },
                          ),
                        );
                      },
                    )
                  else
                    _BookableTimesWeekSection(
                      title: l10n.bookableTimesSectionTitle,
                      slots: success.availability,
                      isUpdatingAvailability: success.isUpdatingAvailability,
                      scheduleActionLabel: widget.onManageSchedule != null
                          ? l10n.editWeeklyTemplate
                          : null,
                      onManageSchedule: widget.onManageSchedule != null
                          ? () => _openManageSchedule(source: 'bookable_header')
                          : null,
                      buildSlot: (context, slot, showDivider) => _buildSlotTile(
                        context,
                        slot,
                        showDivider: showDivider,
                      ),
                    ),
                  SliverPadding(
                    padding: EdgeInsets.only(
                      bottom: TilawaComfortableReachPadding.resolve(context),
                    ),
                    sliver: const SliverToBoxAdapter(child: SizedBox.shrink()),
                  ),
                ],
              ),
            ),
          },
        ),
      ),
    );
  }

  Widget _buildSlotTile(
    BuildContext context,
    TeacherAvailability slot, {
    required bool showDivider,
  }) {
    final tile = _SlotTile(
      slot: slot,
      timeOnly: true,
      showDivider: showDivider,
      onRemove: () => _confirmAndBlockSlot(context, slot),
    );

    if (!_enterAnimatedSlotIds.contains(slot.slotId)) return tile;

    return _EnterAnimatedSlotTile(
      key: ValueKey('enter-${slot.slotId}'),
      onComplete: () {
        if (mounted) {
          setState(() => _enterAnimatedSlotIds.remove(slot.slotId));
        }
      },
      child: tile,
    );
  }

  void _showDeleteUndoToast(
    BuildContext context,
    TeacherAvailability slot, {
    required int pendingDeleteCount,
  }) {
    final l10n = context.quranSessionsL10n;
    final locale = Localizations.localeOf(context).languageCode;
    final timeFmt = DateFormat('EEE d MMM، h:mm a', locale);
    final timeLabel = timeFmt.format(slot.startsAt.toLocal());
    final message = pendingDeleteCount > 1
        ? l10n.deleteSlotRemovedSnackBarWithPending(
            timeLabel,
            pendingDeleteCount,
          )
        : l10n.deleteSlotRemovedSnackBar(timeLabel);

    TilawaFeedback.showActionable(
      context,
      message: message,
      variant: TilawaFeedbackVariant.success,
      duration: _undoSnackDuration,
      dedupeKey: _slotUndoDedupeKey,
      actions: <TilawaFeedbackAction>[
        TilawaFeedbackAction(
          label: l10n.deleteSlotUndo,
          onPressed: () {
            final current = context.read<TeacherDashboardBloc>().state;
            if (current is! TeacherDashboardSuccess) return;
            final undoId = current.undoableSlotId;
            if (undoId == null) return;

            setState(() => _enterAnimatedSlotIds.add(undoId));
            context.read<TeacherDashboardBloc>().add(
              AvailabilitySlotDeleteUndone(slotId: undoId),
            );
          },
        ),
      ],
    );
  }

  void _dismissSlotUndoToast(BuildContext context) {
    TilawaFeedback.dismiss(context, dedupeKey: _slotUndoDedupeKey);
  }

  Future<void> _confirmAndBlockSlot(
    BuildContext context,
    TeacherAvailability slot,
  ) async {
    final l10n = context.quranSessionsL10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteSlotConfirmTitle),
        content: Text(l10n.deleteSlotConfirmMessage),
        actions: [
          TilawaButton(
            text: l10n.cancel,
            variant: TilawaButtonVariant.ghost,
            size: TilawaButtonSize.small,
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          TilawaButton(
            text: l10n.deleteSlotConfirm,
            variant: TilawaButtonVariant.dangerOutline,
            size: TilawaButtonSize.small,
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    context.read<TeacherDashboardBloc>().add(
      AvailabilitySlotRemoved(teacherId: widget.teacherId, slot: slot),
    );
  }

  Future<void> _openManageSchedule({String source = 'app_bar'}) async {
    final openEditor = widget.onManageSchedule;
    if (openEditor == null) return;
    final state = context.read<TeacherDashboardBloc>().state;
    if (state is TeacherDashboardSuccess) {
      widget.schedulingAnalytics?.onWeeklyTemplateOpened?.call(
        _schedulingAnalyticsBase(state, extra: {'source': source}),
      );
    }
    await openEditor();
    if (!mounted) return;
    await _reload();
  }

  Future<void> _openMeetingLinkSettings() async {
    final builder = widget.meetingUrlSettingsBuilder;
    if (builder == null) return;

    await showTilawaModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: TilawaBottomSheetScaffold.modalShape(context),
      builder: (sheetContext) {
        final tokens = Theme.of(sheetContext).tokens;
        return TilawaBottomSheetScaffold(
          topBar: TilawaBottomSheetTitleRow(
            title:
                sheetContext.quranSessionsL10n.teacherExternalMeetingUrlLabel,
          ),
          children: [
            Padding(
              padding: TilawaBottomSheetScaffold.resolvedBodyPadding(
                sheetContext,
              ),
              child: builder(sheetContext),
            ),
            SizedBox(height: tokens.spaceSmall),
          ],
        );
      },
    );
  }

  String _studentDisplayName(BuildContext context, String studentId) {
    return widget.resolveStudentName?.call(studentId) ??
        context.quranSessionsL10n.tutorDashboardStudentFallback;
  }

  QuranSession? _findSession(
    TeacherDashboardSuccess state,
    String sessionId,
  ) {
    for (final session in state.upcomingSessions) {
      if (session.id == sessionId) {
        return session;
      }
    }
    return null;
  }

  bool _isExternalMeeting(QuranSession session) {
    if (session.callProviderKind != SessionCallProviderKind.external) {
      return false;
    }
    final url = session.joinUrl?.trim();
    return url?.isNotEmpty ?? false;
  }

  Future<void> _requestJoin(QuranSession session) async {
    if (_isExternalMeeting(session)) {
      final confirmed = await showExternalMeetingJoinSheet(
        context,
        meetingUrl: session.joinUrl!,
      );
      if (!confirmed || !mounted) return;
    }
    context.read<TeacherDashboardBloc>().add(
      TeacherDashboardSessionJoinRequested(sessionId: session.id),
    );
  }

  Future<void> _openSessionDetail(String bookingId) async {
    final openDetail = widget.onSessionDetailRequested;
    if (openDetail == null) return;
    final shouldReload = await openDetail(bookingId);
    if (!mounted || shouldReload != true) return;
    await _reload();
  }

  Future<void> _confirmRejectBookingRequest(String bookingId) async {
    final result = await showTutorRejectBookingSheet(context);
    if (result == null || !mounted) return;
    context.read<TeacherDashboardBloc>().add(
      TeacherBookingRequestRejected(
        bookingId: bookingId,
        reason: result.reason,
      ),
    );
  }

  Future<void> _confirmTutorCancelSession(QuranSession session) async {
    final confirmed = await showTutorCancelSessionDialog(context);
    if (!confirmed || !mounted) return;
    context.read<TeacherDashboardBloc>().add(
      TeacherSessionCancelled(
        bookingId: session.bookingId,
        reason: tutorCancelSessionReason,
      ),
    );
  }

  void _maybeLogWeekView(TeacherDashboardSuccess state) {
    if (_loggedWeekView) return;
    _loggedWeekView = true;
    final analytics = widget.schedulingAnalytics?.onWeekViewOpened;
    if (analytics == null) return;
    if (state.weekScopedDashboard) {
      analytics(
        _schedulingAnalyticsBase(
          state,
          extra: {
            'section': 'this_week',
            'slot_count': state.thisWeekAvailability.length,
            'interaction': 'dashboard_load',
          },
        ),
      );
    } else {
      analytics(
        _schedulingAnalyticsBase(
          state,
          extra: {
            'section': 'horizon',
            'slot_count': state.availability.length,
          },
        ),
      );
    }
  }

  void _maybeLogFridayBanner(TeacherDashboardSuccess state) {
    if (!state.showFridayReviewBanner || _loggedFridayBanner) return;
    _loggedFridayBanner = true;
    widget.schedulingAnalytics?.onFridayReviewBannerShown?.call(
      _schedulingAnalyticsBase(
        state,
        extra: {
          'next_week_slot_count': state.nextWeekAvailability.length,
          'this_week_slot_count': state.thisWeekAvailability.length,
        },
      ),
    );
  }

  Map<String, Object> _schedulingAnalyticsBase(
    TeacherDashboardSuccess state, {
    Map<String, Object>? extra,
  }) {
    return {
      'scheduling_mode': state.schedulingConfig.schedulingMode.storageKey,
      'policy_version': state.schedulingConfig.policyVersion,
      if (state.marketCountryCode != null)
        'market_code': state.marketCountryCode!,
      ...?extra,
    };
  }

  int _bookableOpenSlotsCount(TeacherDashboardSuccess state) {
    final slots = state.weekScopedDashboard
        ? state.thisWeekAvailability
        : state.availability;
    return slots.where((slot) => !slot.isBooked).length;
  }

  Future<void> _reload() async {
    final bloc = context.read<TeacherDashboardBloc>();
    final wasSuccess = bloc.state is TeacherDashboardSuccess;

    // Subscribe before dispatch so we never complete on the pre-reload state.
    final Future<void> reloadDone = bloc.stream
        .firstWhere(
          (s) {
            if (wasSuccess) {
              return (s is TeacherDashboardSuccess && !s.isRefreshing) ||
                  s is TeacherDashboardEmpty ||
                  s is TeacherDashboardFailure;
            }
            return s is TeacherDashboardSuccess ||
                s is TeacherDashboardEmpty ||
                s is TeacherDashboardFailure;
          },
          orElse: () => bloc.state,
        )
        .then((_) {});

    bloc.add(TeacherDashboardLoadRequested(teacherId: widget.teacherId));
    await reloadDone;
  }
}

// ── Enter animation (undo restore only; removal is instant) ───────────────────

class _EnterAnimatedSlotTile extends StatefulWidget {
  const _EnterAnimatedSlotTile({
    super.key,
    required this.child,
    required this.onComplete,
  });

  final Widget child;
  final VoidCallback onComplete;

  @override
  State<_EnterAnimatedSlotTile> createState() => _EnterAnimatedSlotTileState();
}

class _EnterAnimatedSlotTileState extends State<_EnterAnimatedSlotTile>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 200);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _duration,
  )..forward().whenComplete(widget.onComplete);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: SizeTransition(
        sizeFactor: CurvedAnimation(parent: _controller, curve: Curves.easeOut),
        alignment: Alignment.topCenter,
        child: widget.child,
      ),
    );
  }
}

// ── Slot tile ─────────────────────────────────────────────────────────────────

class _SlotTile extends StatelessWidget {
  const _SlotTile({
    required this.slot,
    required this.onRemove,
    this.timeOnly = false,
    this.showDivider = true,
  });

  final TeacherAvailability slot;
  final bool timeOnly;
  final VoidCallback onRemove;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final locale = Localizations.localeOf(context).languageCode;
    final dateFmt = DateFormat('EEE d MMM، h:mm a', locale);
    final timeFmt = DateFormat('h:mm a', locale);
    final scheme = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).tokens;
    final settingsTokens = Theme.of(context).componentTokens.settingsGroup;

    return TilawaCompactListRow(
      showDivider: showDivider,
      leading: Icon(
        slot.isBooked ? Icons.lock_outline : Icons.schedule,
        size: settingsTokens.tileIconSize,
        color: slot.isBooked ? scheme.primary : scheme.onSurfaceVariant,
      ),
      title: timeOnly
          ? timeFmt.format(slot.startsAt.toLocal())
          : dateFmt.format(slot.startsAt.toLocal()),
      subtitle: slot.isBooked ? l10n.slotBooked : l10n.slotAvailable,
      subtitleStyle:
          tilawaResolveTextRole(
            Theme.of(context).textTheme,
            settingsTokens.tileSubtitleTextRole,
          ).copyWith(
            fontWeight: FontWeight.w500,
            color: slot.isBooked ? scheme.primary : scheme.tertiary,
            height: 1.2,
          ),
      trailing: slot.isBooked
          ? null
          : _BlockSlotTrailing(
              onRemove: onRemove,
              blockTooltip: l10n.deleteSlot,
              minInteractiveDimension: tokens.minInteractiveDimension,
              iconSizeSmall: tokens.iconSizeSmall,
            ),
    );
  }
}

class _BlockSlotTrailing extends StatelessWidget {
  const _BlockSlotTrailing({
    required this.onRemove,
    required this.blockTooltip,
    required this.minInteractiveDimension,
    required this.iconSizeSmall,
  });

  final VoidCallback onRemove;
  final String blockTooltip;
  final double minInteractiveDimension;
  final double iconSizeSmall;

  static const _visualDensity = VisualDensity.compact;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.block_outlined),
      tooltip: blockTooltip,
      onPressed: onRemove,
      visualDensity: _visualDensity,
      constraints: BoxConstraints.tightFor(
        width: minInteractiveDimension,
        height: minInteractiveDimension,
      ),
      padding: EdgeInsets.zero,
    );
  }
}

// ── Bookable section header trailing (schedule edit + sync spinner) ─────────

class _BookableSectionTrailing extends StatelessWidget {
  const _BookableSectionTrailing({
    required this.isUpdatingAvailability,
    this.scheduleActionLabel,
    this.onManageSchedule,
  });

  final bool isUpdatingAvailability;
  final String? scheduleActionLabel;
  final VoidCallback? onManageSchedule;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final children = <Widget>[];

    if (isUpdatingAvailability) {
      children.add(
        SizedBox(
          width: tokens.iconSizeSmall,
          height: tokens.iconSizeSmall,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final label = scheduleActionLabel;
    final onSchedule = onManageSchedule;
    if (label != null && onSchedule != null) {
      children.add(
        TeacherDashboardScheduleSection(
          actionLabel: label,
          onManageSchedule: onSchedule,
        ),
      );
    }

    if (children.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: tokens.spaceExtraSmall,
      children: children,
    );
  }
}

// ── Bookable times (week-scoped, single scope at a time) ────────────────────

enum _BookableWeekScope { thisWeek, nextWeek }

_BookableWeekScope _bookableWeekScopeFromTabIndex(int index) =>
    index == 0 ? _BookableWeekScope.thisWeek : _BookableWeekScope.nextWeek;

class _BookableTimesWeekScopedSection extends StatefulWidget {
  const _BookableTimesWeekScopedSection({
    required this.thisWeekSlots,
    required this.nextWeekSlots,
    required this.isUpdatingAvailability,
    required this.buildSlot,
    this.onWeekScopeChanged,
    this.scheduleActionLabel,
    this.onManageSchedule,
  });

  final List<TeacherAvailability> thisWeekSlots;
  final List<TeacherAvailability> nextWeekSlots;
  final bool isUpdatingAvailability;
  final Widget Function(
    BuildContext context,
    TeacherAvailability slot,
    bool showDivider,
  )
  buildSlot;
  final void Function(String section, int slotCount)? onWeekScopeChanged;
  final String? scheduleActionLabel;
  final VoidCallback? onManageSchedule;

  @override
  State<_BookableTimesWeekScopedSection> createState() =>
      _BookableTimesWeekScopedSectionState();
}

class _BookableTimesWeekScopedSectionState
    extends State<_BookableTimesWeekScopedSection>
    with SingleTickerProviderStateMixin {
  late final TabController _weekTabController;
  _BookableWeekScope _scope = _BookableWeekScope.thisWeek;

  @override
  void initState() {
    super.initState();
    _weekTabController = TabController(length: 2, vsync: this);
    _weekTabController.addListener(_onWeekTabChanged);
  }

  @override
  void dispose() {
    _weekTabController.removeListener(_onWeekTabChanged);
    _weekTabController.dispose();
    super.dispose();
  }

  void _onWeekTabChanged() {
    if (_weekTabController.indexIsChanging) return;
    _applyScope(_bookableWeekScopeFromTabIndex(_weekTabController.index));
  }

  void _applyScope(_BookableWeekScope next) {
    if (next == _scope) return;
    final slotCount = switch (next) {
      _BookableWeekScope.thisWeek => widget.thisWeekSlots.length,
      _BookableWeekScope.nextWeek => widget.nextWeekSlots.length,
    };
    final section = switch (next) {
      _BookableWeekScope.thisWeek => 'this_week',
      _BookableWeekScope.nextWeek => 'next_week',
    };
    setState(() => _scope = next);
    widget.onWeekScopeChanged?.call(section, slotCount);
  }

  List<TeacherAvailability> get _activeSlots => switch (_scope) {
    _BookableWeekScope.thisWeek => widget.thisWeekSlots,
    _BookableWeekScope.nextWeek => widget.nextWeekSlots,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final locale = Localizations.localeOf(context).languageCode;
    final dayLabelFmt = DateFormat('EEEE, d MMMM', locale);
    final tokens = Theme.of(context).tokens;
    final scheme = Theme.of(context).colorScheme;
    final emptyMessage = switch (_scope) {
      _BookableWeekScope.thisWeek => l10n.bookableTimesEmptyThisWeek,
      _BookableWeekScope.nextWeek => l10n.bookableTimesEmptyNextWeek,
    };

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: TutorDashboardSection(
            title: l10n.bookableTimesWeekScopedTitle,
            variant: TutorDashboardSectionVariant.secondary,
            trailing: _BookableSectionTrailing(
              isUpdatingAvailability: widget.isUpdatingAvailability,
              scheduleActionLabel: widget.scheduleActionLabel,
              onManageSchedule: widget.onManageSchedule,
            ),
          ),
        ),
        SliverPersistentHeader(
          pinned: true,
          delegate: _PinnedWeekScopeTabBarDelegate(
            tabController: _weekTabController,
            thisWeekLabel: l10n.bookableTimesThisWeekSectionTitle,
            nextWeekLabel: l10n.bookableTimesNextWeekSectionTitle,
          ),
        ),
        if (_activeSlots.isEmpty)
          SliverToBoxAdapter(
            child: TeacherDashboardInlineEmptyState(
              title: emptyMessage,
            ),
          )
        else
          SliverToBoxAdapter(
            child: DateGroupedSlotsLayout(
              key: ValueKey(_scope),
              slots: _activeSlots,
              padding: EdgeInsetsDirectional.only(
                start: tokens.spaceLarge,
                end: tokens.spaceLarge,
                top: tokens.spaceMedium,
              ),
              belowTabsBuilder: (context, selectedDay) => Text(
                l10n.bookableTimesSelectedDayCaption(
                  dayLabelFmt.format(selectedDay),
                ),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              slotsForDayBuilder: (context, daySlots) => Padding(
                padding: EdgeInsets.only(bottom: tokens.spaceExtraLarge),
                child: Column(
                  children: [
                    for (var i = 0; i < daySlots.length; i++)
                      widget.buildSlot(
                        context,
                        daySlots[i],
                        i < daySlots.length - 1,
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PinnedWeekScopeTabBarDelegate extends SliverPersistentHeaderDelegate {
  _PinnedWeekScopeTabBarDelegate({
    required this.tabController,
    required this.thisWeekLabel,
    required this.nextWeekLabel,
  });

  final TabController tabController;
  final String thisWeekLabel;
  final String nextWeekLabel;

  @override
  double get minExtent => _extentFor(null);

  @override
  double get maxExtent => _extentFor(null);

  double _extentFor(BuildContext? context) {
    final double vertical = context != null
        ? Theme.of(context).tokens.spaceSmall * 2
        : 16;
    return vertical + kTextTabBarHeight;
  }

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = theme.tokens;
    final isStuck = shrinkOffset > 0;

    return Material(
      color: isStuck ? scheme.surface : theme.scaffoldBackgroundColor,
      elevation: isStuck ? 1 : 0,
      shadowColor: scheme.shadow.withValues(alpha: 0.1),
      child: DecoratedBox(
        decoration: isStuck
            ? BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: scheme.outlineVariant.withValues(alpha: 0.85),
                  ),
                ),
              )
            : const BoxDecoration(),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            tokens.spaceLarge,
            tokens.spaceSmall,
            tokens.spaceLarge,
            tokens.spaceSmall,
          ),
          child: TilawaTabBar(
            controller: tabController,
            tabs: [
              Tab(text: thisWeekLabel),
              Tab(text: nextWeekLabel),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedWeekScopeTabBarDelegate old) {
    return old.tabController != tabController ||
        old.thisWeekLabel != thisWeekLabel ||
        old.nextWeekLabel != nextWeekLabel ||
        old.tabController.index != tabController.index;
  }
}

// ── Bookable times week section (legacy 14-day horizon) ─────────────────────

class _BookableTimesWeekSection extends StatelessWidget {
  const _BookableTimesWeekSection({
    required this.title,
    required this.slots,
    required this.isUpdatingAvailability,
    required this.buildSlot,
    this.scheduleActionLabel,
    this.onManageSchedule,
  });

  final String title;
  final List<TeacherAvailability> slots;
  final bool isUpdatingAvailability;
  final Widget Function(
    BuildContext context,
    TeacherAvailability slot,
    bool showDivider,
  )
  buildSlot;
  final String? scheduleActionLabel;
  final VoidCallback? onManageSchedule;

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: TutorDashboardSection(
            title: title,
            variant: TutorDashboardSectionVariant.secondary,
            trailing: _BookableSectionTrailing(
              isUpdatingAvailability: isUpdatingAvailability,
              scheduleActionLabel: scheduleActionLabel,
              onManageSchedule: onManageSchedule,
            ),
          ),
        ),
        if (slots.isEmpty)
          SliverToBoxAdapter(
            child: Builder(
              builder: (context) {
                final l10n = context.quranSessionsL10n;
                return TeacherDashboardInlineEmptyState(
                  title: l10n.bookableTimesEmptyHorizonTitle,
                );
              },
            ),
          )
        else
          SliverToBoxAdapter(
            child: Builder(
              builder: (context) {
                final tokens = Theme.of(context).tokens;
                return DateGroupedSlotsLayout(
                  slots: slots,
                  padding: EdgeInsetsDirectional.only(
                    start: tokens.spaceLarge,
                    end: tokens.spaceLarge,
                  ),
                  slotsForDayBuilder: (context, daySlots) => Padding(
                    padding: EdgeInsets.only(bottom: tokens.spaceExtraLarge),
                    child: Column(
                      children: [
                        for (var i = 0; i < daySlots.length; i++)
                          buildSlot(
                            context,
                            daySlots[i],
                            i < daySlots.length - 1,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

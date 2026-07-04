import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:quran_sessions/l10n/quran_sessions_localizations.dart';
import 'package:quran_sessions/quran_sessions.dart';

import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../failure_ui/quran_sessions_failure_body.dart';
import '../utils/teacher_availability_by_date.dart';
import '../widgets/date_grouped_day_tab_bar.dart';
import '../widgets/friday_review_reminder_banner.dart';
import '../widgets/teacher_dashboard_inline_empty_state.dart';
import '../widgets/teacher_dashboard_loading_skeleton.dart';
import '../widgets/teacher_dashboard_schedule_section.dart';
import '../widgets/teacher_dashboard_summary_stats.dart';
import '../widgets/tutor_dashboard_section.dart';
import '../widgets/tutor_session_compact_card.dart';

enum _BookableWeekScope { thisWeek, nextWeek }

_BookableWeekScope _bookableWeekScopeFromTabIndex(int index) =>
    index == 0 ? _BookableWeekScope.thisWeek : _BookableWeekScope.nextWeek;

enum _TeacherDashboardCategory {
  bookingRequests,
  upcomingSessions,
  bookableTimes,
}

enum _TeacherDashboardCategoryViewMode { grid, list }

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
  _TeacherDashboardCategoryViewMode _categoryViewMode =
      _TeacherDashboardCategoryViewMode.grid;

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
              return;
            }

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
              const TeacherDashboardLoadingSkeleton(),
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
              backgroundColor: Theme.of(context).colorScheme.surface,
              color: Theme.of(context).colorScheme.primary,
              onRefresh: () async => _reload(),
              child: Stack(
                children: [
                  CustomScrollView(
                    slivers: [
                      // Session lists are capped so bookable slots stay
                      // reachable.
                      SliverToBoxAdapter(
                        child: TeacherDashboardSummaryStats(
                          sectionTitle: l10n.teacherDashboardSummaryTitle,
                          pendingRequestsCount:
                              success.pendingBookingRequests.length,
                          upcomingSessionsCount:
                              success.upcomingSessions.length,
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

                      SliverToBoxAdapter(
                        child: _TeacherDashboardCategoriesSection(
                          viewMode: _categoryViewMode,
                          categories: _categoryItems(context, success),
                          onViewModeChanged: (viewMode) {
                            setState(() => _categoryViewMode = viewMode);
                          },
                          onCategorySelected: _openDashboardCategory,
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: Theme.of(context).tokens.spaceExtraLarge,
                        ),
                      ),
                    ],
                  ),
                  // Post-mutation reloads keep the dashboard interactive;
                  // this thin bar is the only signal a refresh is running
                  // (pull-to-refresh has its own indicator).
                  if (success.isRefreshing)
                    PositionedDirectional(
                      top: 0,
                      start: 0,
                      end: 0,
                      child: Semantics(
                        label: l10n.teacherDashboardRefreshingLabel,
                        liveRegion: true,
                        child: const LinearProgressIndicator(minHeight: 2),
                      ),
                    ),
                ],
              ),
            ),
          },
        ),
      ),
    );
  }

  List<_TeacherDashboardCategoryItem> _categoryItems(
    BuildContext context,
    TeacherDashboardSuccess success,
  ) {
    final l10n = context.quranSessionsL10n;
    return [
      _TeacherDashboardCategoryItem(
        category: _TeacherDashboardCategory.bookingRequests,
        title: l10n.teacherPendingBookingRequestsSectionTitle,
        subtitle: l10n.teacherDashboardBookingRequestsCategorySubtitle,
        count: success.pendingBookingRequests.length,
        countLabel: l10n.teacherDashboardStatPendingRequests,
        icon: Icons.inbox_outlined,
        semanticTint: TilawaSemanticTint.ink,
      ),
      _TeacherDashboardCategoryItem(
        category: _TeacherDashboardCategory.upcomingSessions,
        title: l10n.upcomingSessionsSectionTitle,
        subtitle: l10n.teacherDashboardUpcomingSessionsCategorySubtitle,
        count: success.upcomingSessions.length,
        countLabel: l10n.teacherDashboardStatUpcomingSessions,
        icon: Icons.event_outlined,
        semanticTint: TilawaSemanticTint.scholar,
      ),
      _TeacherDashboardCategoryItem(
        category: _TeacherDashboardCategory.bookableTimes,
        title: l10n.bookableTimesWeekScopedTitle,
        subtitle: l10n.teacherDashboardBookableTimesCategorySubtitle,
        count: _bookableOpenSlotsCount(success),
        countLabel: success.weekScopedDashboard
            ? l10n.teacherDashboardStatBookableSlotsThisWeek
            : l10n.teacherDashboardStatBookableSlotsHorizon,
        icon: Icons.schedule_outlined,
        semanticTint: TilawaSemanticTint.neutral,
      ),
    ];
  }

  Future<void> _openDashboardCategory(
    _TeacherDashboardCategory category,
  ) async {
    final bloc = context.read<TeacherDashboardBloc>();
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        settings: RouteSettings(name: 'teacher-dashboard-${category.name}'),
        builder: (_) => BlocProvider<TeacherDashboardBloc>.value(
          value: bloc,
          child: _TeacherDashboardCategoryScreen(
            category: category,
            teacherId: widget.teacherId,
            canManageSchedule: widget.onManageSchedule != null,
            onManageSchedule: _openManageSchedule,
            onReload: _reload,
            onRejectBookingRequest: _confirmRejectBookingRequest,
            onSessionDetailRequested: _openSessionDetail,
            onRequestJoin: _requestJoin,
            onCancelSession: _confirmTutorCancelSession,
            studentDisplayName: _studentDisplayName,
            buildSlotTile: _buildSlotTile,
            viewerAuthUserId: widget.viewerAuthUserId,
            schedulingAnalytics: widget.schedulingAnalytics,
          ),
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

class _TeacherDashboardCategoryItem {
  const _TeacherDashboardCategoryItem({
    required this.category,
    required this.title,
    required this.subtitle,
    required this.count,
    required this.countLabel,
    required this.icon,
    required this.semanticTint,
  });

  final _TeacherDashboardCategory category;
  final String title;
  final String subtitle;
  final int count;
  final String countLabel;
  final IconData icon;
  final TilawaSemanticTint semanticTint;
}

class _TeacherDashboardCategoriesSection extends StatelessWidget {
  const _TeacherDashboardCategoriesSection({
    required this.viewMode,
    required this.categories,
    required this.onViewModeChanged,
    required this.onCategorySelected,
  });

  final _TeacherDashboardCategoryViewMode viewMode;
  final List<_TeacherDashboardCategoryItem> categories;
  final ValueChanged<_TeacherDashboardCategoryViewMode> onViewModeChanged;
  final ValueChanged<_TeacherDashboardCategory> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final l10n = context.quranSessionsL10n;

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        tokens.spaceLarge,
        tokens.spaceLarge,
        tokens.spaceLarge,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          TilawaSectionHeader(
            title: l10n.teacherDashboardCategoriesTitle,
            subtitle: l10n.teacherDashboardCategoriesSubtitle,
            padding: EdgeInsets.zero,
            trailing: _CategoryViewModeToggle(
              viewMode: viewMode,
              onViewModeChanged: onViewModeChanged,
            ),
          ),
          SizedBox(height: tokens.spaceMedium),
          if (viewMode == _TeacherDashboardCategoryViewMode.grid)
            TilawaContentGrid(
              targetItemExtent: 220,
              childAspectRatio: 0.95,
              mainAxisSpacing: tokens.spaceSmall,
              crossAxisSpacing: tokens.spaceSmall,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final item = categories[index];
                return _TeacherDashboardCategoryCard(
                  item: item,
                  compact: true,
                  onTap: () => onCategorySelected(item.category),
                );
              },
            )
          else
            Column(
              spacing: tokens.spaceSmall,
              children: [
                for (final item in categories)
                  _TeacherDashboardCategoryCard(
                    item: item,
                    compact: false,
                    onTap: () => onCategorySelected(item.category),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _CategoryViewModeToggle extends StatelessWidget {
  const _CategoryViewModeToggle({
    required this.viewMode,
    required this.onViewModeChanged,
  });

  final _TeacherDashboardCategoryViewMode viewMode;
  final ValueChanged<_TeacherDashboardCategoryViewMode> onViewModeChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final isGrid = viewMode == _TeacherDashboardCategoryViewMode.grid;
    final label = isGrid
        ? l10n.teacherDashboardShowAsList
        : l10n.teacherDashboardShowAsGrid;

    return TilawaIconActionButton(
      icon: isGrid ? Icons.view_list_rounded : Icons.grid_view_rounded,
      tooltip: label,
      semanticLabel: label,
      onTap: () {
        onViewModeChanged(
          isGrid
              ? _TeacherDashboardCategoryViewMode.list
              : _TeacherDashboardCategoryViewMode.grid,
        );
      },
    );
  }
}

class _TeacherDashboardCategoryCard extends StatelessWidget {
  const _TeacherDashboardCategoryCard({
    required this.item,
    required this.compact,
    required this.onTap,
  });

  final _TeacherDashboardCategoryItem item;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final scheme = theme.colorScheme;
    final l10n = context.quranSessionsL10n;

    final count = Text(
      '${item.count}',
      style: theme.textTheme.titleLarge?.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.w800,
        height: 1.1,
      ),
    );

    final countLabel = Text(
      item.countLabel,
      maxLines: compact ? 2 : 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.bodySmall?.copyWith(
        color: scheme.onSurfaceVariant,
        height: 1.25,
      ),
      textAlign: TextAlign.start,
    );

    final title = Text(
      item.title,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.titleSmall?.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.w700,
        height: 1.25,
      ),
      textAlign: TextAlign.start,
    );

    final subtitle = Text(
      item.subtitle,
      maxLines: compact ? 2 : 3,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.bodySmall?.copyWith(
        color: scheme.onSurfaceVariant,
        height: 1.35,
      ),
      textAlign: TextAlign.start,
    );

    if (!compact) {
      return TilawaCard(
        onTap: onTap,
        padding: EdgeInsets.all(tokens.spaceMedium),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: tokens.spaceMedium,
          children: [
            TilawaIconBox(
              icon: item.icon,
              variant: TilawaIconBoxVariant.tinted,
              semanticTint: item.semanticTint,
              size: tokens.iconSizeMedium,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: tokens.spaceExtraSmall,
                children: [
                  title,
                  subtitle,
                  Row(
                    spacing: tokens.spaceExtraSmall,
                    children: [
                      count,
                      Flexible(child: countLabel),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_rounded,
              size: tokens.iconSizeSmall,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
      );
    }

    return TilawaCard(
      onTap: onTap,
      expandHeight: true,
      padding: EdgeInsets.all(tokens.spaceMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TilawaIconBox(
                icon: item.icon,
                variant: TilawaIconBoxVariant.tinted,
                semanticTint: item.semanticTint,
                size: tokens.iconSizeMedium,
              ),
              const Spacer(),
              count,
            ],
          ),
          SizedBox(height: tokens.spaceSmall),
          title,
          SizedBox(height: tokens.spaceExtraSmall),
          subtitle,
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: tokens.spaceExtraSmall,
            children: [
              Text(
                l10n.teacherDashboardOpenCategory,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                size: tokens.iconSizeSmall,
                color: scheme.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TeacherDashboardCategoryScreen extends StatefulWidget {
  const _TeacherDashboardCategoryScreen({
    required this.category,
    required this.teacherId,
    required this.canManageSchedule,
    required this.onManageSchedule,
    required this.onReload,
    required this.onRejectBookingRequest,
    required this.onSessionDetailRequested,
    required this.onRequestJoin,
    required this.onCancelSession,
    required this.studentDisplayName,
    required this.buildSlotTile,
    required this.viewerAuthUserId,
    required this.schedulingAnalytics,
  });

  final _TeacherDashboardCategory category;
  final String teacherId;
  final bool canManageSchedule;
  final Future<void> Function({String source}) onManageSchedule;
  final Future<void> Function() onReload;
  final Future<void> Function(String bookingId) onRejectBookingRequest;
  final Future<void> Function(String bookingId) onSessionDetailRequested;
  final Future<void> Function(QuranSession session) onRequestJoin;
  final Future<void> Function(QuranSession session) onCancelSession;
  final String Function(BuildContext context, String studentId)
  studentDisplayName;
  final Widget Function(
    BuildContext context,
    TeacherAvailability slot, {
    required bool showDivider,
  })
  buildSlotTile;
  final String? viewerAuthUserId;
  final QuranSessionsSchedulingAnalyticsCallbacks? schedulingAnalytics;

  @override
  State<_TeacherDashboardCategoryScreen> createState() =>
      _TeacherDashboardCategoryScreenState();
}

class _TeacherDashboardCategoryScreenState
    extends State<_TeacherDashboardCategoryScreen>
    with SingleTickerProviderStateMixin {
  TabController? _bookableWeekTabController;
  _BookableWeekScope _bookableWeekScope = _BookableWeekScope.thisWeek;
  DateTime _bookableSelectedDay = localDayKey(DateTime.now());
  bool _loggedWeekView = false;
  bool _loggedFridayBanner = false;

  @override
  void dispose() {
    _bookableWeekTabController?.removeListener(_onBookableWeekTabChanged);
    _bookableWeekTabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;

    return QuranSessionsScaffold(
      title: _categoryTitle(l10n),
      actions: [
        if (widget.category == _TeacherDashboardCategory.bookableTimes &&
            widget.canManageSchedule)
          IconButton(
            icon: const Icon(Icons.edit_calendar_outlined),
            tooltip: l10n.editWeeklyTemplate,
            onPressed: () {
              widget.onManageSchedule(source: 'category_app_bar');
            },
          ),
      ],
      body: BlocBuilder<TeacherDashboardBloc, TeacherDashboardState>(
        builder: (context, state) => switch (state) {
          TeacherDashboardInitial() || TeacherDashboardLoading() =>
            const Center(child: CircularProgressIndicator()),
          TeacherDashboardEmpty() => _DashboardSetupEmptyState(
            canManageSchedule: widget.canManageSchedule,
            onManageSchedule: widget.onManageSchedule,
          ),
          TeacherDashboardFailure(:final failure) =>
            buildQuranSessionsFailureBody(
              context,
              failure: failure,
              onRetry: widget.onReload,
            ),
          TeacherDashboardSuccess success => _buildSuccess(context, success),
        },
      ),
    );
  }

  String _categoryTitle(QuranSessionsLocalizations l10n) {
    return switch (widget.category) {
      _TeacherDashboardCategory.bookingRequests =>
        l10n.teacherPendingBookingRequestsSectionTitle,
      _TeacherDashboardCategory.upcomingSessions =>
        l10n.upcomingSessionsSectionTitle,
      _TeacherDashboardCategory.bookableTimes =>
        l10n.bookableTimesWeekScopedTitle,
    };
  }

  Widget _buildSuccess(
    BuildContext context,
    TeacherDashboardSuccess success,
  ) {
    if (widget.category == _TeacherDashboardCategory.bookableTimes) {
      _maybeLogWeekView(success);
      _maybeLogFridayBanner(success);
    }

    return RefreshIndicator(
      backgroundColor: Theme.of(context).colorScheme.surface,
      color: Theme.of(context).colorScheme.primary,
      onRefresh: widget.onReload,
      child: CustomScrollView(
        slivers: switch (widget.category) {
          _TeacherDashboardCategory.bookingRequests =>
            _buildPendingRequestSlivers(context, success),
          _TeacherDashboardCategory.upcomingSessions =>
            _buildUpcomingSessionSlivers(context, success),
          _TeacherDashboardCategory.bookableTimes => _buildBookableTimeSlivers(
            context,
            success,
          ),
        },
      ),
    );
  }

  List<Widget> _buildPendingRequestSlivers(
    BuildContext context,
    TeacherDashboardSuccess success,
  ) {
    final l10n = context.quranSessionsL10n;
    final sessions = success.pendingBookingRequests;

    if (sessions.isEmpty) {
      return [
        _CategoryEmptySliver(
          icon: Icons.inbox_outlined,
          title: l10n.teacherPendingBookingRequestsEmptyTitle,
          subtitle: l10n.teacherPendingBookingRequestsEmptySubtitle,
        ),
      ];
    }

    return [
      _CategoryTopGapSliver(),
      SliverList.builder(
        itemCount: sessions.length,
        itemBuilder: (context, index) {
          final session = sessions[index];
          final inProgress =
              success.bookingRequestActionInProgress == session.bookingId;
          return TutorSessionCompactCard(
            session: session,
            studentDisplayName: widget.studentDisplayName(
              context,
              session.studentId,
            ),
            now: DateTime.now(),
            isLoading: inProgress,
            viewerUserId: widget.viewerAuthUserId,
            onAccept: () => context.read<TeacherDashboardBloc>().add(
              TeacherBookingRequestAccepted(bookingId: session.bookingId),
            ),
            onReject: () => widget.onRejectBookingRequest(session.bookingId),
          );
        },
      ),
      _CategoryBottomGapSliver(),
    ];
  }

  List<Widget> _buildUpcomingSessionSlivers(
    BuildContext context,
    TeacherDashboardSuccess success,
  ) {
    final l10n = context.quranSessionsL10n;
    final sessions = success.upcomingSessions;

    if (sessions.isEmpty) {
      return [
        _CategoryEmptySliver(
          icon: Icons.event_outlined,
          title: l10n.upcomingSessionsEmptyTitle,
          subtitle: l10n.upcomingSessionsEmptySubtitle,
        ),
      ];
    }

    return [
      _CategoryTopGapSliver(),
      SliverList.builder(
        itemCount: sessions.length,
        itemBuilder: (context, index) {
          final session = sessions[index];
          final canJoin = session.effectiveLifecycleStatus.canJoinSession;
          final cancelInProgress =
              success.sessionCancelInProgress == session.bookingId;
          final acceptInProgress =
              success.bookingRequestActionInProgress == session.bookingId;
          final joinInProgress = success.joinInProgress == session.id;
          return TutorSessionCompactCard(
            session: session,
            studentDisplayName: widget.studentDisplayName(
              context,
              session.studentId,
            ),
            now: DateTime.now(),
            isLoading: cancelInProgress,
            isJoinLoading: joinInProgress,
            viewerUserId: widget.viewerAuthUserId,
            onTap: () => widget.onSessionDetailRequested(session.bookingId),
            onJoin: canJoin ? () => widget.onRequestJoin(session) : null,
            showCancelInOverflowMenu: true,
            onCancel:
                canTeacherCancelQuranSession(session) &&
                    !cancelInProgress &&
                    !acceptInProgress
                ? () => widget.onCancelSession(session)
                : null,
          );
        },
      ),
      _CategoryBottomGapSliver(),
    ];
  }

  List<Widget> _buildBookableTimeSlivers(
    BuildContext context,
    TeacherDashboardSuccess success,
  ) {
    final slivers = <Widget>[
      if (success.showFridayReviewBanner)
        SliverToBoxAdapter(
          child: FridayReviewReminderBanner(
            onReview: () {
              widget.schedulingAnalytics?.onFridayReviewBannerTapped?.call(
                _schedulingAnalyticsBase(
                  success,
                  extra: const {'action': 'review'},
                ),
              );
              widget.onManageSchedule(source: 'friday_banner');
            },
            onDismiss: () {
              widget.schedulingAnalytics?.onFridayReviewBannerDismissed?.call(
                _schedulingAnalyticsBase(
                  success,
                  extra: const {'action': 'dismiss'},
                ),
              );
              context.read<TeacherDashboardBloc>().add(
                FridayReviewBannerDismissed(teacherId: widget.teacherId),
              );
            },
          ),
        ),
      if (widget.canManageSchedule)
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              Theme.of(context).tokens.spaceLarge,
              Theme.of(context).tokens.spaceMedium,
              Theme.of(context).tokens.spaceLarge,
              0,
            ),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: TeacherDashboardScheduleSection(
                actionLabel: context.quranSessionsL10n.editWeeklyTemplate,
                onManageSchedule: () {
                  widget.onManageSchedule(source: 'category_inline');
                },
              ),
            ),
          ),
        ),
    ];

    slivers.addAll(
      success.weekScopedDashboard
          ? _buildWeekScopedBookableSlivers(context, success)
          : _buildHorizonBookableSlivers(context, success),
    );
    return slivers;
  }

  void _ensureBookableWeekTabController() {
    if (_bookableWeekTabController != null) return;
    _bookableWeekTabController = TabController(length: 2, vsync: this);
    _bookableWeekTabController!.addListener(_onBookableWeekTabChanged);
  }

  void _onBookableWeekTabChanged() {
    final controller = _bookableWeekTabController;
    if (controller == null || controller.indexIsChanging) return;
    _applyBookableWeekScope(
      _bookableWeekScopeFromTabIndex(controller.index),
    );
  }

  void _applyBookableWeekScope(_BookableWeekScope next) {
    if (next == _bookableWeekScope) return;
    final blocState = context.read<TeacherDashboardBloc>().state;
    if (blocState is! TeacherDashboardSuccess) return;

    final slotCount = switch (next) {
      _BookableWeekScope.thisWeek => blocState.thisWeekAvailability.length,
      _BookableWeekScope.nextWeek => blocState.nextWeekAvailability.length,
    };
    final section = switch (next) {
      _BookableWeekScope.thisWeek => 'this_week',
      _BookableWeekScope.nextWeek => 'next_week',
    };

    setState(() {
      _bookableWeekScope = next;
      final grouped = groupTeacherAvailabilityByLocalDay(
        _activeBookableSlots(blocState),
      );
      if (grouped.days.isNotEmpty &&
          !grouped.days.contains(_bookableSelectedDay)) {
        _bookableSelectedDay = grouped.days.first;
      }
    });

    widget.schedulingAnalytics?.onWeekViewOpened?.call(
      _schedulingAnalyticsBase(
        blocState,
        extra: {
          'section': section,
          'slot_count': slotCount,
          'interaction': 'scope_selected',
        },
      ),
    );
  }

  List<TeacherAvailability> _activeBookableSlots(
    TeacherDashboardSuccess state,
  ) => switch (_bookableWeekScope) {
    _BookableWeekScope.thisWeek => state.thisWeekAvailability,
    _BookableWeekScope.nextWeek => state.nextWeekAvailability,
  };

  ({
    List<DateTime> days,
    Map<DateTime, List<TeacherAvailability>> byDay,
    DateTime selectedDay,
    List<TeacherAvailability> selectedDaySlots,
  })
  _bookableDayView(List<TeacherAvailability> slots) {
    final grouped = groupTeacherAvailabilityByLocalDay(slots);
    final selectedDay = grouped.days.contains(_bookableSelectedDay)
        ? _bookableSelectedDay
        : grouped.days.isEmpty
        ? localDayKey(DateTime.now())
        : grouped.days.first;

    return (
      days: grouped.days,
      byDay: grouped.byDay,
      selectedDay: selectedDay,
      selectedDaySlots: grouped.byDay[selectedDay] ?? const [],
    );
  }

  List<Widget> _buildWeekScopedBookableSlivers(
    BuildContext context,
    TeacherDashboardSuccess success,
  ) {
    final l10n = context.quranSessionsL10n;
    final locale = Localizations.localeOf(context).languageCode;
    final dayLabelFmt = DateFormat('EEEE, d MMMM', locale);
    final tokens = Theme.of(context).tokens;
    _ensureBookableWeekTabController();

    final activeSlots = _activeBookableSlots(success);
    final dayView = _bookableDayView(activeSlots);

    final empty = switch (_bookableWeekScope) {
      _BookableWeekScope.thisWeek => (
        title: l10n.bookableTimesEmptyThisWeekTitle,
        subtitle: l10n.bookableTimesEmptyThisWeekSubtitle,
      ),
      _BookableWeekScope.nextWeek => (
        title: l10n.bookableTimesEmptyNextWeekTitle,
        subtitle: l10n.bookableTimesEmptyNextWeekSubtitle,
      ),
    };

    return [
      SliverPersistentHeader(
        pinned: true,
        delegate: _PinnedBookableSlotsControlsDelegate(
          showTopDivider: false,
          title: l10n.bookableTimesWeekScopedTitle,
          isUpdatingAvailability: success.isUpdatingAvailability,
          weekTabController: _bookableWeekTabController,
          thisWeekLabel: l10n.bookableTimesThisWeekSectionTitle,
          nextWeekLabel: l10n.bookableTimesNextWeekSectionTitle,
          days: activeSlots.isEmpty ? null : dayView.days,
          selectedDay: dayView.selectedDay,
          onDaySelected: (day) => setState(() => _bookableSelectedDay = day),
          selectedDayCaption: activeSlots.isEmpty
              ? null
              : l10n.bookableTimesSelectedDayCaption(
                  dayLabelFmt.format(dayView.selectedDay),
                ),
        ),
      ),
      if (activeSlots.isEmpty)
        SliverToBoxAdapter(
          child: TeacherDashboardInlineEmptyState(
            icon: Icons.schedule_outlined,
            title: empty.title,
            subtitle: empty.subtitle,
          ),
        )
      else
        SliverPadding(
          padding: EdgeInsetsDirectional.only(
            start: tokens.spaceLarge,
            end: tokens.spaceLarge,
            bottom: tokens.spaceExtraLarge,
          ),
          sliver: SliverList.builder(
            itemCount: dayView.selectedDaySlots.length,
            itemBuilder: (context, index) {
              final slot = dayView.selectedDaySlots[index];
              return widget.buildSlotTile(
                context,
                slot,
                showDivider: index < dayView.selectedDaySlots.length - 1,
              );
            },
          ),
        ),
    ];
  }

  List<Widget> _buildHorizonBookableSlivers(
    BuildContext context,
    TeacherDashboardSuccess success,
  ) {
    final l10n = context.quranSessionsL10n;
    final tokens = Theme.of(context).tokens;
    final dayView = _bookableDayView(success.availability);

    return [
      SliverPersistentHeader(
        pinned: true,
        delegate: _PinnedBookableSlotsControlsDelegate(
          showTopDivider: false,
          title: l10n.bookableTimesSectionTitle,
          isUpdatingAvailability: success.isUpdatingAvailability,
          days: success.availability.isEmpty ? null : dayView.days,
          selectedDay: dayView.selectedDay,
          onDaySelected: (day) => setState(() => _bookableSelectedDay = day),
        ),
      ),
      if (success.availability.isEmpty)
        SliverToBoxAdapter(
          child: TeacherDashboardInlineEmptyState(
            icon: Icons.schedule_outlined,
            title: l10n.bookableTimesEmptyHorizonTitle,
            subtitle: l10n.bookableTimesEmptyHorizonSubtitle,
          ),
        )
      else
        SliverPadding(
          padding: EdgeInsetsDirectional.only(
            start: tokens.spaceLarge,
            end: tokens.spaceLarge,
            bottom: tokens.spaceExtraLarge,
          ),
          sliver: SliverList.builder(
            itemCount: dayView.selectedDaySlots.length,
            itemBuilder: (context, index) {
              final slot = dayView.selectedDaySlots[index];
              return widget.buildSlotTile(
                context,
                slot,
                showDivider: index < dayView.selectedDaySlots.length - 1,
              );
            },
          ),
        ),
    ];
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
            'interaction': 'category_open',
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
            'interaction': 'category_open',
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
}

class _DashboardSetupEmptyState extends StatelessWidget {
  const _DashboardSetupEmptyState({
    required this.canManageSchedule,
    required this.onManageSchedule,
  });

  final bool canManageSchedule;
  final Future<void> Function({String source}) onManageSchedule;

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final tokens = Theme.of(context).tokens;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(tokens.spaceLarge),
        child: TilawaEmptyState(
          icon: Icons.event_available_outlined,
          title: l10n.availabilitySetupHeadline,
          subtitle:
              '${l10n.availabilitySetupBenefitRecurring}  ·  '
              '${l10n.availabilitySetupBenefitTimezone}  ·  '
              '${l10n.availabilitySetupBenefitSelfBooking}',
          action: canManageSchedule
              ? TilawaButton(
                  text: l10n.availabilitySetupCta,
                  leadingIcon: const Icon(Icons.calendar_month_outlined),
                  onPressed: () {
                    onManageSchedule(source: 'empty_state');
                  },
                )
              : null,
        ),
      ),
    );
  }
}

class _CategoryEmptySliver extends StatelessWidget {
  const _CategoryEmptySliver({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;

    return SliverFillRemaining(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(tokens.spaceLarge),
          child: TilawaEmptyState(
            icon: icon,
            title: title,
            subtitle: subtitle,
          ),
        ),
      ),
    );
  }
}

class _CategoryTopGapSliver extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: SizedBox(height: Theme.of(context).tokens.spaceSmall),
    );
  }
}

class _CategoryBottomGapSliver extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: SizedBox(height: Theme.of(context).tokens.spaceExtraLarge),
    );
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

// ── Bookable section sync indicator (header trailing) ───────────────────────

class _AvailabilitySyncTrailing extends StatelessWidget {
  const _AvailabilitySyncTrailing({required this.isUpdatingAvailability});

  final bool isUpdatingAvailability;

  @override
  Widget build(BuildContext context) {
    if (!isUpdatingAvailability) return const SizedBox.shrink();

    final tokens = Theme.of(context).tokens;
    return SizedBox(
      width: tokens.iconSizeSmall,
      height: tokens.iconSizeSmall,
      child: const CircularProgressIndicator(strokeWidth: 2),
    );
  }
}

class _PinnedBookableSlotsControlsDelegate
    extends SliverPersistentHeaderDelegate {
  _PinnedBookableSlotsControlsDelegate({
    required this.showTopDivider,
    required this.title,
    required this.isUpdatingAvailability,
    this.weekTabController,
    this.thisWeekLabel,
    this.nextWeekLabel,
    this.days,
    this.selectedDay,
    this.onDaySelected,
    this.selectedDayCaption,
  });

  final bool showTopDivider;
  final String title;
  final bool isUpdatingAvailability;
  final TabController? weekTabController;
  final String? thisWeekLabel;
  final String? nextWeekLabel;
  final List<DateTime>? days;
  final DateTime? selectedDay;
  final ValueChanged<DateTime>? onDaySelected;
  final String? selectedDayCaption;

  bool get _showsWeekTabs =>
      weekTabController != null &&
      thisWeekLabel != null &&
      nextWeekLabel != null;

  bool get _showsDayChips =>
      days != null &&
      days!.isNotEmpty &&
      selectedDay != null &&
      onDaySelected != null;

  @override
  double get minExtent => _layoutExtent;

  @override
  double get maxExtent => _layoutExtent;

  /// Pixel-aligned extent shared by [minExtent], [maxExtent], and [build].
  ///
  /// Uses design-token defaults (not [BuildContext]) so declared geometry
  /// always matches the [SizedBox] height we paint.
  double get _layoutExtent => _rawExtent.ceilToDouble();

  static const _titleLineHeight = 24.0;
  static const _captionLineHeight = 16.0;
  static const _extentSlack = 32.0;

  double _titleExtent() {
    const spaceLarge = 16.0;
    const spaceMedium = 12.0;
    const spaceExtraSmall = 4.0;

    var height = spaceMedium + _titleLineHeight + spaceExtraSmall;
    if (showTopDivider) {
      height += spaceLarge + 1 + spaceMedium;
    }
    return height;
  }

  double _weekTabsExtent() => 16 + kTextTabBarHeight;

  double _dayChipsExtent() {
    const spaceMedium = 12.0;
    const spaceSmall = 8.0;
    const chipHeight = 76.0; // spaceXXL * 2 + spaceMedium

    var height = spaceMedium + chipHeight;
    if (selectedDayCaption != null && selectedDayCaption!.isNotEmpty) {
      height += spaceSmall + _captionLineHeight + spaceSmall;
    }
    return height;
  }

  double get _rawExtent {
    var height = _titleExtent();
    if (_showsWeekTabs) {
      height += _weekTabsExtent();
    }
    if (_showsDayChips) {
      height += _dayChipsExtent();
    }
    return height + _extentSlack;
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
    final caption = selectedDayCaption;

    return SizedBox(
      height: _layoutExtent,
      child: Material(
        color: isStuck ? scheme.surface : theme.scaffoldBackgroundColor,
        elevation: isStuck ? 1 : 0,
        shadowColor: scheme.shadow.withValues(alpha: 0.1),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                TutorDashboardSection(
                  title: title,
                  variant: TutorDashboardSectionVariant.secondary,
                  showTopDivider: showTopDivider,
                  trailing: _AvailabilitySyncTrailing(
                    isUpdatingAvailability: isUpdatingAvailability,
                  ),
                ),
                if (_showsWeekTabs)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      tokens.spaceLarge,
                      tokens.spaceSmall,
                      tokens.spaceLarge,
                      tokens.spaceSmall,
                    ),
                    child: TilawaTabBar(
                      controller: weekTabController!,
                      tabs: [
                        Tab(text: thisWeekLabel!),
                        Tab(text: nextWeekLabel!),
                      ],
                    ),
                  ),
                if (_showsDayChips) ...[
                  Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(
                      tokens.spaceLarge,
                      tokens.spaceMedium,
                      tokens.spaceLarge,
                      0,
                    ),
                    child: DateGroupedDayTabBar(
                      days: days!,
                      selected: selectedDay!,
                      onDaySelected: onDaySelected!,
                    ),
                  ),
                  if (caption != null && caption.isNotEmpty) ...[
                    SizedBox(height: tokens.spaceSmall),
                    Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(
                        tokens.spaceLarge,
                        0,
                        tokens.spaceLarge,
                        tokens.spaceSmall,
                      ),
                      child: Text(
                        caption,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
            if (isStuck)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: scheme.outlineVariant.withValues(alpha: 0.85),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedBookableSlotsControlsDelegate old) {
    return old.showTopDivider != showTopDivider ||
        old.title != title ||
        old.isUpdatingAvailability != isUpdatingAvailability ||
        old.weekTabController != weekTabController ||
        old.thisWeekLabel != thisWeekLabel ||
        old.nextWeekLabel != nextWeekLabel ||
        old.weekTabController?.index != weekTabController?.index ||
        old.days != days ||
        old.selectedDay != selectedDay ||
        old.selectedDayCaption != selectedDayCaption;
  }
}

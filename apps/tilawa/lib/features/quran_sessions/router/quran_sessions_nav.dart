import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:quran_sessions_rtc/quran_sessions_rtc.dart';
import 'package:tilawa/core/bootstrap/app_launch_config.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/core/layout/list_scroll_bottom_padding.dart';
import 'package:tilawa/features/quran_sessions/quran_sessions_launch_policy.dart';
import 'package:tilawa/features/settings/presentation/widgets/settings_teacher_capability_scope.dart';
import 'package:tilawa/features/quran_sessions/presentation/quran_sessions_analytics.dart';
import 'package:tilawa/features/quran_sessions/presentation/quran_sessions_scheduling_analytics.dart';
import 'package:tilawa/features/quran_sessions/presentation/quran_sessions_user.dart';
import 'package:tilawa/features/quran_sessions/quran_sessions_feature_flags.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../data/quran_sessions_mvp_store.dart';
import '../di/quran_sessions_backend_config.dart';

/// Routes teacher flows based on resolved [TeacherCapability].
Future<void> navigateAfterTeacherApproval(
  BuildContext context, {
  required String userId,
  required QuranSessionsAnalyticsCallbacks analytics,
  bool showBlockedMessage = false,
  bool replace = false,
}) async {
  analytics.onTeacherApplicationApproved?.call();
  final capabilityResult =
      await getIt<GetCurrentUserTeacherCapabilityUseCase>()(userId);
  if (!context.mounted) return;
  capabilityResult.fold(
    (failure) {
      TilawaFeedback.showToast(
        context,
        message: failure.toLocalizedMessage(context),
        variant: TilawaFeedbackVariant.error,
      );
    },
    (capability) {
      SettingsTeacherCapabilityScope.refreshOf(context);
      navigateForTeacherCapability(
        context,
        capability,
        analytics: analytics,
        showBlockedMessage:
            showBlockedMessage || capability.shouldCompleteTeacherProfile,
        replace: replace,
      );
    },
  );
}

void navigateForTeacherCapability(
  BuildContext context,
  TeacherCapability capability, {
  required QuranSessionsAnalyticsCallbacks analytics,
  bool showBlockedMessage = false,
  bool replace = false,
}) {
  void navigate(String route) {
    if (replace) {
      context.pushReplacement(route);
    } else {
      context.push(route);
    }
  }

  switch (capability.navigationTarget) {
    case TeacherCapabilityNavigationTarget.apply:
      analytics.onTeacherApplyStarted?.call();
      navigate(QuranSessionsRoutes.teacherApply);
    case TeacherCapabilityNavigationTarget.applicationStatus:
      analytics.onTeacherApplicationStatusViewed?.call();
      navigate(QuranSessionsRoutes.teacherApplicationStatus);
    case TeacherCapabilityNavigationTarget.completeTeacherProfile:
      if (showBlockedMessage) {
        TilawaFeedback.showToast(
          context,
          message: context.quranSessionsL10n.completeTeacherProfileFirstMessage,
          variant: TilawaFeedbackVariant.info,
        );
      }
      navigate(QuranSessionsRoutes.completeTeacherProfile);
    case TeacherCapabilityNavigationTarget.teacherDashboard:
      analytics.onTeacherDashboardOpened?.call();
      navigate(QuranSessionsRoutes.teacherDashboard);
  }
}

/// GoRouter route tree for the QuranTutor feature (legacy package: quran_sessions).
List<RouteBase> get quranSessionsRoutes => [
  GoRoute(
    path: QuranSessionsRoutes.quranTutorHome,
    redirect: (context, state) => QuranSessionsRoutes.home,
  ),
  GoRoute(
    path: QuranSessionsRoutes.home,
    builder: (context, state) => BlocProvider(
      create: (_) =>
          getIt<TeacherListBloc>()..add(const LoadTeachersRequested()),
      child: _withQuranSessionsTheme(
        _QuranSessionsHomeRoute(
          onSeeAllTeachers: () => context.push(QuranSessionsRoutes.teacherList),
          onTeacherTapped: (id) => context.push(
            QuranSessionsRoutes.teacherProfile.replaceFirst(':teacherId', id),
          ),
          onMySessions: () => context.push(QuranSessionsRoutes.mySessions),
          onWallet: quranSessionsFeatureConfig().walletEnabled
              ? () => context.push(QuranSessionsRoutes.wallet)
              : null,
          onBecomeTeacher: () => _openTeacherApply(context),
          onChangeCity: () => _openProfileCompletion(context),
        ),
      ),
    ),
  ),
  GoRoute(
    path: QuranSessionsRoutes.teacherList,
    builder: (context, state) => BlocProvider(
      create: (_) =>
          getIt<TeacherListBloc>()..add(const LoadTeachersRequested()),
      child: _withQuranSessionsTheme(
        TeacherListScreen(
          featureConfig: quranSessionsFeatureConfig(),
          analytics: quranSessionsAnalyticsCallbacks(),
          onTeacherTapped: (id) => context.push(
            QuranSessionsRoutes.teacherProfile.replaceFirst(':teacherId', id),
          ),
          onNotifyInterest: () => quranSessionsAnalyticsCallbacks()
              .onQuranSessionsNotifyInterestSubmitted
              ?.call(),
          onChangeCity: () => _openProfileCompletion(context),
          onTeacherApplyEntry:
              quranSessionsFeatureConfig().showEmptyStateTeacherEntry
              ? () => _openTeacherApply(context)
              : null,
          onEmptyStateSeen:
              quranSessionsAnalyticsCallbacks().onQuranSessionsEmptyStateSeen,
        ),
      ),
    ),
  ),
  GoRoute(
    path: QuranSessionsRoutes.teacherProfile,
    builder: (context, state) {
      final teacherId = state.pathParameters['teacherId']!;
      final bookingEnabled =
          quranSessionsFeatureConfig().quranSessionsBookingEnabled;
      return BlocProvider(
        create: (_) {
          final now = DateTime.now();
          return getIt<TeacherProfileBloc>()..add(
            TeacherProfileRequested(
              teacherId: teacherId,
              availabilityFrom: now,
              availabilityTo: now.add(const Duration(days: 14)),
            ),
          );
        },
        child: _withQuranSessionsTheme(
          TeacherProfileScreen(
            teacherId: teacherId,
            bookingEnabled: bookingEnabled,
            analytics: quranSessionsAnalyticsCallbacks(),
            onBookTapped: bookingEnabled
                ? (tId, slotId) => context.push(
                    QuranSessionsRoutes.booking.replaceFirst(':teacherId', tId),
                    extra: slotId,
                  )
                : null,
          ),
        ),
      );
    },
  ),
  GoRoute(
    path: QuranSessionsRoutes.booking,
    redirect: (context, state) {
      if (!quranSessionsFeatureConfig().quranSessionsBookingEnabled) {
        return QuranSessionsRoutes.home;
      }
      return null;
    },
    builder: (context, state) {
      final teacherId = state.pathParameters['teacherId']!;
      final preSelectedSlotId = state.extra as String?;
      final studentId = requireQuranSessionsUserId(getIt);
      final launchConfig = getIt<AppLaunchConfig>();
      return BlocProvider(
        create: (_) => getIt<BookingBloc>(),
        child: _withQuranSessionsTheme(
          BookingScreen(
            teacherId: teacherId,
            studentId: studentId,
            analytics: quranSessionsAnalyticsCallbacks(),
            preSelectedSlotId: preSelectedSlotId,
            sessionModePolicy: sessionModePolicyFromLaunchConfig(launchConfig),
            bookingModeHint: resolveQuranTutorBookingModeHint(
              launchConfig: launchConfig,
            ),
            voiceVideoProviderHint: resolveVoiceVideoProviderHint(launchConfig),
            onBookingSuccess: (_) {
              context
                ..pop()
                ..pop()
                ..push(QuranSessionsRoutes.mySessions);
            },
            onCompleteProfile: () async {
              await context.push(QuranSessionsRoutes.profileCompletion);
            },
            onGuardianApprovalRequested: () async {
              final approved = await context.push<bool>(
                QuranSessionsRoutes.guardianApproval,
                extra: studentId,
              );
              return approved ?? false;
            },
            onGuardianDashboardRequested: () {
              context.push(QuranSessionsRoutes.guardianDashboard);
            },
          ),
        ),
      );
    },
  ),
  GoRoute(
    path: QuranSessionsRoutes.mySessions,
    builder: (context, state) {
      final studentId = requireQuranSessionsUserId(getIt);
      return BlocProvider(
        create: (_) => getIt<MySessionsBloc>(),
        child: _withQuranSessionsTheme(
          MySessionsScreen(
            studentId: studentId,
            analytics: quranSessionsAnalyticsCallbacks(),
            scrollBottomPadding: listScrollBottomPadding,
            resolveTeacherName: _resolveTeacherName,
            createCallControlGateway: _createQuranSessionCallControlGateway,
            createCallTelemetry: _createCallTelemetry,
            buildCallSurface: _buildQuranSessionsCallSurface(),
            onSessionDetailRequested: (bookingId) => context.push(
              QuranSessionsRoutes.sessionDetail.replaceFirst(
                ':bookingId',
                bookingId,
              ),
            ),
            onRescheduleRequested:
                ({
                  required bookingId,
                  required teacherId,
                  required studentId,
                }) => context.push(
                  QuranSessionsRoutes.rescheduleSession.replaceFirst(
                    ':bookingId',
                    bookingId,
                  ),
                  extra: {'teacherId': teacherId, 'actorId': studentId},
                ),
          ),
        ),
      );
    },
  ),
  GoRoute(
    path: QuranSessionsRoutes.wallet,
    redirect: (context, state) {
      if (!quranSessionsFeatureConfig().walletEnabled) {
        return QuranSessionsRoutes.home;
      }
      return null;
    },
    builder: (context, state) {
      final studentId = requireQuranSessionsUserId(getIt);
      return BlocProvider(
        create: (_) => getIt<WalletBloc>(),
        child: WalletScreen(userId: studentId),
      );
    },
  ),
  GoRoute(
    path: QuranSessionsRoutes.sessionDetail,
    builder: (context, state) {
      final bookingId = state.pathParameters['bookingId']!;
      return BlocProvider(
        create: (_) => getIt<SessionDetailBloc>(),
        child: SessionDetailScreen(
          bookingId: bookingId,
          analytics: quranSessionsAnalyticsCallbacks(),
          createCallControlGateway: _createQuranSessionCallControlGateway,
          createCallTelemetry: _createCallTelemetry,
          buildCallSurface: _buildQuranSessionsCallSurface(),
          onPracticeRevisionRequested:
              ({
                required surahNumber,
                ayahNumber,
              }) {
                QuranReaderRoute(
                  surahNumber: surahNumber,
                  ayahNumber: ayahNumber,
                ).push(context);
              },
        ),
      );
    },
  ),
  GoRoute(
    path: QuranSessionsRoutes.rescheduleSession,
    builder: (context, state) {
      final bookingId = state.pathParameters['bookingId']!;
      final extra = state.extra as Map<String, String>? ?? const {};
      return BlocProvider(
        create: (_) => getIt<RescheduleBloc>(),
        child: RescheduleSessionScreen(
          bookingId: bookingId,
          teacherId: extra['teacherId'] ?? '',
          actorId: extra['actorId'] ?? requireQuranSessionsUserId(getIt),
        ),
      );
    },
  ),
  GoRoute(
    path: QuranSessionsRoutes.teacherDashboard,
    builder: (context, state) => _TeacherDashboardGate(
      childBuilder: (teacherId) => BlocProvider(
        create: (_) => getIt<TeacherDashboardBloc>(),
        child: TeacherDashboardScreen(
          teacherId: teacherId,
          onManageSchedule: () =>
              context.push(QuranSessionsRoutes.availability),
          onSessionDetailRequested: (bookingId) => context.push<bool>(
            QuranSessionsRoutes.sessionDetail.replaceFirst(
              ':bookingId',
              bookingId,
            ),
          ),
          schedulingAnalytics: quranSessionsSchedulingAnalyticsCallbacks(),
          meetingUrlSettingsBuilder: (context) => TeacherExternalMeetingUrlCard(
            userId: requireQuranSessionsUserId(getIt),
            getCapability: getIt<GetCurrentUserTeacherCapabilityUseCase>(),
            updateMeetingLink: getIt<UpdateTeacherMeetingLinkUseCase>(),
            useCardChrome: false,
          ),
        ),
      ),
    ),
  ),
  GoRoute(
    path: QuranSessionsRoutes.availability,
    builder: (context, state) => _TeacherDashboardGate(
      childBuilder: (teacherId) => BlocProvider(
        create: (_) => getIt<AvailabilityCubit>()..load(teacherId),
        child: WeeklyAvailabilityScreen(
          teacherId: teacherId,
          schedulingAnalytics: quranSessionsSchedulingAnalyticsCallbacks(),
          resolveSchedulingAnalyticsBase: () =>
              resolveTeacherSchedulingAnalyticsBase(teacherId),
        ),
      ),
    ),
  ),
  GoRoute(
    path: QuranSessionsRoutes.profileCompletion,
    builder: (context, state) {
      final userId = requireQuranSessionsUserId(getIt);
      return BlocProvider(
        create: (_) => getIt<ProfileCompletionBloc>(),
        child: ProfileCompletionScreen(userId: userId),
      );
    },
  ),
  GoRoute(
    path: QuranSessionsRoutes.guardianDashboard,
    builder: (context, state) => GuardianDashboardScreen(
      onApproveBookings: () => context.push(
        QuranSessionsRoutes.guardianApproval,
        extra: state.extra as String? ?? requireQuranSessionsUserId(getIt),
      ),
    ),
  ),
  GoRoute(
    path: QuranSessionsRoutes.guardianApproval,
    builder: (context, state) {
      final studentId =
          state.extra as String? ?? requireQuranSessionsUserId(getIt);
      return GuardianApprovalCaptureScreen(
        studentId: studentId,
        approveChildGuardianBooking:
            getIt<ApproveChildGuardianBookingUseCase>(),
      );
    },
  ),
  GoRoute(
    path: QuranSessionsRoutes.completeTeacherProfile,
    builder: (context, state) {
      final userId = requireQuranSessionsUserId(getIt);
      final analytics = quranSessionsAnalyticsCallbacks();
      return CompleteTeacherPublicProfileScreen(
        userId: userId,
        getCapability: getIt<GetCurrentUserTeacherCapabilityUseCase>(),
        saveProfile: getIt<SaveTeacherPublicProfileUseCase>(),
        onComplete: () {
          analytics.onTeacherDashboardOpened?.call();
          context
            ..pop()
            ..push(QuranSessionsRoutes.teacherDashboard);
        },
      );
    },
  ),
  GoRoute(
    path: QuranSessionsRoutes.teacherApply,
    redirect: (context, state) {
      if (!quranSessionsFeatureConfig().teacherApplicationEnabled) {
        return QuranSessionsRoutes.home;
      }
      return null;
    },
    builder: (context, state) {
      final userId = requireQuranSessionsUserId(getIt);
      final analytics = quranSessionsAnalyticsCallbacks();
      analytics.onTeacherApplyStarted?.call();
      return BlocProvider(
        create: (_) => getIt<TeacherApplicationBloc>(),
        child: TeacherApplicationScreen(
          userId: userId,
          onSubmitted: () {
            analytics.onTeacherApplicationSubmitted?.call();
            context
              ..pop()
              ..push(QuranSessionsRoutes.teacherApplicationStatus);
          },
        ),
      );
    },
  ),
  GoRoute(
    path: QuranSessionsRoutes.teacherApplicationStatus,
    builder: (context, state) {
      final userId = requireQuranSessionsUserId(getIt);
      final analytics = quranSessionsAnalyticsCallbacks();
      analytics.onTeacherApplicationStatusViewed?.call();
      return BlocProvider(
        create: (_) => getIt<TeacherApplicationBloc>(),
        child: TeacherApplicationStatusScreen(
          userId: userId,
          onApproved: () => navigateAfterTeacherApproval(
            context,
            userId: userId,
            analytics: analytics,
            replace: true,
          ),
        ),
      );
    },
  ),
];

void _openTeacherApply(BuildContext context) {
  if (!quranSessionsFeatureConfig().teacherApplicationEnabled) {
    TilawaFeedback.showToast(
      context,
      message: context.quranSessionsL10n.teacherApplicationDisabled,
      variant: TilawaFeedbackVariant.info,
    );
    return;
  }
  quranSessionsAnalyticsCallbacks().onTeacherApplyEntrySeen?.call();
  context.push(QuranSessionsRoutes.teacherApply);
}

void _openProfileCompletion(BuildContext context) async {
  await context.push(QuranSessionsRoutes.profileCompletion);
}

/// Wraps student-facing Quran Tutor screens with the feature theme scope.
Widget _withQuranSessionsTheme(Widget child) {
  return QuranSessionsThemeScope(child: child);
}

InAppCallSurfaceBuilder? _buildQuranSessionsCallSurface() {
  return (
    context, {
    required sessionId,
    required callType,
    required callProviderKind,
  }) {
    if (!getIt.isRegistered<AgoraRtcEnginePool>()) {
      return null;
    }
    final l10n = context.quranSessionsL10n;
    return buildAgoraCallSurface(
      sessionId: sessionId,
      callType: callType,
      providerKind: callProviderKind,
      enginePool: getIt<AgoraRtcEnginePool>(),
      eventHub: getIt.isRegistered<SessionCallProviderEventHub>()
          ? getIt<SessionCallProviderEventHub>()
          : null,
      labels: AgoraCallSurfaceLabels(
        connecting: l10n.inAppCallShellConnecting,
        connected: l10n.inAppCallShellConnected,
        waitingForParticipant: l10n.inAppCallShellWaitingForParticipant,
        voiceCallTitle: l10n.inAppCallShellTitle,
      ),
    );
  };
}

SessionCallControlGateway _createQuranSessionCallControlGateway(
  String sessionId,
) {
  final inner = SessionCallControlGatewayAdapter(
    provider: getIt<SessionCallProvider>(),
    sessionId: sessionId,
  );
  if (!getIt.isRegistered<QuranSessionCallTelemetryCoordinator>()) {
    return inner;
  }
  return TelemetrySessionCallControlGateway(
    inner: inner,
    telemetry: getIt<QuranSessionCallTelemetryCoordinator>(),
  );
}

QuranSessionCallTelemetryCoordinator? _createCallTelemetry() {
  if (!getIt.isRegistered<QuranSessionCallTelemetryCoordinator>()) {
    return null;
  }
  return getIt<QuranSessionCallTelemetryCoordinator>();
}

String? _resolveTeacherName(String teacherId) {
  final config = getIt<AppLaunchConfig>();
  final mode = quranSessionsBackendModeFromEnvironment(
    firebaseInitEnabled: config.firebaseInit,
  );
  if (mode == QuranSessionsBackendMode.fake) {
    return QuranSessionsMvpStore.instance.resolveTeacherName(teacherId);
  }
  return null;
}

class _QuranSessionsHomeRoute extends StatefulWidget {
  const _QuranSessionsHomeRoute({
    required this.onSeeAllTeachers,
    required this.onTeacherTapped,
    required this.onMySessions,
    this.onWallet,
    required this.onBecomeTeacher,
    required this.onChangeCity,
  });

  final VoidCallback onSeeAllTeachers;
  final void Function(String teacherId) onTeacherTapped;
  final VoidCallback onMySessions;
  final VoidCallback? onWallet;
  final VoidCallback onBecomeTeacher;
  final VoidCallback onChangeCity;

  @override
  State<_QuranSessionsHomeRoute> createState() =>
      _QuranSessionsHomeRouteState();
}

class _QuranSessionsHomeRouteState extends State<_QuranSessionsHomeRoute> {
  bool _showTeacherApplyEntry = false;

  @override
  void initState() {
    super.initState();
    _loadApplyEligibility();
  }

  Future<void> _loadApplyEligibility() async {
    final userId = quranSessionsCurrentUserId(getIt);
    if (userId == null) return;

    final accessResult = await getIt<ResolveTeacherApplicationAccessUseCase>()(
      userId,
    );
    final capabilityResult =
        await getIt<GetCurrentUserTeacherCapabilityUseCase>()(userId);
    if (!mounted) return;

    final remoteAllowed = accessResult.fold(
      (_) => false,
      (access) => access.canApplyAsTeacher,
    );
    final canShow = capabilityResult.fold((_) => false, (capability) {
      if (capability.state != TeacherCapabilityState.none) {
        return capability.canStartOrContinueApply;
      }
      return remoteAllowed;
    });
    setState(() => _showTeacherApplyEntry = canShow);
  }

  @override
  Widget build(BuildContext context) {
    return QuranSessionsHomeScreen(
      featureConfig: quranSessionsFeatureConfig(),
      analytics: quranSessionsAnalyticsCallbacks(),
      onSeeAllTeachers: widget.onSeeAllTeachers,
      onTeacherTapped: widget.onTeacherTapped,
      onMySessions: widget.onMySessions,
      onWallet: widget.onWallet,
      onBecomeTeacher: widget.onBecomeTeacher,
      onChangeCity: widget.onChangeCity,
      showTeacherApplyEntry: _showTeacherApplyEntry,
    );
  }
}

class _TeacherDashboardGate extends StatefulWidget {
  const _TeacherDashboardGate({required this.childBuilder});

  final Widget Function(String teacherId) childBuilder;

  @override
  State<_TeacherDashboardGate> createState() => _TeacherDashboardGateState();
}

class _TeacherDashboardGateState extends State<_TeacherDashboardGate> {
  bool _allowed = false;
  bool _checking = true;
  String? _teacherProfileId;

  @override
  void initState() {
    super.initState();
    _verifyAccess();
  }

  Future<void> _verifyAccess() async {
    final userId = requireQuranSessionsUserId(getIt);
    final result = await getIt<GetCurrentUserTeacherCapabilityUseCase>()(
      userId,
    );
    if (!mounted) return;

    final capability = result.fold(
      (_) => const TeacherCapability(state: TeacherCapabilityState.none),
      (value) => value,
    );

    if (capability.canAccessTeacherDashboard) {
      final teacherProfileId = capability.teacherProfileId;
      if (teacherProfileId == null) {
        setState(() => _checking = false);
        navigateForTeacherCapability(
          context,
          capability,
          analytics: quranSessionsAnalyticsCallbacks(),
          showBlockedMessage: capability.shouldCompleteTeacherProfile,
          replace: true,
        );
        return;
      }
      quranSessionsAnalyticsCallbacks().onTeacherDashboardOpened?.call();
      setState(() {
        _allowed = true;
        _checking = false;
        _teacherProfileId = teacherProfileId;
      });
      return;
    }

    setState(() => _checking = false);
    navigateForTeacherCapability(
      context,
      capability,
      analytics: quranSessionsAnalyticsCallbacks(),
      showBlockedMessage: capability.shouldCompleteTeacherProfile,
      replace: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_checking || !_allowed || _teacherProfileId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return widget.childBuilder(_teacherProfileId!);
  }
}

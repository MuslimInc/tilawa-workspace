import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/home/presentation/cubit/home_learning_cubit.dart';
import 'package:tilawa/features/quran_sessions/data/quran_sessions_mvp_store.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';
import 'home_dashboard_card.dart';
import 'home_dashboard_icon_well.dart';
import 'home_dashboard_section.dart';
import 'home_feature_pastel.dart';
import 'home_learn_quran_analytics.dart';

/// Card requesting tutoring interest with Yes/Not Now buttons.
///
/// Low-emphasis surface + tonal/ghost CTAs so prayer remains the sole filled
/// primary action on Home.
class HomeLearningInterestCard extends StatelessWidget {
  const HomeLearningInterestCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final accent = theme.colorScheme.primary;

    return HomeDashboardCard(
      surface: TilawaCardSurface.flat,
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceMedium,
        vertical: tokens.spaceSmall + tokens.spaceExtraSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            spacing: tokens.spaceSmall,
            children: [
              HomeDashboardIconWell(
                accent: accent,
                fillAlpha: HomeFeaturePastel.iconWellFillAlpha,
                extent: tokens.iconBoxSize,
                child: Icon(
                  TilawaIcons.teacherCapability,
                  size: tokens.iconSizeMedium,
                  color: accent,
                ),
              ),
              Expanded(
                child: Text(
                  context.l10n.homeLearningInterestPromptTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: tokens.spaceExtraSmall),
          Text(
            context.l10n.homeLearningInterestPromptSubtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: HomeDashboardSection.secondaryTextColor(context),
              height: 1.3,
            ),
          ),
          SizedBox(height: tokens.spaceSmall),
          Row(
            spacing: tokens.spaceSmall,
            children: [
              Expanded(
                child: TilawaButton(
                  text: context.l10n.homeLearningInterestPromptYes,
                  variant: TilawaButtonVariant.secondary,
                  size: TilawaButtonSize.small,
                  isFullWidth: true,
                  onPressed: () {
                    logHomeLearnQuranCardAction(
                      action: 'accept_interest',
                      status: 'none',
                    );
                    context.read<HomeLearningCubit>().setTutoringInterest(
                      isInterested: true,
                    );
                    context.push(QuranSessionsRoutes.home);
                  },
                ),
              ),
              Expanded(
                child: TilawaButton(
                  text: context.l10n.homeLearningInterestPromptNo,
                  variant: TilawaButtonVariant.ghost,
                  size: TilawaButtonSize.small,
                  isFullWidth: true,
                  onPressed: () {
                    logHomeLearnQuranCardAction(
                      action: 'dismiss_interest',
                      status: 'none',
                    );
                    context.read<HomeLearningCubit>().setTutoringInterest(
                      isInterested: false,
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Persistent Learn Quran entry for students who answered the interest
/// prompt with yes — keeps the section reachable from Home until a real
/// learning state takes over.
///
/// Single-row tap target (icon + copy + chevron) — no competing CTA button.
class HomeLearningBrowseCard extends StatelessWidget {
  const HomeLearningBrowseCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final accent = theme.colorScheme.primary;

    void openLearnQuran() {
      logHomeLearnQuranCardAction(action: 'open_learn_quran', status: 'browse');
      context.push(QuranSessionsRoutes.home);
    }

    return HomeDashboardCard(
      surface: TilawaCardSurface.flat,
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceMedium,
        vertical: tokens.spaceMedium,
      ),
      onTap: openLearnQuran,
      child: Row(
        spacing: tokens.spaceMedium,
        children: [
          HomeDashboardIconWell(
            accent: accent,
            fillAlpha: HomeFeaturePastel.iconWellFillAlpha,
            extent: tokens.iconBoxSize,
            child: Icon(
              TilawaIcons.teacherCapability,
              size: tokens.iconSizeMedium,
              color: accent,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              spacing: tokens.spaceExtraSmall,
              children: [
                Text(
                  context.l10n.homeLearningBrowseTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
                Text(
                  context.l10n.homeLearningBrowseSubtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: HomeDashboardSection.secondaryTextColor(context),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: tokens.iconSizeMedium,
            color: HomeDashboardSection.secondaryTextColor(context),
          ),
        ],
      ),
    );
  }
}

/// Card representing an imminent or ongoing live Quran tutoring session.
class HomeLearningNextSessionCard extends StatefulWidget {
  const HomeLearningNextSessionCard({
    super.key,
    required this.session,
    this.nowResolver,
  });

  final QuranSession session;
  final DateTime Function()? nowResolver;

  @override
  State<HomeLearningNextSessionCard> createState() =>
      _HomeLearningNextSessionCardState();
}

class _HomeLearningNextSessionCardState
    extends State<HomeLearningNextSessionCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final accent = theme.colorScheme.primary;

    final now = widget.nowResolver?.call() ?? DateTime.now();
    final startsAt = widget.session.startsAt;
    final endsAt = widget.session.endsAt;

    final isLive = !now.isBefore(startsAt) && !now.isAfter(endsAt);
    final diffInMin = startsAt.difference(now).inMinutes;

    final statusText = isLive
        ? context.l10n.homeLearningNextSessionLive
        : context.l10n.homeLearningNextSessionStartsIn(diffInMin);

    final tutorName =
        QuranSessionsMvpStore.instance.resolveTeacherName(
          widget.session.teacherId,
        ) ??
        context.quranSessionsL10n.quranTeacherFallbackName;

    return HomeDashboardCard(
      surface: TilawaCardSurface.raised,
      padding: EdgeInsets.all(tokens.spaceMedium),
      onTap: () {
        logHomeLearnQuranCardAction(
          action: 'view_details',
          status: 'nextSession',
          bookingId: widget.session.bookingId,
        );
        context.push(
          QuranSessionsRoutes.sessionDetail.replaceFirst(
            ':bookingId',
            widget.session.bookingId,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            spacing: tokens.spaceSmall,
            children: [
              HomeDashboardIconWell(
                accent: accent,
                fillAlpha: HomeFeaturePastel.iconWellFillAlpha,
                extent: tokens.iconBoxSize,
                child: Icon(
                  TilawaIcons.timer,
                  size: tokens.iconSizeLarge,
                  color: accent,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.homeLearningNextSessionTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                    ),
                    SizedBox(height: tokens.spaceTiny),
                    Row(
                      children: [
                        if (isLive) ...[
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: tokens.spaceExtraSmall),
                        ],
                        Text(
                          statusText,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: isLive
                                ? theme.colorScheme.success
                                : theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: tokens.spaceMedium),
          Text(
            tutorName,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: tokens.spaceMedium),
          SizedBox(
            width: double.infinity,
            child: TilawaButton(
              text: context.quranSessionsL10n.joinSessionNow,
              // Filled primary only while live — otherwise tonal so prayer
              // remains the sole filled accent on Home.
              variant: isLive
                  ? TilawaButtonVariant.primary
                  : TilawaButtonVariant.secondary,
              leadingIcon: const Icon(Icons.video_call_rounded),
              onPressed: () {
                logHomeLearnQuranCardAction(
                  action: 'join_call',
                  status: 'nextSession',
                  bookingId: widget.session.bookingId,
                );
                context.push(
                  QuranSessionsRoutes.sessionDetail.replaceFirst(
                    ':bookingId',
                    widget.session.bookingId,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Card representing a pending booking.
class HomeLearningPendingBookingCard extends StatelessWidget {
  const HomeLearningPendingBookingCard({
    super.key,
    required this.session,
  });

  final QuranSession session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final accent = theme.colorScheme.primary;

    final tutorName =
        QuranSessionsMvpStore.instance.resolveTeacherName(session.teacherId) ??
        context.quranSessionsL10n.quranTeacherFallbackName;

    final isPendingPayment =
        session.effectiveLifecycleStatus ==
        SessionLifecycleStatus.pendingPayment;
    final statusText = isPendingPayment
        ? context.l10n.homeLearningPendingBookingPayment
        : context.l10n.homeLearningPendingBookingApproval;

    return HomeDashboardCard(
      surface: TilawaCardSurface.raised,
      padding: EdgeInsets.all(tokens.spaceMedium),
      onTap: () {
        logHomeLearnQuranCardAction(
          action: 'view_details',
          status: 'pendingBooking',
          bookingId: session.bookingId,
        );
        context.push(
          QuranSessionsRoutes.sessionDetail.replaceFirst(
            ':bookingId',
            session.bookingId,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            spacing: tokens.spaceSmall,
            children: [
              HomeDashboardIconWell(
                accent: accent,
                fillAlpha: HomeFeaturePastel.iconWellFillAlpha,
                extent: tokens.iconBoxSize,
                child: Icon(
                  TilawaIcons.schedule,
                  size: tokens.iconSizeLarge,
                  color: accent,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.homeLearningPendingBookingTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                    ),
                    SizedBox(height: tokens.spaceTiny),
                    Text(
                      statusText,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: isPendingPayment
                            ? HomeDashboardSection.secondaryTextColor(context)
                            : HomeDashboardSection.secondaryTextColor(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: tokens.spaceMedium),
          Text(
            tutorName,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: tokens.spaceMedium),
          SizedBox(
            width: double.infinity,
            child: TilawaButton(
              text: context.quranSessionsL10n.viewSessionDetails,
              variant: TilawaButtonVariant.secondary,
              onPressed: () {
                logHomeLearnQuranCardAction(
                  action: 'view_details_btn',
                  status: 'pendingBooking',
                  bookingId: session.bookingId,
                );
                context.push(
                  QuranSessionsRoutes.sessionDetail.replaceFirst(
                    ':bookingId',
                    session.bookingId,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Card representing a completed session's revision homework.
class HomeLearningRevisionCard extends StatelessWidget {
  const HomeLearningRevisionCard({
    super.key,
    required this.revisionAggregate,
  });

  final SessionAggregate revisionAggregate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final accent = theme.colorScheme.primary;

    final surahNumber = revisionAggregate.revisionSurahNumber ?? 1;
    final ayahNumber = revisionAggregate.revisionAyahNumber;

    return HomeDashboardCard(
      surface: TilawaCardSurface.raised,
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceMedium,
        vertical: tokens.spaceSmall + tokens.spaceExtraSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            spacing: tokens.spaceSmall,
            children: [
              HomeDashboardIconWell(
                accent: accent,
                fillAlpha: HomeFeaturePastel.iconWellFillAlpha,
                extent: tokens.iconBoxSize,
                child: TilawaIcons.quran.svg(
                  color: accent,
                  size: tokens.iconSizeLarge,
                ),
              ),
              Expanded(
                child: Text(
                  context.l10n.homeLearningRevisionTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: tokens.spaceExtraSmall),
          Text(
            context.quranSessionsL10n.sessionRevisionPracticeBody(surahNumber),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: HomeDashboardSection.secondaryTextColor(context),
              height: 1.3,
            ),
          ),
          SizedBox(height: tokens.spaceMedium),
          SizedBox(
            width: double.infinity,
            child: TilawaButton(
              text: context.quranSessionsL10n.sessionRevisionPracticeAction,
              variant: TilawaButtonVariant.secondary,
              leadingIcon: Icon(
                Icons.menu_book_rounded,
                size: tokens.iconSizeMedium,
              ),
              onPressed: () async {
                logHomeLearnQuranCardAction(
                  action: 'practice_revision',
                  status: 'continueLearning',
                  bookingId: revisionAggregate.id,
                );
                // Mark as practiced immediately so card doesn't reappear
                await context.read<HomeLearningCubit>().markRevisionAsPracticed(
                  revisionAggregate.id,
                );
                if (context.mounted) {
                  QuranReaderRoute(
                    surahNumber: surahNumber,
                    ayahNumber: ayahNumber,
                  ).push(context);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
